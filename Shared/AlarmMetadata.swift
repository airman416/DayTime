//
//  AlarmMetadata.swift
//  DayTime
//
//  Created by Armaan Agrawal on 10/23/25.
//

import AlarmKit
import SwiftUI

struct DayTimeAlarmMetadata: AlarmMetadata {
    var sessionId: UUID
    var intervalSeconds: Int
    var createdAt: Date = Date()
}

