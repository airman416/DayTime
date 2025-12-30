//
//  GeminiService.swift
//  DayTime
//
//  AI Summary Service using Google Gemini API
//

import Foundation
import SwiftData

actor GeminiService {
    static let shared = GeminiService()
    
    // TODO: Add your Gemini API key here
    private let apiKey: String = "AIzaSyD9A1v_KZT5FK1waWUFtkoowSYJxq8MjpQ"
    private let baseURL = "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent"
    
    struct DaySummary {
        let shareableOverview: String
        let personalInsights: String
        let generatedDate: Date
    }
    
    private init() {
        // Initialize
    }
    
    func generateDaySummary(userName: String, activities: [ActivityEntry]) async throws -> DaySummary {
        guard apiKey != "YOUR_GEMINI_API_KEY_HERE" && !apiKey.isEmpty else {
            throw GeminiError.missingAPIKey
        }
        
        // Create prompt for Gemini (handles both empty and populated activity lists)
        let prompt: String
        
        if activities.isEmpty {
            // Special prompt for when user has no activities
            prompt = """
            You are Clocky, \(userName)'s friendly check-in partner from the DayTime app. \(userName) just opened the summary view, but they haven't recorded any activities with you today yet!
            
            You MUST respond with valid JSON only, in this exact format:
            {
              "shareableOverview": "Write a warm, encouraging message in FIRST PERSON perspective (as if \(userName) is writing it themselves, using 'I' and 'my'). Make it friendly and motivating. Keep it concise and positive. CRITICAL: The shareableOverview MUST be 280 characters or less (for social media sharing). Do NOT include hashtags. This could be shared on social media.",
              "personalInsights": "Write as Clocky talking directly to \(userName) in SECOND PERSON perspective (using 'you' and 'your'). Provide a gentle, encouraging message without introducing yourself as Clocky or using any greetings. Keep it short, punchy, and valuable. Do not use any markdown formatting such as ** for bold or * for italics. Use plain text with bullet points for lists if appropriate. Include: 1. Explanation that they haven't started tracking yet, 2. The benefits of tracking activities with Clocky, 3. A friendly nudge to start their first session, 4. What they can expect when they do track (insights, patterns, productivity tips), 5. An enthusiastic message about being here to support them. Keep the tone very friendly, supportive, and non-judgmental - like a supportive friend who's excited to help them on their productivity journey. Use emojis sparingly but effectively."
            }
            
            CRITICAL: The shareableOverview field MUST be 280 characters or less. Count your characters carefully. Write shareableOverview in FIRST PERSON, personalInsights in SECOND PERSON. Do NOT include hashtags in shareableOverview.
            Respond with ONLY the JSON object, no other text before or after.
            """
        } else {
            // Prepare activity data
            let activitiesText = activities.map { activity in
                let timeFormatter = DateFormatter()
                timeFormatter.timeStyle = .short
                let time = timeFormatter.string(from: activity.timestamp)
                return "• \(time): \(activity.activity)"
            }.joined(separator: "\n")
            
            // Calculate duration
            let totalTime = calculateProductiveTime(activities: activities)
            
            // Normal prompt with activities
            prompt = """
            You are Clocky, \(userName)'s friendly check-in partner from the DayTime app. Analyze the following day's activities and create a warm, engaging summary.
            
            Activities for today:
            \(activitiesText)
            
            Total productive time tracked: \(totalTime)
            Number of check-ins: \(activities.count)
            
            You MUST respond with valid JSON only, in this exact format:
            {
              "shareableOverview": "Write a brief, positive summary in FIRST PERSON perspective (as if \(userName) is writing it themselves, using 'I' and 'my'). Summarize what \(userName) accomplished today. Make it shareable and celebration-worthy. Keep it concise, warm, and friendly. CRITICAL: The shareableOverview MUST be 280 characters or less (for social media sharing). Do NOT include hashtags. This will be shared on social media.",
              "personalInsights": "Write as Clocky talking directly to \(userName) in SECOND PERSON perspective (using 'you' and 'your'). Provide detailed, actionable insights without introducing yourself as Clocky or using any greetings. Keep it short, punchy, and valuable. Do not use any markdown formatting such as ** for bold or * for italics. Use plain text with bullet points for lists if appropriate. Include: 1. What \(userName) did well today (be specific and encouraging), 2. Time analysis: Where did they spend most of their time? Any patterns?, 3. Efficiency tips: 2-3 specific suggestions to improve productivity, 4. Gap identification: Any missing activities or areas that need attention?, 5. Encouraging message to come back tomorrow. Keep the tone friendly, supportive, and conversational - as if you're a helpful friend checking in. Use emojis sparingly but effectively."
            }
            
            CRITICAL: The shareableOverview field MUST be 280 characters or less. Count your characters carefully. Write shareableOverview in FIRST PERSON, personalInsights in SECOND PERSON. Do NOT include hashtags in shareableOverview.
            Respond with ONLY the JSON object, no other text before or after.
            """
        }
        
        // Prepare request
        let requestBody: [String: Any] = [
            "contents": [
                [
                    "parts": [
                        ["text": prompt]
                    ]
                ]
            ],
            "generationConfig": [
                "temperature": 0.7,
                "maxOutputTokens": 2000,
                "responseMimeType": "application/json"
            ]
        ]
        
        guard let url = URL(string: "\(baseURL)?key=\(apiKey)") else {
            throw GeminiError.invalidURL
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: requestBody)
        
        // Make API call
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw GeminiError.invalidResponse
        }
        
        guard httpResponse.statusCode == 200 else {
            if httpResponse.statusCode == 400 {
                print("DEBUG: Gemini API returned 400 status code. Response: \(String(data: data, encoding: .utf8) ?? "nil")")
                throw GeminiError.invalidAPIKey
            }
            print("DEBUG: Gemini API error with status code: \(httpResponse.statusCode). Response: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw GeminiError.apiError(statusCode: httpResponse.statusCode)
        }
        
        // Parse response
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]],
              let firstPart = parts.first,
              let text = firstPart["text"] as? String else {
            print("DEBUG: Failed to parse Gemini JSON response. Raw data: \(String(data: data, encoding: .utf8) ?? "nil")")
            throw GeminiError.parsingError
        }
        
        print("DEBUG: Gemini API response text (length: \(text.count)): \(text)")
        
        // Clean the text - remove markdown code blocks if present
        var cleanedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if cleanedText.hasPrefix("```json") {
            cleanedText = String(cleanedText.dropFirst(7))
        }
        if cleanedText.hasPrefix("```") {
            cleanedText = String(cleanedText.dropFirst(3))
        }
        if cleanedText.hasSuffix("```") {
            cleanedText = String(cleanedText.dropLast(3))
        }
        cleanedText = cleanedText.trimmingCharacters(in: .whitespacesAndNewlines)
        
        print("DEBUG: Cleaned text (length: \(cleanedText.count)): \(cleanedText)")
        
        // Helper function for default insights
        func generateDefaultInsights(activities: [ActivityEntry]) -> String {
            if activities.isEmpty {
                return """
                You haven't started tracking activities yet today! Here's what you can do:
                
                • Start your first check-in session with Clocky
                • Track your activities throughout the day
                • Get personalized insights and productivity tips
                • Build better habits and see your progress over time
                
                Clocky is here to help you stay productive and organized. Ready to get started?
                """
            } else {
                let activityCount = activities.count
                let timeText = calculateProductiveTime(activities: activities)
                return """
                Great job tracking \(activityCount) check-in\(activityCount == 1 ? "" : "s") today!
                
                • You've been consistent with your tracking
                • Total productive time: \(timeText)
                • Keep up the momentum and continue tracking tomorrow
                
                The more you track, the better insights Clocky can provide. See you tomorrow!
                """
            }
        }
        
        // Parse JSON response
        let shareableOverview: String
        let personalInsights: String
        
        // Try to parse JSON
        if let jsonData = cleanedText.data(using: .utf8) {
            do {
                if let json = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any] {
                    print("DEBUG: Successfully parsed JSON object. Keys: \(json.keys.joined(separator: ", "))")
                    
                    if let overview = json["shareableOverview"] as? String,
                       let insights = json["personalInsights"] as? String {
                        print("DEBUG: Successfully extracted both fields")
                        var trimmedOverview = overview.trimmingCharacters(in: .whitespacesAndNewlines)
                        
                        // Ensure shareableOverview is 280 characters or less
                        if trimmedOverview.count > 280 {
                            print("DEBUG: shareableOverview is \(trimmedOverview.count) characters, truncating to 280")
                            let endIndex = trimmedOverview.index(trimmedOverview.startIndex, offsetBy: 277)
                            trimmedOverview = String(trimmedOverview[..<endIndex]) + "..."
                        }
                        print("DEBUG: Final shareableOverview length: \(trimmedOverview.count) characters")
                        
                        shareableOverview = trimmedOverview
                        personalInsights = insights.trimmingCharacters(in: .whitespacesAndNewlines)
                    } else {
                        print("DEBUG: JSON parsed but missing required fields.")
                        print("DEBUG: shareableOverview exists: \(json["shareableOverview"] != nil)")
                        print("DEBUG: personalInsights exists: \(json["personalInsights"] != nil)")
                        print("DEBUG: Available keys: \(json.keys.joined(separator: ", "))")
                        
                        // Fallback: try to extract what we can
                        var extractedOverview = (json["shareableOverview"] as? String) ?? text.trimmingCharacters(in: .whitespacesAndNewlines)
                        let extractedInsights = (json["personalInsights"] as? String) ?? generateDefaultInsights(activities: activities)
                        
                        // Ensure shareableOverview is 280 characters or less
                        if extractedOverview.count > 280 {
                            print("DEBUG: shareableOverview is \(extractedOverview.count) characters, truncating to 280")
                            let endIndex = extractedOverview.index(extractedOverview.startIndex, offsetBy: 277)
                            extractedOverview = String(extractedOverview[..<endIndex]) + "..."
                        }
                        
                        shareableOverview = extractedOverview
                        personalInsights = extractedInsights
                    }
                } else {
                    print("DEBUG: JSON parsing returned wrong type")
                    shareableOverview = text.trimmingCharacters(in: .whitespacesAndNewlines)
                    personalInsights = generateDefaultInsights(activities: activities)
                }
            } catch {
                print("DEBUG: JSON parsing error: \(error.localizedDescription)")
                print("DEBUG: Error details: \(error)")
                var fallbackOverview = text.trimmingCharacters(in: .whitespacesAndNewlines)
                
                // Ensure shareableOverview is 280 characters or less
                if fallbackOverview.count > 280 {
                    print("DEBUG: Fallback overview is \(fallbackOverview.count) characters, truncating to 280")
                    let endIndex = fallbackOverview.index(fallbackOverview.startIndex, offsetBy: 277)
                    fallbackOverview = String(fallbackOverview[..<endIndex]) + "..."
                }
                
                shareableOverview = fallbackOverview
                personalInsights = generateDefaultInsights(activities: activities)
            }
        } else {
            print("DEBUG: Failed to convert text to data")
            var fallbackOverview = text.trimmingCharacters(in: .whitespacesAndNewlines)
            
            // Ensure shareableOverview is 280 characters or less
            if fallbackOverview.count > 280 {
                print("DEBUG: Fallback overview is \(fallbackOverview.count) characters, truncating to 280")
                let endIndex = fallbackOverview.index(fallbackOverview.startIndex, offsetBy: 277)
                fallbackOverview = String(fallbackOverview[..<endIndex]) + "..."
            }
            
            shareableOverview = fallbackOverview
            personalInsights = generateDefaultInsights(activities: activities)
        }
        
        return DaySummary(
            shareableOverview: shareableOverview,
            personalInsights: personalInsights,
            generatedDate: Date()
        )
    }
    
    private func calculateProductiveTime(activities: [ActivityEntry]) -> String {
        guard activities.count > 1,
              let firstActivity = activities.first,
              let lastActivity = activities.last else {
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

enum GeminiError: LocalizedError {
    case missingAPIKey
    case invalidAPIKey
    case invalidURL
    case invalidResponse
    case apiError(statusCode: Int)
    case parsingError
    
    var errorDescription: String? {
        switch self {
        case .missingAPIKey:
            return "AI summary service is not configured. Please contact support."
        case .invalidAPIKey:
            return "Unable to connect to AI service. Please try again later."
        case .invalidURL:
            return "Invalid API URL"
        case .invalidResponse:
            return "Invalid response from Gemini API"
        case .apiError(let statusCode):
            return "API Error: \(statusCode)"
        case .parsingError:
            return "Failed to parse Gemini response"
        }
    }
}

