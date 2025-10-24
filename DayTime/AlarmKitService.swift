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
    }
    
    func requestAuthorization() async throws {
        let state = try await alarmManager.requestAuthorization()
        if state != .authorized {
            throw _Error.noAuthorized
        }
    }
    
    func scheduleCheckInAlarm(intervalSeconds: Int, sessionId: UUID) async throws {
        try await checkAuthorization()
        
        // Cancel existing alarm if any
        if let existingId = currentAlarmId {
            try? alarmManager.cancel(id: existingId)
        }
        
        let alarmId = UUID()
        currentAlarmId = alarmId
        
        // Calculate the time for the next check-in
        let fireDate = Date().addingTimeInterval(TimeInterval(intervalSeconds))
        
        // Create metadata
        let metadata = DayTimeAlarmMetadata(
            sessionId: sessionId,
            intervalSeconds: intervalSeconds
        )
        
        // Create presentation with "Update Clocky" button
        let updateClockyButton = AlarmButton(
            text: "Update Clocky",
            textColor: .white,
            systemImageName: "checkmark.circle.fill"
        )
        
        let stopButton = AlarmButton(
            text: "Stop",
            textColor: .white,
            systemImageName: "xmark"
        )
        
        let alert = AlarmPresentation.Alert(
            title: "Time to check in with Clocky!",
            stopButton: stopButton,
            secondaryButton: updateClockyButton,
            secondaryButtonBehavior: nil
        )
        
        let presentation = AlarmPresentation(alert: alert)
        
        // Create attributes with theme color
        let attributes = AlarmAttributes(
            presentation: presentation,
            metadata: metadata,
            tintColor: .init(red: 0.96, green: 0.76, blue: 0.05) // DayTime theme color
        )
        
        // Create configuration using fixed schedule for the specific fire time
        typealias AlarmConfig = AlarmManager.AlarmConfiguration<DayTimeAlarmMetadata>
        let configuration = AlarmConfig(
            countdownDuration: nil,
            schedule: .fixed(fireDate),
            attributes: attributes,
            stopIntent: StopSessionIntent(alarmID: alarmId),
            secondaryIntent: UpdateClockyIntent(alarmID: alarmId),
            sound: .default
        )
        
        // Schedule the alarm
        do {
            let _ = try await alarmManager.schedule(id: alarmId, configuration: configuration)
            print("✅ Alarm scheduled for \(fireDate)")
        } catch {
            print("❌ Failed to schedule alarm: \(error)")
            throw _Error.failToSchedule
        }
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
    
    private func checkAuthorization() async throws {
        switch alarmManager.authorizationState {
        case .notDetermined:
            try await requestAuthorization()
        case .denied:
            throw _Error.noAuthorized
        case .authorized:
            return
        @unknown default:
            throw _Error.unknownAuthState
        }
    }
}

