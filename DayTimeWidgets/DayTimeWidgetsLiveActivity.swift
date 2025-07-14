//
//  DayTimeWidgetsLiveActivity.swift
//  DayTimeWidgets
//
//  Created by Armaan Agrawal on 7/14/25.
//

import ActivityKit
import WidgetKit
import SwiftUI

struct DayTimeWidgetsAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        // Dynamic stateful properties about your activity go here!
        var emoji: String
    }

    // Fixed non-changing properties about your activity go here!
    var name: String
}

struct DayTimeWidgetsLiveActivity: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: DayTimeWidgetsAttributes.self) { context in
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

extension DayTimeWidgetsAttributes {
    fileprivate static var preview: DayTimeWidgetsAttributes {
        DayTimeWidgetsAttributes(name: "World")
    }
}

extension DayTimeWidgetsAttributes.ContentState {
    fileprivate static var smiley: DayTimeWidgetsAttributes.ContentState {
        DayTimeWidgetsAttributes.ContentState(emoji: "😀")
     }
     
     fileprivate static var starEyes: DayTimeWidgetsAttributes.ContentState {
         DayTimeWidgetsAttributes.ContentState(emoji: "🤩")
     }
}

#Preview("Notification", as: .content, using: DayTimeWidgetsAttributes.preview) {
   DayTimeWidgetsLiveActivity()
} contentStates: {
    DayTimeWidgetsAttributes.ContentState.smiley
    DayTimeWidgetsAttributes.ContentState.starEyes
}
