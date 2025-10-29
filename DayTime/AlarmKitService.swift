//
//  AlarmKitService.swift
//  DayTime
//
//  Created by Armaan Agrawal on 10/23/25.
//

import AlarmKit
import SwiftUI
import ActivityKit

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
    private var isRescheduling = false
    
    var isAuthorized: Bool {
        alarmManager.authorizationState == .authorized
    }
    
    private init() {
        observeAlarmUpdates()
        observeAuthorizationUpdates()
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
        try await checkAuthorization()
        
        // Cancel existing alarm if any
        if let existingId = currentAlarmId {
            print("🔄 Cancelling existing alarm: \(existingId)")
            isRescheduling = true
            try? alarmManager.cancel(id: existingId)
        } else {
            // Starting fresh session, ensure flag is reset
            isRescheduling = false
        }
        
        let alarmId = UUID()
        currentAlarmId = alarmId
        
        print("⏰ Scheduling check-in alarm for \(intervalSeconds) seconds")
        
        // Create metadata
        let metadata = DayTimeAlarmMetadata(
            sessionId: sessionId,
            intervalSeconds: intervalSeconds
        )
        
        // Create check-in button (primary action - opens app without stopping session)
        let checkInButton = AlarmButton(
            text: "Check In",
            textColor: .white,
            systemImageName: "arrow.right.circle.fill"
        )
        
        // Create alert with shorter title to prevent cutoff
        let alert = AlarmPresentation.Alert(
            title: "Check In Time!",
            stopButton: checkInButton
        )
        
        let presentation = AlarmPresentation(alert: alert)
        
        // Create attributes with theme color and custom metadata
        let attributes = AlarmAttributes<DayTimeAlarmMetadata>(
            presentation: presentation,
            metadata: metadata,
            tintColor: .init(red: 0.96, green: 0.76, blue: 0.05)
        )
        
        // Calculate the fire date
        let fireDate = Date().addingTimeInterval(TimeInterval(intervalSeconds))
        
        // Create configuration with check-in intent
        let configuration = AlarmManager.AlarmConfiguration<DayTimeAlarmMetadata>(
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: UpdateClockyIntent(alarmID: alarmId),
            sound: .default
        )
        
        // Schedule the alarm
        do {
            let alarm: Alarm = try await alarmManager.schedule(id: alarmId, configuration: configuration)
            print("✅ Alarm scheduled successfully for \(fireDate)")
            print("   State: \(alarm.state)")
            isRescheduling = false
        } catch let error as NSError {
            print("❌ Failed to schedule alarm:")
            print("   Domain: \(error.domain)")
            print("   Code: \(error.code)")
            print("   Description: \(error.localizedDescription)")
            isRescheduling = false
            throw _Error.failToSchedule
        }
    }
    
    func stopSession(alarmID: UUID) throws {
        try alarmManager.cancel(id: alarmID)
        if currentAlarmId == alarmID {
            currentAlarmId = nil
        }
        isRescheduling = false
        
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
    
    func resetReschedulingFlag() {
        isRescheduling = false
    }
    
    private func observeAlarmUpdates() {
        Task {
            for await alarms in alarmManager.alarmUpdates {
                print("📢 Alarms updated: \(alarms.count) active")
                
                // Check if our current alarm exists and its state
                if let currentId = currentAlarmId,
                   let alarm = alarms.first(where: { $0.id == currentId }) {
                    
                    let alarmState = alarm.state
                    print("🔔 Alarm \(currentId) state: \(alarmState)")
                    
                    // When alarm fires (state = .alerting), trigger the check-in UI
                    // and set rescheduling flag preemptively
                    if alarmState == .alerting && !TimerService.shared.isInputPresented {
                        print("⏰ ALARM IS ALERTING! Triggering check-in UI")
                        isRescheduling = true
                        
                        // End the countdown Live Activity to prevent buffering
                        Task {
                            let activities = Activity<DayTimeActivityAttributes>.activities
                            for activity in activities {
                                await activity.end(dismissalPolicy: .immediate)
                            }
                        }
                        
                        DispatchQueue.main.async {
                            TimerService.shared.onAlarmTriggered?()
                        }
                    }
                } else if let currentId = currentAlarmId,
                          !alarms.contains(where: { $0.id == currentId }),
                          !isRescheduling {
                    // Current alarm was dismissed/deleted and we're not rescheduling
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

