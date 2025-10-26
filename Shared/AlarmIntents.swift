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
    static var openAppWhenRun: Bool = true
    
    @Parameter(title: "alarmID")
    var alarmID: String
    
    func perform() throws -> some IntentResult {
        guard let id = UUID(uuidString: alarmID) else {
            throw DayTimeAlarmError.badAlarmID
        }
        
        print("🎯 UpdateClockyIntent triggered for alarm: \(id)")
        
        // Silence the alarm (stop it from ringing)
        try AlarmManager.shared.stop(id: id)
        print("🔕 Alarm silenced")
        
        // Post a Darwin notification to trigger the check-in UI
        // This works across process boundaries (widget extension -> main app)
        // The app will be opened automatically due to openAppWhenRun = true
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.daytime.showCheckIn" as CFString),
            nil,
            nil,
            true
        )
        print("📢 Posted showCheckIn notification - app will open and show check-in UI")
        
        return .result()
    }
    
    init(alarmID: UUID) {
        self.alarmID = alarmID.uuidString
    }
    
    init() {
        self.alarmID = ""
    }
}

