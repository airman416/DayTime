//
//  DaySummaryView.swift
//  DayTime
//
//  AI-Generated Day Summary View with Clocky
//

import SwiftUI
import SwiftData

struct DaySummaryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var activities: [ActivityEntry]
    @Query private var settings: [UserSettings]
    @Query private var summaries: [DaySummary]
    
    @State private var isLoading = false
    @State private var summary: GeminiService.DaySummary?
    @State private var errorMessage: String?
    @State private var clockyRotation: Double = 0
    @State private var showingShareSheet = false
    @State private var fallbackMode = false
    @State private var hasLoadedPersistedSummary = false
    
    // UserDefaults key for storing name as backup (in case SwiftData falls back to in-memory)
    private static let userNameKey = "DayTime_UserName"
    
    private var userSettings: UserSettings? {
        settings.first
    }
    
    /// Gets the user's name from SwiftData or UserDefaults backup
    private var displayName: String {
        // First check SwiftData
        if let name = userSettings?.userName.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        // Fall back to UserDefaults
        if let name = UserDefaults.standard.string(forKey: Self.userNameKey)?.trimmingCharacters(in: .whitespacesAndNewlines),
           !name.isEmpty {
            return name
        }
        return "Friend"
    }
    
    private var todayActivities: [ActivityEntry] {
        let calendar = Calendar.current
        return activities.filter { activity in
            calendar.isDateInToday(activity.timestamp)
        }.sorted { $0.timestamp < $1.timestamp }
    }
    
    /// Get the persisted summary for today, if it exists
    private var todaySummary: DaySummary? {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return summaries.first { summary in
            calendar.isDate(summary.date, inSameDayAs: today)
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            headerView
            
            ScrollView {
                VStack(spacing: 24) {
                    if isLoading {
                        loadingView
                    } else if let summary = summary {
                        summaryContent(summary)
                    } else if fallbackMode {
                        fallbackContent
                    } else if let error = errorMessage {
                        errorView(error)
                    } else {
                        promptView
                    }
                }
                .padding()
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            loadPersistedSummary()
        }
        .sheet(isPresented: $showingShareSheet) {
            if let summary = summary {
                ShareSheet(
                    activityItems: [createShareText(summary)]
                )
            } else if fallbackMode {
                ShareSheet(
                    activityItems: [createFallbackShareText()]
                )
            }
        }
    }
    
    private var headerView: some View {
        HStack(spacing: 8) {
            // Back button
            Button(action: { dismiss() }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Day Summary")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("By Clocky")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            // Clocky Icon
            Image("clocky")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 40, height: 40)
                .foregroundStyle(Color.themeColor.gradient)
        }
        .padding()
        .background(.ultraThinMaterial)
    }
    
    private var loadingView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            // Animated Clocky
            Image("clocky")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.themeColor.gradient)
                .rotationEffect(.degrees(clockyRotation))
                .onAppear {
                    withAnimation(.linear(duration: 2).repeatForever(autoreverses: false)) {
                        clockyRotation = 360
                    }
                }
            
            VStack(spacing: 10) {
                Text("Clocky is seeing what you did today...")
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Analyzing your activities and productivity patterns")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
        }
    }
    
    private func summaryContent(_ summary: GeminiService.DaySummary) -> some View {
        VStack(spacing: 24) {
            // Shareable Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image("clocky")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30, height: 30)
                        .foregroundStyle(Color.themeColor.gradient)
                    
                    Text("Shareable Highlight")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                }
                
                ScrollView {
                    Text(summary.shareableOverview)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .background(Color.themeColor.opacity(0.1))
                .cornerRadius(12)
                
                Button(action: { showingShareSheet = true }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share Your Progress")
                    }
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.themeColor.gradient)
                    .cornerRadius(12)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            // Personal Insights Section
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "lightbulb.fill")
                        .font(.title3)
                        .foregroundColor(.themeColor)
                    
                    Text("Personal Insights")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    Image(systemName: "lock.fill")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                ScrollView {
                    Text(summary.personalInsights)
                        .font(.body)
                        .foregroundColor(.primary)
                        .lineSpacing(6)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            // Footer
            VStack(spacing: 8) {
                Text("Generated by Clocky at \(summary.generatedDate, style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Delete existing summary before regenerating
                    if let existingSummary = todaySummary {
                        modelContext.delete(existingSummary)
                        try? modelContext.save()
                    }
                    generateSummary()
                }) {
                    HStack {
                        Image(systemName: "arrow.clockwise")
                        Text("Regenerate Summary")
                    }
                    .font(.subheadline)
                    .foregroundColor(.themeColor)
                }
            }
            .padding(.top, 10)
        }
    }
    
    private var promptView: some View {
        VStack(spacing: 30) {
            Spacer()
            
            Image("clocky")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 100, height: 100)
                .foregroundStyle(Color.themeColor.gradient)
            
            VStack(spacing: 10) {
                Text("Ready to see your day?")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                Text("Clocky will analyze your activities and create a personalized summary with insights and tips")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
            }
            
            Button(action: generateSummary) {
                HStack {
                    Image(systemName: "sparkles")
                    Text("Generate Summary")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themeColor.gradient)
                .cornerRadius(12)
            }
            .padding(.horizontal, 40)
            
            Spacer()
        }
    }
    
    private var fallbackContent: some View {
        VStack(spacing: 24) {
            // Activity List
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Image(systemName: "list.bullet.clipboard.fill")
                        .font(.title3)
                        .foregroundColor(.themeColor)
                    
                    Text("Today's Activities")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                    
                    Spacer()
                    
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("\(todayActivities.count)")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.themeColor)
                        Text("check-ins")
                            .font(.caption2)
                            .foregroundColor(.secondary)
                    }
                }
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(todayActivities) { activity in
                            HStack(alignment: .top, spacing: 12) {
                                Text(activity.timestamp, style: .time)
                                    .font(.system(.caption, design: .monospaced))
                                    .foregroundColor(.themeColor)
                                    .frame(width: 60, alignment: .leading)
                                
                                Text(activity.activity)
                                    .font(.body)
                                    .foregroundColor(.primary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                            
                            if activity.id != todayActivities.last?.id {
                                Divider()
                            }
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
            .cornerRadius(16)
            
            // Share button
            Button(action: { showingShareSheet = true }) {
                HStack {
                    Image(systemName: "square.and.arrow.up")
                    Text("Share Your Day")
                }
                .font(.headline)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.themeColor.gradient)
                .cornerRadius(12)
            }
            
            // Footer with retry option
            VStack(spacing: 8) {
                Text("Captured by Clocky at \(Date(), style: .time)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Button(action: {
                    // Delete existing summary before regenerating
                    if let existingSummary = todaySummary {
                        modelContext.delete(existingSummary)
                        try? modelContext.save()
                    }
                    fallbackMode = false
                    generateSummary()
                }) {
                    HStack {
                        Image(systemName: "sparkles")
                        Text("Try AI Summary Again")
                    }
                    .font(.subheadline)
                    .foregroundColor(.themeColor)
                }
            }
            .padding(.top, 10)
        }
    }
    
    private func errorView(_ error: String) -> some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 60))
                .foregroundColor(.orange)
            
            Text("Oops!")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(error)
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            Button(action: generateSummary) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Try Again")
                }
                .font(.headline)
                .foregroundColor(.white)
                .padding()
                .background(Color.themeColor.gradient)
                .cornerRadius(12)
            }
            
            Spacer()
        }
    }
    
    /// Load persisted summary for today if it exists
    private func loadPersistedSummary() {
        guard !hasLoadedPersistedSummary else { return }
        hasLoadedPersistedSummary = true
        
        if let persistedSummary = todaySummary {
            // Load the persisted summary
            summary = persistedSummary.toGeminiSummary()
            fallbackMode = persistedSummary.isFallbackMode
            print("✅ Loaded persisted summary for today")
        } else {
            // No summary exists for today, show prompt
            print("ℹ️ No persisted summary found for today")
        }
    }
    
    private func generateSummary() {
        isLoading = true
        errorMessage = nil
        summary = nil
        fallbackMode = false
        clockyRotation = 0
        
        Task {
            do {
                let generatedSummary = try await GeminiService.shared.generateDaySummary(
                    userName: displayName,
                    activities: todayActivities
                )
                
                await MainActor.run {
                    self.summary = generatedSummary
                    self.isLoading = false
                    
                    // Save the summary to SwiftData
                    saveSummary(generatedSummary, isFallback: false)
                }
            } catch {
                print("DEBUG: Failed to generate summary. Error: \(error.localizedDescription)")
                print("DEBUG: Today's activities count: \(todayActivities.count)")
                
                // Fallback to activity list only when Gemini actually fails
                // (not for empty activities - Gemini handles that case)
                await MainActor.run {
                    if todayActivities.isEmpty {
                        // If there are no activities and Gemini failed, show error
                        print("DEBUG: No activities, showing error message")
                        self.errorMessage = error.localizedDescription
                    } else {
                        // If there are activities but Gemini failed, show timeline fallback
                        print("DEBUG: Has activities, showing fallback mode")
                        self.fallbackMode = true
                        
                        // Save fallback summary
                        let fallbackSummary = createFallbackSummary()
                        saveSummary(fallbackSummary, isFallback: true)
                    }
                    self.isLoading = false
                }
            }
        }
    }
    
    /// Save summary to SwiftData, replacing any existing summary for today
    private func saveSummary(_ geminiSummary: GeminiService.DaySummary, isFallback: Bool) {
        // Delete any existing summary for today
        if let existingSummary = todaySummary {
            modelContext.delete(existingSummary)
        }
        
        // Create and save new summary
        let newSummary = DaySummary(
            date: Date(),
            shareableOverview: geminiSummary.shareableOverview,
            personalInsights: geminiSummary.personalInsights,
            generatedDate: geminiSummary.generatedDate,
            isFallbackMode: isFallback
        )
        
        modelContext.insert(newSummary)
        
        do {
            try modelContext.save()
            print("✅ Saved summary for today")
            
            // Also backup to JSON
            let descriptor = FetchDescriptor<DaySummary>()
            let allSummaries = try modelContext.fetch(descriptor)
            DataPersistenceService.shared.backupSummaries(allSummaries)
        } catch {
            print("⚠️ Failed to save summary: \(error)")
        }
    }
    
    /// Create a fallback summary from activities (when AI fails)
    private func createFallbackSummary() -> GeminiService.DaySummary {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: Date())
        
        let shareableOverview = "\(displayName) tracked \(todayActivities.count) check-in\(todayActivities.count == 1 ? "" : "s") today with Clocky on DayTime! 🕐✨"
        
        var personalInsights = "Today's Activities (\(dateString)):\n\n"
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for activity in todayActivities {
            let time = timeFormatter.string(from: activity.timestamp)
            personalInsights += "• \(time) - \(activity.activity)\n"
        }
        
        let totalTime = calculateProductiveTime()
        personalInsights += "\n📊 \(todayActivities.count) check-ins tracked"
        if !totalTime.isEmpty && totalTime != "0m" {
            personalInsights += " | \(totalTime) productive time"
        }
        
        return GeminiService.DaySummary(
            shareableOverview: shareableOverview,
            personalInsights: personalInsights,
            generatedDate: Date()
        )
    }
    
    private func createShareText(_ summary: GeminiService.DaySummary) -> String {
        return """
        \(summary.shareableOverview)
        
        Generated by Clocky, \(displayName)'s check-in partner, on the DayTime app 🕐✨
        """
    }
    
    private func createFallbackShareText() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        let dateString = dateFormatter.string(from: Date())
        
        var text = "\(displayName)'s DayTime - \(dateString)\n\n"
        
        // Add activities
        let timeFormatter = DateFormatter()
        timeFormatter.timeStyle = .short
        
        for activity in todayActivities {
            let time = timeFormatter.string(from: activity.timestamp)
            text += "• \(time) - \(activity.activity)\n"
        }
        
        // Add stats
        let totalTime = calculateProductiveTime()
        text += "\n"
        text += "📊 \(todayActivities.count) check-ins tracked"
        if !totalTime.isEmpty && totalTime != "0m" {
            text += " | \(totalTime) productive time"
        }
        text += "\n\n"
        text += "Captured by Clocky, \(displayName)'s check-in partner, on the DayTime app 🕐✨"
        
        return text
    }
    
    private func calculateProductiveTime() -> String {
        guard todayActivities.count > 1,
              let firstActivity = todayActivities.first,
              let lastActivity = todayActivities.last else {
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
}

// Share Sheet for iOS
struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    NavigationView {
        DaySummaryView()
            .modelContainer(for: [ActivityEntry.self, UserSettings.self, DaySummary.self], inMemory: true)
    }
}

