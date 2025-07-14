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
    @State private var timerService = TimerService.shared
    @State private var showingAlarm = false
    @State private var currentActivity = ""
    @State private var isSessionActive = false
    @State private var lastNotificationTime: Date?
    
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
                    if isSessionActive {
                        VStack(spacing: 15) {
                            Image(systemName: "timer")
                                .font(.system(size: 60))
                                .foregroundStyle(.green.gradient)
                                .symbolEffect(.pulse)
                            
                            Text("Session Active")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("We'll check in with you every \(formatTimerInterval(timerService.timerInterval))")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    } else {
                        VStack(spacing: 15) {
                            Image(systemName: "play.circle")
                                .font(.system(size: 60))
                                .foregroundStyle(Color.dayTimePurple.gradient)
                            
                            Text("Ready to Begin")
                                .font(.title2)
                                .fontWeight(.semibold)
                            
                            Text("Start your productivity session and we'll help you track your progress")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                    }
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    if isSessionActive {
                        Button(action: stopSession) {
                            Text("Stop Session")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.red.gradient)
                                .cornerRadius(12)
                        }
                    } else {
                        Button(action: startSession) {
                            Text("Start Tracking")
                                .font(.title3)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.dayTimePurple.gradient)
                                .cornerRadius(12)
                        }
                    }
                    
                    HStack(spacing: 15) {
                        NavigationLink("View Calendar") {
                            CalendarView()
                        }
                        .font(.title3)
                        .foregroundColor(.dayTimePurple)
                        
                        NavigationLink("Day Overview") {
                            DayOverviewView()
                        }
                        .font(.title3)
                        .foregroundColor(.dayTimePurple)
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
                            .foregroundColor(.dayTimePurple)
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showingAlarm) {
            ActivityInputView(
                isPresented: $showingAlarm,
                sessionId: timerService.currentSessionId ?? UUID(),
                activity: $currentActivity,
                onStopSession: stopSession
            )
        }
        .onAppear {
            isSessionActive = activeSession != nil
            if let settings = userSettings {
                timerService.updateTimerInterval(settings.timerInterval)
            }
            setupAlarmHandling()
        }
    }
    
    private func startSession() {
        let sessionId = timerService.startSession()
        let session = TrackingSession(startTime: Date())
        session.id = sessionId
        modelContext.insert(session)
        
        withAnimation(.spring()) {
            isSessionActive = true
        }
        
        lastNotificationTime = Date()
    }
    
    private func stopSession() {
        timerService.stopSession()
        
        if let session = activeSession {
            session.stop()
        }
        
        withAnimation(.spring()) {
            isSessionActive = false
        }
        
        lastNotificationTime = nil
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