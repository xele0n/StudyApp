import SwiftUI

struct ContentView: View {
    @EnvironmentObject var studyManager: StudyManager
    @EnvironmentObject var appBlocker: AppBlockerManager
    @EnvironmentObject var calendarManager: CalendarManager
    @EnvironmentObject var roadmapManager: RoadmapManager
    @EnvironmentObject var notesManager: NotesManager
    
    var body: some View {
        TabView {
            RevisionView()
                .tabItem {
                    Label("Revision", systemImage: "timer")
                }
            
            CalendarView()
                .tabItem {
                    Label("Calendar", systemImage: "calendar")
                }
            
            RoadmapView()
                .tabItem {
                    Label("Roadmap", systemImage: "map")
                }
            
            NotesView()
                .tabItem {
                    Label("Notes", systemImage: "note.text")
                }
            
            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(StudyManager())
            .environmentObject(AppBlockerManager())
            .environmentObject(CalendarManager())
            .environmentObject(RoadmapManager())
            .environmentObject(NotesManager())
    }
} 