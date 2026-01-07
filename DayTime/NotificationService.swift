//
//  NotificationService.swift
//  DayTime
//
//  Service for managing daily push notifications to remind users to track their day
//

import Foundation
import UserNotifications

class NotificationService {
    static let shared = NotificationService()
    
    // 50 predefined messages to remind users to track their day
    private let reminderMessages = [
        "Time to check in with Clocky! How's your day going?",
        "Don't forget to track your activities today!",
        "Ready for a quick check-in? Let's see what you've been up to!",
        "Your daily reminder: Track your progress with Clocky!",
        "Hey! How's your day shaping up? Time to log your activities!",
        "Don't let today slip away - track it with Clocky!",
        "Quick check-in time! What have you accomplished today?",
        "Stay on track! Log your activities with Clocky.",
        "Your productivity partner is here! Time to check in.",
        "Let's capture your day! Open Clocky and track your activities.",
        "Don't forget to track your day! Every moment counts.",
        "Ready to see your progress? Check in with Clocky!",
        "Time to log your activities! Your future self will thank you.",
        "Stay consistent! Track your day with Clocky.",
        "What have you been up to? Let Clocky know!",
        "Your daily tracking reminder is here! Open Clocky now.",
        "Don't miss out on tracking today's activities!",
        "Quick reminder: Log your progress with Clocky!",
        "Time to check in! How productive have you been today?",
        "Keep the momentum going! Track your day with Clocky.",
        "Your reminder to track your day is here!",
        "Don't forget - track your activities with Clocky!",
        "Ready for a productivity check-in? Open Clocky!",
        "Stay accountable! Log your activities now.",
        "Time to see how your day is going! Check in with Clocky.",
        "Your daily tracking partner is waiting! Open Clocky.",
        "Don't let today go untracked! Log your activities.",
        "Quick check-in time! What's on your agenda?",
        "Stay on top of your day! Track it with Clocky.",
        "Ready to track your progress? Clocky is here to help!",
        "Don't forget to log your activities today!",
        "Time for your daily check-in! Open Clocky now.",
        "Keep tracking! Your productivity insights await.",
        "What have you accomplished? Let Clocky know!",
        "Stay consistent with your tracking! Check in now.",
        "Your reminder: Track your day with Clocky!",
        "Don't miss tracking today! Open Clocky and log your activities.",
        "Quick productivity check-in time!",
        "Time to log your progress! Clocky is ready.",
        "Stay accountable to yourself! Track your day.",
        "Ready to see your day's progress? Check in with Clocky!",
        "Don't forget - every activity counts! Track them now.",
        "Your daily reminder is here! Open Clocky and track your day.",
        "Keep the habit going! Log your activities with Clocky.",
        "Time to check in! What have you been working on?",
        "Stay on track! Don't forget to log your activities.",
        "Ready for your daily tracking? Clocky is waiting!",
        "Don't let today slip by! Track it with Clocky.",
        "Quick reminder: Check in with Clocky and track your day!",
        "Time to log your activities! Your productivity journey continues."
    ]
    
    private init() {}
    
    /// Request notification permissions from the user
    func requestAuthorization() async -> Bool {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge])
            return granted
        } catch {
            print("⚠️ Error requesting notification authorization: \(error)")
            return false
        }
    }
    
    /// Check current notification authorization status
    func getAuthorizationStatus() async -> UNAuthorizationStatus {
        let settings = await UNUserNotificationCenter.current().notificationSettings()
        return settings.authorizationStatus
    }
    
    /// Schedule daily notification at 9am
    func scheduleDailyReminder() {
        // Remove any existing daily reminder notifications first
        removeDailyReminder()
        
        // Create notification content
        let content = UNMutableNotificationContent()
        content.title = "Daily Reminder"
        content.body = getRandomMessage()
        content.sound = .default
        content.categoryIdentifier = "DAILY_REMINDER"
        
        // Configure notification to open the app when tapped
        content.userInfo = ["type": "daily_reminder"]
        
        // Schedule for 9am every day
        var dateComponents = DateComponents()
        dateComponents.hour = 9
        dateComponents.minute = 0
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        
        // Create request with unique identifier
        let request = UNNotificationRequest(
            identifier: "daily_reminder_9am",
            content: content,
            trigger: trigger
        )
        
        // Schedule the notification
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("⚠️ Error scheduling daily reminder: \(error)")
            } else {
                print("✅ Daily reminder scheduled for 9am")
            }
        }
    }
    
    /// Remove the daily reminder notification
    func removeDailyReminder() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["daily_reminder_9am"])
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["daily_reminder_9am"])
    }
    
    /// Get a random message from the predefined list
    private func getRandomMessage() -> String {
        return reminderMessages.randomElement() ?? reminderMessages[0]
    }
    
    /// Update the scheduled notification with a new random message
    /// This is useful if you want to refresh the message periodically
    func refreshNotificationMessage() {
        // Check if notification is already scheduled
        UNUserNotificationCenter.current().getPendingNotificationRequests { requests in
            if requests.contains(where: { $0.identifier == "daily_reminder_9am" }) {
                // Reschedule with new message
                self.scheduleDailyReminder()
            }
        }
    }
}

