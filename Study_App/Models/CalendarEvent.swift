import Foundation

struct CalendarEvent: Identifiable, Codable {
    var id = UUID()
    var title: String
    var startDate: Date
    var endDate: Date
    var subject: String
    var notes: String
    var isRecurring: Bool = false
    var recurrencePattern: RecurrencePattern?
    
    init(title: String, startDate: Date, endDate: Date, subject: String, notes: String = "") {
        self.title = title
        self.startDate = startDate
        self.endDate = endDate
        self.subject = subject
        self.notes = notes
    }
}

struct RecurrencePattern: Codable {
    enum RecurrenceType: String, Codable {
        case daily
        case weekly
        case monthly
    }
    
    var type: RecurrenceType
    var interval: Int // Every N days/weeks/months
    var endDate: Date?
} 