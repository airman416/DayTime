//
//  TimerService.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import Foundation
import UserNotifications
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
        requestNotificationPermission()
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else {
                print("Notification permission denied")
            }
        }
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
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        nextCheckInDate = nil
        syncLiveActivity()
    }
    
    private func scheduleNotifications() {
        guard isRunning, let nextDate = nextCheckInDate else { return }
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()

        let timeIntervalToNext = max(1, nextDate.timeIntervalSinceNow)

        let content = UNMutableNotificationContent()
        content.title = "🚨 DayTime Check-in!"
        content.body = "Time to log your activity! What did you accomplish?"
        content.categoryIdentifier = "DAYTIME_ALARM"
        content.threadIdentifier = "daytime-checkin"
        content.interruptionLevel = .timeSensitive
        content.sound = UNNotificationSound.default
        content.userInfo = ["sessionId": currentSessionId?.uuidString ?? ""]

        // Schedule regular
        let regularTrigger = UNTimeIntervalNotificationTrigger(timeInterval: timeIntervalToNext, repeats: false)
        let regularRequest = UNNotificationRequest(identifier: "dayTimeCheckIn_\(UUID().uuidString)", content: content, trigger: regularTrigger)
        UNUserNotificationCenter.current().add(regularRequest) { error in
            if let error = error {
                print("Error scheduling regular notification: \(error)")
            }
        }

        // Schedule 60 nags
        for i in 1...60 {
            let nagTime = timeIntervalToNext + Double(i)
            if nagTime < 1 { continue }
            let nagTrigger = UNTimeIntervalNotificationTrigger(timeInterval: nagTime, repeats: false)
            let nagRequest = UNNotificationRequest(identifier: "dayTimeNag_\(i)_\(UUID().uuidString)", content: content, trigger: nagTrigger)
            UNUserNotificationCenter.current().add(nagRequest) { error in
                if let error = error {
                    print("Error scheduling nag \(i): \(error)")
                }
            }
        }
    }
    
    func scheduleCheckInAndNags() {
        guard isRunning else { return }
        nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
        scheduleNotifications()
        syncLiveActivity()
    }
    
    func clearPendingNotifications() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }
    
    func scheduleNags() {
        guard isRunning else { return }
        clearPendingNotifications()

        let content = UNMutableNotificationContent()
        content.title = "🚨 DayTime Check-in!"
        content.body = "Time to log your activity! What did you accomplish?"
        content.categoryIdentifier = "DAYTIME_ALARM"
        content.threadIdentifier = "daytime-checkin"
        content.interruptionLevel = .timeSensitive
        content.sound = UNNotificationSound.default
        content.userInfo = ["sessionId": currentSessionId?.uuidString ?? ""]

        for i in 1...60 {
            let nagTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(i), repeats: false)
            let nagRequest = UNNotificationRequest(identifier: "dayTimeNag_\(i)_\(UUID().uuidString)", content: content, trigger: nagTrigger)
            UNUserNotificationCenter.current().add(nagRequest) { error in
                if let error = error {
                    print("Error scheduling nag \(i): \(error)")
                }
            }
        }

        nextCheckInDate = Date().addingTimeInterval(60)
        syncLiveActivity()
    }
}