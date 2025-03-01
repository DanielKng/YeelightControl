import Foundation
import Combine

protocol AutomationManaging {
    func createAutomation(_ automation: Automation) async throws
    func updateAutomation(_ automation: Automation) async throws
    func deleteAutomation(_ id: String) async throws
    func getAutomation(_ id: String) async throws -> Automation
    func getAllAutomations() async throws -> [Automation]
    func enableAutomation(_ id: String) async throws
    func disableAutomation(_ id: String) async throws
    var automationsPublisher: AnyPublisher<[Automation], Never> { get }
}

struct Automation: Codable, Identifiable {
    let id: String
    var name: String
    var isEnabled: Bool
    var trigger: AutomationTrigger
    var actions: [AutomationAction]
    var conditions: [AutomationCondition]
    var schedule: AutomationSchedule?
    var createdAt: Date
    var updatedAt: Date
}

enum AutomationTrigger: Codable {
    case time(TimeOfDay)
    case deviceState(String, DeviceState)
    case location(LocationTrigger)
    case manual
}

enum AutomationAction: Codable {
    case setDeviceState(String, DeviceState)
    case executeScene(String)
    case notification(String)
    case wait(TimeInterval)
    case conditional(AutomationCondition, [AutomationAction], [AutomationAction])
}

enum AutomationCondition: Codable {
    case deviceState(String, DeviceState)
    case time(TimeRange)
    case location(LocationCondition)
    case weather(WeatherCondition)
    case and([AutomationCondition])
    case or([AutomationCondition])
    case not(AutomationCondition)
}

struct AutomationSchedule: Codable {
    var days: [Weekday]
    var startDate: Date?
    var endDate: Date?
    var repeatInterval: TimeInterval?
    var maxExecutions: Int?
}

enum Weekday: Int, Codable, CaseIterable {
    case sunday = 1
    case monday = 2
    case tuesday = 3
    case wednesday = 4
    case thursday = 5
    case friday = 6
    case saturday = 7
}

struct TimeOfDay: Codable {
    var hour: Int
    var minute: Int
    var second: Int
}

struct TimeRange: Codable {
    var start: TimeOfDay
    var end: TimeOfDay
}

struct LocationTrigger: Codable {
    var enter: Bool
    var location: Location
    var radius: Double
}

struct LocationCondition: Codable {
    var inside: Bool
    var location: Location
    var radius: Double
}

struct Location: Codable {
    var latitude: Double
    var longitude: Double
    var name: String?
}

struct WeatherCondition: Codable {
    var type: WeatherType
    var value: Double?
    var comparison: Comparison
}

enum WeatherType: String, Codable {
    case temperature
    case humidity
    case windSpeed
    case uvIndex
    case precipitation
    case cloudCover
}

enum Comparison: String, Codable {
    case equal
    case notEqual
    case greaterThan
    case lessThan
    case greaterThanOrEqual
    case lessThanOrEqual
}

final class AutomationManager: AutomationManaging {
    private let services: BaseServiceContainer
    private let storage: StorageManagingServiceServiceServiceServiceService
    private let deviceManager: DeviceManaging
    private let notificationManager: NotificationManaging
    private let locationManager: LocationManagingServiceServiceServiceServiceService
    private var automations: [Automation] = []
    private let automationsSubject = CurrentValueSubject<[Automation], Never>([])
    private var subscriptions = Set<AnyCancellable>()
    
    init(services: BaseServiceContainer) {
        self.services = services
        self.storage = services.storageManager
        self.deviceManager = services.deviceManager
        self.notificationManager = services.notificationManager
        self.locationManager = services.locationManager
        
        setupSubscriptions()
        loadAutomations()
    }
    
    var automationsPublisher: AnyPublisher<[Automation], Never> {
        automationsSubject.eraseToAnyPublisher()
    }
    
    func createAutomation(_ automation: Automation) async throws {
        var automations = automationsSubject.value
        automations.append(automation)
        try await saveAutomations(automations)
        automationsSubject.send(automations)
    }
    
    func updateAutomation(_ automation: Automation) async throws {
        var automations = automationsSubject.value
        guard let index = automations.firstIndex(where: { $0.id == automation.id }) else {
            throw AutomationError.notFound
        }
        automations[index] = automation
        try await saveAutomations(automations)
        automationsSubject.send(automations)
    }
    
    func deleteAutomation(_ id: String) async throws {
        var automations = automationsSubject.value
        guard let index = automations.firstIndex(where: { $0.id == id }) else {
            throw AutomationError.notFound
        }
        automations.remove(at: index)
        try await saveAutomations(automations)
        automationsSubject.send(automations)
    }
    
    func getAutomation(_ id: String) async throws -> Automation {
        guard let automation = automationsSubject.value.first(where: { $0.id == id }) else {
            throw AutomationError.notFound
        }
        return automation
    }
    
    func getAllAutomations() async throws -> [Automation] {
        return automationsSubject.value
    }
    
    func enableAutomation(_ id: String) async throws {
        var automations = automationsSubject.value
        guard let index = automations.firstIndex(where: { $0.id == id }) else {
            throw AutomationError.notFound
        }
        automations[index].isEnabled = true
        try await saveAutomations(automations)
        automationsSubject.send(automations)
    }
    
    func disableAutomation(_ id: String) async throws {
        var automations = automationsSubject.value
        guard let index = automations.firstIndex(where: { $0.id == id }) else {
            throw AutomationError.notFound
        }
        automations[index].isEnabled = false
        try await saveAutomations(automations)
        automationsSubject.send(automations)
    }
    
    private func setupSubscriptions() {
        // Subscribe to relevant events (device state changes, location updates, etc.)
        deviceManager.deviceStatePublisher
            .sink { [weak self] updates in
                Task {
                    await self?.handleDeviceStateUpdates(updates)
                }
            }
            .store(in: &subscriptions)
        
        locationManager.locationPublisher
            .sink { [weak self] location in
                Task {
                    await self?.handleLocationUpdate(location)
                }
            }
            .store(in: &subscriptions)
    }
    
    private func loadAutomations() {
        Task {
            do {
                let automations: [Automation] = try await storage.load(.automations)
                automationsSubject.send(automations)
            } catch {
                print("Failed to load automations: \(error)")
                automationsSubject.send([])
            }
        }
    }
    
    private func saveAutomations(_ automations: [Automation]) async throws {
        try await storage.save(automations, for: .automations)
    }
    
    private func handleDeviceStateUpdates(_ updates: [DeviceStateUpdate]) async {
        // Check and execute automations based on device state changes
    }
    
    private func handleLocationUpdate(_ location: Location) async {
        // Check and execute automations based on location changes
    }
}

enum AutomationError: LocalizedError {
    case notFound
    case invalidTrigger
    case invalidAction
    case invalidCondition
    case executionFailed
    
    var errorDescription: String? {
        switch self {
        case .notFound: return "Automation not found"
        case .invalidTrigger: return "Invalid automation trigger"
        case .invalidAction: return "Invalid automation action"
        case .invalidCondition: return "Invalid automation condition"
        case .executionFailed: return "Failed to execute automation"
        }
    }
} 