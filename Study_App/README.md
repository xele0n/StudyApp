# Study App for iOS

A comprehensive study application designed to help students focus, organize their study sessions, and track progress toward their academic goals.

## Features

### 1. Revision Time
- **App Blocking**: Block distracting apps like TikTok, Instagram, and Snapchat during study sessions
- **Study Timer**: Track time spent studying
- **Pomodoro Technique**: Use the popular 25-minute work, 5-minute break cycle
- **Study Analytics**: View statistics on your study habits by subject

### 2. Revision Calendar
- Create and manage a study schedule
- View events by day, week, or month
- Set recurring study sessions

### 3. AI-Powered Roadmap
- Generate personalized study roadmaps for any goal
- Track progress toward your goals
- Update roadmap steps as you complete them

### 4. Notes System
- Store and organize notes by subject
- Search through your notes
- Easy note creation and editing

## Technical Implementation

This app is built with:
- Swift
- SwiftUI
- Combine framework
- UserNotifications framework
- EventKit for calendar integration

## Getting Started

1. Clone this repository
2. Open in Xcode
3. Build and run on iOS simulator or device

## API Keys

To use the AI roadmap generation feature with OpenAI:
1. Get an API key from OpenAI
2. Replace the placeholder in `RoadmapManager.swift` with your actual key

## Future Enhancements

- Screen Time API integration for more robust app blocking
- Cloud sync of notes and roadmaps
- Social features to study with friends
- Gamification elements to increase motivation 