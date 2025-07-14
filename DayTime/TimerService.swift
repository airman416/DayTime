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
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            scheduleRepeatingNotifications()

            // Update live activity
            Task {
                let nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
                let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextCheckInDate)
                let content = ActivityContent(state: contentState, staleDate: nextCheckInDate.addingTimeInterval(60))

                for activity in Activity<DayTimeActivityAttributes>.activities {
                    await activity.update(content)
                }
            }
        }
    }
    
    func startSession() -> UUID {
        let sessionId = UUID()
        currentSessionId = sessionId
        isRunning = true
        scheduleRepeatingNotifications()

        // Start live activity
        let attributes = DayTimeActivityAttributes()
        let nextCheckInDate = Date().addingTimeInterval(TimeInterval(timerInterval))
        let contentState = DayTimeActivityAttributes.ContentState(nextCheckInTime: nextCheckInDate)
        let content = ActivityContent(state: contentState, staleDate: nextCheckInDate.addingTimeInterval(60))

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
}