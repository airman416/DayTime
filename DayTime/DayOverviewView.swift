//
//  DayOverviewView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData

struct DayOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [ActivityEntry]
    @Query private var sessions: [TrackingSession]
    @Query private var settings: [UserSettings]
    @State private var selectedDate = Date()
    @Environment(\.dismiss) private var dismiss
    @State private var showingEditSheet = false
    @State private var editingActivity: ActivityEntry?
    @State private var editText = ""
    // Flag to ensure sample data is injected only once when needed (debug builds)
    #if DEBUG
    @State private var didPrefillSample = false
    #endif
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    private var dayActivities: [ActivityEntry] {
        let calendar = Calendar.current
        return activities.filter { activity in
            calendar.isDate(activity.timestamp, inSameDayAs: selectedDate)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    private var totalProductiveTime: String {
        guard dayActivities.count > 1,
              let firstActivity = dayActivities.first,
              let lastActivity = dayActivities.last else {
            return "0m"
        }
        
        let difference = Calendar.current.dateComponents([.hour, .minute], from: firstActivity.timestamp, to: lastActivity.timestamp)
        let hours = difference.hour ?? 0
        let minutes = difference.minute ?? 0
        
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
    
    var body: some View {
        GeometryReader { geometry in
            // Fixed row height since entries will now scroll
            let rowHeight: CGFloat = 60

            VStack(spacing: 0) {
                headerView

                activitySection(rowHeight: rowHeight)

                footerView
            }
            .frame(width: geometry.size.width, height: geometry.size.height)
        }
        .sheet(isPresented: $showingEditSheet) {
            EditActivitySheet(
                activity: editingActivity,
                editText: $editText,
                onSave: { updateActivity() },
                onCancel: { showingEditSheet = false }
            )
        }
        .navigationBarHidden(true)
        #if DEBUG
        .onAppear {
            if !didPrefillSample {
                prefillSampleData()
                didPrefillSample = true
            }
        }
        #endif
    }

    private var headerView: some View {
        HStack(spacing: 8) {
            // Custom Back Button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("\(userSettings?.userName ?? "User")'s DayTime")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)

                Text(selectedDate, style: .date)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 8) {
                HStack(spacing: 15) {
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(dayActivities.count)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.themeColor)
                        Text("Check-ins")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                    VStack(alignment: .trailing, spacing: 2) {
                        Text(totalProductiveTime)
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.green)
                        Text("Productive")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding()
        .background(.ultraThinMaterial)
    }

    @ViewBuilder
    private func activitySection(rowHeight: CGFloat) -> some View {
        if dayActivities.isEmpty {
            VStack(spacing: 20) {
                Spacer()
                Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 40))
                    .foregroundColor(.secondary)
                Text("No activities recorded")
                    .font(.headline)
                    .foregroundColor(.secondary)
                Text("Start tracking your day to see your activities here")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                Spacer()
            }
        } else {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(Array(dayActivities.enumerated()), id: \.element.id) { index, activity in
                        EnhancedActivityRow(
                            activity: activity,
                            interval: userSettings?.timerInterval ?? 900,
                            isLast: index == dayActivities.count - 1,
                            rowHeight: rowHeight,
                            onEdit: {
                                editingActivity = activity
                                editText = activity.activity
                                showingEditSheet = true
                            },
                            onDelete: { deleteActivity(activity) }
                        )
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 20)
            }
        }
    }

    private var footerView: some View {
        HStack {
            Spacer()
            Text("Generated by DayTime")
                .font(.caption2)
                .foregroundColor(.secondary)
            Spacer()
        }
        .padding(.vertical, 8)
        .background(.ultraThinMaterial)
    }
    
    private func updateActivity() {
        guard let activity = editingActivity else { return }
        activity.activity = editText
        try? modelContext.save()
        showingEditSheet = false
    }
    
    private func deleteActivity(_ activity: ActivityEntry) {
        modelContext.delete(activity)
        try? modelContext.save()
    }

    #if DEBUG
    private func prefillSampleData() {
        guard dayActivities.isEmpty else { return }

        let calendar = Calendar.current
        let baseDate = calendar.startOfDay(for: selectedDate)
        let timesAndDescriptions: [(Int, Int, String)] = [
            (9, 0, "Morning planning and coffee. Reviewed to-do list."),
            (9, 15, "Deep work: Finished writing product brief for new feature."),
            (9, 30, "Quick stand-up meeting with the team. Shared updates."),
            (9, 45, "Took a mini break. Did dishes and stretched a bit."),
            (10, 0, "Coding session. Fixed a bug that's been annoying me for days."),
            (10, 15, "Still coding. Got into a flow state with Lofi in the background."),
            (10, 30, "Sent pull request. Reviewed two teammate PRs."),
            (10, 45, "Scrolled Twitter for research and memes."),
            (11, 0, "Cleaned up work desk. Felt messy."),
            (11, 15, "Read a chapter from 'Show Your Work'. Taking notes."),
            (11, 30, "Wrote draft for tomorrow's blog post."),
            (11, 45, "Made a quick omelette and hydrated."),
            (12, 0, "Walked outside for 10 minutes. Needed fresh air."),
            (12, 15, "Replied to DMs and checked emails."),
            (12, 30, "Short breathing exercise. Recentering."),
            (12, 45, "Brainstorming new video ideas for TikTok.")
        ]

        // Create a tracking session for the sample entries
        let session = TrackingSession(startTime: baseDate)
        modelContext.insert(session)

        for (hour, minute, description) in timesAndDescriptions {
            var components = DateComponents()
            components.hour = hour
            components.minute = minute
            if let timestamp = calendar.date(byAdding: components, to: baseDate) {
                let entry = ActivityEntry(activity: description, sessionId: session.id, timestamp: timestamp)
                modelContext.insert(entry)
            }
        }

        try? modelContext.save()
    }
    #endif
}

