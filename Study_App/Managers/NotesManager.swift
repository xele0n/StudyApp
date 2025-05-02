import Foundation

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    private let saveKey = "saved_notes"
    
    init() {
        loadNotes()
    }
    
    func addNote(title: String, content: String, subject: String) {
        let note = Note(title: title, content: content, subject: subject)
        notes.append(note)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    func getNotesForSubject(_ subject: String) -> [Note] {
        return notes.filter { $0.subject == subject }
    }
    
    func searchNotes(searchText: String) -> [Note] {
        guard !searchText.isEmpty else { return notes }
        
        let lowercasedSearchText = searchText.lowercased()
        return notes.filter {
            $0.title.lowercased().contains(lowercasedSearchText) ||
            $0.content.lowercased().contains(lowercasedSearchText)
        }
    }
    
    private func saveNotes() {
        if let encoded = try? JSONEncoder().encode(notes) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadNotes() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Note].self, from: data) {
            notes = decoded
        }
    }
    
    func exportNotes() -> Data? {
        try? JSONEncoder().encode(notes)
    }
    
    func importNotes(from data: Data) -> Bool {
        if let importedNotes = try? JSONDecoder().decode([Note].self, from: data) {
            notes.append(contentsOf: importedNotes)
            saveNotes()
            return true
        }
        return false
    }
} 