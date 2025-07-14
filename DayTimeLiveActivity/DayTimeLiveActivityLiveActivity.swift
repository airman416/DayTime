//
//  DayTimeLiveActivityLiveActivity.swift
//  DayTimeLiveActivity
//
//  Created by Armaan Agrawal on 7/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DayTimeLiveActivityAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DayTimeLiveActivityLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayTimeLiveActivityAttributes.self) { context in
            // Lock screen/banner UI goes here
            VStack {
                Text("Hello \(context.state.emoji)")
            }
            .activityBackgroundTint(Color.cyan)
            .activitySystemActionForegroundColor(Color.black)

        } dynamicIsland: { context in
            DynamicIsland {
                // Expanded UI goes here.  Compose the expanded UI through
                // various regions, like leading/trailing/center/bottom
                DynamicIslandExpandedRegion(.leading) {
                    Text("Leading")
                }
                DynamicIslandExpandedRegion(.trailing) {
                    Text("Trailing")
                }
                DynamicIslandExpandedRegion(.bottom) {
                    Text("Bottom \(context.state.emoji)")
                    // more content
                }
            } compactLeading: {
                Text("L")
            } compactTrailing: {
                Text("T \(context.state.emoji)")
            } minimal: {
                Text(context.state.emoji)
            }
            .widgetURL(URL(string: "http://www.apple.com"))
            .keylineTint(Color.red)
        }
    }
}

extension DayTimeLiveActivityAttributes {
    fileprivate static var preview: DayTimeLiveActivityAttributes {
        DayTimeLiveActivityAttributes(name: "World")
    }
}

extension DayTimeLiveActivityAttributes.ContentState {
    fileprivate static var smiley: DayTimeLiveActivityAttributes.ContentState {
        DayTimeLiveActivityAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DayTimeLiveActivityAttributes.ContentState {
         DayTimeLiveActivityAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DayTimeLiveActivityAttributes.preview) {
   DayTimeLiveActivityLiveActivity()
} contentStates: {
    DayTimeLiveActivityAttributes.ContentState.smiley
    DayTimeLiveActivityAttributes.ContentState.starEyes
}
