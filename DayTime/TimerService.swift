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
    
    func updateTimerInterval(_ newInterval: Int) {
        timerInterval = newInterval
        
        // If a session is running, we need to reschedule
        if isRunning {
            scheduleCheckInAndNags()
            
            // Update live activity
            Task {
                if let nextCheckInDate = nextCheckInDate {
                    let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextCheckInDate)
                    let content = ActivityContent(state: contentState, staleDate: nextCheckInDate.addingTimeInterval(60))
                    
                    for activity in Activity<DayTimeActivityAttributes>.activities {
                        await activity.update(content)
                    }
                }
            }
        }
    }
    
    func startSession() -> UUID {
        let sessionId = UUID()
        currentSessionId = sessionId
        isRunning = true
        scheduleCheckInAndNags()

        // Start live activity
        let attributes = DayTimeActivityAttributes()
        let nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
        let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextCheckInDate)
        let content = ActivityContent(state: contentState, staleDate: nextCheckInDate.addingTimeInterval(60))
        
        self.nextCheckInDate = nextCheckInDate

        do {
            _ = try Activity<DayTimeActivityAttributes>.request(
                attributes: attributes,
                content: content,
                pushType: nil)
        } catch (let error) {
            print("Error starting live activity: \(error.localizedDescription)")
        }

        return sessionId
    }
    
    func stopSession() {
        isRunning = false
        currentSessionId = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        nextCheckInDate = nil

        // End all live activities
        Task {
            for activity in Activity<DayTimeActivityAttributes>.activities {
                await activity.end(dismissalPolicy: .immediate)
            }
        }
    }
    
    private func scheduleRepeatingNotifications() {
        guard isRunning else { return }
        
        // Schedule multiple notifications (iOS allows up to 64 pending notifications)
        for i in 1...60 { // Schedule for next 60 intervals
            let content = UNMutableNotificationContent()
            content.title = "🚨 DayTime Check-in!"
            content.body = "Time to log your activity! What did you accomplish?"
            content.categoryIdentifier = "DAYTIME_ALARM"
            content.threadIdentifier = "daytime-checkin"
            // Time-sensitive can break through some DND settings
            content.interruptionLevel = .timeSensitive
            content.userInfo = ["sessionId": currentSessionId?.uuidString ?? ""]
            content.sound = UNNotificationSound.default
            
            let triggerTime = TimeInterval(timerInterval * i)
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: triggerTime, repeats: false)
            
            let request = UNNotificationRequest(
                identifier: "dayTimeAlarm_\(i)",
                content: content,
                trigger: trigger
            )
            
            UNUserNotificationCenter.current().add(request) { error in
                if let error = error {
                    print("Error scheduling notification \(i): \(error)")
                }
            }
        }
    }
    
    func scheduleCheckInAndNags() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        guard isRunning else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "🚨 DayTime Check-in!"
        content.body = "Time to log your activity! What did you accomplish?"
        content.categoryIdentifier = "DAYTIME_ALARM"
        content.threadIdentifier = "daytime-checkin"
        content.interruptionLevel = .timeSensitive
        content.sound = UNNotificationSound.default
        content.userInfo = ["sessionId": currentSessionId?.uuidString ?? ""]
        
        // Schedule regular
        let regularTrigger = UNTimeIntervalNotificationTrigger(timeInterval: TimeInterval(timerInterval), repeats: false)
        let regularRequest = UNNotificationRequest(identifier: "dayTimeCheckIn_\(UUID().uuidString)", content: content, trigger: regularTrigger)
        UNUserNotificationCenter.current().add(regularRequest) { error in
            if let error = error {
                print("Error scheduling regular notification: \(error)")
            }
        }
        
        // Schedule 60 nags
        for i in 1...60 {
            let nagTime = TimeInterval(timerInterval + i)
            let nagTrigger = UNTimeIntervalNotificationTrigger(timeInterval: nagTime, repeats: false)
            let nagRequest = UNNotificationRequest(identifier: "dayTimeNag_\(i)_\(UUID().uuidString)", content: content, trigger: nagTrigger)
            UNUserNotificationCenter.current().add(nagRequest) { error in
                if let error = error {
                    print("Error scheduling nag \(i): \(error)")
                }
            }
        }
        
        nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
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
        
        // Update live activity
        Task {
            let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextCheckInDate!)
            let content = ActivityContent(state: contentState, staleDate: nextCheckInDate!.addingTimeInterval(60))
            for activity in Activity<DayTimeActivityAttributes>.activities {
                await activity.update(content)
            }
        }
    }
}