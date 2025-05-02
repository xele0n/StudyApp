import Foundation

class RoadmapManager: ObservableObject {
    @Published var roadmaps: [Roadmap] = []
    @Published var isGeneratingRoadmap = false
    
    private let saveKey = "saved_roadmaps"
    private let apiKey = "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" // OpenAI API key
    
    init() {
        loadRoadmaps()
    }
    
    func addRoadmap(_ roadmap: Roadmap) {
        roadmaps.append(roadmap)
        saveRoadmaps()
    }
    
    func updateRoadmap(_ roadmap: Roadmap) {
        if let index = roadmaps.firstIndex(where: { $0.id == roadmap.id }) {
            roadmaps[index] = roadmap
            saveRoadmaps()
        }
    }
    
    func deleteRoadmap(id: UUID) {
        roadmaps.removeAll { $0.id == id }
        saveRoadmaps()
    }
    
    func updateStepStatus(roadmapId: UUID, stepId: UUID, newStatus: StepStatus) {
        guard let roadmapIndex = roadmaps.firstIndex(where: { $0.id == roadmapId }),
              let stepIndex = roadmaps[roadmapIndex].steps.firstIndex(where: { $0.id == stepId }) else {
            return
        }
        
        roadmaps[roadmapIndex].steps[stepIndex].status = newStatus
        saveRoadmaps()
    }
    
    // MARK: - AI Integration
    
    func generateRoadmap(for goal: String, subject: String, completion: @escaping (Roadmap?) -> Void) {
        isGeneratingRoadmap = true
        
        // In a real app with proper API key, we would use this
        if apiKey.starts(with: "sk-") && !apiKey.contains("YOUR_OPENAI_API_KEY") {
            // Generate content using OpenAI API
            let prompt = "Create a detailed study roadmap for the goal: '\(goal)' in the subject area: '\(subject)'. The roadmap should include 5-7 sequential steps with clear objectives and timeframes. For each step, provide a title and a short description of what to focus on."
            
            makeOpenAIRequest(prompt: prompt) { [weak self] response in
                guard let self = self, let response = response else {
                    self?.isGeneratingRoadmap = false
                    completion(nil)
                    return
                }
                
                // Parse the response and create a roadmap
                let roadmap = self.parseRoadmapFromAIResponse(response, goal: goal, subject: subject)
                self.isGeneratingRoadmap = false
                completion(roadmap)
            }
        } else {
            // For demo purposes, use simulated response
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) { [weak self] in
                guard let self = self else { return }
                
                let roadmap = self.createSimulatedRoadmap(goal: goal, subject: subject)
                self.isGeneratingRoadmap = false
                completion(roadmap)
            }
        }
    }
    
    private func parseRoadmapFromAIResponse(_ response: String, goal: String, subject: String) -> Roadmap {
        var roadmap = Roadmap(title: "Roadmap for \(goal)", description: "A structured plan to achieve \(goal) in \(subject)")
        
        // In a full implementation, we would parse the AI response to extract steps
        // For simplicity, we'll return the simulated roadmap
        return createSimulatedRoadmap(goal: goal, subject: subject)
    }
    
    private func createSimulatedRoadmap(goal: String, subject: String) -> Roadmap {
        var roadmap = Roadmap(title: "Roadmap for \(goal)", description: "A structured plan to achieve \(goal) in \(subject)")
        
        // Sample steps based on common study approaches
        let steps: [(title: String, description: String, daysFromNow: Int)] = [
            ("Understand the basics", "Master the fundamental concepts of \(subject) related to \(goal)", 7),
            ("Research key topics", "Identify and study the most important areas for \(goal)", 14),
            ("Practice with exercises", "Solve problems and complete exercises to reinforce learning", 21),
            ("Review and consolidate", "Go through all materials and identify knowledge gaps", 28),
            ("Final preparation", "Focus on weak areas and ensure complete understanding", 35)
        ]
        
        for (index, step) in steps.enumerated() {
            let dueDate = Calendar.current.date(byAdding: .day, value: step.daysFromNow, to: Date())
            let roadmapStep = RoadmapStep(
                title: step.title,
                description: step.description,
                dueDate: dueDate,
                status: .notStarted,
                order: index
            )
            roadmap.steps.append(roadmapStep)
        }
        
        return roadmap
    }
    
    // MARK: - OpenAI API Implementation
    
    private func makeOpenAIRequest(prompt: String, completion: @escaping (String?) -> Void) {
        let url = URL(string: "https://api.openai.com/v1/chat/completions")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: Any] = [
            "model": "gpt-3.5-turbo",
            "messages": [
                ["role": "system", "content": "You are an educational planning assistant. Create a detailed study roadmap."],
                ["role": "user", "content": prompt]
            ],
            "temperature": 0.7
        ]
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: body) else {
            completion(nil)
            return
        }
        
        request.httpBody = jsonData
        
        let task = URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                completion(nil)
                return
            }
            
            // Parse the response
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               let choices = json["choices"] as? [[String: Any]],
               let firstChoice = choices.first,
               let message = firstChoice["message"] as? [String: Any],
               let content = message["content"] as? String {
                completion(content)
            } else {
                completion(nil)
            }
        }
        
        task.resume()
    }
    
    // MARK: - Persistence
    
    private func saveRoadmaps() {
        if let encoded = try? JSONEncoder().encode(roadmaps) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadRoadmaps() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([Roadmap].self, from: data) {
            roadmaps = decoded
        }
    }
} 