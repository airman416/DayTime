//
//  DayTimeApp.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import SuperwallKit
import UserNotifications

@main
struct DayTimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            ActivityEntry.self,
            TrackingSession.self,
            UserSettings.self,
            DaySummary.self
        ])
        
        // Use persistent storage (not in-memory) to ensure data persists
        let modelConfiguration = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            
            // Restore from backup if SwiftData is empty
            Task { @MainActor in
                DayTimeApp.restoreFromBackupIfNeeded(container: container)
            }
            
            return container
        } catch {
            // Schema migration error - this happens when we add new properties to existing models
            print("⚠️ ModelContainer load error: \(error)")
            print("⚠️ This usually happens after adding new properties to SwiftData models.")
            print("⚠️ Attempting to restore from backup...")
            
            // Try to restore from backup before falling back to in-memory
            do {
                let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
                let fallbackContainer = try ModelContainer(for: schema, configurations: [fallbackConfig])
                
                // Restore from backup
                Task { @MainActor in
                    DayTimeApp.restoreFromBackupIfNeeded(container: fallbackContainer)
                }
                
                return fallbackContainer
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()
    
    /// Restore data from JSON backup if SwiftData is empty
    @MainActor
    private static func restoreFromBackupIfNeeded(container: ModelContainer) {
        let context = container.mainContext
        let descriptor = FetchDescriptor<ActivityEntry>()
        
        do {
            let existingActivities = try context.fetch(descriptor)
            
            // Only restore if SwiftData is empty but backup exists
            if existingActivities.isEmpty && DataPersistenceService.shared.hasBackups() {
                print("📦 SwiftData is empty but backups exist. Restoring from backup...")
                let (activities, sessions, settings, summaries) = DataPersistenceService.shared.restoreAll(modelContext: context)
                
                if !activities.isEmpty || !sessions.isEmpty || !settings.isEmpty || !summaries.isEmpty {
                    print("✅ Successfully restored \(activities.count) activities, \(sessions.count) sessions, \(settings.count) settings, and \(summaries.count) summaries from backup")
                }
            }
        } catch {
            print("⚠️ Error checking for existing data: \(error)")
        }
    }
    
    init() {
        // Configure Superwall SDK
        // API key is loaded from Info.plist (which gets values from .xcconfig build settings)
        let apiKey = Bundle.main.infoDictionary?["SUPERWALL_API_KEY"] as? String ?? ""
        Superwall.configure(apiKey: apiKey)
        
        // Set up notification delegate
        UNUserNotificationCenter.current().delegate = NotificationDelegate.shared
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .onAppear {
                    setupSuperwallDelegate()
                    checkAndScheduleNotifications()
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    private func setupSuperwallDelegate() {
        // Set up Superwall delegate to track subscription changes
        let context = sharedModelContainer.mainContext
        let delegate = DayTimeSuperwallDelegate(modelContext: context)
        Superwall.shared.delegate = delegate
        
        // Initial sync of subscription status and trial end date
        Task { @MainActor in
            updateInitialSubscriptionStatus(delegate: delegate)
        }
    }
    
    @MainActor
    private func updateInitialSubscriptionStatus(delegate: DayTimeSuperwallDelegate) {
        // Update subscription status
        let status = Superwall.shared.subscriptionStatus
        delegate.subscriptionStatusDidChange(from: .unknown, to: status)
        
        // Update trial end date
        let customerInfo = Superwall.shared.customerInfo
        delegate.customerInfoDidChange(from: customerInfo, to: customerInfo)
    }
    
    private func handleOpenURL(_ url: URL) {
        print("📱 Opened URL: \(url)")
        
        // Handle Superwall deep links first
        let handledBySuperwall = Superwall.handleDeepLink(url)
        if handledBySuperwall {
            print("✅ Superwall handled deep link: \(url)")
            return
        }
        
        // Handle AlarmKit deep link for "Update Clocky" action
        if url.scheme == "daytime" && url.host == "checkin" {
            // Trigger the check-in view
            print("✅ Triggering check-in from URL")
            DispatchQueue.main.async {
                TimerService.shared.onAlarmTriggered?()
            }
        }
    }
    
    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        // When app becomes active, check if we need to show the check-in UI
        // This handles cases where the alarm fired while the app was in the background
        if newPhase == .active && oldPhase != .active {
            print("📱 App became active - checking for pending alarms")
            // The Darwin notification observer will handle showing the UI if needed
            checkAndScheduleNotifications()
            
            // Sync live activity state when app becomes active
            // This ensures the widget has the latest state after being backgrounded
            if TimerService.shared.isRunning {
                TimerService.shared.syncLiveActivity()
            }
        } else if newPhase == .background && oldPhase == .active {
            print("📱 App going to background - ensuring live activity state is synced")
            // Final sync before going to background to ensure widget has latest state
            // TimelineView will continue updating automatically
            if TimerService.shared.isRunning {
                TimerService.shared.syncLiveActivity()
            }
        }
    }
    
    /// Check notification settings and schedule daily reminder if enabled
    private func checkAndScheduleNotifications() {
        Task {
            let context = sharedModelContainer.mainContext
            let descriptor = FetchDescriptor<UserSettings>()
            
            do {
                let settings = try context.fetch(descriptor)
                if let userSettings = settings.first, userSettings.dailyReminderEnabled {
                    // Check if we have notification permission
                    let status = await NotificationService.shared.getAuthorizationStatus()
                    if status == .authorized {
                        // Schedule the notification with user's preferred time
                        NotificationService.shared.scheduleDailyReminder(
                            hour: userSettings.dailyReminderHour,
                            minute: userSettings.dailyReminderMinute
                        )
                        let timeString = String(format: "%02d:%02d", userSettings.dailyReminderHour, userSettings.dailyReminderMinute)
                        print("✅ Daily reminder scheduled for \(timeString) (enabled in settings)")
                    } else {
                        print("ℹ️ Daily reminder is enabled but notification permission not granted")
                    }
                } else {
                    // Daily reminder is disabled, remove any scheduled notifications
                    NotificationService.shared.removeDailyReminder()
                }
            } catch {
                print("⚠️ Error checking notification settings: \(error)")
            }
        }
    }
}

// MARK: - Notification Delegate

class NotificationDelegate: NSObject, UNUserNotificationCenterDelegate {
    static let shared = NotificationDelegate()
    
    // Handle notification when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // Show notification even when app is in foreground
        completionHandler([.banner, .sound, .badge])
    }
    
    // Handle notification tap
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        
        // Check if this is a daily reminder notification
        if let type = userInfo["type"] as? String, type == "daily_reminder" {
            print("📱 Daily reminder notification tapped - app should open")
            // The app will already be opened by the system, no additional action needed
        }
        
        completionHandler()
    }
}