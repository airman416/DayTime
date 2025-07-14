//
//  OnboardingView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var userName = ""
    @State private var isAnimating = false
    @Binding var isOnboardingComplete: Bool
    
    var body: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 20) {
                Image(systemName: "clock.fill")
                    .font(.system(size: 80))
                    .foregroundStyle(Color.themeColor.gradient)
                    .scaleEffect(isAnimating ? 1.1 : 1.0)
                    .animation(.easeInOut(duration: 2).repeatForever(autoreverses: true), value: isAnimating)
                
                Text("DayTime")
                    .font(.system(size: 48, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                
                Text("Track your productive moments")
                    .font(.title3)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            // Name input section
            VStack(spacing: 20) {
                Text("What should we call you?")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                TextField("Your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .padding(.horizontal)
                
                Button(action: completeOnboarding) {
                    Text("Let's Start!")
                        .font(.title3)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.themeColor.gradient)
                        .cornerRadius(12)
                }
                .disabled(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .opacity(userName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? 0.6 : 1.0)
                .padding(.horizontal)
            }
            
            Spacer()
        }
        .padding()
        .onAppear {
            isAnimating = true
        }
    }
    
    private func completeOnboarding() {
        let settings = UserSettings(userName: userName.trimmingCharacters(in: .whitespacesAndNewlines), isOnboardingComplete: true)
        modelContext.insert(settings)
        
        withAnimation(.spring()) {
            isOnboardingComplete = true
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .modelContainer(for: [UserSettings.self], inMemory: true)
}