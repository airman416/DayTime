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
        }
    }
    
    func startSession() -> UUID {
        let sessionId = UUID()
        currentSessionId = sessionId
        isRunning = true
        scheduleRepeatingNotifications()
        return sessionId
    }
    
    func stopSession() {
        isRunning = false
        currentSessionId = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
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