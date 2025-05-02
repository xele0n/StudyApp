import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var title: String
    var content: String
    var subject: String
    var dateCreated: Date
    var dateModified: Date
    
    init(title: String, content: String, subject: String) {
        self.title = title
        self.content = content
        self.subject = subject
        self.dateCreated = Date()
        self.dateModified = Date()
    }
    
    mutating func update(title: String? = nil, content: String? = nil, subject: String? = nil) {
        if let title = title {
            self.title = title
        }
        
        if let content = content {
            self.content = content
        }
        
        if let subject = subject {
            self.subject = subject
        }
        
        self.dateModified = Date()
    }
} 