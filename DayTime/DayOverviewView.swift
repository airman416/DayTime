//
//  DayOverviewView.swift
//  DayTime
//
//  Created by Armaan Agrawal on 7/13/25.
//

import SwiftUI
import SwiftData
import Photos

struct DayOverviewView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [ActivityEntry]
    @Query private var sessions: [TrackingSession]
    @Query private var settings: [UserSettings]
    @State private var selectedDate = Date()
    @State private var showingSaveAlert = false
    @State private var saveMessage = ""
    
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
        let totalSeconds = dayActivities.count * (userSettings?.timerInterval ?? 900)
        let minutes = totalSeconds / 60
        let hours = minutes / 60
        let remainingMinutes = minutes % 60
        
        if hours > 0 {
            return "\(hours)h \(remainingMinutes)m"
        } else {
            return "\(remainingMinutes)m"
        }
    }
    
    var body: some View {
        NavigationView {
            ScreenshotView(
                userName: userSettings?.userName ?? "User",
                selectedDate: selectedDate,
                dayActivities: dayActivities,
                totalProductiveTime: totalProductiveTime,
                checkInCount: dayActivities.count,
                userSettings: userSettings
            )
            .navigationTitle("Day Overview")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save to Photos") {
                        saveToPhotos()
                    }
                    .foregroundColor(.dayTimePurple)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button("Today") { selectedDate = Date() }
                        Button("Yesterday") { selectedDate = Calendar.current.date(byAdding: .day, value: -1, to: Date()) ?? Date() }
                    } label: {
                        Image(systemName: "calendar")
                            .foregroundColor(.dayTimePurple)
                    }
                }
            }
        }
        .alert("Photo Saved", isPresented: $showingSaveAlert) {
            Button("OK") { }
        } message: {
            Text(saveMessage)
        }
    }
    
    private func saveToPhotos() {
        let renderer = ImageRenderer(content: ScreenshotView(
            userName: userSettings?.userName ?? "User",
            selectedDate: selectedDate,
            dayActivities: dayActivities,
            totalProductiveTime: totalProductiveTime,
            checkInCount: dayActivities.count,
            userSettings: userSettings
        ))
        
        renderer.scale = 3.0 // High resolution
        
        if let image = renderer.uiImage {
            PHPhotoLibrary.requestAuthorization { status in
                if status == .authorized {
                    UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
                    DispatchQueue.main.async {
                        saveMessage = "Your DayTime overview has been saved to Photos!"
                        showingSaveAlert = true
                    }
                } else {
                    DispatchQueue.main.async {
                        saveMessage = "Please allow photo access in Settings to save your overview."
                        showingSaveAlert = true
                    }
                }
            }
        }
    }
}

struct ScreenshotView: View {
    let userName: String
    let selectedDate: Date
    let dayActivities: [ActivityEntry]
    let totalProductiveTime: String
    let checkInCount: Int
    let userSettings: UserSettings?
    
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
                                .foregroundColor(.dayTimePurple)
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
                    
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ForEach(Array(dayActivities.enumerated()), id: \.element.id) { index, activity in
                            CompactActivityRow(
                                activity: activity,
                                interval: userSettings?.timerInterval ?? 900,
                                isLast: index == dayActivities.count - 1
                            )
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
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

struct CompactActivityRow: View {
    let activity: ActivityEntry
    let interval: Int
    let isLast: Bool
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Time and indicator
            VStack(spacing: 4) {
                Text(activity.timestamp, style: .time)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.dayTimePurple)
                
                Circle()
                    .fill(Color.dayTimePurple)
                    .frame(width: 6, height: 6)
            }
            .frame(width: 50)
            
            // Activity content
            VStack(alignment: .leading, spacing: 2) {
                Text(activity.activity)
                    .font(.caption)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(formatInterval(interval))
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 6)
        .padding(.horizontal, 12)
        .background(.ultraThinMaterial)
        .cornerRadius(8)
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