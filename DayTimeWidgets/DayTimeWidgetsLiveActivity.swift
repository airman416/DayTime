//
//  DayTimeWidgetsLiveActivity.swift
//  DayTimeWidgets
//
//  Created by Armaan Agrawal on 7/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DayTimeWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayTimeActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            HStack {
                Image("clocky")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 40, height: 40)
                    .colorInvert()
                Spacer()
                Text("Next check-in:")
                    .foregroundColor(.white)
                Spacer()
                Text(timerInterval: context.state.nextCheckInTime...Date.distantFuture, countsDown: true)
                    .multilineTextAlignment(.center)
                    .frame(width: 80)
                    .foregroundColor(.white)
            }
            .padding()
            .activityBackgroundTint(Color.black.opacity(0.8))
            .activitySystemActionForegroundColor(.white)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Image("clocky")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 30, height: 30)
                        .colorInvert()
                }
                DynamicIslandExpandedRegion(.trailing) {
                     Text(timerInterval: context.state.nextCheckInTime...Date.distantFuture, countsDown: true)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                        .foregroundColor(.white)
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("What are you working on?")
                        .font(.caption)
                        .foregroundColor(.white)
                    // more content
                }
            } compactLeading: {
                Image("clocky")
                    .resizable()
                    .scaledToFit()
                    .colorInvert()
            } compactTrailing: {
                Text(timerInterval: context.state.nextCheckInTime...Date.distantFuture, countsDown: true)
                    .frame(width: 50)
                    .foregroundColor(.white)
            } minimal: {
                 Image("clocky")
                    .resizable()
                    .scaledToFit()
                    .colorInvert()
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}
