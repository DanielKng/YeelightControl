import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - Location Managing Protocol
protocol LocationManaging {
    var currentLocation: CLLocation? { get }
    var locationUpdates: AnyPublisher<CLLocation, Never> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var authorizationUpdates: AnyPublisher<CLAuthorizationStatus, Never> { get }
    
    func requestWhenInUseAuthorization()
    func requestAlwaysAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoring(region: CLRegion)
    func stopMonitoring(region: CLRegion)
    func requestLocation()
}

@MainActor
public final class UnifiedLocationManager: NSObject, LocationManaging, ObservableObject {
    // MARK: - Published Properties
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var isMonitoringLocation = false
    
    // MARK: - Publishers
    var locationUpdates: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    var authorizationUpdates: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }
    
    // MARK: - Private Properties
    private let services: ServiceContainer
    private let locationManager = CLLocationManager()
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let authorizationSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    private var monitoredRegions: Set<CLRegion> = []
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    
    // MARK: - Singleton
    public static let shared = UnifiedLocationManager()
    
    // MARK: - Initialization
    private override init() {
        self.services = .shared
        super.init()
        setupLocationManager()
        setupConfigurationObserver()
    }
    
    // MARK: - Public Methods
    public func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startMonitoringLocation() {
        guard CLLocationManager.locationServicesEnabled() else {
            print("Location services are disabled")
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            print("Location authorization not granted")
            return
        }
        
        locationManager.startUpdatingLocation()
        isMonitoringLocation = true
    }
    
    public func stopMonitoringLocation() {
        locationManager.stopUpdatingLocation()
        isMonitoringLocation = false
    }
    
    public func getCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationUpdateHandler = { location in
                self.locationUpdateHandler = nil
                continuation.resume(returning: location)
            }
            
            startMonitoringLocation()
            
            // Set a timeout
            Task {
                try await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                if let handler = self.locationUpdateHandler {
                    self.locationUpdateHandler = nil
                    handler(self.currentLocation ?? CLLocation())
                }
            }
        }
    }
    
    func requestWhenInUseAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
        services.logger.info("Started location updates", category: .system)
    }
    
    func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
        services.logger.info("Stopped location updates", category: .system)
    }
    
    func startMonitoring(region: CLRegion) {
        guard CLLocationManager.isMonitoringAvailable(for: type(of: region)) else {
            services.logger.warning("Region monitoring not available for region type", category: .system)
            return
        }
        
        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(region)
        services.logger.info("Started monitoring region: \(region.identifier)", category: .system)
    }
    
    func stopMonitoring(region: CLRegion) {
        locationManager.stopMonitoring(for: region)
        monitoredRegions.remove(region)
        services.logger.info("Stopped monitoring region: \(region.identifier)", category: .system)
    }
    
    func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Private Methods
    private func setupLocationManager() {
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = 10 // meters
        
        // Update initial authorization status
        authorizationStatus = locationManager.authorizationStatus
    }
    
    private func setupConfigurationObserver() {
        services.config.configurationUpdates
            .sink { [weak self] _ in
                self?.updateLocationManagerConfiguration()
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationManagerConfiguration() {
        locationManager.desiredAccuracy = services.config.getValue(for: .desiredAccuracy) ?? kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = services.config.getValue(for: .distanceFilter) ?? 100
        locationManager.activityType = CLActivityType(rawValue: services.config.getValue(for: .activityType) ?? 0) ?? .other
        locationManager.pausesLocationUpdatesAutomatically = services.config.getValue(for: .pausesLocationUpdatesAutomatically) ?? true
        locationManager.allowsBackgroundLocationUpdates = services.config.getValue(for: .allowsBackgroundLocationUpdates) ?? false
    }
}

// MARK: - Location Manager Delegate
extension UnifiedLocationManager: CLLocationManagerDelegate {
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationUpdateHandler?(location)
        locationSubject.send(location)
        services.logger.debug("Location updated: \(location.coordinate)", category: .system)
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        services.logger.error("Location update failed: \(error.localizedDescription)", category: .system)
        services.errorHandler.handle(error)
    }
    
    public func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        authorizationSubject.send(manager.authorizationStatus)
        services.logger.info("Location authorization status changed: \(manager.authorizationStatus.rawValue)", category: .system)
        
        switch manager.authorizationStatus {
        case .authorizedWhenInUse, .authorizedAlways:
            if isMonitoringLocation {
                startMonitoringLocation()
            }
        case .denied, .restricted:
            stopMonitoringLocation()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        services.logger.info("Started monitoring region: \(region.identifier)", category: .system)
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        services.logger.info("Entered region: \(region.identifier)", category: .system)
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        services.logger.info("Exited region: \(region.identifier)", category: .system)
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        if let region = region {
            services.logger.error("Region monitoring failed for \(region.identifier): \(error.localizedDescription)", category: .system)
        } else {
            services.logger.error("Region monitoring failed: \(error.localizedDescription)", category: .system)
        }
        services.errorHandler.handle(error)
    }
}

// MARK: - Location Errors
enum LocationError: LocalizedError {
    case authorizationDenied
    case locationServicesDisabled
    case monitoringNotAvailable
    case invalidRegion
    case systemError(String)
    
    var errorDescription: String? {
        switch self {
        case .authorizationDenied:
            return "Location authorization denied"
        case .locationServicesDisabled:
            return "Location services are disabled"
        case .monitoringNotAvailable:
            return "Region monitoring is not available"
        case .invalidRegion:
            return "Invalid region configuration"
        case .systemError(let message):
            return "System error: \(message)"
        }
    }
} 