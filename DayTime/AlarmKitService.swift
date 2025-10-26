//
//  AlarmKitService.swift
//  DayTime
//
//  Created by Armaan Agrawal on 10/23/25.
//

import AlarmKit
import SwiftUI

@Observable
@MainActor
class AlarmKitService {
    static let shared = AlarmKitService()
    
    enum _Error: Error, LocalizedError {
        case noAuthorized
        case unknownAuthState
        case badAlarmID
        case failToSchedule
        
        var errorDescription: String? {
            switch self {
            case .noAuthorized:
                return "Not authorized to access alarms"
            case .unknownAuthState:
                return "Unknown authorization state"
            case .badAlarmID:
                return "Invalid alarm ID"
            case .failToSchedule:
                return "Failed to schedule alarm"
            }
        }
    }
    
    private let alarmManager = AlarmManager.shared
    private var currentAlarmId: UUID?
    
    var isAuthorized: Bool {
        alarmManager.authorizationState == .authorized
    }
    
    private init() {
        observeAlarmUpdates()
        observeAuthorizationUpdates()
        observeAlarmStateChanges()
    }
    
    func requestAuthorization() async throws {
        print("🔔 Requesting AlarmKit authorization...")
        print("🔔 Current state before request: \(alarmManager.authorizationState)")
        
        // Check if NSAlarmKitUsageDescription exists in Info.plist
        if let usageDescription = Bundle.main.object(forInfoDictionaryKey: "NSAlarmKitUsageDescription") as? String {
            print("✅ Found NSAlarmKitUsageDescription: \(usageDescription)")
        } else {
            print("❌ WARNING: NSAlarmKitUsageDescription not found in Info.plist!")
        }
        
        do {
            let state = try await alarmManager.requestAuthorization()
            print("🔔 Authorization result: \(state)")
            
            if state != .authorized {
                print("❌ Authorization denied or restricted: \(state)")
                throw _Error.noAuthorized
            }
            
            print("✅ Authorization granted successfully")
        } catch let error as NSError {
            print("❌ Error during authorization request:")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            print("   UserInfo: \(error.userInfo)")
            throw error
        }
    }
    
    func scheduleCheckInAlarm(intervalSeconds: Int, sessionId: UUID) async throws {
        print("🔍 [DEBUG] ===== START ALARM SCHEDULING =====")
        print("   Interval: \(intervalSeconds) seconds")
        print("   Session ID: \(sessionId)")
        
        try await checkAuthorization()
        print("✅ [DEBUG] Authorization check passed")
        
        // Cancel existing alarm if any
        if let existingId = currentAlarmId {
            print("🔄 Cancelling existing alarm: \(existingId)")
            try? alarmManager.cancel(id: existingId)
            print("✅ [DEBUG] Existing alarm cancelled")
        }
        
        let alarmId = UUID()
        currentAlarmId = alarmId
        
        print("⏰ Scheduling new alarm \(alarmId) for \(intervalSeconds) seconds")
        
        // Create metadata
        print("🔍 [DEBUG] Creating metadata...")
        let metadata = DayTimeAlarmMetadata(
            sessionId: sessionId,
            intervalSeconds: intervalSeconds
        )
        print("✅ [DEBUG] Metadata created")
        
        // Create presentation with "Update Clocky" button
        print("🔍 [DEBUG] Creating buttons...")
        
        // Try simple stop button
        print("🔍 [DEBUG] Creating simple stop button...")
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "xmark"
        )
        print("✅ [DEBUG] Stop button created")
        
        print("🔍 [DEBUG] Creating alert with ONLY stop button (no secondary)...")
        let alert = AlarmPresentation.Alert(
            title: "Time to check in!",
            stopButton: stopButton
        )
        print("✅ [DEBUG] Alert created (minimal)")
        
        print("🔍 [DEBUG] Creating presentation...")
        let presentation = AlarmPresentation(alert: alert)
        print("✅ [DEBUG] Presentation created")
        
        // Create attributes with theme color and custom metadata
        // Following https://developer.apple.com/documentation/alarmkit/alarmattributes
        print("🔍 [DEBUG] Creating attributes...")
        
        // Try without metadata first
        print("🔍 [DEBUG] Trying attributes WITHOUT metadata...")
        let attributes = AlarmAttributes<DayTimeAlarmMetadata>(
            presentation: presentation,
            metadata: nil,
            tintColor: .init(red: 0.96, green: 0.76, blue: 0.05) // DayTime theme color
        )
        print("✅ [DEBUG] Attributes created (without metadata)")
        
        // Calculate the fire date
        let fireDate = Date().addingTimeInterval(TimeInterval(intervalSeconds))
        print("🔍 [DEBUG] Fire date calculated:")
        print("   Current time: \(Date())")
        print("   Fire date: \(fireDate)")
        print("   Time until fire: \(fireDate.timeIntervalSinceNow) seconds")
        
        // Validate fire date
        if fireDate <= Date() {
            print("❌ [DEBUG] Fire date is not in the future!")
            throw _Error.failToSchedule
        }
        
        // Create configuration with fixed schedule (one-time alarm at specific date)
        // Following https://developer.apple.com/documentation/alarmkit/scheduling-an-alarm-with-alarmkit
        print("🔍 [DEBUG] Creating configuration...")
        
