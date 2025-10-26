//
//  DayTimeApp.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

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
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    handleOpenURL(url)
                }
        }
        .modelContainer(sharedModelContainer)
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
    }
    
    private func handleOpenURL(_ url: URL) {
        print("📱 Opened URL: \(url)")
        
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