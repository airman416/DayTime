//
//  DayTimeWidgets.swift
//  DayTimeWidgets
//
//  Created by Armaan Agrawal on 7/14/25.
//

import WidgetKit
import SwiftUI
import ActivityKit

// This is the Live Activity UI
struct DayTimeLiveActivityView: View {
    let context: ActivityViewContext<DayTimeActivityAttributes>

    var body: some View {
        HStack {
            Image("clocky") // Make sure clocky is in the widget's asset catalog
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding()

            VStack(alignment: .leading) {
                Text("Next Check-in:")
                    .font(.caption)
                Text(timerInterval: Date()...context.state.nextCheckInTime, countsDown: true)
                    .font(.title.bold())
            }
            .padding(.trailing)
        }
        .activityBackgroundTint(Color.black.opacity(0.8))
        .activitySystemActionForegroundColor(Color.white)
    }
}


@main
struct DayTimeWidgets: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayTimeActivityAttributes.self) { context in
            // Lock screen UI
            DayTimeLiveActivityView(context: context)
        } dynamicIsland: { context in
            // Dynamic Island UI
            DynamicIsland {
                // Expanded UI
                DynamicIslandExpandedRegion(.leading) {
                    Image("clocky")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 40, height: 40)
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text(timerInterval: Date()...context.state.nextCheckInTime, countsDown: true)
                       .font(.title.bold())
                }
                DynamicIslandExpandedRegion(.center) {
                    Text("Next check-in")
                }
            } compactLeading: {
                Image("clocky")
                    .resizable()
                    .scaledToFit()
            } compactTrailing: {
                Text(timerInterval: Date()...context.state.nextCheckInTime, countsDown: true)
                    .frame(width: 50)
            } minimal: {
                 Image("clocky")
                    .resizable()
                    .scaledToFit()
            }
            .keylineTint(Color.red)
        }
    }
}

extension ConfigurationAppIntent {
    fileprivate static var smiley: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "😀"
        return intent
    }
    
    fileprivate static var starEyes: ConfigurationAppIntent {
        let intent = ConfigurationAppIntent()
        intent.favoriteEmoji = "🤩"
        return intent
    }
}
