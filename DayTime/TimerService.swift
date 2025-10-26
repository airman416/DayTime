//
//  TimerService.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import Foundation
import SwiftUI
import SwiftData
import ActivityKit

// Notification names for widget actions
extension Notification.Name {
    static let pauseSession = Notification.Name("pauseSession")
    static let stopSession = Notification.Name("stopSession")
}

@Observable
class TimerService {
    static let shared = TimerService()
    
    var isRunning = false
    var isPaused = false
    var currentSessionId: UUID?
    var timerInterval: Int = 900 // 15 minutes in seconds
    var onAlarmTriggered: (() -> Void)?
    var nextCheckInDate: Date?
    var pausedTimeRemaining: TimeInterval?
    var isInputPresented = false
    
    private var liveActivityUpdateTimer: Timer? = nil
    
    private init() {
        // Setup notification observers for widget actions
        setupNotificationObservers()
    }
    
    private func setupNotificationObservers() {
        // Listen for Darwin notifications from widget extension
        let pauseCallback: CFNotificationCallback = { _, observer, name, _, _ in
            DispatchQueue.main.async {
                TimerService.shared.pauseSession()
            }
        }
        
        let stopCallback: CFNotificationCallback = { _, observer, name, _, _ in
            DispatchQueue.main.async {
                TimerService.shared.stopSession()
            }
        }
        
        let resumeCallback: CFNotificationCallback = { _, observer, name, _, _ in
            DispatchQueue.main.async {
                TimerService.shared.resumeSession()
            }
        }
        
        let showCheckInCallback: CFNotificationCallback = { _, observer, name, _, _ in
            DispatchQueue.main.async {
                print("✅ Received showCheckIn notification")
                // Only trigger if not already showing the input view
                if !TimerService.shared.isInputPresented {
                    TimerService.shared.onAlarmTriggered?()
                } else {
                    print("⚠️ Check-in UI already presented, skipping")
                }
            }
        }
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            pauseCallback,
            "com.daytime.pauseSession" as CFString,
            nil,
            .deliverImmediately
        )
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            stopCallback,
            "com.daytime.stopSession" as CFString,
            nil,
            .deliverImmediately
        )
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            resumeCallback,
            "com.daytime.resumeSession" as CFString,
            nil,
            .deliverImmediately
        )
        
        CFNotificationCenterAddObserver(
            CFNotificationCenterGetDarwinNotifyCenter(),
            nil,
            showCheckInCallback,
            "com.daytime.showCheckIn" as CFString,
            nil,
            .deliverImmediately
        )
    }
    
    // Sync countdown Live Activity (separate from AlarmKit alarm)
    func syncLiveActivity() {
        Task {
            let activities = Activity<DayTimeActivityAttributes>.activities
            
            // End Live Activity if not running at all
            guard isRunning else {
                for activity in activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
                return
            }
            
            // Create content state - includes paused state
            let nextDate = nextCheckInDate ?? Date()
            let contentState = DayTimeActivityAttributes.ContentState(
                nextCheckInTime: nextDate,
                isPaused: isPaused,
                pausedTimeRemaining: pausedTimeRemaining
            )
            let content = ActivityContent(state: contentState, staleDate: nil)

            if activities.isEmpty {
                let attributes = DayTimeActivityAttributes()
                do {
                    _ = try Activity<DayTimeActivityAttributes>.request(
                        attributes: attributes,
                        content: content,
                        pushType: nil
                    )
                } catch {
                    print("Error starting live activity: \(error.localizedDescription)")
                }
            } else {
                for activity in activities {
                    await activity.update(content)
                }
            }
        }
    }
    
    func updateTimerInterval(_ newInterval: Int) {
        timerInterval = newInterval
        
        // If a session is running AND not paused, we need to reschedule
        // Don't reschedule during restoration - only during active changes
        if isRunning && !isPaused && nextCheckInDate != nil {
            scheduleCheckInAndNags()
        }
    }
    
    func startSession() -> UUID {
        let sessionId = UUID()
        currentSessionId = sessionId
        isRunning = true
        scheduleCheckInAndNags()
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.syncLiveActivity()
        }
        return sessionId
    }
    
    func restoreSession(sessionId: UUID) {
        // Restore session state without scheduling new alarms
        currentSessionId = sessionId
        isRunning = true
        
        // Only start the update timer if not paused
        if !isPaused {
            liveActivityUpdateTimer?.invalidate()
            liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                self.syncLiveActivity()
            }
        }
    }
    
    func pauseSession() {
        guard isRunning && !isPaused else { return }
        
        isPaused = true
        
        // Calculate time remaining
        if let nextDate = nextCheckInDate {
            pausedTimeRemaining = nextDate.timeIntervalSinceNow
        }
        
        // Cancel the alarm
        Task { @MainActor in
            try? AlarmKitService.shared.cancelCurrentAlarm()
        }
        
        // Update the Live Activity to show paused state
        syncLiveActivity()
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil
    }
    
    func resumeSession() {
        guard isRunning && isPaused else { return }
        
        isPaused = false
        
        // Reschedule with remaining time
        if let remaining = pausedTimeRemaining, remaining > 0 {
            nextCheckInDate = Date().addingTimeInterval(remaining)
            scheduleAlarm(customInterval: Int(remaining))
            syncLiveActivity()
        }
        
        pausedTimeRemaining = nil
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            self.syncLiveActivity()
        }
    }
    
    func stopSession() {
        isRunning = false
        isPaused = false
        currentSessionId = nil
        nextCheckInDate = nil
        pausedTimeRemaining = nil
        
        // Cancel AlarmKit alarm
        Task { @MainActor in
            try? AlarmKitService.shared.cancelCurrentAlarm()
        }
        
        // End countdown Live Activity
        syncLiveActivity()
        liveActivityUpdateTimer?.invalidate()
        liveActivityUpdateTimer = nil
    }
    
    private func scheduleAlarm(customInterval: Int? = nil) {
        guard isRunning, let sessionId = currentSessionId else { return }
        
        let interval = customInterval ?? timerInterval
        
        Task {
            do {
                try await AlarmKitService.shared.scheduleCheckInAlarm(
                    intervalSeconds: interval,
                    sessionId: sessionId
                )
                print("✅ Successfully scheduled check-in alarm for \(interval) seconds")
            } catch {
                print("❌ Failed to schedule alarm: \(error)")
                print("   Error details: \(error.localizedDescription)")
                
                // If alarm fails, we should still notify the user
                // For now, log it - in production you might want to show an alert
            }
        }
    }
    
    func scheduleCheckInAndNags() {
        guard isRunning else { return }
        nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
        scheduleAlarm()
        // Update countdown Live Activity (separate from alarm)
        syncLiveActivity()
    }
}