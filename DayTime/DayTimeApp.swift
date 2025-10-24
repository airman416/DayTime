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
    }
    
    private func handleOpenURL(_ url: URL) {
        print("📱 Opened URL: \(url)")
        
        // Handle AlarmKit deep link for "Update Clocky" action
        if url.scheme == "daytime" && url.host == "checkin" {
            // Trigger the check-in view
            DispatchQueue.main.async {
                TimerService.shared.onAlarmTriggered?()
            }
        }
    }
}