import Foundation
import ActivityKit

struct DayTimeActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic state
        var nextCheckInTime: Date
    }

    // Static state - for future use
} 