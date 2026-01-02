//
//  DashboardView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct DashboardView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @Query private var sessions: [TrackingSession]
    @Query private var activities: [ActivityEntry]
    @State private var timerService = TimerService.shared
    @State private var showingAlarm = false
    @State private var showingCheckIn = false
    @State private var currentActivity = ""
    @State private var countdownTimer: Timer?
    @State private var timeRemaining: Int = 0
    @State private var iconOpacity: Double = 1.0
    @State private var showingAuthError = false
    @State private var motivationalMessage: String = ""
    
    // UserDefaults key for storing name as backup (in case SwiftData falls back to in-memory)
    private static let userNameKey = "DayTime_UserName"
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var activeSession: TrackingSession? {
        sessions.first { $0.isActive }
    }
    
    /// Gets the user's name from SwiftData or UserDefaults backup
    private var displayName: String {
        // First check SwiftData
        if let name = userSettings?.userName.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        // Fall back to UserDefaults
        if let name = UserDefaults.standard.string(forKey: Self.userNameKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return "Friend"
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with greeting
                VStack(spacing: 10) {
                    Text("Hello, \(displayName)! 👋")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Ready to track your productive day?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Session status
                VStack(spacing: 20) {
                    if timerService.isRunning {
                        VStack(spacing: 15) {
                            Image("clocky")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundStyle(timerService.isPaused ? .orange : .green)
                                .opacity(timerService.isPaused ? 1.0 : iconOpacity)
                            
                            Text(timerService.isPaused ? "Session Paused" : "Session Active")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundStyle(timerService.isPaused ? .orange : .primary)
                            
                            // Countdown Timer
                            VStack(spacing: 5) {
                                Text(timerService.isPaused ? "Time remaining:" : "Next check-in in:")
                                    .font(.headline)
                                    .foregroundColor(.secondary)
                                
                                Text(formatCountdown(timeRemaining))
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundStyle(timerService.isPaused ? .orange : .green)
                            }
                            
                            Text(timerService.isPaused ? "Session is paused. Tap Resume to continue." : "Clocky will check in with you every \(formatTimerInterval(timerService.timerInterval))")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 15) {
                            Image("clocky")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 80, height: 80)
                                .foregroundStyle(Color.themeColor.gradient)
                            
                            Text("Ready to Begin")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start your productivity session and Clocky will help you track your progress")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    if timerService.isRunning {
                        HStack(spacing: 10) {
                            if timerService.isPaused {
                                Button(action: {
                                    timerService.resumeSession()
                                }) {
                                    HStack {
                                        Image(systemName: "play.fill")
                                        Text("Resume")
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.themeColor.gradient)
                                    .cornerRadius(12)
                                }
                            } else {
                                Button(action: {
                                    timerService.pauseSession()
                                }) {
                                    HStack {
                                        Image(systemName: "pause.fill")
                                        Text("Pause")
                                    }
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.themeColor.gradient)
                                    .cornerRadius(12)
                                }
                            }
                            
                            Button(action: stopSession) {
                                HStack {
                                    Image(systemName: "stop.fill")
                                    Text("Stop")
                                }
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red.gradient)
                                .cornerRadius(12)
                            }
                        }
                    } else {
                        VStack(spacing: 12) {
                            Text(motivationalMessage)
                                .font(.body)
                                .fontWeight(.medium)
                                .foregroundColor(.primary)
                                .multilineTextAlignment(.center)
                                .padding(.horizontal)
                            
                            Button(action: startSession) {
                                Text("Start Tracking")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.themeColor.gradient)
                                    .cornerRadius(12)
                            }
                            
                            Button(action: {
                                showingCheckIn = true
                            }) {
                                Text("Check in Now")
                                    .font(.title3)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.themeColor)
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.themeColor.opacity(0.1))
                                    .cornerRadius(12)
                            }
                        }
                    }
                    
                    HStack(spacing: 15) {
                        NavigationLink("View Calendar") {
                            CalendarView()
                        }
                        .font(.title3)
                        .foregroundColor(.themeColor)
                        
                        NavigationLink("Day Overview") {
                            DayOverviewView()
                        }
                        .font(.title3)
                        .foregroundColor(.themeColor)
                    }
                    
                    NavigationLink {
                        DaySummaryView()
                    } label: {
                        HStack {
                            Image("clocky")
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                                .frame(width: 20, height: 20)
                                .foregroundStyle(Color.themeColor.gradient)
                            Text("See Summary")
                        }
                        .font(.title3)
                        .foregroundColor(.themeColor)
                        .frame(maxWidth: .infinity)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("DayTime")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gear")
                            .foregroundColor(.themeColor)
                    }
                }
            }
        }
        .navigationViewStyle(.stack)
        .fullScreenCover(isPresented: $showingAlarm) {
            ActivityInputView(
                isPresented: $showingAlarm,
                sessionId: timerService.currentSessionId ?? UUID(),
                activity: $currentActivity,
                onStopSession: stopSession
            )
        }
        .fullScreenCover(isPresented: $showingCheckIn) {
            ActivityInputView(
                isPresented: $showingCheckIn,
                sessionId: UUID(), // Dummy UUID for check-ins without active session
                activity: $currentActivity,
                onStopSession: nil, // No session to stop
                isManualCheckIn: true // This is a manual check-in without active session
            )
        }
        .alert("Alarm Permission Denied", isPresented: $showingAuthError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("DayTime needs permission to schedule check-in reminders. Without this permission, the app cannot track your sessions properly.")
        }
        .onAppear {
            // Load user settings first
            if let settings = userSettings {
                timerService.updateTimerInterval(settings.timerInterval)
            }
            
            setupAlarmHandling()
            
            // Clean up any lingering active sessions from previous app runs
            // Don't auto-restore - user should manually start tracking
            if let session = activeSession {
                print("⚠️ Found lingering session from \(session.startTime), cleaning it up")
                session.stop()
                
                // Make sure TimerService is also stopped
                if timerService.isRunning {
                    timerService.stopSession()
                }
            }
            
            // Ensure icon is solid when not active
            iconOpacity = 1.0
            
            // Sync Live Activity state
            timerService.syncLiveActivity()
            
            // Set random motivational message
            motivationalMessage = getRandomMotivationalMessage()
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    private func startSession() {
        Task { @MainActor in
            // Request authorization first
            do {
                try await AlarmKitService.shared.requestAuthorization()
                
                // Authorization granted, proceed with session
                let sessionId = timerService.startSession()
                let session = TrackingSession(startTime: Date())
                session.id = sessionId
                modelContext.insert(session)
                
                let calendar = Calendar.current
                let isFirstForDay = !activities.contains { activity in
                    calendar.isDate(activity.timestamp, inSameDayAs: Date())
                }
                
                if isFirstForDay {
                    let startTrackingActivity = ActivityEntry(activity: "Started Tracking", sessionId: session.id)
                    modelContext.insert(startTrackingActivity)
                }
                
                // Save context and backup
                do {
                    try modelContext.save()
                    
                    // Backup sessions and activities
                    let sessionDescriptor = FetchDescriptor<TrackingSession>()
                    let activityDescriptor = FetchDescriptor<ActivityEntry>()
                    let allSessions = try modelContext.fetch(sessionDescriptor)
                    let allActivities = try modelContext.fetch(activityDescriptor)
                    DataPersistenceService.shared.backupSessions(allSessions)
                    DataPersistenceService.shared.backupActivities(allActivities)
                } catch {
                    print("⚠️ Failed to save session: \(error)")
                }
                
                // Start the flashing animation
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    iconOpacity = 0.3
                }
                
                startCountdownTimer()
            } catch {
                // Handle authorization error
                print("⚠️ Authorization failed in startSession: \(error)")
                showingAuthError = true
            }
        }
    }
    
    private func stopSession() {
        timerService.stopSession()
        
        if let session = activeSession {
            session.stop()
        }
        
        // Save context and backup
        do {
            try modelContext.save()
            
            // Backup sessions after stopping
            let sessionDescriptor = FetchDescriptor<TrackingSession>()
            let allSessions = try modelContext.fetch(sessionDescriptor)
            DataPersistenceService.shared.backupSessions(allSessions)
        } catch {
            print("⚠️ Failed to save session stop: \(error)")
        }
        
        // Stop the flashing animation and return to solid
        withAnimation(.easeInOut(duration: 0.3)) {
            iconOpacity = 1.0
        }
        
        stopCountdownTimer()
    }
    
    private func startCountdownTimer() {
        // Calculate initial time remaining
        updateTimeRemaining()
        
        // Start the countdown timer
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            updateTimeRemaining()
        }
    }
    
    private func stopCountdownTimer() {
        countdownTimer?.invalidate()
        countdownTimer = nil
    }
    
    private func updateTimeRemaining() {
        // If paused, show the paused time remaining
        if timerService.isPaused, let pausedTime = timerService.pausedTimeRemaining {
            timeRemaining = max(0, Int(pausedTime))
        } else if let nextDate = timerService.nextCheckInDate {
            let remaining = Int(nextDate.timeIntervalSinceNow)
            timeRemaining = max(0, remaining)
        } else {
            timeRemaining = 0
        }
    }
    
    private func formatCountdown(_ seconds: Int) -> String {
        let minutes = seconds / 60
        let remainingSeconds = seconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }
    
    private func setupAlarmHandling() {
        timerService.onAlarmTriggered = {
            showingAlarm = true
        }
    }
    
    private func formatTimerInterval(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds) seconds"
        } else {
            let minutes = seconds / 60
            return "\(minutes) minutes"
        }
    }
    
    private func getRandomMotivationalMessage() -> String {
        let messages = [
            "Every great achievement begins with a single step.",
            "You've got this! Let's make today count.",
            "Small progress is still progress.",
            "Your future self will thank you.",
            "Focus on progress, not perfection.",
            "You're capable of amazing things.",
            "Today is a fresh start.",
            "Believe in yourself and all that you are.",
            "Success is the sum of small efforts repeated daily.",
            "You're stronger than you think.",
            "Make today your masterpiece.",
            "The only way to do great work is to love what you do.",
            "Dream big, work hard, stay focused.",
            "Your potential is limitless.",
            "Every moment is a new beginning.",
            "You are braver than you believe.",
            "Turn your dreams into reality.",
            "Progress, not perfection.",
            "You're on the right track.",
            "Today's effort is tomorrow's success.",
            "Stay focused, stay determined.",
            "You have the power to change your day.",
            "Every step forward counts.",
            "Your dedication will pay off.",
            "Keep going, you're doing great.",
            "Success starts with a single decision.",
            "You're building something amazing.",
            "Today's work shapes tomorrow's results.",
            "Stay positive, stay productive.",
            "You're making progress every moment.",
            "Focus on what you can control.",
            "Your hard work is paying off.",
            "Every day is a chance to improve.",
            "You're creating your own success story.",
            "Keep pushing forward.",
            "You're capable of more than you know.",
            "Today's discipline is tomorrow's freedom.",
            "You're on your way to greatness.",
            "Stay committed to your goals.",
            "You're building momentum.",
            "Every action moves you closer to your goal.",
            "You're stronger than any challenge.",
            "Today is your opportunity to shine.",
            "Keep your eyes on the prize.",
            "You're making a difference.",
            "Success is built one moment at a time.",
            "You're exactly where you need to be.",
            "Stay focused on your why.",
            "You're creating positive change.",
            "Every effort brings you closer to success."
        ]
        return messages.randomElement() ?? messages[0]
    }
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserSettings.self, TrackingSession.self], inMemory: true)
}