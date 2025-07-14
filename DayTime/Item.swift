//
//  Models.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import Foundation
import SwiftData

@Model
final class ActivityEntry {
    var id: UUID
    var timestamp: Date
    var activity: String
    var sessionId: UUID
    
    init(activity: String, sessionId: UUID, timestamp: Date = Date()) {
        self.id = UUID()
        self.activity = activity
        self.sessionId = sessionId
        self.timestamp = timestamp
    }
}

@Model
final class TrackingSession {
    var id: UUID
    var startTime: Date
    var endTime: Date?
    var isActive: Bool
    
    init(startTime: Date = Date()) {
        self.id = UUID()
        self.startTime = startTime
        self.endTime = nil
        self.isActive = true
    }
    
    func stop() {
        self.endTime = Date()
        self.isActive = false
    }
}

@Model
final class UserSettings {
    var userName: String
    var timerInterval: Int // in seconds
    var notificationSoundName: String
    var isOnboardingComplete: Bool
    
    init(userName: String = "", timerInterval: Int = 900, notificationSoundName: String = "default", isOnboardingComplete: Bool = false) { // 900 seconds = 15 minutes
        self.userName = userName
        self.timerInterval = timerInterval
        self.notificationSoundName = notificationSoundName
        self.isOnboardingComplete = isOnboardingComplete
    }
}