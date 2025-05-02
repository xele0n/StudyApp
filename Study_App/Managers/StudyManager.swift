import Foundation
import Combine

class StudyManager: ObservableObject {
    @Published var currentSession: StudySession?
    @Published var allSessions: [StudySession] = []
    @Published var timerMode: TimerMode = .stopped
    @Published var elapsedTime: TimeInterval = 0
    @Published var pomodoroWorkDuration: TimeInterval = 25 * 60 // 25 minutes in seconds
    @Published var pomodoroBreakDuration: TimeInterval = 5 * 60 // 5 minutes in seconds
    @Published var pomodoroCompletedCycles: Int = 0
    
    private var timer: AnyCancellable?
    private let saveKey = "study_sessions"
    
    init() {
        loadSessions()
    }
    
    // MARK: - Session Management
    
    func startNewSession(subject: String) {
        if currentSession?.isOngoing == true {
            endCurrentSession()
        }
        
        currentSession = StudySession(subject: subject, startTime: Date())
        startTimer()
    }
    
    func endCurrentSession() {
        guard var session = currentSession, session.isOngoing else { return }
        
        session.endTime = Date()
        allSessions.append(session)
        currentSession = nil
        stopTimer()
        saveSessions()
    }
    
    func pauseSession() {
        timerMode = .paused
        timer?.cancel()
    }
    
    func resumeSession() {
        startTimer()
    }
    
    // MARK: - Timer Functions
    
    private func startTimer() {
        timerMode = .running
        timer?.cancel()
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.elapsedTime += 1
            }
    }
    
    private func stopTimer() {
        timerMode = .stopped
        timer?.cancel()
        elapsedTime = 0
    }
    
    // MARK: - Pomodoro Functions
    
    func startPomodoro() {
        if currentSession?.isOngoing == true {
            endCurrentSession()
        }
        
        currentSession = StudySession(subject: "Pomodoro Session", startTime: Date())
        startPomodoroWorkPeriod()
    }
    
    private func startPomodoroWorkPeriod() {
        timerMode = .pomodoro(isWorkPeriod: true)
        timer?.cancel()
        elapsedTime = 0
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.elapsedTime += 1
                
                if self.elapsedTime >= self.pomodoroWorkDuration {
                    self.startPomodoroBreakPeriod()
                }
            }
    }
    
    private func startPomodoroBreakPeriod() {
        timerMode = .pomodoro(isWorkPeriod: false)
        timer?.cancel()
        elapsedTime = 0
        
        if let session = currentSession {
            currentSession?.pomodoroCycles += 1
        }
        
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                self.elapsedTime += 1
                
                if self.elapsedTime >= self.pomodoroBreakDuration {
                    self.pomodoroCompletedCycles += 1
                    self.startPomodoroWorkPeriod()
                }
            }
    }
    
    func stopPomodoro() {
        endCurrentSession()
        pomodoroCompletedCycles = 0
    }
    
    // MARK: - Persistence
    
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(allSessions) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadSessions() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([StudySession].self, from: data) {
            allSessions = decoded
        }
    }
    
    // MARK: - Analytics
    
    func totalStudyTime() -> TimeInterval {
        return allSessions.reduce(0) { $0 + $1.totalDuration }
    }
    
    func totalStudyTimeForSubject(_ subject: String) -> TimeInterval {
        return allSessions
            .filter { $0.subject == subject }
            .reduce(0) { $0 + $1.totalDuration }
    }
    
    func sessionsGroupedBySubject() -> [String: [StudySession]] {
        Dictionary(grouping: allSessions) { $0.subject }
    }
} 