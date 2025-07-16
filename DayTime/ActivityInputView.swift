//
//  ActivityInputView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct ActivityInputView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var settings: [UserSettings]
    @Binding var isPresented: Bool
    let sessionId: UUID
    @Binding var activity: String
    @State private var activityText = ""
    @State private var hasStartedTyping = false
    @State private var didSubmit = false
    @FocusState private var isTextFieldFocused: Bool
    var onStopSession: (() -> Void)?
    @State private var nagsScheduledDueToBackground = false
    @Environment(\.scenePhase) private var scenePhase
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var formattedInterval: String {
        let interval = userSettings?.timerInterval ?? 900
        if interval < 60 {
            return "\(interval) seconds"
        } else {
            let minutes = interval / 60
            return "\(minutes) minute\(minutes == 1 ? "" : "s")"
        }
    }
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image("clocky")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 80, height: 80)
                        .foregroundStyle(Color.themeColor.gradient)
                    
                    Text("Check-in Time!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("What did you accomplish in the last \(formattedInterval)?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(nil)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                // Text input
                VStack(alignment: .leading, spacing: 15) {
                    Text("Your Activity")
                        .font(.headline)
                    
                    TextField("Describe what you worked on...", text: $activityText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                        .font(.body)
                    
                    // Done button
                    Button(action: saveActivity) {
                        Text("Done")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.themeColor.gradient)
                            .cornerRadius(12)
                    }
                    .disabled(activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
                
                Spacer(minLength: 100)
                }
                .padding()
            }
            .scrollDisabled(true)
            .scrollDismissesKeyboard(.never)
            .navigationTitle("Activity Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .ignoresSafeArea(.keyboard, edges: .bottom)
            .onChange(of: scenePhase) { _, newPhase in
                if newPhase == .background {
                    if !didSubmit && hasStartedTyping {
                        TimerService.shared.scheduleNags()
                        nagsScheduledDueToBackground = true
                    }
                }
            }
        }
        .onAppear {
            // Auto-focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
            TimerService.shared.isInputPresented = true
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
        .onChange(of: activityText) { oldValue, newValue in
            if !newValue.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !hasStartedTyping {
                TimerService.shared.clearPendingNotifications()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                hasStartedTyping = true
            }
            if nagsScheduledDueToBackground {
                TimerService.shared.clearPendingNotifications()
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                nagsScheduledDueToBackground = false
            }
        }
        .onDisappear {
            if !didSubmit && hasStartedTyping {
                TimerService.shared.scheduleNags()
            }
            TimerService.shared.isInputPresented = false
        }
    }
    
    private func saveActivity() {
        let entry = ActivityEntry(
            activity: activityText.trimmingCharacters(in: .whitespacesAndNewlines),
            sessionId: sessionId
        )
        modelContext.insert(entry)
        
        activity = activityText
        activityText = ""
        didSubmit = true
        isPresented = false
        TimerService.shared.scheduleCheckInAndNags()
    }
    
    private func saveActivityAndStop() {
        let entry = ActivityEntry(
            activity: activityText.trimmingCharacters(in: .whitespacesAndNewlines),
            sessionId: sessionId
        )
        modelContext.insert(entry)
        
        didSubmit = true
        onStopSession?()
        isPresented = false
    }
}

#Preview {
    ActivityInputView(
        isPresented: .constant(true),
        sessionId: UUID(),
        activity: .constant("")
    )
    .modelContainer(for: [ActivityEntry.self, UserSettings.self], inMemory: true)
}