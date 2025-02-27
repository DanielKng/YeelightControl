import Foundation
import CoreLocation
import UserNotifications

class AutomationManager: NSObject, ObservableObject {
    static let shared = AutomationManager()
    @Published private(set) var automations: [Automation] = []
    private let storage = DeviceStorage.shared
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        loadAutomations()
        setupLocationManager()
        setupNotifications()
    }
    
    func addAutomation(_ automation: Automation) {
        automations.append(automation)
        saveAutomations()
        scheduleAutomation(automation)
    }
    
    func removeAutomation(_ automation: Automation) {
        automations.removeAll { $0.id == automation.id }
        saveAutomations()
        UNUserNotificationCenter.current().removePendingNotificationRequests(
            withIdentifiers: [automation.id.uuidString]
        )
    }
    
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyHundredMeters
        locationManager.requestWhenInUseAuthorization()
    }
    
    private func setupNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }
    
    private func scheduleAutomation(_ automation: Automation) {
        switch automation.trigger {
        case .time(let time):
            scheduleTimeBasedAutomation(automation, at: time)
        case .location(let location):
            startMonitoringLocation(location, for: automation)
        case .sunset, .sunrise:
            scheduleAstronomicalAutomation(automation)
        }
    }
    
    private func scheduleTimeBasedAutomation(_ automation: Automation, at time: Date) {
        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)
        
        let request = UNNotificationRequest(
            identifier: automation.id.uuidString,
            content: UNNotificationContent(),
            trigger: trigger
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    private func startMonitoringLocation(_ location: CLLocationCoordinate2D, for automation: Automation) {
        let region = CLCircularRegion(
            center: location,
            radius: 100,
            identifier: automation.id.uuidString
        )
        region.notifyOnEntry = true
        region.notifyOnExit = true
        
        locationManager.startMonitoring(for: region)
    }
    
    private func scheduleAstronomicalAutomation(_ automation: Automation) {
        // Implementation would use astronomical calculations or a service
        // to determine sunrise/sunset times for the user's location
    }
    
    private func loadAutomations() {
        automations = storage.loadAutomations()
    }
    
    private func saveAutomations() {
        storage.saveAutomations(automations)
    }
}

extension AutomationManager: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        handleRegionEvent(region, isEntry: true)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        handleRegionEvent(region, isEntry: false)
    }
    
    private func handleRegionEvent(_ region: CLRegion, isEntry: Bool) {
        guard let automation = automations.first(where: { $0.id.uuidString == region.identifier })
        else { return }
        
        executeAutomation(automation)
    }
    
    private func executeAutomation(_ automation: Automation) {
        // Execute the automation's actions
        for action in automation.actions {
            switch action {
            case .setPower(let deviceIP, let on):
                if let device = YeelightManager.shared.devices.first(where: { $0.ip == deviceIP }) {
                    YeelightManager.shared.setPower(device, on: on)
                }
            case .setScene(let deviceIP, let scene):
                if let device = YeelightManager.shared.devices.first(where: { $0.ip == deviceIP }) {
                    YeelightManager.shared.applyScene(scene, to: device)
                }
            }
        }
    }
} 