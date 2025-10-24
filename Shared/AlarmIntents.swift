//
//  AlarmIntents.swift
//  DayTime
//
//  Created by Armaan Agrawal on 10/23/25.
//

import AppIntents
import AlarmKit

// Error type for intents
enum DayTimeAlarmError: Error {
    case badAlarmID
}

// Stop button - terminates session
// This is called when user taps "Stop" on the alarm
struct StopSessionIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Stop"
    static var description = IntentDescription("Stop the current check-in session")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw DayTimeAlarmError.badAlarmID
        }
        
        // Cancel the alarm using AlarmManager directly
        // This will cause the alarm to be removed, which the main app detects
        // via alarmUpdates and stops the session
        try AlarmManager.shared.cancel(id: id)
        
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
// This is called when user taps "Update Clocky" on the alarm
struct UpdateClockyIntent: LiveActivityIntent {
    static var title: LocalizedStringResource = "Update Clocky"
    static var description = IntentDescription("Open app to log your activity")
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw DayTimeAlarmError.badAlarmID
        }
        
        // Silence the alarm (stop it from ringing)
        // The app will detect this and show the check-in UI
        try AlarmManager.shared.stop(id: id)
        
        // The app opening is handled via the widgetURL deep link
        // which is automatically triggered when the intent completes
        
        return .result()
    }
    
    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }
    
    init() {
        self.alarmID = ""
    }
}

