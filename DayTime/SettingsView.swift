//
//  SettingsView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var userName = ""
    @State private var timerInterval = 900 // 15 minutes in seconds
    private let timerService = TimerService.shared
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    let intervalOptions = [5, 30, 300, 600, 900, 1200, 1800, 2700, 3600]
    
    var body: some View {
        Form {
            Section("Personal") {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Your name", text: $userName)
                        .multilineTextAlignment(.trailing)
                }
            }
            
            Section("Timer Settings") {
                Picker("Check-in Interval", selection: $timerInterval) {
                    ForEach(intervalOptions, id: \.self) { interval in
                        Text(formatInterval(interval))
                            .tag(interval)
                    }
                }
            }
            
            Section("About") {
                Link("Privacy Policy", destination: URL(string: "https://swipefeed.live/daytime-policy")!)

                HStack {
                    Text("Version")
                    Spacer()
                    Text("1.0.0")
                        .foregroundColor(.secondary)
                }
                
                Text("Created with ❤️ by Armaan Agrawal at SwipeFeed LLC")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            loadSettings()
        }
        .onDisappear {
            saveSettings()
        }
        .onChange(of: timerInterval) { oldValue, newValue in
            // Update timer service immediately when user changes the setting
            timerService.updateTimerInterval(newValue)
            saveSettings()
        }
    }
    
    private func formatInterval(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else {
            let minutes = seconds / 60
            return "\(minutes) minutes"
        }
    }
    
    private func loadSettings() {
        if let settings = userSettings {
            userName = settings.userName
            timerInterval = settings.timerInterval
        }
    }
    
    private func saveSettings() {
        if let existingSettings = userSettings {
            existingSettings.userName = userName
            existingSettings.timerInterval = timerInterval
        } else {
            let newSettings = UserSettings(
                userName: userName,
                timerInterval: timerInterval,
                notificationSoundName: "default",
                isOnboardingComplete: true
            )
            modelContext.insert(newSettings)
        }
        
        // Update the timer service with the new interval
        timerService.updateTimerInterval(timerInterval)
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}