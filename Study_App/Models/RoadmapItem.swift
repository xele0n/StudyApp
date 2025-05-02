import Foundation

struct Roadmap: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var dateCreated: Date
    var steps: [RoadmapStep]
    
    init(title: String, description: String) {
        self.title = title
        self.description = description
        self.dateCreated = Date()
        self.steps = []
    }
}

struct RoadmapStep: Identifiable, Codable {
    var id = UUID()
    var title: String
    var description: String
    var dueDate: Date?
    var status: StepStatus = .notStarted
    var order: Int
}

enum StepStatus: String, Codable, CaseIterable, Identifiable {
    case notStarted = "Not Started"
    case inProgress = "In Progress"
    case completed = "Completed"
    
    var id: String { self.rawValue }
} 