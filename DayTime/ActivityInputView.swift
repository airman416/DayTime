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
    @Binding var isPresented: Bool
    let sessionId: UUID
    @Binding var activity: String
    @State private var activityText = ""
    @FocusState private var isTextFieldFocused: Bool
    var onStopSession: (() -> Void)?
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Header
                VStack(spacing: 15) {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 60))
                        .foregroundStyle(Color.dayTimePurple.gradient)
                    
                    Text("Check-in Time!")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("What did you accomplish in the last 15 minutes?")
                        .font(.title3)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                
                // Text input
                VStack(alignment: .leading, spacing: 10) {
                    Text("Your Activity")
                        .font(.headline)
                    
                    TextField("Describe what you worked on...", text: $activityText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .focused($isTextFieldFocused)
                        .font(.body)
                }
                
                Spacer()
                
                // Action buttons
                VStack(spacing: 15) {
                    Button(action: saveActivity) {
                        Text("Keep Going")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.dayTimePurple.gradient)
                            .cornerRadius(12)
                    }
                    .disabled(activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                    
                    Button(action: saveActivityAndStop) {
                        Text("Save & Stop Session")
                            .font(.title3)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.orange.gradient)
                            .cornerRadius(12)
                    }
                    .disabled(activityText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .padding()
            .navigationTitle("Activity Check-in")
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
        }
        .onAppear {
            // Auto-focus the text field when the view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isTextFieldFocused = true
            }
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
        isPresented = false
    }
    
    private func saveActivityAndStop() {
        let entry = ActivityEntry(
            activity: activityText.trimmingCharacters(in: .whitespacesAndNewlines),
            sessionId: sessionId
        )
        modelContext.insert(entry)
        
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
    .modelContainer(for: [ActivityEntry.self], inMemory: true)
}