// ScreenshotView is no longer needed; kept as a minimal placeholder
struct ScreenshotView: View {
    var body: some View { EmptyView() }
}

struct EnhancedActivityRow: View {
    let activity: ActivityEntry
    let interval: Int
    let isLast: Bool
    let rowHeight: CGFloat
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        // Scale fonts relative to the current rowHeight (baseline = 60)
        let scale = rowHeight / 60
        let timeFont = max(10, 13 * scale)
        let activityFont = max(11, 15 * scale)
        let iconFont = max(11, 16 * scale)

        HStack(alignment: .center, spacing: 16) {
            // Time and visual indicator
            VStack(spacing: 6) {
                Text(activity.timestamp, style: .time)
                    .font(.system(size: timeFont, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
            .frame(width: 60)
            
            // Ensure the time text doesn't wrap
            .lineLimit(1)
            .minimumScaleFactor(0.8)
            
            // Activity text
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activity)
                    .font(.system(size: activityFont, weight: .medium, design: .default))
                    .foregroundColor(.primary)
                    .lineLimit(3)
                    .multilineTextAlignment(.leading)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Action buttons overlayed on the right
            HStack(spacing: 12) {
                // Edit button
                Button(action: onEdit) {
                    Image(systemName: "pencil")
                        .font(.system(size: iconFont, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Delete button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: iconFont, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: rowHeight)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.04), radius: 8, x: 0, y: 2)
                .shadow(color: .black.opacity(0.08), radius: 2, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .stroke(Color.primary.opacity(0.06), lineWidth: 0.5)
        )
        .padding(.horizontal, 16)
        .alert("Delete Activity", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                onDelete()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this activity? This action cannot be undone.")
        }
    }
}

struct EditActivitySheet: View {
    let activity: ActivityEntry?
    @Binding var editText: String
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Activity")
                        .font(.headline)
                        .foregroundColor(.primary)
                    
                    TextField("What were you working on?", text: $editText, axis: .vertical)
                        .textFieldStyle(.roundedBorder)
                        .lineLimit(3...6)
                        .font(.body)
                }
                
                if let activity = activity {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Time")
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text(activity.timestamp, style: .time)
                            .font(.body)
                            .foregroundColor(.secondary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(Color.gray.opacity(0.1))
                            .cornerRadius(8)
                    }
                }
                
                Spacer()
            }
            .padding()
            .navigationTitle("Edit Activity")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save") {
                        onSave()
                    }
                    .disabled(editText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

// Legacy component for compatibility
struct CompactActivityRow: View {
    let activity: ActivityEntry
    let interval: Int
    let isLast: Bool
    let rowHeight: CGFloat = 60
    
    var body: some View {
        EnhancedActivityRow(
            activity: activity,
            interval: interval,
            isLast: isLast,
            rowHeight: rowHeight,
            onEdit: {},
            onDelete: {}
        )
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
    DayOverviewView()
        .modelContainer(for: [ActivityEntry.self, TrackingSession.self, UserSettings.self], inMemory: true)
}