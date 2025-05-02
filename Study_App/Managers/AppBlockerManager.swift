import Foundation
import UserNotifications
// Uncommented frameworks for app blocking
import DeviceActivity
import ManagedSettings
import FamilyControls

class AppBlockerManager: ObservableObject {
    @Published var isBlockingEnabled = false
    @Published var blockedApps: [String] = ["TikTok", "Instagram", "Snapchat"]
    @Published var customBlockedApps: [String] = []
    @Published var blockStartTime: Date?
    @Published var blockEndTime: Date?
    @Published var blockDuration: TimeInterval = 3600 // Default 1 hour in seconds
    
    private let saveKey = "blocked_apps"
    
    // Screen Time API implementation
    private let activityName = DeviceActivityName("StudyTime")
    private var store: ManagedSettingsStore?
    private var selection: FamilyActivitySelection?
    private let center = AuthorizationCenter.shared
    
    init() {
        loadBlockedApps()
        
        // Initialize the settings store and request authorization
        store = ManagedSettingsStore()
        
        // Request authorization to use Screen Time API
        Task {
            do {
                try await center.requestAuthorization(for: .individual)
                
                // Load stored selection if available
                if let selectionData = UserDefaults.standard.data(forKey: "blockedAppsSelection"),
                   let decodedSelection = try? JSONDecoder().decode(FamilyActivitySelection.self, from: selectionData) {
                    selection = decodedSelection
                } else {
                    // Create a default selection with our blocked apps
                    let defaultSelection = FamilyActivitySelection()
                    selection = defaultSelection
                }
            } catch {
                print("Authorization failed: \(error.localizedDescription)")
            }
        }
    }
    
    func startBlocking() {
        isBlockingEnabled = true
        blockStartTime = Date()
        blockEndTime = Date().addingTimeInterval(blockDuration)
        requestNotificationPermission()
        scheduleEndBlockingNotification()
        
        // Implement Screen Time API blocking
        guard let selection = selection, let store = store else { return }
        
        // Create a schedule for the specified duration
        let schedule = DeviceActivitySchedule(
            intervalStart: DateComponents(hour: 0, minute: 0),
            intervalEnd: DateComponents(hour: 23, minute: 59),
            repeats: false,
            warningTime: nil
        )
        
        // Configure the schedule in DeviceActivityCenter
        let center = DeviceActivityCenter()
        try? center.startMonitoring(
            selection,
            during: [activityName: schedule]
        )
        
        // Apply the app restrictions
        store.shield.applications = selection.applicationTokens
        store.shield.applicationCategories = .all()
        
        // Enable shields
        store.shield.isEnabled = true
    }
    
    func stopBlocking() {
        isBlockingEnabled = false
        blockStartTime = nil
        blockEndTime = nil
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // Disable shields and stop monitoring
        store?.shield.isEnabled = false
        
        // Stop monitoring
        let center = DeviceActivityCenter()
        center.stopMonitoring([activityName])
    }
    
    func addAppToBlock(_ appName: String) {
        if !customBlockedApps.contains(appName) {
            customBlockedApps.append(appName)
            saveBlockedApps()
        }
    }
    
    func removeAppFromBlock(_ appName: String) {
        if let index = customBlockedApps.firstIndex(of: appName) {
            customBlockedApps.remove(at: index)
            saveBlockedApps()
        }
    }
    
    func isAppBlocked(_ appName: String) -> Bool {
        guard isBlockingEnabled else { return false }
        return blockedApps.contains(appName) || customBlockedApps.contains(appName)
    }
    
    // Implement app selection UI
    func selectAppsToBlock() async {
        do {
            // Launch app selection UI
            let newSelection = try await FamilyActivityPicker.shared.requestSelection(
                initialSelection: selection ?? FamilyActivitySelection()
            )
            
            selection = newSelection
            
            // Save selection to UserDefaults
            if let encodedData = try? JSONEncoder().encode(newSelection) {
                UserDefaults.standard.set(encodedData, forKey: "blockedAppsSelection")
            }
        } catch {
            print("App selection failed: \(error.localizedDescription)")
        }
    }
    
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in
            // Handle permission result if needed
        }
    }
    
    private func scheduleEndBlockingNotification() {
        guard let endTime = blockEndTime else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Study Block Ended"
        content.body = "Your app blocking period has ended. Great job focusing on your studies!"
        content.sound = .default
        
        let timeInterval = endTime.timeIntervalSinceNow
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval, repeats: false)
        
        let request = UNNotificationRequest(identifier: "blockEndNotification", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
    }
    
    private func saveBlockedApps() {
        if let encoded = try? JSONEncoder().encode(customBlockedApps) {
            UserDefaults.standard.set(encoded, forKey: saveKey)
        }
    }
    
    private func loadBlockedApps() {
        if let data = UserDefaults.standard.data(forKey: saveKey),
           let decoded = try? JSONDecoder().decode([String].self, from: data) {
            customBlockedApps = decoded
        }
    }
} 