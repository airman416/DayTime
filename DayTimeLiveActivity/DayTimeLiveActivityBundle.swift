//
//  DayTimeLiveActivityBundle.swift
//  DayTimeLiveActivity
//
//  Created by Armaan Agrawal on 7/14/25.
//

import WidgetKit
import SwiftUI

@main
struct DayTimeLiveActivityBundle: WidgetBundle {
    var body: some Widget {
        DayTimeLiveActivity()
        DayTimeLiveActivityControl()
        DayTimeLiveActivityLiveActivity()
    }
}
