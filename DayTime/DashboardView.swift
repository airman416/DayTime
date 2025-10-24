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
    @State private var currentActivity = ""
    @State private var countdownTimer: Timer?
    @State private var timeRemaining: Int = 0
    @State private var iconOpacity: Double = 1.0
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var activeSession: TrackingSession? {
        sessions.first { $0.isActive }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header with greeting
                VStack(spacing: 10) {
                    Text("Hello, \(userSettings?.userName ?? "Friend")! 👋")
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
        .onAppear {
            timerService.isRunning = activeSession != nil
            if let settings = userSettings {
                timerService.updateTimerInterval(settings.timerInterval)
            }
            setupAlarmHandling()
            
            if timerService.isRunning {
                startCountdownTimer()
                // Start flashing animation for existing active session
                withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                    iconOpacity = 0.3
                }
            } else {
                // Ensure icon is solid when not active
                iconOpacity = 1.0
            }
            
            // Sync countdown Live Activity
            timerService.syncLiveActivity()
            
            // Check for overdue - now handled by AlarmKit
            if timerService.isRunning,
               let nextDate = timerService.nextCheckInDate,
               Date() > nextDate {
                showingAlarm = true
            }
        }
        .onDisappear {
            stopCountdownTimer()
        }
    }
    
    private func startSession() {
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
        
        // Start the flashing animation
        withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
            iconOpacity = 0.3
        }
        
        startCountdownTimer()
    }
    
    private func stopSession() {
        timerService.stopSession()
        
        if let session = activeSession {
            session.stop()
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
}

#Preview {
    DashboardView()
        .modelContainer(for: [UserSettings.self, TrackingSession.self], inMemory: true)
}