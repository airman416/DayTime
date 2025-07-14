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
    @State private var showingEditSheet = false
    @State private var editingActivity: ActivityEntry?
    @State private var editText = ""
    
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
        ScreenshotView(
            userName: userSettings?.userName ?? "User",
            selectedDate: selectedDate,
            dayActivities: dayActivities,
            totalProductiveTime: totalProductiveTime,
            checkInCount: dayActivities.count,
            userSettings: userSettings,
            onEdit: { activity in
                editingActivity = activity
                editText = activity.activity
                showingEditSheet = true
            },
            onDelete: { activity in
                deleteActivity(activity)
            }
        )
        .sheet(isPresented: $showingEditSheet) {
            EditActivitySheet(
                activity: editingActivity,
                editText: $editText,
                onSave: { updateActivity() },
                onCancel: { showingEditSheet = false }
            )
        }
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
    

}

struct ScreenshotView: View {
    let userName: String
    let selectedDate: Date
    let dayActivities: [ActivityEntry]
    let totalProductiveTime: String
    let checkInCount: Int
    let userSettings: UserSettings?
    let onEdit: (ActivityEntry) -> Void
    let onDelete: (ActivityEntry) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header with stats
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("\(userName)'s DayTime")
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
                            Text("\(checkInCount)")
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
            
            // Activities list
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
                                onEdit: { onEdit(activity) },
                                onDelete: { onDelete(activity) }
                            )
                        }
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 20)
                }
            }
            
            // Footer
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
        .background(Color(.systemBackground))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct EnhancedActivityRow: View {
    let activity: ActivityEntry
    let interval: Int
    let isLast: Bool
    let onEdit: () -> Void
    let onDelete: () -> Void
    
    @State private var showingDeleteAlert = false
    
    var body: some View {
        HStack(alignment: .center, spacing: 16) {
            // Time and visual indicator
            VStack(spacing: 6) {
                Text(activity.timestamp, style: .time)
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundColor(.themeColor)
            }
            .frame(width: 60)
            
            // Activity text
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activity)
                    .font(.system(size: 15, weight: .medium, design: .default))
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
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
                
                // Delete button
                Button(action: {
                    showingDeleteAlert = true
                }) {
                    Image(systemName: "trash")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundColor(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .frame(height: 60)
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
    
    var body: some View {
        EnhancedActivityRow(
            activity: activity,
            interval: interval,
            isLast: isLast,
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