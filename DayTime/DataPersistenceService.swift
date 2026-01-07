//
//  DataPersistenceService.swift
//  DayTime
//
//  Created to ensure activities persist across app reinstalls
//

import Foundation
import SwiftData

/// Service to backup and restore activities using JSON files
/// This ensures data persists even if SwiftData fails or gets corrupted
class DataPersistenceService {
    static let shared = DataPersistenceService()
    
    private let backupFileName = "activities_backup.json"
    private let sessionsBackupFileName = "sessions_backup.json"
    private let settingsBackupFileName = "settings_backup.json"
    private let summariesBackupFileName = "summaries_backup.json"
    
    private init() {}
    
    /// Get the Documents directory URL for backup storage
    private var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
    
    private var activitiesBackupURL: URL {
        documentsDirectory.appendingPathComponent(backupFileName)
    }
    
    private var sessionsBackupURL: URL {
        documentsDirectory.appendingPathComponent(sessionsBackupFileName)
    }
    
    private var settingsBackupURL: URL {
        documentsDirectory.appendingPathComponent(settingsBackupFileName)
    }
    
    private var summariesBackupURL: URL {
        documentsDirectory.appendingPathComponent(summariesBackupFileName)
    }
    
    // MARK: - Backup Methods
    
    /// Backup all activities to JSON file
    func backupActivities(_ activities: [ActivityEntry]) {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = .prettyPrinted
            
            let activityData = activities.map { activity in
                [
                    "id": activity.id.uuidString,
                    "timestamp": ISO8601DateFormatter().string(from: activity.timestamp),
                    "activity": activity.activity,
                    "sessionId": activity.sessionId.uuidString
                ]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: activityData, options: .prettyPrinted)
            try jsonData.write(to: activitiesBackupURL, options: .atomic)
            
            print("✅ Backed up \(activities.count) activities to \(activitiesBackupURL.path)")
        } catch {
            print("⚠️ Failed to backup activities: \(error)")
        }
    }
    
    /// Backup all sessions to JSON file
    func backupSessions(_ sessions: [TrackingSession]) {
        do {
            let sessionData = sessions.map { session in
                var dict: [String: Any] = [
                    "id": session.id.uuidString,
                    "startTime": ISO8601DateFormatter().string(from: session.startTime),
                    "isActive": session.isActive
                ]
                if let endTime = session.endTime {
                    dict["endTime"] = ISO8601DateFormatter().string(from: endTime)
                }
                return dict
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: sessionData, options: .prettyPrinted)
            try jsonData.write(to: sessionsBackupURL, options: .atomic)
            
            print("✅ Backed up \(sessions.count) sessions to \(sessionsBackupURL.path)")
        } catch {
            print("⚠️ Failed to backup sessions: \(error)")
        }
    }
    
    /// Backup user settings to JSON file
    func backupSettings(_ settings: [UserSettings]) {
        do {
            let settingsData = settings.map { setting in
                var dict: [String: Any] = [
                    "userName": setting.userName,
                    "timerInterval": setting.timerInterval,
                    "notificationSoundName": setting.notificationSoundName,
                    "isOnboardingComplete": setting.isOnboardingComplete,
                    "subscriptionStatus": setting.subscriptionStatus,
                    "dailyReminderEnabled": setting.dailyReminderEnabled,
                    "dailyReminderHour": setting.dailyReminderHour,
                    "dailyReminderMinute": setting.dailyReminderMinute
                ]
                if let freeTrialEndDate = setting.freeTrialEndDate {
                    dict["freeTrialEndDate"] = ISO8601DateFormatter().string(from: freeTrialEndDate)
                }
                return dict
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: settingsData, options: .prettyPrinted)
            try jsonData.write(to: settingsBackupURL, options: .atomic)
            
            print("✅ Backed up \(settings.count) settings to \(settingsBackupURL.path)")
        } catch {
            print("⚠️ Failed to backup settings: \(error)")
        }
    }
    
    /// Backup summaries to JSON file
    func backupSummaries(_ summaries: [DaySummary]) {
        do {
            let dateFormatter = ISO8601DateFormatter()
            let summaryData = summaries.map { summary in
                [
                    "id": summary.id.uuidString,
                    "date": dateFormatter.string(from: summary.date),
                    "shareableOverview": summary.shareableOverview,
                    "personalInsights": summary.personalInsights,
                    "generatedDate": dateFormatter.string(from: summary.generatedDate),
                    "isFallbackMode": summary.isFallbackMode
                ]
            }
            
            let jsonData = try JSONSerialization.data(withJSONObject: summaryData, options: .prettyPrinted)
            try jsonData.write(to: summariesBackupURL, options: .atomic)
            
            print("✅ Backed up \(summaries.count) summaries to \(summariesBackupURL.path)")
        } catch {
            print("⚠️ Failed to backup summaries: \(error)")
        }
    }
    
    /// Restore summaries from JSON backup
    func restoreSummaries(modelContext: ModelContext) -> [DaySummary] {
        guard FileManager.default.fileExists(atPath: summariesBackupURL.path) else {
            print("ℹ️ No summaries backup found at \(summariesBackupURL.path)")
            return []
        }
        
        do {
            let jsonData = try Data(contentsOf: summariesBackupURL)
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
            
            let dateFormatter = ISO8601DateFormatter()
            var restoredSummaries: [DaySummary] = []
            
            for item in jsonArray {
                guard let idString = item["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let dateString = item["date"] as? String,
                      let date = dateFormatter.date(from: dateString),
                      let shareableOverview = item["shareableOverview"] as? String,
                      let personalInsights = item["personalInsights"] as? String,
                      let generatedDateString = item["generatedDate"] as? String,
                      let generatedDate = dateFormatter.date(from: generatedDateString),
                      let isFallbackMode = item["isFallbackMode"] as? Bool else {
                    continue
                }
                
                let summary = DaySummary(
                    date: date,
                    shareableOverview: shareableOverview,
                    personalInsights: personalInsights,
                    generatedDate: generatedDate,
                    isFallbackMode: isFallbackMode
                )
                summary.id = id
                modelContext.insert(summary)
                restoredSummaries.append(summary)
            }
            
            print("✅ Restored \(restoredSummaries.count) summaries from backup")
            return restoredSummaries
        } catch {
            print("⚠️ Failed to restore summaries: \(error)")
            return []
        }
    }
    
    /// Backup all data at once
    func backupAll(activities: [ActivityEntry], sessions: [TrackingSession], settings: [UserSettings], summaries: [DaySummary]) {
        backupActivities(activities)
        backupSessions(sessions)
        backupSettings(settings)
        backupSummaries(summaries)
    }
    
    // MARK: - Restore Methods
    
    /// Restore activities from JSON backup
    func restoreActivities(modelContext: ModelContext) -> [ActivityEntry] {
        guard FileManager.default.fileExists(atPath: activitiesBackupURL.path) else {
            print("ℹ️ No activities backup found at \(activitiesBackupURL.path)")
            return []
        }
        
        do {
            let jsonData = try Data(contentsOf: activitiesBackupURL)
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
            
            let dateFormatter = ISO8601DateFormatter()
            var restoredActivities: [ActivityEntry] = []
            
            for item in jsonArray {
                guard let idString = item["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let timestampString = item["timestamp"] as? String,
                      let timestamp = dateFormatter.date(from: timestampString),
                      let activity = item["activity"] as? String,
                      let sessionIdString = item["sessionId"] as? String,
                      let sessionId = UUID(uuidString: sessionIdString) else {
                    continue
                }
                
                let activityEntry = ActivityEntry(activity: activity, sessionId: sessionId, timestamp: timestamp)
                activityEntry.id = id
                modelContext.insert(activityEntry)
                restoredActivities.append(activityEntry)
            }
            
            print("✅ Restored \(restoredActivities.count) activities from backup")
            return restoredActivities
        } catch {
            print("⚠️ Failed to restore activities: \(error)")
            return []
        }
    }
    
    /// Restore sessions from JSON backup
    func restoreSessions(modelContext: ModelContext) -> [TrackingSession] {
        guard FileManager.default.fileExists(atPath: sessionsBackupURL.path) else {
            print("ℹ️ No sessions backup found at \(sessionsBackupURL.path)")
            return []
        }
        
        do {
            let jsonData = try Data(contentsOf: sessionsBackupURL)
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
            
            let dateFormatter = ISO8601DateFormatter()
            var restoredSessions: [TrackingSession] = []
            
            for item in jsonArray {
                guard let idString = item["id"] as? String,
                      let id = UUID(uuidString: idString),
                      let startTimeString = item["startTime"] as? String,
                      let startTime = dateFormatter.date(from: startTimeString),
                      let isActive = item["isActive"] as? Bool else {
                    continue
                }
                
                let session = TrackingSession(startTime: startTime)
                session.id = id
                session.isActive = isActive
                
                if let endTimeString = item["endTime"] as? String,
                   let endTime = dateFormatter.date(from: endTimeString) {
                    session.endTime = endTime
                }
                
                modelContext.insert(session)
                restoredSessions.append(session)
            }
            
            print("✅ Restored \(restoredSessions.count) sessions from backup")
            return restoredSessions
        } catch {
            print("⚠️ Failed to restore sessions: \(error)")
            return []
        }
    }
    
    /// Restore settings from JSON backup
    func restoreSettings(modelContext: ModelContext) -> [UserSettings] {
        guard FileManager.default.fileExists(atPath: settingsBackupURL.path) else {
            print("ℹ️ No settings backup found at \(settingsBackupURL.path)")
            return []
        }
        
        do {
            let jsonData = try Data(contentsOf: settingsBackupURL)
            let jsonArray = try JSONSerialization.jsonObject(with: jsonData) as? [[String: Any]] ?? []
            
            let dateFormatter = ISO8601DateFormatter()
            var restoredSettings: [UserSettings] = []
            
            for item in jsonArray {
                guard let userName = item["userName"] as? String,
                      let timerInterval = item["timerInterval"] as? Int,
                      let notificationSoundName = item["notificationSoundName"] as? String,
                      let isOnboardingComplete = item["isOnboardingComplete"] as? Bool,
                      let subscriptionStatus = item["subscriptionStatus"] as? String else {
                    continue
                }
                
                var freeTrialEndDate: Date? = nil
                if let freeTrialEndDateString = item["freeTrialEndDate"] as? String {
                    freeTrialEndDate = dateFormatter.date(from: freeTrialEndDateString)
                }
                
                // Handle dailyReminderEnabled with default value for backward compatibility
                let dailyReminderEnabled = item["dailyReminderEnabled"] as? Bool ?? false
                // Handle dailyReminderHour and dailyReminderMinute with default values for backward compatibility (default to 9:00 AM)
                let dailyReminderHour = item["dailyReminderHour"] as? Int ?? 9
                let dailyReminderMinute = item["dailyReminderMinute"] as? Int ?? 0
                
                let setting = UserSettings(
                    userName: userName,
                    timerInterval: timerInterval,
                    notificationSoundName: notificationSoundName,
                    isOnboardingComplete: isOnboardingComplete,
                    subscriptionStatus: subscriptionStatus,
                    freeTrialEndDate: freeTrialEndDate,
                    dailyReminderEnabled: dailyReminderEnabled,
                    dailyReminderHour: dailyReminderHour,
                    dailyReminderMinute: dailyReminderMinute
                )
                
                modelContext.insert(setting)
                restoredSettings.append(setting)
            }
            
            print("✅ Restored \(restoredSettings.count) settings from backup")
            return restoredSettings
        } catch {
            print("⚠️ Failed to restore settings: \(error)")
            return []
        }
    }
    
    /// Restore all data from backups
    @MainActor
    func restoreAll(modelContext: ModelContext) -> (activities: [ActivityEntry], sessions: [TrackingSession], settings: [UserSettings], summaries: [DaySummary]) {
        let activities = restoreActivities(modelContext: modelContext)
        let sessions = restoreSessions(modelContext: modelContext)
        let settings = restoreSettings(modelContext: modelContext)
        let summaries = restoreSummaries(modelContext: modelContext)
        
        // Save the context after restoring
        do {
            try modelContext.save()
            print("✅ Successfully restored all data from backups")
        } catch {
            print("⚠️ Failed to save restored data: \(error)")
        }
        
        return (activities, sessions, settings, summaries)
    }
    
    /// Check if backup files exist
    func hasBackups() -> Bool {
        return FileManager.default.fileExists(atPath: activitiesBackupURL.path) ||
               FileManager.default.fileExists(atPath: sessionsBackupURL.path) ||
               FileManager.default.fileExists(atPath: settingsBackupURL.path) ||
               FileManager.default.fileExists(atPath: summariesBackupURL.path)
    }
}

