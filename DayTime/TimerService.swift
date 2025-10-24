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

@Observable
class TimerService {
    static let shared = TimerService()
    
    var isRunning = false
    var currentSessionId: UUID?
    var timerInterval: Int = 900 // 15 minutes in seconds
    var onAlarmTriggered: (() -> Void)?
    var nextCheckInDate: Date?
    var isInputPresented = false
    
    private init() {
        // Initialization
    }
    
    func syncLiveActivity() {
        Task {
            let activities = Activity<DayTimeActivityAttributes>.activities
            guard isRunning, let nextDate = nextCheckInDate else {
                for activity in activities {
                    await activity.end(dismissalPolicy: .immediate)
                }
                return
            }

            let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextDate)
            let content = ActivityContent(state: contentState, staleDate: nextDate.addingTimeInterval(60))

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
        
        // If a session is running, we need to reschedule
        if isRunning {
            scheduleCheckInAndNags()
        }
    }
    
    func startSession() -> UUID {
        let sessionId = UUID()
        currentSessionId = sessionId
        isRunning = true
        scheduleCheckInAndNags()
        return sessionId
    }
    
    func stopSession() {
        isRunning = false
        currentSessionId = nil
        nextCheckInDate = nil
        
        // Cancel AlarmKit alarm
        Task { @MainActor in
            try? AlarmKitService.shared.cancelCurrentAlarm()
        }
        
        syncLiveActivity()
    }
    
    private func scheduleAlarm() {
        guard isRunning, let sessionId = currentSessionId else { return }
        
        Task {
            do {
                try await AlarmKitService.shared.scheduleCheckInAlarm(
                    intervalSeconds: timerInterval,
                    sessionId: sessionId
                )
            } catch {
                print("❌ Failed to schedule alarm: \(error)")
            }
        }
    }
    
    func scheduleCheckInAndNags() {
        guard isRunning else { return }
        nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
        scheduleAlarm()
        syncLiveActivity()
    }
}