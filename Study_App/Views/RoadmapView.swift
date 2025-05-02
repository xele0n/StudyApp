import SwiftUI

struct RoadmapView: View {
    @EnvironmentObject var roadmapManager: RoadmapManager
    @State private var showingAddRoadmap = false
    @State private var showingGenerateRoadmap = false
    @State private var selectedRoadmap: Roadmap?
    @State private var newRoadmapTitle = ""
    @State private var newRoadmapDescription = ""
    @State private var goalForAI = ""
    @State private var subjectForAI = ""
    
    var body: some View {
        NavigationView {
            List {
                // Add or generate roadmap buttons
                Section {
                    Button(action: {
                        showingAddRoadmap = true
                    }) {
                        Label("Create New Roadmap", systemImage: "plus.circle")
                    }
                    
                    Button(action: {
                        showingGenerateRoadmap = true
                    }) {
                        Label("Generate Roadmap with AI", systemImage: "wand.and.stars")
                    }
                }
                
                // Roadmaps list
                Section(header: Text("Your Roadmaps")) {
                    if roadmapManager.roadmaps.isEmpty {
                        Text("No roadmaps yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(roadmapManager.roadmaps) { roadmap in
                            NavigationLink(destination: RoadmapDetailView(roadmap: roadmap)) {
                                RoadmapRow(roadmap: roadmap)
                            }
                        }
                        .onDelete { indexSet in
                            for index in indexSet {
                                roadmapManager.deleteRoadmap(id: roadmapManager.roadmaps[index].id)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Study Roadmaps")
            .sheet(isPresented: $showingAddRoadmap) {
                AddRoadmapView(
                    isPresented: $showingAddRoadmap,
                    title: $newRoadmapTitle,
                    description: $newRoadmapDescription,
                    onSave: saveNewRoadmap
                )
            }
            .sheet(isPresented: $showingGenerateRoadmap) {
                GenerateRoadmapView(
                    isPresented: $showingGenerateRoadmap,
                    goal: $goalForAI,
                    subject: $subjectForAI,
                    onGenerate: generateRoadmap
                )
            }
            .overlay(
                Group {
                    if roadmapManager.isGeneratingRoadmap {
                        ZStack {
                            Color.black.opacity(0.4)
                                .edgesIgnoringSafeArea(.all)
                            
                            VStack {
                                ProgressView()
                                    .scaleEffect(1.5)
                                    .padding()
                                
                                Text("Generating your roadmap...")
                                    .font(.headline)
                                    .foregroundColor(.white)
                            }
                            .padding(20)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                        }
                    }
                }
            )
        }
    }
    
    private func saveNewRoadmap() {
        let newRoadmap = Roadmap(
            title: newRoadmapTitle,
            description: newRoadmapDescription
        )
        
        roadmapManager.addRoadmap(newRoadmap)
        
        // Reset form
        newRoadmapTitle = ""
        newRoadmapDescription = ""
    }
    
    private func generateRoadmap() {
        roadmapManager.generateRoadmap(for: goalForAI, subject: subjectForAI) { roadmap in
            if let roadmap = roadmap {
                roadmapManager.addRoadmap(roadmap)
                
                // Reset form
                goalForAI = ""
                subjectForAI = ""
            }
        }
    }
}

struct RoadmapRow: View {
    let roadmap: Roadmap
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(roadmap.title)
                .font(.headline)
            
            Text(roadmap.description)
                .font(.caption)
                .foregroundColor(.secondary)
                .lineLimit(2)
            
            Text("Created: \(roadmap.dateCreated, formatter: dateFormatter)")
                .font(.caption2)
                .foregroundColor(.secondary)
            
            ProgressView(value: completionPercentage, total: 1.0)
                .progressViewStyle(LinearProgressViewStyle())
                .accentColor(progressColor)
        }
        .padding(.vertical, 4)
    }
    
    private var completionPercentage: Double {
        if roadmap.steps.isEmpty { return 0 }
        
        let completedSteps = roadmap.steps.filter { $0.status == .completed }.count
        return Double(completedSteps) / Double(roadmap.steps.count)
    }
    
    private var progressColor: Color {
        switch completionPercentage {
        case 0..<0.33:
            return .red
        case 0.33..<0.66:
            return .orange
        default:
            return .green
        }
    }
}

struct RoadmapDetailView: View {
    @EnvironmentObject var roadmapManager: RoadmapManager
    @State var roadmap: Roadmap
    
    var body: some View {
        List {
            Section(header: Text("Overview")) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(roadmap.description)
                        .font(.body)
                    
                    Text("Created: \(roadmap.dateCreated, formatter: dateFormatter)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ProgressView(value: completionPercentage, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle())
                }
                .padding(.vertical, 4)
            }
            
            Section(header: Text("Steps")) {
                if roadmap.steps.isEmpty {
                    Text("No steps yet. Tap + to add steps.")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(roadmap.steps.sorted(by: { $0.order < $1.order })) { step in
                        RoadmapStepRow(
                            step: step,
                            onStatusChange: { newStatus in
                                roadmapManager.updateStepStatus(
                                    roadmapId: roadmap.id,
                                    stepId: step.id,
                                    newStatus: newStatus
                                )
                                
                                // Update local copy for UI
                                if let index = roadmap.steps.firstIndex(where: { $0.id == step.id }) {
                                    var steps = roadmap.steps
                                    steps[index].status = newStatus
                                    roadmap.steps = steps
                                }
                            }
                        )
                    }
                }
            }
        }
        .navigationTitle(roadmap.title)
    }
    
    private var completionPercentage: Double {
        if roadmap.steps.isEmpty { return 0 }
        
        let completedSteps = roadmap.steps.filter { $0.status == .completed }.count
        return Double(completedSteps) / Double(roadmap.steps.count)
    }
}

struct RoadmapStepRow: View {
    let step: RoadmapStep
    let onStatusChange: (StepStatus) -> Void
    @State private var showingStatusPicker = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: statusIcon)
                    .foregroundColor(statusColor)
                
                Text(step.title)
                    .font(.headline)
                
                Spacer()
                
                Button(action: {
                    showingStatusPicker = true
                }) {
                    Text(step.status.rawValue)
                        .font(.caption)
                        .padding(4)
                        .background(statusColor.opacity(0.2))
                        .cornerRadius(4)
                }
            }
            
