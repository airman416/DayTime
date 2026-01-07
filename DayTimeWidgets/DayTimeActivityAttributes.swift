import Foundation
import ActivityKit

struct DayTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var nextCheckInTime: Date
        var isPaused: Bool
        var pausedTimeRemaining: TimeInterval?
        var pauseStartDate: Date? // When pause started, so widget can calculate accurate remaining time
    }

    // Static state - for future use
} 