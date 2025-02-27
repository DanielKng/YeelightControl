import Foundation
import Combine

// MARK: - Analytics Managing Protocol
protocol AnalyticsManaging {
    func trackEvent(_ event: AnalyticsEvent)
    func startSession()
    func endSession()
    func logError(_ error: Error, context: [String: Any]?)
    func setUserProperty(_ value: Any?, forKey key: String)
    func incrementMetric(_ metric: AnalyticsMetric)
}

// MARK: - Analytics Event
struct AnalyticsEvent {
    let name: String
    let category: AnalyticsCategory
    let parameters: [String: Any]?
    let timestamp: Date
    
    init(
        name: String,
        category: AnalyticsCategory,
        parameters: [String: Any]? = nil,
        timestamp: Date = Date()
    ) {
        self.name = name
        self.category = category
        self.parameters = parameters
        self.timestamp = timestamp
    }
}

// MARK: - Analytics Category
enum AnalyticsCategory: String {
    case device
    case room
    case scene
    case effect
    case automation
    case network
    case error
    case performance
    case user
}

// MARK: - Analytics Metric
enum AnalyticsMetric: String {
    case deviceCount
    case roomCount
    case sceneCount
    case effectCount
    case automationCount
    case networkRequests
    case errorCount
    case sessionDuration
    case appLaunchTime
    case backgroundTaskCount
}

// MARK: - Analytics Manager Implementation
final class UnifiedAnalyticsManager: AnalyticsManaging {
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let queue = DispatchQueue(label: "de.knng.app.yeelightcontrol.analytics", qos: .utility)
    private var metrics: [AnalyticsMetric: Int] = [:]
    private var sessionStartTime: Date?
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Configuration
    private struct Configuration {
        var batchSize = 50
        var uploadInterval: TimeInterval = 300 // 5 minutes
        var maxStorageSize = 10 * 1024 * 1024 // 10MB
        var maxEventAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
    }
    
    private let config = Configuration()
    
    // MARK: - Initialization
    init(services: ServiceContainer = .shared) {
        self.services = services
        setupObservers()
        startPeriodicUpload()
    }
    
    // MARK: - Public Methods
    func trackEvent(_ event: AnalyticsEvent) {
        queue.async { [weak self] in
            self?.storeEvent(event)
            self?.uploadEventsIfNeeded()
        }
    }
    
    func startSession() {
        sessionStartTime = Date()
        trackEvent(AnalyticsEvent(name: "session_start", category: .user))
    }
    
    func endSession() {
        if let startTime = sessionStartTime {
            let duration = Date().timeIntervalSince(startTime)
            trackEvent(AnalyticsEvent(
                name: "session_end",
                category: .user,
                parameters: ["duration": duration]
            ))
        }
        sessionStartTime = nil
    }
    
    func logError(_ error: Error, context: [String: Any]? = nil) {
        var parameters: [String: Any] = [
            "error_description": error.localizedDescription,
            "error_domain": (error as NSError).domain,
            "error_code": (error as NSError).code
        ]
        
        if let context = context {
            parameters.merge(context) { current, _ in current }
        }
        
        trackEvent(AnalyticsEvent(
            name: "error",
            category: .error,
            parameters: parameters
        ))
        
        incrementMetric(.errorCount)
    }
    
    func setUserProperty(_ value: Any?, forKey key: String) {
        queue.async {
            // Store user property for future events
            UserDefaults.standard.set(value, forKey: "analytics_user_\(key)")
        }
    }
    
    func incrementMetric(_ metric: AnalyticsMetric) {
        queue.async { [weak self] in
            self?.metrics[metric, default: 0] += 1
        }
    }
    
    // MARK: - Private Methods
    private func setupObservers() {
        // Track device changes
        services.deviceManager.deviceUpdates
            .sink { [weak self] update in
                switch update {
                case .added:
                    self?.incrementMetric(.deviceCount)
                case .removed:
                    self?.decrementMetric(.deviceCount)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        // Track network requests
        NotificationCenter.default
            .publisher(for: .networkRequestCompleted)
            .sink { [weak self] _ in
                self?.incrementMetric(.networkRequests)
            }
            .store(in: &cancellables)
    }
    
    private func startPeriodicUpload() {
        Timer.publish(every: config.uploadInterval, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.uploadEvents()
            }
            .store(in: &cancellables)
    }
    
    private func storeEvent(_ event: AnalyticsEvent) {
        Task {
            do {
                var events: [AnalyticsEvent] = (try? await services.storage.load(forKey: .analytics)) ?? []
                events.append(event)
                
                // Remove old events if needed
                let cutoffDate = Date().addingTimeInterval(-config.maxEventAge)
                events = events.filter { $0.timestamp > cutoffDate }
                
                try await services.storage.save(events, forKey: .analytics)
            } catch {
                services.logger.error("Failed to store analytics event: \(error.localizedDescription)", category: .analytics)
            }
        }
    }
    
    private func uploadEvents() {
        Task {
            do {
                let events: [AnalyticsEvent] = (try? await services.storage.load(forKey: .analytics)) ?? []
                guard !events.isEmpty else { return }
                
                // Upload events (implement your upload logic here)
                // For now, we'll just log them
                services.logger.info("Would upload \(events.count) events", category: .analytics)
                
                // Clear uploaded events
                try await services.storage.save([], forKey: .analytics)
            } catch {
                services.logger.error("Failed to upload analytics events: \(error.localizedDescription)", category: .analytics)
            }
        }
    }
    
    private func uploadEventsIfNeeded() {
        Task {
            do {
                let events: [AnalyticsEvent] = (try? await services.storage.load(forKey: .analytics)) ?? []
                if events.count >= config.batchSize {
                    uploadEvents()
                }
            } catch {
                services.logger.error("Failed to check analytics events: \(error.localizedDescription)", category: .analytics)
            }
        }
    }
    
    private func decrementMetric(_ metric: AnalyticsMetric) {
        queue.async { [weak self] in
            guard let self = self, let value = self.metrics[metric], value > 0 else { return }
            self.metrics[metric] = value - 1
        }
    }
}

// MARK: - Notification Extension
extension Notification.Name {
    static let networkRequestCompleted = Notification.Name("NetworkRequestCompleted")
}

// MARK: - Logger Category Extension
extension LogCategory {
    static let analytics: LogCategory = "analytics"
} 