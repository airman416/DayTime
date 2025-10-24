//
//  DayTimeWidgets.swift
//  DayTimeWidgets
//
//  Created by Armaan Agrawal on 7/14/25.
//

import WidgetKit
import SwiftUI
import ActivityKit
import AlarmKit
import AppIntents

// Alarm Live Activity - Shows when alarm fires (AlarmKit)
struct DayTimeAlarmWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: AlarmAttributes<DayTimeAlarmMetadata>.self) { context in
            // Lock screen/banner UI - This is the ALARM interface
            let attributes: AlarmAttributes<DayTimeAlarmMetadata> = context.attributes
            let state: AlarmPresentationState = context.state
            
            HStack(spacing: 16) {
                // Action buttons (Update Clocky / Stop)
                AlarmControls(presentation: attributes.presentation, state: state)
                
                Spacer()
                
                // Clocky icon and message
                HStack(spacing: 12) {
                    Image("clocky")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Time to check in!")
                            .font(.headline)
                            .foregroundStyle(.white)
                        
                        if let metadata = attributes.metadata {
                            Text("Interval: \(formatInterval(metadata.intervalSeconds))")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                    }
                }
            }
            .padding(.all, 16)
            .background(.black.opacity(0.95))
            .widgetURL(state.alarmID.widgetURL)
            
        } dynamicIsland: { context in
            let attributes: AlarmAttributes<DayTimeAlarmMetadata> = context.attributes
            let state: AlarmPresentationState = context.state
            
            return DynamicIsland {
                DynamicIslandExpandedRegion(.leading) {
                    AlarmControls(presentation: attributes.presentation, state: state)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    HStack(spacing: 8) {
                        Image("clocky")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(width: 30, height: 30)
                        
                        Text("Check in!")
                            .font(.headline)
                    }
                    .foregroundStyle(attributes.tintColor)
                }
            } compactLeading: {
                Image("clocky")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.all, 4)
            } compactTrailing: {
                Image(systemName: "bell.fill")
                    .foregroundStyle(attributes.tintColor)
            } minimal: {
                Image("clocky")
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .padding(.all, 4)
            }
            .keylineTint(attributes.tintColor)
            .widgetURL(state.alarmID.widgetURL)
        }
    }
    
    private func formatInterval(_ seconds: Int) -> String {
        let minutes = seconds / 60
        return "\(minutes) min"
    }
}

// Alarm control buttons (Update Clocky and Stop)
struct AlarmControls: View {
    var presentation: AlarmPresentation
    var state: AlarmPresentationState
    
    var body: some View {
        let id = state.alarmID
        
        HStack(spacing: 8) {
            // Show secondary button (Update Clocky) when alerting
            if case .alert(_) = state.mode {
                if let secondaryButton = presentation.alert.secondaryButton {
                    Button(intent: UpdateClockyIntent(alarmID: id), label: {
                        buttonImage(secondaryButton)
                            .foregroundStyle(.white)
                    })
                    .tint(Color(red: 0.96, green: 0.76, blue: 0.05).opacity(0.3))
                }
            }
            
            // Always show Stop button
            Button(intent: StopSessionIntent(alarmID: id), label: {
                buttonImage(presentation.alert.stopButton)
                    .foregroundStyle(.white)
            })
            .tint(.gray.opacity(0.3))
        }
        .roundButtonStyle()
    }
    
    private func buttonImage(_ alarmButton: AlarmButton) -> some View {
        Image(systemName: alarmButton.systemImageName)
            .foregroundStyle(alarmButton.textColor)
            .font(.system(size: 20))
            .fontWeight(.bold)
            .frame(width: 20, height: 20)
            .padding(.all, 4)
    }
}

extension View {
    func roundButtonStyle() -> some View {
        self
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.circle)
    }
}

extension Alarm.ID {
    var widgetURL: URL? {
        URL(string: "daytime://checkin?alarmID=\(self.uuidString)")
    }
}

extension AlarmButton {
    var textColor: Color {
        Color(red: 0.96, green: 0.76, blue: 0.05) // DayTime theme color
    }
}

// Widget Bundle - Contains both countdown and alarm widgets
@main
struct DayTimeWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownLiveActivity()  // Countdown during session
        DayTimeAlarmWidget()     // Alarm when time is up
    }
}
