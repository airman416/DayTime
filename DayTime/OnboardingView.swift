//
//  OnboardingView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import SuperwallKit

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var settings: [UserSettings]
    @State private var userName = ""
    @State private var isAnimating = false
    @State private var hasPurchased = false
    @State private var paywallPresented = false
    @Binding var isOnboardingComplete: Bool
    
    // UserDefaults key for storing name as backup (in case SwiftData falls back to in-memory)
    private static let userNameKey = "DayTime_UserName"
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    /// Gets the user's name from SwiftData or UserDefaults backup
    private var existingUserName: String? {
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
        return nil
    }
    
    var body: some View {
        Group {
            if hasPurchased {
                // Check if user already has a name (from SwiftData or UserDefaults)
                if existingUserName != nil {
                    // User already has a name, skip name input
                    EmptyView()
                        .onAppear {
                            completeOnboardingWithExistingName()
                        }
                } else {
                    // Show name input after purchase
                    nameInputView
                }
            } else {
                // Show paywall first
                paywallView
            }
        }
        .onAppear {
            isAnimating = true
            
            // Pre-populate name if user already has one (from SwiftData or UserDefaults)
            if let name = existingUserName {
                userName = name
            }
            
            // Check if user already has a name and has purchased - if so, skip everything
            checkIfShouldSkipOnboarding()
            
            // Present paywall immediately when view appears (only once)
            if !hasPurchased && !paywallPresented {
                paywallPresented = true
                presentPaywall()
            }
        }
        .onChange(of: settings) { oldValue, newValue in
            // When settings load, check again if we should skip onboarding
            if let name = existingUserName {
                userName = name
            }
            checkIfShouldSkipOnboarding()
        }
        .onChange(of: hasPurchased) { oldValue, newValue in
            // When hasPurchased changes, check if we should skip name input
            if newValue {
                checkIfShouldSkipOnboarding()
            }
        }
    }
    
    private var paywallView: some View {
        // Just a black screen - paywall will be presented on top
        Color.black
            .ignoresSafeArea()
    }
    
    private var nameInputView: some View {
        VStack(spacing: 40) {
            Spacer()
            
            // App Logo/Title
            VStack(spacing: 20) {
                Image("clocky")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .foregroundStyle(Color.themeColor.gradient)
                
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
    }
    
    private func checkIfShouldSkipOnboarding() {
        // If user already has a name (from SwiftData or UserDefaults), they've already completed onboarding before
        // Don't ask for their name again - just mark onboarding as complete
        if existingUserName != nil {
            // User has a name - check if onboarding is already marked complete
            if let existingSettings = userSettings, existingSettings.isOnboardingComplete {
                // Settings say onboarding is complete, update binding to match
                if !isOnboardingComplete {
                    isOnboardingComplete = true
                }
            } else {
                // User has a name but onboarding isn't marked complete
                // Complete onboarding immediately without asking for name again
                completeOnboardingWithExistingName()
            }
        }
    }
    
    private func presentPaywall() {
        // Present hard paywall - user must purchase to continue
        // The feature block will only execute if user has "pro" entitlement (gated mode)
        Superwall.shared.register(
            placement: "onboarding_complete",
            params: [:]
        ) {
            // This block only executes if user has purchased (gated paywall)
            // Check if user already has a name (from SwiftData or UserDefaults) - if so, complete onboarding immediately
            if existingUserName != nil {
                // User already has a name, complete onboarding without showing name input
                completeOnboardingWithExistingName()
            } else {
                // User doesn't have a name yet, show name input
                withAnimation(.spring()) {
                    hasPurchased = true
                }
            }
        }
    }
    
    private func completeOnboarding() {
        let trimmedName = userName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Save to UserDefaults as backup (in case SwiftData is using in-memory storage)
        UserDefaults.standard.set(trimmedName, forKey: Self.userNameKey)
        
        // Set user attributes in Superwall
        Superwall.shared.setUserAttributes([
            "name": trimmedName
        ])
        
        // Complete onboarding in SwiftData
        if let existingSettings = userSettings {
            // Update existing settings
            existingSettings.userName = trimmedName
            existingSettings.isOnboardingComplete = true
        } else {
            // Create new settings
            let settings = UserSettings(userName: trimmedName, isOnboardingComplete: true)
            modelContext.insert(settings)
        }
        
        withAnimation(.spring()) {
            isOnboardingComplete = true
        }
    }
    
    private func completeOnboardingWithExistingName() {
        // User already has a name (from SwiftData or UserDefaults), just mark onboarding as complete
        guard let name = existingUserName else {
            // This shouldn't happen, but handle it gracefully
            // Create settings with empty name (fallback)
            let settings = UserSettings(userName: "", isOnboardingComplete: true)
            modelContext.insert(settings)
            withAnimation(.spring()) {
                isOnboardingComplete = true
            }
            return
        }
        
        // Make sure the name is saved to UserDefaults as backup
        UserDefaults.standard.set(name, forKey: Self.userNameKey)
        
        // Make sure Superwall has the name attribute
        Superwall.shared.setUserAttributes([
            "name": name
        ])
        
        // Update SwiftData
        if let existingSettings = userSettings {
            existingSettings.userName = name
            existingSettings.isOnboardingComplete = true
        } else {
            // Create new settings with the existing name
            let settings = UserSettings(userName: name, isOnboardingComplete: true)
            modelContext.insert(settings)
        }
        
        withAnimation(.spring()) {
            isOnboardingComplete = true
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .modelContainer(for: [UserSettings.self], inMemory: true)
}
