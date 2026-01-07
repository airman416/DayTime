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
    var subscriptionStatus: String // "active", "inactive", or "unknown"
    var freeTrialEndDate: Date?
    var dailyReminderEnabled: Bool
    var dailyReminderHour: Int // Hour (0-23) for daily reminder
    var dailyReminderMinute: Int // Minute (0-59) for daily reminder
    
    init(userName: String = "", timerInterval: Int = 900, notificationSoundName: String = "default", isOnboardingComplete: Bool = false, subscriptionStatus: String = "unknown", freeTrialEndDate: Date? = nil, dailyReminderEnabled: Bool = false, dailyReminderHour: Int = 9, dailyReminderMinute: Int = 0) { // 900 seconds = 15 minutes, default reminder at 9:00am
        self.userName = userName
        self.timerInterval = timerInterval
        self.notificationSoundName = notificationSoundName
        self.isOnboardingComplete = isOnboardingComplete
        self.subscriptionStatus = subscriptionStatus
        self.freeTrialEndDate = freeTrialEndDate
        self.dailyReminderEnabled = dailyReminderEnabled
        self.dailyReminderHour = dailyReminderHour
        self.dailyReminderMinute = dailyReminderMinute
    }
}

@Model
final class DaySummary {
    var id: UUID
    var date: Date // The date this summary is for (start of day)
    var shareableOverview: String
    var personalInsights: String
    var generatedDate: Date // When the summary was generated
    var isFallbackMode: Bool // Whether this is a fallback summary (no AI)
    
    init(date: Date, shareableOverview: String, personalInsights: String, generatedDate: Date = Date(), isFallbackMode: Bool = false) {
        self.id = UUID()
        self.date = Calendar.current.startOfDay(for: date)
        self.shareableOverview = shareableOverview
        self.personalInsights = personalInsights
        self.generatedDate = generatedDate
        self.isFallbackMode = isFallbackMode
    }
    
    /// Convert to GeminiService.DaySummary for compatibility
    func toGeminiSummary() -> GeminiService.DaySummary {
        return GeminiService.DaySummary(
            shareableOverview: shareableOverview,
            personalInsights: personalInsights,
            generatedDate: generatedDate
        )
    }
}