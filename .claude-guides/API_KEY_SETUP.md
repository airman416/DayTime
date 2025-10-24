# API Key Setup Guide

## 🔑 How to Add Your Gemini API Key

The AI summary feature is now configured to use a single API key that you provide (rather than having each user enter their own).

## Step 1: Get Your Free Gemini API Key

1. Visit: **https://aistudio.google.com/app/apikey**
2. Sign in with your Google account
3. Click **"Create API Key"**
4. Copy the key (starts with "AIza...")

## Step 2: Add the Key to Your Code

Open the file:
```
DayTime/GeminiService.swift
```

Find line 14:
```swift
private let apiKey: String = "YOUR_GEMINI_API_KEY_HERE"
```

Replace `"YOUR_GEMINI_API_KEY_HERE"` with your actual API key:
```swift
private let apiKey: String = "AIzaSyAbc123YourActualKeyHere"
```

## Step 3: Build and Test

1. Save the file
2. Build the project (⌘ + B)
3. Run the app (⌘ + R)
4. Track some activities
5. Tap "See Summary" on the Dashboard
6. Watch Clocky generate your AI summary!

---

## 🔐 Security Notes

- The API key is compiled into your app
- It's not visible to users in the UI
- Consider using a separate API key for production vs. development
- Monitor your API usage at: https://aistudio.google.com/app/apikey

## 💰 API Costs

**Gemini API (Free Tier):**
- 60 requests per minute
- 1,500 requests per day
- This is shared across ALL your app users
- For a small user base, the free tier is sufficient
- If you exceed limits, you'll need to upgrade (very affordable)

## 📊 Usage Estimation

**Example Usage:**
- 10 users × 3 summaries per day = 30 requests/day
- 100 users × 3 summaries per day = 300 requests/day
- 500 users × 3 summaries per day = 1,500 requests/day (free tier limit)

For most apps starting out, the free tier is more than enough!

## 🚀 That's It!

Once you've added your API key, the feature is ready to use. Users will simply:
1. Track their activities
2. Tap "See Summary"
3. Get their AI-generated insights
4. Share their progress

No setup required for users - it just works! ✨

---

## 🔄 Alternative: Environment Variables (Advanced)

For better security in production, you could use environment variables or a secure configuration file instead of hardcoding the key. Let me know if you'd like help setting that up!

