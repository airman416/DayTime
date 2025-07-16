//
//  DayTimeApp.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import UserNotifications

@main
struct DayTimeApp: App {
    @StateObject private var notificationDelegate = AppNotificationDelegate()
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ActivityEntry.self,
            TrackingSession.self,
            UserSettings.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onAppear {
                    setupNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().delegate = notificationDelegate
        
        // Register notification categories
        let openAction = UNNotificationAction(
            identifier: "OPEN_APP",
            title: "Open App",
            options: [.foreground]
        )
        
        let category = UNNotificationCategory(
            identifier: "DAYTIME_ALARM",
            actions: [openAction],
            intentIdentifiers: [],
            options: [.allowInCarPlay, .customDismissAction]
        )
        
        UNUserNotificationCenter.current().setNotificationCategories([category])
    }
}

class AppNotificationDelegate: NSObject, UNUserNotificationCenterDelegate, ObservableObject {
    
    // This allows notifications to show even when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        if notification.request.content.categoryIdentifier == "DAYTIME_ALARM" {
            // Show the alarm notification with sound even when app is open
            completionHandler([.banner, .sound, .badge])
            
            // Also trigger the in-app alarm
            DispatchQueue.main.async {
                TimerService.shared.onAlarmTriggered?()
            }
        } else {
            completionHandler([])
        }
    }
    
    // Handle when user taps the notification
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        
        if response.notification.request.content.categoryIdentifier == "DAYTIME_ALARM" {
            DispatchQueue.main.async {
                // Trigger the alarm view when notification is tapped
                TimerService.shared.onAlarmTriggered?()
            }
        }
        
        completionHandler()
    }
}