            Text(step.description)
                .font(.caption)
                .foregroundColor(.secondary)
            
            if let dueDate = step.dueDate {
                Text("Due: \(dueDate, formatter: dateFormatter)")
                    .font(.caption2)
                    .foregroundColor(isOverdue(dueDate) ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
        .actionSheet(isPresented: $showingStatusPicker) {
            ActionSheet(title: Text("Update Status"), buttons: 
                StepStatus.allCases.map { status in
                    .default(Text(status.rawValue)) {
                        onStatusChange(status)
                    }
                } + [.cancel()]
            )
        }
    }
    
    private var statusIcon: String {
        switch step.status {
        case .notStarted:
            return "circle"
        case .inProgress:
            return "clock"
        case .completed:
            return "checkmark.circle.fill"
        }
    }
    
    private var statusColor: Color {
        switch step.status {
        case .notStarted:
            return .gray
        case .inProgress:
            return .blue
        case .completed:
            return .green
        }
    }
    
    private func isOverdue(_ date: Date) -> Bool {
        return date < Date() && step.status != .completed
    }
}

struct AddRoadmapView: View {
    @Binding var isPresented: Bool
    @Binding var title: String
    @Binding var description: String
    var onSave: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Roadmap Details")) {
                    TextField("Title", text: $title)
                    
                    VStack(alignment: .leading) {
                        Text("Description")
                        TextEditor(text: $description)
                            .frame(height: 100)
                    }
                }
            }
            .navigationTitle("New Roadmap")
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

struct GenerateRoadmapView: View {
    @Binding var isPresented: Bool
    @Binding var goal: String
    @Binding var subject: String
    @State private var selectedSubject = StudySubject.math.rawValue
    var onGenerate: () -> Void
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("What's your goal?")) {
                    TextField("Example: Master calculus by the end of semester", text: $goal)
                        .autocapitalization(.none)
                }
                
                Section(header: Text("Subject Area")) {
                    Picker("Subject", selection: $selectedSubject) {
                        ForEach(StudySubject.allCases) { subject in
                            Text(subject.rawValue).tag(subject.rawValue)
                        }
                    }
                    .pickerStyle(MenuPickerStyle())
                    .onChange(of: selectedSubject) { newValue in
                        subject = newValue
                    }
                    
                    if selectedSubject == StudySubject.other.rawValue {
                        TextField("Enter subject", text: $subject)
                    }
                }
                
                Section(header: Text("AI Roadmap Generation")) {
                    Text("The AI will create a personalized roadmap with steps to help you achieve your goal.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Generate Roadmap")
            .navigationBarItems(
                leading: Button("Cancel") {
                    isPresented = false
                },
                trailing: Button("Generate") {
                    if subject.isEmpty && selectedSubject != StudySubject.other.rawValue {
                        subject = selectedSubject
                    }
                    onGenerate()
                    isPresented = false
                }
                .disabled(goal.isEmpty || (subject.isEmpty && selectedSubject == StudySubject.other.rawValue))
            )
            .onAppear {
                if subject.isEmpty {
                    subject = selectedSubject
                }
            }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .none
    return formatter
}() 