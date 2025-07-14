//
//  ContentView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var isOnboardingComplete = false
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        Group {
            if isOnboardingComplete {
                DashboardView()
            } else {
                OnboardingView(isOnboardingComplete: $isOnboardingComplete)
            }
        }
        .onAppear {
            checkOnboardingStatus()
        }
    }
    
    private func checkOnboardingStatus() {
        if let settings = userSettings, settings.isOnboardingComplete {
            isOnboardingComplete = true
        }
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [UserSettings.self, ActivityEntry.self, TrackingSession.self], inMemory: true)
}