//
//  DayTimeApp.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import SuperwallKit

@main
struct DayTimeApp: App {
    @Environment(\.scenePhase) private var scenePhase
    
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
            // Schema migration error - this happens when we add new properties to existing models
            print("⚠️ ModelContainer load error: \(error)")
            print("⚠️ This usually happens after adding new properties to SwiftData models.")
            print("⚠️ Solution: Delete the app from your device/simulator and reinstall.")
            print("⚠️ Falling back to in-memory storage for this session...")
            
            // Use in-memory storage as fallback so the app doesn't crash
            let fallbackConfig = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallbackConfig])
            } catch {
                fatalError("Could not create ModelContainer even with in-memory storage: \(error)")
            }
        }
    }()
    
    init() {
        // Configure Superwall SDK
        let apiKey = "pk_ZLANkTPR-wJCkJy0vNp5m"
        Superwall.configure(apiKey: apiKey)
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleOpenURL(url)
                }
                .onAppear {
                    setupSuperwallDelegate()
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
        }
    }
}