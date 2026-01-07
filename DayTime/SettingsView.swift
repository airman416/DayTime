//
//  SettingsView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import SuperwallKit
import UserNotifications

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var userName = ""
    @State private var timerInterval = 900 // 15 minutes in seconds
    @State private var dailyReminderEnabled = false
    @State private var showingPermissionAlert = false
    @State private var showingPermissionExplanation = false
    private let timerService = TimerService.shared
    private let notificationService = NotificationService.shared
    
    // UserDefaults key for storing name as backup (in case SwiftData falls back to in-memory)
    private static let userNameKey = "DayTime_UserName"
    
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
            
            Section("Notifications") {
                Toggle("Daily Reminder (9am)", isOn: $dailyReminderEnabled)
                    .onChange(of: dailyReminderEnabled) { oldValue, newValue in
                        handleDailyReminderToggle(newValue: newValue)
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
        .alert("Enable Daily Reminders?", isPresented: $showingPermissionExplanation) {
            Button("Enable", role: .none) {
                requestNotificationPermission()
            }
            Button("Cancel", role: .cancel) {
                dailyReminderEnabled = false
            }
        } message: {
            Text("DayTime needs notification permission to send you daily reminders at 9am. These reminders help you stay consistent with tracking your activities and building better productivity habits.")
        }
        .alert("Notification Permission Required", isPresented: $showingPermissionAlert) {
            Button("Settings", role: .none) {
                if let settingsUrl = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsUrl)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable notifications in Settings to receive daily reminders at 9am.")
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
            dailyReminderEnabled = settings.dailyReminderEnabled
        }
        
        // If userName is empty, try to load from UserDefaults backup
        if userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            if let backupName = UserDefaults.standard.string(forKey: Self.userNameKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
               !backupName.isEmpty {
                userName = backupName
            }
        }
    }
    
    private func saveSettings() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save to UserDefaults as backup (in case SwiftData is using in-memory storage)
        if !trimmedName.isEmpty {
            UserDefaults.standard.set(trimmedName, forKey: Self.userNameKey)
        }
        
        if let existingSettings = userSettings {
            let oldName = existingSettings.userName
            existingSettings.userName = userName
            existingSettings.timerInterval = timerInterval
            existingSettings.dailyReminderEnabled = dailyReminderEnabled
            
            // Update Superwall user attributes if name changed
            if oldName != userName {
                Superwall.shared.setUserAttributes([
                    "name": userName
                ])
            }
        } else {
            let newSettings = UserSettings(
                userName: userName,
                timerInterval: timerInterval,
                notificationSoundName: "default",
                isOnboardingComplete: true,
                subscriptionStatus: "unknown",
                freeTrialEndDate: nil,
                dailyReminderEnabled: dailyReminderEnabled
            )
            modelContext.insert(newSettings)
            
            // Set user attributes in Superwall
            Superwall.shared.setUserAttributes([
                "name": userName
            ])
        }
        
        // Save context and backup settings
        do {
            try modelContext.save()
            
            // Backup settings after saving
            let descriptor = FetchDescriptor<UserSettings>()
            let allSettings = try modelContext.fetch(descriptor)
            DataPersistenceService.shared.backupSettings(allSettings)
        } catch {
            print("⚠️ Failed to save settings: \(error)")
        }
        
        // Update the timer service with the new interval
        timerService.updateTimerInterval(timerInterval)
    }
    
    private func handleDailyReminderToggle(newValue: Bool) {
        if newValue {
            // User wants to enable daily reminders - check permission status first
            Task {
                let status = await notificationService.getAuthorizationStatus()
                
                await MainActor.run {
                    if status == .notDetermined {
                        // Show explanation before requesting permission
                        showingPermissionExplanation = true
                    } else if status == .authorized {
                        // Already authorized, schedule notification
                        notificationService.scheduleDailyReminder()
                        saveSettings()
                    } else {
                        // Permission denied previously, show alert to go to Settings
                        dailyReminderEnabled = false
                        showingPermissionAlert = true
                    }
                }
            }
        } else {
            // User wants to disable daily reminders
            notificationService.removeDailyReminder()
            saveSettings()
        }
    }
    
    private func requestNotificationPermission() {
        Task {
            let granted = await notificationService.requestAuthorization()
            await MainActor.run {
                if granted {
                    notificationService.scheduleDailyReminder()
                    saveSettings()
                } else {
                    // Permission denied, revert toggle
                    dailyReminderEnabled = false
                    showingPermissionAlert = true
                }
            }
        }
    }
}

#Preview {
    NavigationView {
        SettingsView()
    }
    .modelContainer(for: [UserSettings.self], inMemory: true)
}
