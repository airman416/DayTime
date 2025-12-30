//
//  SuperwallDelegate.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import Foundation
import SuperwallKit
import SwiftData

class DayTimeSuperwallDelegate: SuperwallDelegate {
    private let modelContext: ModelContext
    
    init(modelContext: ModelContext) {
        self.modelContext = modelContext
    }
    
    @MainActor
    func subscriptionStatusDidChange(from oldValue: SubscriptionStatus, to newValue: SubscriptionStatus) {
        print("📱 Subscription status changed: \(oldValue) -> \(newValue)")
        
        // Update UserSettings with subscription status
        updateSubscriptionStatus(newValue)
    }
    
    @MainActor
    func customerInfoDidChange(from oldValue: CustomerInfo, to newValue: CustomerInfo) {
        print("📱 Customer info changed")
        
        // Extract free trial end date from active subscriptions
        updateFreeTrialEndDate(from: newValue)
    }
    
    private func updateSubscriptionStatus(_ status: SubscriptionStatus) {
        let descriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try modelContext.fetch(descriptor)
            if let userSettings = settings.first {
                let statusString: String
                switch status {
                case .unknown:
                    statusString = "unknown"
                case .active(let entitlements):
                    statusString = "active"
                    print("✅ User has active subscription with entitlements: \(entitlements.map { $0.id })")
                case .inactive:
                    statusString = "inactive"
                }
                
                userSettings.subscriptionStatus = statusString
                print("💾 Updated subscription status to: \(statusString)")
            }
        } catch {
            print("❌ Error updating subscription status: \(error)")
        }
    }
    
    private func updateFreeTrialEndDate(from customerInfo: CustomerInfo) {
        let descriptor = FetchDescriptor<UserSettings>()
        
        do {
            let settings = try modelContext.fetch(descriptor)
            if let userSettings = settings.first {
                // Find the earliest trial end date from active subscriptions
                var earliestTrialEndDate: Date?
                
                for subscription in customerInfo.subscriptions {
                    // Check if subscription is active and in trial period
                    if subscription.isActive,
                       let expirationDate = subscription.expirationDate {
                        // Check if this is a trial offer (available in 4.11.0+)
                        if let offerType = subscription.offerType {
                            // Explicitly check for trial offer type
                            if offerType == .trial {
                                if earliestTrialEndDate == nil || expirationDate < earliestTrialEndDate! {
                                    earliestTrialEndDate = expirationDate
                                }
                            }
                        } else {
                            // Fallback: If offerType is not available (pre-4.11.0), 
                            // check if purchase was recent and expiration is soon (heuristic for trial)
                            let daysSincePurchase = Calendar.current.dateComponents([.day], from: subscription.purchaseDate, to: Date()).day ?? 0
                            let daysUntilExpiration = Calendar.current.dateComponents([.day], from: Date(), to: expirationDate).day ?? 0
                            // If purchased recently and expires soon, might be a trial
                            if daysSincePurchase <= 14 && daysUntilExpiration <= 14 {
                                if earliestTrialEndDate == nil || expirationDate < earliestTrialEndDate! {
                                    earliestTrialEndDate = expirationDate
                                }
                            }
                        }
                    }
                }
                
                userSettings.freeTrialEndDate = earliestTrialEndDate
                
                if let trialEndDate = earliestTrialEndDate {
                    let formatter = DateFormatter()
                    formatter.dateStyle = .medium
                    formatter.timeStyle = .short
                    print("💾 Updated free trial end date to: \(formatter.string(from: trialEndDate))")
                } else {
                    print("💾 No active trial found")
                }
            }
        } catch {
            print("❌ Error updating free trial end date: \(error)")
        }
    }
}

