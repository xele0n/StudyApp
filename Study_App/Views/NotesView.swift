import SwiftUI

struct NotesView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State private var searchText = ""
    @State private var showingAddNote = false
    @State private var selectedSubject: String? = nil
    @State private var newNoteTitle = ""
    @State private var newNoteContent = ""
    @State private var newNoteSubject = StudySubject.math.rawValue
    
    var body: some View {
        NavigationView {
            List {
                // Search bar
                SearchBar(text: $searchText)
                
                // Filter by subject
                Section(header: Text("Filter by Subject")) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack {
                            FilterChip(title: "All", isSelected: selectedSubject == nil) {
                                selectedSubject = nil
                            }
                            
                            ForEach(StudySubject.allCases) { subject in
                                FilterChip(title: subject.rawValue, isSelected: selectedSubject == subject.rawValue) {
                                    selectedSubject = subject.rawValue
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 5)
                }
                
                // Notes list
                Section(header: Text("Your Notes")) {
                    let filteredNotes = filteredNotes()
                    
                    if filteredNotes.isEmpty {
                        Text("No notes found")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(filteredNotes) { note in
                            NavigationLink(destination: NoteDetailView(note: note)) {
                                NoteRow(note: note)
                            }
                        }
                        .onDelete { indexSet in
                            let notesToDelete = indexSet.map { filteredNotes[$0] }
                            for note in notesToDelete {
                                notesManager.deleteNote(note)
                            }
                        }
                    }
                }
            }
            .listStyle(InsetGroupedListStyle())
            .navigationTitle("Study Notes")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddNote = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddNote) {
                AddNoteView(
                    isPresented: $showingAddNote,
                    title: $newNoteTitle,
                    content: $newNoteContent,
                    subject: $newNoteSubject,
                    onSave: saveNewNote
                )
            }
        }
    }
    
    private func filteredNotes() -> [Note] {
        var notes = notesManager.notes
        
        // Apply subject filter
        if let subject = selectedSubject {
            notes = notes.filter { $0.subject == subject }
        }
        
        // Apply search text filter
        if !searchText.isEmpty {
            notes = notesManager.searchNotes(searchText: searchText)
            
            // Apply both filters if needed
            if let subject = selectedSubject {
                notes = notes.filter { $0.subject == subject }
            }
        }
        
        // Sort by most recently modified
        return notes.sorted { $0.dateModified > $1.dateModified }
    }
    
    private func saveNewNote() {
        notesManager.addNote(
            title: newNoteTitle,
            content: newNoteContent,
            subject: newNoteSubject
        )
        
        // Reset form
        newNoteTitle = ""
        newNoteContent = ""
        newNoteSubject = StudySubject.math.rawValue
    }
}

struct NoteRow: View {
    let note: Note
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(note.title)
                .font(.headline)
            
            Text(note.subject)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(note.dateModified, formatter: dateFormatter)
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 4)
    }
}

struct NoteDetailView: View {
    @EnvironmentObject var notesManager: NotesManager
    @State var note: Note
    @State private var isEditing = false
    @State private var editedTitle: String
    @State private var editedContent: String
    @State private var editedSubject: String
    
    init(note: Note) {
        self.note = note
        _editedTitle = State(initialValue: note.title)
        _editedContent = State(initialValue: note.content)
        _editedSubject = State(initialValue: note.subject)
    }
    
    var body: some View {
        VStack {
            if isEditing {
                Form {
                    Section(header: Text("Edit Note")) {
                        TextField("Title", text: $editedTitle)
                        
                        Picker("Subject", selection: $editedSubject) {
                            ForEach(StudySubject.allCases) { subject in
                                Text(subject.rawValue).tag(subject.rawValue)
                            }
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Content")
                            TextEditor(text: $editedContent)
                                .frame(minHeight: 200)
                        }
                    }
                }
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text(note.subject)
                                .font(.subheadline)
                                .padding(6)
                                .background(Color.blue.opacity(0.1))
                                .cornerRadius(4)
                            
                            Spacer()
                            
                            Text(note.dateModified, formatter: dateFormatter)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        
                        Text(note.content)
                            .font(.body)
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(note.title)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    if isEditing {
                        // Save changes
                        var updatedNote = note
                        updatedNote.update(
                            title: editedTitle,
                            content: editedContent,
                            subject: editedSubject
                        )
                        notesManager.updateNote(updatedNote)
                        note = updatedNote
                    }
                    isEditing.toggle()
                }) {
                    Text(isEditing ? "Save" : "Edit")
                }
            }
        }
    }
}

struct AddNoteView: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var content: String
    @Binding var subject: String
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Note Details")) {
                    TextField("Title", text: $title)
                    
                    Picker("Subject", selection: $subject) {
                        ForEach(StudySubject.allCases) { subject in
                            Text(subject.rawValue).tag(subject.rawValue)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Content")
                        TextEditor(text: $content)
                            .frame(height: 200)
                    }
                }
            }
            .navigationTitle("Add Note")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Save") {
                    onSave()
                    isPresented = false
                }
                .disabled(title.isEmpty)
            )
        }
    }
}

struct SearchBar: View {
    @Binding var text: String
    
    var body: some View {
        HStack {
            TextField("Search notes...", text: $text)
                .padding(7)
                .padding(.horizontal, 25)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .overlay(
                    HStack {
                        Image(systemName: "magnifyingglass")
                            .foregroundColor(.gray)
                            .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                            .padding(.leading, 8)
                        
                        if !text.isEmpty {
                            Button(action: {
                                text = ""
                            }) {
                                Image(systemName: "multiply.circle.fill")
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 8)
                            }
                        }
                    }
                )
        }
        .padding(.horizontal)
    }
}

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.blue : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(16)
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
}() 