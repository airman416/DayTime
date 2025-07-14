//
//  CalendarView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct CalendarView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var sessions: [TrackingSession]
    @Query private var activities: [ActivityEntry]
    @State private var selectedDate = Date()
    
    var body: some View {
        VStack(spacing: 20) {
            // Date picker
            DatePicker("Select Date", selection: $selectedDate, displayedComponents: .date)
                .datePickerStyle(.graphical)
                .padding()
            
            // Activities for selected date
           ScrollView {
                LazyVStack(spacing: 15) {
                    let dayActivities = activitiesForDate(selectedDate)
                    
                    if dayActivities.isEmpty {
                        VStack(spacing: 10) {
                            Image(systemName: "calendar.badge.exclamationmark")
                                .font(.system(size: 50))
                                .foregroundColor(.secondary)
                            
                            Text("No activities recorded")
                                .font(.title3)
                                .foregroundColor(.secondary)
                            
                            Text("Start a tracking session to see your activities here")
                                .font(.body)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        ForEach(dayActivities, id: \.id) { activity in
                            ActivityCard(activity: activity)
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Calendar")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func activitiesForDate(_ date: Date) -> [ActivityEntry] {
        let calendar = Calendar.current
        return activities.filter { activity in
            calendar.isDate(activity.timestamp, inSameDayAs: date)
        }.sorted { $0.timestamp < $1.timestamp }
    }
}

struct ActivityCard: View {
    let activity: ActivityEntry
    @Query private var settings: [UserSettings]
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            VStack {
                Text(activity.timestamp, style: .time)
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Circle()
                    .fill(Color.dayTimePurple.gradient)
                    .frame(width: 12, height: 12)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(activity.activity)
                    .font(.body)
                    .multilineTextAlignment(.leading)
                
                Text(formatInterval(userSettings?.timerInterval ?? 900))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
    }
    
    private func formatInterval(_ seconds: Int) -> String {
        if seconds < 60 {
            return "\(seconds)s block"
        } else {
            let minutes = seconds / 60
            return "\(minutes)m block"
        }
    }
}

#Preview {
    NavigationView {
        CalendarView()
    }
    .modelContainer(for: [ActivityEntry.self, TrackingSession.self, UserSettings.self], inMemory: true)
}