        // Try minimal configuration first - no sound, no intents
        print("🔍 [DEBUG] Trying minimal configuration without sound and intents...")
        let configuration = AlarmManager.AlarmConfiguration<DayTimeAlarmMetadata>(
            schedule: .fixed(fireDate),
            attributes: attributes
        )
        print("✅ [DEBUG] Configuration created (minimal)")
        
        // Schedule the alarm
        print("🔍 [DEBUG] Calling alarmManager.schedule(id: \(alarmId), configuration: ...)")
        do {
            let alarm = try await alarmManager.schedule(id: alarmId, configuration: configuration) as Alarm
            print("✅ Alarm scheduled successfully!")
            print("   ID: \(alarmId)")
            print("   Will fire at: \(fireDate)")
            print("   State: \(alarm.state)")
            if let countdown = alarm.countdownDuration {
                print("   Countdown - preAlert: \(countdown.preAlert ?? 0)s, postAlert: \(countdown.postAlert ?? 0)s")
            }
        } catch let error as NSError {
            print("❌ [DEBUG] ===== ALARM SCHEDULING FAILED =====")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            print("   User Info: \(error.userInfo)")
            print("   Localized Failure Reason: \(error.localizedFailureReason ?? "none")")
            print("   Localized Recovery Suggestion: \(error.localizedRecoverySuggestion ?? "none")")
            
            // Try to get underlying error
            if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
                print("   Underlying Error Domain: \(underlyingError.domain)")
                print("   Underlying Error Code: \(underlyingError.code)")
                print("   Underlying Error: \(underlyingError.localizedDescription)")
            }
            
            print("🔍 [DEBUG] ===== END ERROR DETAILS =====")
            throw _Error.failToSchedule
        }
        
        print("🔍 [DEBUG] ===== ALARM SCHEDULING COMPLETED SUCCESSFULLY =====")
    }
    
    func stopSession(alarmID: UUID) throws {
        try alarmManager.cancel(id: alarmID)
        if currentAlarmId == alarmID {
            currentAlarmId = nil
        }
        
        // Notify TimerService to stop session
        DispatchQueue.main.async {
            TimerService.shared.stopSession()
        }
    }
    
    func handleUpdateClocky(alarmID: UUID) throws {
        // Silence the alarm
        try silenceAlarm(alarmID: alarmID)
        
        // Trigger the check-in view
        DispatchQueue.main.async {
            TimerService.shared.onAlarmTriggered?()
        }
    }
    
    func silenceAlarm(alarmID: UUID) throws {
        // Stop silences the alarm
        try alarmManager.stop(id: alarmID)
    }
    
    func cancelCurrentAlarm() throws {
        guard let alarmId = currentAlarmId else { return }
        try alarmManager.cancel(id: alarmId)
        currentAlarmId = nil
    }
    
    private func observeAlarmUpdates() {
        Task {
            for await alarms in alarmManager.alarmUpdates {
                print("📢 Alarms updated: \(alarms.count) active")
                
                // Check if current alarm was dismissed/deleted
                if let currentId = currentAlarmId,
                   !alarms.contains(where: { $0.id == currentId }) {
                    print("⚠️ Current alarm was dismissed - stopping session")
                    currentAlarmId = nil
                    
                    // Alarm was dismissed via X or Stop - stop session
                    DispatchQueue.main.async {
                        TimerService.shared.stopSession()
                    }
                }
            }
        }
    }
    
    private func observeAuthorizationUpdates() {
        Task {
            for await state in alarmManager.authorizationUpdates {
                print("🔐 Authorization state: \(state)")
            }
        }
    }
    
    private func observeAlarmStateChanges() {
        Task {
            // Observe all alarm state changes
            for await alarms in alarmManager.alarmUpdates {
                // Check if any of our alarms are now in the "alerting" state
                if let currentId = currentAlarmId,
                   let alarm = alarms.first(where: { $0.id == currentId }) {
                    
                    // Check alarm state
                    // Possible states: .alerting, .countdown, .paused, .scheduled
                    let alarmState = alarm.state
                    print("🔔 Alarm \(currentId) state: \(alarmState)")
                    
                    // When alarm fires (state = .alerting), trigger the check-in UI
                    // Only trigger if the input view is not already presented
                    if alarmState == .alerting && !TimerService.shared.isInputPresented {
                        print("⏰ ALARM IS ALERTING! Triggering check-in UI")
                        DispatchQueue.main.async {
                            TimerService.shared.onAlarmTriggered?()
                        }
                    }
                }
            }
        }
    }
    
    private func checkAuthorization() async throws {
        let currentState = alarmManager.authorizationState
        print("🔐 Current authorization state: \(currentState)")
        
        switch currentState {
        case .notDetermined:
            print("⚠️ Authorization not determined, requesting...")
            try await requestAuthorization()
        case .denied:
            print("❌ Authorization denied")
            throw _Error.noAuthorized
        case .authorized:
            print("✅ Authorization already granted")
            return
        @unknown default:
            print("❌ Unknown authorization state")
            throw _Error.unknownAuthState
        }
    }
}

