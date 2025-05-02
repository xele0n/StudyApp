import Foundation

struct StudySession: Identifiable, Codable {
    var id = UUID()
    var subject: String
    var startTime: Date
    var endTime: Date?
    var totalDuration: TimeInterval {
        if let end = endTime {
            return end.timeIntervalSince(startTime)
        } else {
            return Date().timeIntervalSince(startTime)
        }
    }
    var isOngoing: Bool {
        return endTime == nil
    }
    var pomodoroCycles: Int = 0
    var notes: String = ""
}

enum TimerMode {
    case running
    case paused
    case stopped
    case pomodoro(isWorkPeriod: Bool)
}

enum StudySubject: String, CaseIterable, Identifiable, Codable {
    case math = "Math"
    case science = "Science"
    case history = "History"
    case languages = "Languages"
    case art = "Art"
    case music = "Music"
    case computerScience = "Computer Science"
    case other = "Other"
    
    var id: String { self.rawValue }
} 