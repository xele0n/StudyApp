import SwiftUI

struct CalendarView: View {
    @EnvironmentObject var calendarManager: CalendarManager
    @State private var selectedDate = Date()
    @State private var showingAddEvent = false
    @State private var newEventTitle = ""
    @State private var newEventStartDate = Date()
    @State private var newEventEndDate = Date().addingTimeInterval(3600)
    @State private var newEventSubject = StudySubject.math.rawValue
    @State private var newEventNotes = ""
    
    var body: some View {
        NavigationView {
            VStack {
                // Simple month view
                DatePicker("Select Date", selection: $selectedDate, displayedComponents: [.date])
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding()
                
                // Events for selected day
                List {
                    Section(header: Text("Events for \(selectedDate, formatter: dateFormatter)")) {
                        let eventsForDay = calendarManager.eventsForDay(selectedDate)
                        
                        if eventsForDay.isEmpty {
                            Text("No events scheduled")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(eventsForDay) { event in
                                EventRow(event: event)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    calendarManager.deleteEvent(id: eventsForDay[index].id)
                                }
                            }
                        }
                    }
                }
                .listStyle(InsetGroupedListStyle())
            }
            .navigationTitle("Revision Calendar")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddEvent = true
                    }) {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEvent) {
                AddEventView(
                    isPresented: $showingAddEvent,
                    title: $newEventTitle,
                    startDate: $newEventStartDate,
                    endDate: $newEventEndDate,
                    subject: $newEventSubject,
                    notes: $newEventNotes,
                    onSave: saveNewEvent
                )
            }
        }
    }
    
    private func saveNewEvent() {
        let newEvent = CalendarEvent(
            title: newEventTitle,
            startDate: newEventStartDate,
            endDate: newEventEndDate,
            subject: newEventSubject,
            notes: newEventNotes
        )
        
        calendarManager.addEvent(newEvent)
        
        // Reset form
        newEventTitle = ""
        newEventStartDate = Date()
        newEventEndDate = Date().addingTimeInterval(3600)
        newEventSubject = StudySubject.math.rawValue
        newEventNotes = ""
    }
}

struct EventRow: View {
    let event: CalendarEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(event.title)
                .font(.headline)
            
            Text(event.subject)
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text("\(event.startDate, formatter: timeFormatter) - \(event.endDate, formatter: timeFormatter)")
                .font(.caption)
            
            if !event.notes.isEmpty {
                Text(event.notes)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
        }
        .padding(.vertical, 4)
    }
}

struct AddEventView: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var subject: String
    @Binding var notes: String
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Event Details")) {
                    TextField("Title", text: $title)
                    
                    DatePicker("Start Time", selection: $startDate)
                    
                    DatePicker("End Time", selection: $endDate)
                    
                    Picker("Subject", selection: $subject) {
                        ForEach(StudySubject.allCases) { subject in
                            Text(subject.rawValue).tag(subject.rawValue)
                        }
                    }
                    
                    VStack(alignment: .leading) {
                        Text("Notes")
                        TextEditor(text: $notes)
                            .frame(height: 100)
                    }
                }
            }
            .navigationTitle("Add Event")
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

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}()

private let timeFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .none
    formatter.timeStyle = .short
    return formatter
}() 