# DayTime Time-Sensitive Notification Setup

DayTime uses **time-sensitive notifications** to help break through some Do Not Disturb settings and ensure you don't miss important productivity check-ins!

## Features
- ⏰ **Time-Sensitive Priority**: Break through some DND configurations
- 🔊 **Default Sound**: Uses system default notification sound
- ⚙️ **Timer Control**: Adjust check-in interval from the Settings tab
- 📱 **Enhanced Presence**: Time-sensitive notifications have higher priority

## Setup Instructions

### 1. Required Entitlements (DayTime.entitlements)
```xml
<key>com.apple.developer.usernotifications.time-sensitive</key>
<true/>
```

### 2. Required Info.plist Permissions
```xml
<key>NSUserNotificationsUsageDescription</key>
<string>DayTime needs notification access to send productivity reminders that can break through Do Not Disturb mode to help you stay on track with your goals.</string>
```

## How It Works
1. All notifications use `.timeSensitive` interruption level
2. Time-sensitive notifications can break through some DND configurations
3. Notifications are scheduled up to 60 intervals in advance
4. Uses system default notification sound for consistency
5. Timer interval preference is saved and persists across app launches

## User Experience
- Notifications may appear during Do Not Disturb depending on user's Focus settings
- Users can customize their check-in interval from Settings
- Time-sensitive notifications have higher priority than standard notifications
- Works without requiring critical alert permissions
- Consistent notification sound across all alerts

## Technical Implementation
- Uses `UNNotificationSound.default` for reliable notification delivery
- Requests standard notification permissions (`.alert`, `.sound`, `.badge`)
- Integrates with SwiftData for persistent timer interval preferences
- Real-time updates when timer interval changes during active sessions

## Focus Mode Compatibility
Time-sensitive notifications respect user Focus mode settings:
- They can break through when Focus allows time-sensitive notifications
- Users maintain full control over their notification preferences
- No special entitlements required beyond time-sensitive capability
- Simple, reliable notification delivery without customization complexity
