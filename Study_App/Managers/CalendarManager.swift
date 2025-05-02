import Foundation
import EventKit

class CalendarManager: ObservableObject {
    @Published var events: [CalendarEvent] = []
    private let saveKey = "calendar_events"
    
    init() {
        loadEvents()
    }
    
    func addEvent(_ event: CalendarEvent) {
        events.append(event)
        saveEvents()
    }
    
    func updateEvent(_ event: CalendarEvent) {
        if let index = events.firstIndex(where: { $0.id == event.id }) {
            events[index] = event
            saveEvents()
        }
    }
    
    func deleteEvent(id: UUID) {
        events.removeAll { $0.id == id }
        saveEvents()
    }
    
    func eventsForDay(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        return events.filter { event in
            calendar.isDate(event.startDate, inSameDayAs: date) ||
            calendar.isDate(event.endDate, inSameDayAs: date) ||
            (event.startDate < date && event.endDate > date)
        }
    }
    
    func eventsForWeek(startingFrom date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: date) else {
            return []
        }
        
        return events.filter { event in
            (event.startDate >= date && event.startDate < weekEnd) ||
            (event.endDate >= date && event.endDate < weekEnd) ||
            (event.startDate < date && event.endDate > weekEnd)
        }
    }
    
    func eventsForMonth(_ date: Date) -> [CalendarEvent] {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        
        guard let firstDayOfMonth = calendar.date(from: components),
              let lastDayOfMonth = calendar.date(byAdding: DateComponents(month: 1, day: -1), to: firstDayOfMonth) else {
            return []
        }
        
        return events.filter { event in
            (event.startDate >= firstDayOfMonth && event.startDate <= lastDayOfMonth) ||
            (event.endDate >= firstDayOfMonth && event.endDate <= lastDayOfMonth) ||
            (event.startDate < firstDayOfMonth && event.endDate > lastDayOfMonth)
        }
    }
    
    func syncWithSystemCalendar() {
        // In a real app, we would use EventKit to sync with the system calendar
        let eventStore = EKEventStore()
        
        eventStore.requestAccess(to: .event) { granted, error in
            guard granted, error == nil else { return }
            
            // Implementation for syncing with the system calendar would go here
        }
    }
    
    private func saveEvents() {
        if let encoded = try? JSONEncoder().encode(events) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadEvents() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([CalendarEvent].self, from: data) {
            events = decoded
        }
    }
} 