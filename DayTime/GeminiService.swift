//
//  GeminiService.swift
//  DayTime
//
//  AI Summary Service using Google Gemini API
//

import Foundation

actor GeminiService {
    static let shared = GeminiService()
    
    // TODO: Add your Gemini API key here
    private let apiKey: String = "AIzaSyDrOR6r0tvPrJw5-hQvsjB2Q8zEIsRSoEs"
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
            
            Please provide your response in TWO distinct sections separated by "---SEPARATOR---":
            
            SECTION 1 (Shareable Overview - 2-3 sentences max):
            Create a warm, encouraging message for \(userName) about starting their tracking journey. Make it friendly and motivating. Keep it concise and positive. This could be shared on social media.
            
            ---SEPARATOR---
            
            SECTION 2 (Personal Message):
            Provide a gentle, encouraging message including:
            1. A warm greeting explaining they haven't started tracking yet
            2. The benefits of tracking activities with Clocky
            3. A friendly nudge to start their first session
            4. What they can expect when they do track (insights, patterns, productivity tips)
            5. An enthusiastic message about being here to support them
            
            Keep the tone very friendly, supportive, and non-judgmental - like a supportive friend who's excited to help them on their productivity journey. Use emojis sparingly but effectively.
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
            
            Please provide your response in TWO distinct sections separated by "---SEPARATOR---":
            
            SECTION 1 (Shareable Overview - 2-3 sentences max):
            Create a brief, positive summary of what \(userName) accomplished today. Make it shareable and celebration-worthy. Keep it concise, warm, and friendly. This will be shared on social media.
            
            ---SEPARATOR---
            
            SECTION 2 (Personal Insights):
            Provide detailed, actionable insights including:
            1. What \(userName) did well today (be specific and encouraging)
            2. Time analysis: Where did they spend most of their time? Any patterns?
            3. Efficiency tips: 2-3 specific suggestions to improve productivity
            4. Gap identification: Any missing activities or areas that need attention?
            5. Encouraging message to come back tomorrow
            
            Keep the tone friendly, supportive, and conversational - as if you're a helpful friend checking in. Use emojis sparingly but effectively.
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
                "maxOutputTokens": 1000
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
                throw GeminiError.invalidAPIKey
            }
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
            throw GeminiError.parsingError
        }
        
        // Split response into shareable and personal sections
        let components = text.components(separatedBy: "---SEPARATOR---")
        guard components.count >= 2 else {
            throw GeminiError.parsingError
        }
        
        let shareableOverview = components[0].trimmingCharacters(in: .whitespacesAndNewlines)
        let personalInsights = components[1].trimmingCharacters(in: .whitespacesAndNewlines)
        
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

