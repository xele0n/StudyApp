import SwiftUI

struct RevisionView: View {
    @EnvironmentObject var studyManager: StudyManager
    @EnvironmentObject var appBlocker: AppBlockerManager
    @State private var selectedSubject: String = StudySubject.math.rawValue
    @State private var showStartPomodoroAlert = false
    @State private var showBlockAppsAlert = false
    @State private var blockDuration: TimeInterval = 3600 // Default 1 hour
    @State private var isAppSelectionPresented = false
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Start Studying")) {
                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(StudySubject.allCases) { subject in
                            Text(subject.rawValue).tag(subject.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    
                    if studyManager.currentSession == nil {
                        Button("Start Session") {
                            studyManager.startNewSession(subject: selectedSubject)
                        }
                        .foregroundColor(.blue)
                        
                        Button("Start Pomodoro Session") {
                            showStartPomodoroAlert = true
                        }
                        .foregroundColor(.green)
                    } else {
                        Button("End Session") {
                            studyManager.endCurrentSession()
                        }
                        .foregroundColor(.red)
                        
                        if case .paused = studyManager.timerMode {
                            Button("Resume") {
                                studyManager.resumeSession()
                            }
                            .foregroundColor(.blue)
                        } else if case .running = studyManager.timerMode {
                            Button("Pause") {
                                studyManager.pauseSession()
                            }
                            .foregroundColor(.orange)
                        } else if case .pomodoro = studyManager.timerMode {
                            Button("Stop Pomodoro") {
                                studyManager.stopPomodoro()
                            }
                            .foregroundColor(.red)
                        }
                    }
                }
                
                Section(header: Text("Current Session")) {
                    if let session = studyManager.currentSession {
                        VStack(alignment: .leading) {
                            Text("Subject: \(session.subject)")
                            Text("Started: \(session.startTime, formatter: dateFormatter)")
                            
                            if case .pomodoro(let isWorkPeriod) = studyManager.timerMode {
                                Text("Mode: Pomodoro - \(isWorkPeriod ? "Work Period" : "Break Period")")
                                Text("Completed Cycles: \(studyManager.pomodoroCompletedCycles)")
                            }
                            
                            TimerView()
                        }
                    } else {
                        Text("No active session")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("App Blocker")) {
                    Toggle("Block Distracting Apps", isOn: $appBlocker.isBlockingEnabled)
                        .onChange(of: appBlocker.isBlockingEnabled) { isEnabled in
                            if isEnabled {
                                showBlockAppsAlert = true
                            } else {
                                appBlocker.stopBlocking()
                            }
                        }
                    
                    if appBlocker.isBlockingEnabled, let endTime = appBlocker.blockEndTime {
                        Text("Blocking active until: \(endTime, formatter: dateFormatter)")
                    }
                    
                    Button("Select Apps to Block") {
                        isAppSelectionPresented = true
                    }
                    .foregroundColor(.blue)
                    
                    Text("Blocked Apps: \(appBlocker.blockedApps.joined(separator: ", "))")
                        .font(.caption)
                    
                    if !appBlocker.customBlockedApps.isEmpty {
                        Text("Custom Blocked Apps: \(appBlocker.customBlockedApps.joined(separator: ", "))")
                            .font(.caption)
                    }
                }
                
                Section(header: Text("Study Statistics")) {
                    Text("Total study time: \(formatTime(studyManager.totalStudyTime()))")
                    
                    ForEach(StudySubject.allCases) { subject in
                        let time = studyManager.totalStudyTimeForSubject(subject.rawValue)
                        if time > 0 {
                            HStack {
                                Text(subject.rawValue)
                                Spacer()
                                Text(formatTime(time))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Revision Time")
            .alert("Start Pomodoro", isPresented: $showStartPomodoroAlert) {
                Button("Start") {
                    studyManager.startPomodoro()
                }
                Button("Cancel", role: .cancel) { }
            } message: {
                Text("Start a Pomodoro session with 25 minutes of work followed by 5 minutes of break?")
            }
            .alert("Block Apps", isPresented: $showBlockAppsAlert) {
                Button("1 Hour") {
                    appBlocker.blockDuration = 3600
                    appBlocker.startBlocking()
                }
                Button("2 Hours") {
                    appBlocker.blockDuration = 7200
                    appBlocker.startBlocking()
                }
                Button("3 Hours") {
                    appBlocker.blockDuration = 10800
                    appBlocker.startBlocking()
                }
                Button("Cancel", role: .cancel) {
                    appBlocker.isBlockingEnabled = false
                }
            } message: {
                Text("How long would you like to block distracting apps?")
            }
            .task(id: isAppSelectionPresented) {
                if isAppSelectionPresented {
                    await appBlocker.selectAppsToBlock()
                    isAppSelectionPresented = false
                }
            }
        }
    }
    
    private func formatTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = (Int(timeInterval) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}

struct TimerView: View {
    @EnvironmentObject var studyManager: StudyManager
    
    var body: some View {
        VStack {
            Text(timeString)
                .font(.largeTitle)
                .padding()
            
            if case .pomodoro(let isWorkPeriod) = studyManager.timerMode {
                Text(isWorkPeriod ? "Focus Time" : "Break Time")
                    .foregroundColor(isWorkPeriod ? .blue : .green)
                    .font(.headline)
            }
        }
    }
    
    var timeString: String {
        let time = Int(studyManager.elapsedTime)
        let hours = time / 3600
        let minutes = (time % 3600) / 60
        let seconds = time % 60
        
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        } else {
            return String(format: "%d:%02d", minutes, seconds)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .short
    formatter.timeStyle = .short
    return formatter
}() 