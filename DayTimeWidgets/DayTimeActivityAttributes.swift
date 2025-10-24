import Foundation
import ActivityKit

struct DayTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var nextCheckInTime: Date
        var isPaused: Bool
        var pausedTimeRemaining: TimeInterval?
    }

    // Static state - for future use
} 