//
//  CountdownLiveActivity.swift
//  DayTimeWidgets
//
//  Created by Armaan Agrawal on 10/24/25.
//

import ActivityKit
import WidgetKit
import SwiftUI
import AppIntents

// Countdown Live Activity - Shows during the session countdown
// This is SEPARATE from the AlarmKit alarm Live Activity
struct CountdownLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayTimeActivityAttributes.self) { context in
            // Lock screen/banner UI - Bigger elements
            let isPaused = context.state.isPaused
            // Calculate accurate paused time: if paused, account for time passed since pause started
            let pausedTime: TimeInterval = {
                if isPaused, let pauseStart = context.state.pauseStartDate, let originalRemaining = context.state.pausedTimeRemaining {
                    let timePassedSincePause = Date().timeIntervalSince(pauseStart)
                    return max(0, originalRemaining - timePassedSincePause)
                } else if isPaused {
                    return context.state.pausedTimeRemaining ?? 0
                }
                return 0
            }()
            let activeTime = max(0, context.state.nextCheckInTime.timeIntervalSinceNow)
            
            HStack(spacing: 20) {
                // Control buttons on the left - Just swap pause/play icon
                HStack(spacing: 12) {
                    if isPaused {
                        Button(intent: ResumeSessionIntent()) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(Color(red: 0.96, green: 0.76, blue: 0.05))
                        .frame(width: 44, height: 44)
                    } else {
                        Button(intent: PauseSessionIntent()) {
                            Image(systemName: "pause.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(Color(red: 0.96, green: 0.76, blue: 0.05))
                        .frame(width: 44, height: 44)
                    }
                    
                    Button(intent: StopCountdownIntent()) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.borderedProminent)
                    .buttonBorderShape(.circle)
                    .tint(.red)
                    .frame(width: 44, height: 44)
                }
                
                Spacer()
                
                // Countdown on the right - Always white, uses same format
                TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                    HStack(spacing: 12) {
                        Image("clocky")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 50, height: 50)
                        
                        // Calculate display time: if paused, use calculated paused time, otherwise use active countdown
                        let currentDisplayTime: TimeInterval = {
                            if isPaused {
                                if let pauseStart = context.state.pauseStartDate, let originalRemaining = context.state.pausedTimeRemaining {
                                    let timePassedSincePause = timeline.date.timeIntervalSince(pauseStart)
                                    return max(0, originalRemaining - timePassedSincePause)
                                }
                                return context.state.pausedTimeRemaining ?? 0
                            }
                            return max(0, context.state.nextCheckInTime.timeIntervalSince(timeline.date))
                        }()
                        Text(formatTime(currentDisplayTime))
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                            .frame(minWidth: 85, alignment: .trailing)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .activityBackgroundTint(Color.black.opacity(0.95))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            let isPaused = context.state.isPaused
            // Calculate accurate paused time: if paused, account for time passed since pause started
            let pausedTime: TimeInterval = {
                if isPaused, let pauseStart = context.state.pauseStartDate, let originalRemaining = context.state.pausedTimeRemaining {
                    let timePassedSincePause = Date().timeIntervalSince(pauseStart)
                    return max(0, originalRemaining - timePassedSincePause)
                } else if isPaused {
                    return context.state.pausedTimeRemaining ?? 0
                }
                return 0
            }()
            let activeTime = max(0, context.state.nextCheckInTime.timeIntervalSinceNow)
            
            return DynamicIsland {
                // Expanded UI - Bigger elements
                DynamicIslandExpandedRegion(.leading) {
                    HStack(spacing: 10) {
                        if isPaused {
                            Button(intent: ResumeSessionIntent()) {
                                Image(systemName: "play.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.circle)
                            .tint(Color(red: 0.96, green: 0.76, blue: 0.05))
                            .frame(width: 36, height: 36)
                        } else {
                            Button(intent: PauseSessionIntent()) {
                                Image(systemName: "pause.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(.white)
                            }
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.circle)
                            .tint(Color(red: 0.96, green: 0.76, blue: 0.05))
                            .frame(width: 36, height: 36)
                        }
                        
                        Button(intent: StopCountdownIntent()) {
                            Image(systemName: "stop.fill")
                                .font(.system(size: 18))
                                .foregroundColor(.white)
                        }
                        .buttonStyle(.borderedProminent)
                        .buttonBorderShape(.circle)
                        .tint(.red)
                        .frame(width: 36, height: 36)
                    }
                }
                DynamicIslandExpandedRegion(.trailing) {
                    TimelineView(.periodic(from: Date(), by: 1.0)) { timeline in
                        HStack(spacing: 10) {
                            Image("clocky")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 40, height: 40)
                            
                            // Calculate display time: if paused, use calculated paused time, otherwise use active countdown
                            let currentDisplayTime: TimeInterval = {
                                if isPaused {
                                    if let pauseStart = context.state.pauseStartDate, let originalRemaining = context.state.pausedTimeRemaining {
                                        let timePassedSincePause = timeline.date.timeIntervalSince(pauseStart)
                                        return max(0, originalRemaining - timePassedSincePause)
                                    }
                                    return context.state.pausedTimeRemaining ?? 0
                                }
                                return max(0, context.state.nextCheckInTime.timeIntervalSince(timeline.date))
                            }()
                            Text(formatTime(currentDisplayTime))
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .monospacedDigit()
                                .frame(minWidth: 70, alignment: .trailing)
                        }
                        .foregroundStyle(Color(red: 0.96, green: 0.76, blue: 0.05))
                    }
                }
            } compactLeading: {
                Image("clocky")
                    .resizable()
                    .scaledToFit()
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.nextCheckInTime, countsDown: true)
                    .frame(width: 50)
                    .monospacedDigit()
                    .font(.caption2.bold())
            } minimal: {
                 Image("clocky")
                    .resizable()
                    .scaledToFit()
            }
            .keylineTint(Color(red: 0.96, green: 0.76, blue: 0.05))
        }
    }
}

// App Intent to pause the session
struct PauseSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Pause Session"
    
    func perform() async throws -> some IntentResult {
        // Use Darwin notification to communicate across process boundaries
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.daytime.pauseSession" as CFString),
            nil,
            nil,
            true
        )
        return .result()
    }
}

// App Intent to stop the session
struct StopCountdownIntent: AppIntent {
    static var title: LocalizedStringResource = "Stop Session"
    
    func perform() async throws -> some IntentResult {
        // Use Darwin notification to communicate across process boundaries
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.daytime.stopSession" as CFString),
            nil,
            nil,
            true
        )
        return .result()
    }
}

// App Intent to resume the session
struct ResumeSessionIntent: AppIntent {
    static var title: LocalizedStringResource = "Resume Session"
    
    func perform() async throws -> some IntentResult {
        // Use Darwin notification to communicate across process boundaries
        CFNotificationCenterPostNotification(
            CFNotificationCenterGetDarwinNotifyCenter(),
            CFNotificationName("com.daytime.resumeSession" as CFString),
            nil,
            nil,
            true
        )
        return .result()
    }
}

// Helper function to format time
private func formatTime(_ seconds: TimeInterval) -> String {
    let totalSeconds = Int(seconds)
    let minutes = totalSeconds / 60
    let remainingSeconds = totalSeconds % 60
    return String(format: "%02d:%02d", minutes, remainingSeconds)
}

// Notification names
extension Notification.Name {
    static let pauseSession = Notification.Name("pauseSession")
    static let stopSession = Notification.Name("stopSession")
    static let resumeSession = Notification.Name("resumeSession")
}

