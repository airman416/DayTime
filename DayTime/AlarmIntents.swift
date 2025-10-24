//
//  AlarmIntents.swift
//  DayTime
//
//  Created by Armaan Agrawal on 10/23/25.
//

import AppIntents
import AlarmKit

// Stop button - terminates session
struct StopSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop the current check-in session")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw AlarmKitService._Error.badAlarmID
        }
        Task { @MainActor in
            try AlarmKitService.shared.stopSession(alarmID: id)
        }
        return .result()
    }
    
    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }
    
    init() {
        self.alarmID = ""
    }
}

// Update Clocky button - opens app to check-in view
struct UpdateClockyIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Update Clocky"
    static var description = IntentDescription("Open app to log your activity")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw AlarmKitService._Error.badAlarmID
        }
        Task { @MainActor in
            try AlarmKitService.shared.handleUpdateClocky(alarmID: id)
        }
        return .result()
    }
    
    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }
    
    init() {
        self.alarmID = ""
    }
}

