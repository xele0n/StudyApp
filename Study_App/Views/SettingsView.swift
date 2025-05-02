import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var studyManager: StudyManager
    @EnvironmentObject var appBlocker: AppBlockerManager
    @State private var pomodoroWorkDuration: Double
    @State private var pomodoroBreakDuration: Double
    @State private var customAppToBlock = ""
    
    init() {
        // Initialize state from studyManager
        _pomodoroWorkDuration = State(initialValue: 25)
        _pomodoroBreakDuration = State(initialValue: 5)
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Pomodoro Timer Settings")) {
                    VStack {
                        Text("Work Duration: \(Int(pomodoroWorkDuration)) minutes")
                        Slider(value: $pomodoroWorkDuration, in: 5...60, step: 5)
                            .onChange(of: pomodoroWorkDuration) { newValue in
                                studyManager.pomodoroWorkDuration = newValue * 60
                            }
                    }
                    
                    VStack {
                        Text("Break Duration: \(Int(pomodoroBreakDuration)) minutes")
                        Slider(value: $pomodoroBreakDuration, in: 1...20, step: 1)
                            .onChange(of: pomodoroBreakDuration) { newValue in
                                studyManager.pomodoroBreakDuration = newValue * 60
                            }
                    }
                }
                
                Section(header: Text("App Blocker Settings")) {
                    Text("Default Blocked Apps")
                    
                    ForEach(appBlocker.blockedApps, id: \.self) { app in
                        Text(app)
                    }
                    
                    Divider()
                    
                    Text("Custom Blocked Apps")
                    
                    ForEach(appBlocker.customBlockedApps, id: \.self) { app in
                        HStack {
                            Text(app)
                            Spacer()
                            Button(action: {
                                appBlocker.removeAppFromBlock(app)
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    
                    HStack {
                        TextField("Add app to block", text: $customAppToBlock)
                        
                        Button(action: {
                            if !customAppToBlock.isEmpty {
                                appBlocker.addAppToBlock(customAppToBlock)
                                customAppToBlock = ""
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.blue)
                        }
                    }
                }
                
                Section(header: Text("About")) {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    Link("Terms of Service", destination: URL(string: "https://example.com/terms")!)
                    
                    Link("Privacy Policy", destination: URL(string: "https://example.com/privacy")!)
                }
            }
            .navigationTitle("Settings")
            .onAppear {
                // Update state from manager when view appears
                pomodoroWorkDuration = studyManager.pomodoroWorkDuration / 60
                pomodoroBreakDuration = studyManager.pomodoroBreakDuration / 60
            }
        }
    }
} 