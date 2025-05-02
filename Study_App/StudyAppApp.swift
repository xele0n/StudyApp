import SwiftUI

@main
struct StudyAppApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(StudyManager())
                .environmentObject(AppBlockerManager())
                .environmentObject(CalendarManager())
                .environmentObject(RoadmapManager())
                .environmentObject(NotesManager())
        }
    }
} 