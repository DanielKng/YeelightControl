import Foundation
import CoreLocation
import Combine
import SwiftUI

// MARK: - Location Managing Protocol
@preconcurrency protocol LocationManaging: Actor {
    nonisolated var currentLocation: CLLocation? { get }
    nonisolated var locationUpdates: AnyPublisher<CLLocation, Never> { get }
    nonisolated var authorizationStatus: CLAuthorizationStatus { get }
    nonisolated var authorizationUpdates: AnyPublisher<CLAuthorizationStatus, Never> { get }
    
    func requestWhenInUseAuthorization() async
    func requestAlwaysAuthorization() async
    func startUpdatingLocation() async
    func stopUpdatingLocation() async
    func startMonitoring(region: CLRegion) async
    func stopMonitoring(region: CLRegion) async
    func requestLocation() async
}

@MainActor
public final class UnifiedLocationManager: NSObject, LocationManaging, ObservableObject, CLLocationManagerDelegate, Service {
    // MARK: - Published Properties
    @Published public private(set) var currentLocation: CLLocation?
    @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @Published public private(set) var isMonitoringLocation = false
    
    // MARK: - Publishers
    nonisolated var locationUpdates: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    nonisolated var authorizationUpdates: AnyPublisher<CLAuthorizationStatus, Never> {
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
    public func requestAuthorization() async {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startMonitoringLocation() async {
        guard CLLocationManager.locationServicesEnabled() else {
            await services.logger.log(.warning, "Location services are disabled")
            return
        }
        
        guard authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways else {
            await services.logger.log(.warning, "Location authorization not granted")
            return
        }
        
        locationManager.startUpdatingLocation()
        isMonitoringLocation = true
    }
    
    public func stopMonitoringLocation() async {
        locationManager.stopUpdatingLocation()
        isMonitoringLocation = false
    }
    
    public func getCurrentLocation() async throws -> CLLocation {
        try await withCheckedThrowingContinuation { continuation in
            locationUpdateHandler = { location in
                self.locationUpdateHandler = nil
                continuation.resume(returning: location)
            }
            
            Task {
                await startMonitoringLocation()
                
                // Set a timeout
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                if let handler = self.locationUpdateHandler {
                    self.locationUpdateHandler = nil
                    handler(self.currentLocation ?? CLLocation())
                }
            }
        }
    }
    
    func requestWhenInUseAuthorization() async {
        locationManager.requestWhenInUseAuthorization()
    }
    
    func requestAlwaysAuthorization() async {
        locationManager.requestAlwaysAuthorization()
    }
    
    func startUpdatingLocation() async {
        locationManager.startUpdatingLocation()
        await services.logger.log(.info, "Started location updates")
    }
    
    func stopUpdatingLocation() async {
        locationManager.stopUpdatingLocation()
        await services.logger.log(.info, "Stopped location updates")
    }
    
    func startMonitoring(region: CLRegion) async {
        guard CLLocationManager.isMonitoringAvailable(for: type(of: region)) else {
            await services.logger.log(.warning, "Region monitoring not available for region type")
            return
        }
        
        locationManager.startMonitoring(for: region)
        monitoredRegions.insert(region)
        await services.logger.log(.info, "Started monitoring region: \(region.identifier)")
    }
    
    func stopMonitoring(region: CLRegion) async {
        locationManager.stopMonitoring(for: region)
        monitoredRegions.remove(region)
        await services.logger.log(.info, "Stopped monitoring region: \(region.identifier)")
    }
    
    func requestLocation() async {
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
                Task { @MainActor [weak self] in
                    await self?.updateLocationManagerConfiguration()
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateLocationManagerConfiguration() async {
        locationManager.desiredAccuracy = await services.config.getValue(for: .desiredAccuracy) ?? kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = await services.config.getValue(for: .distanceFilter) ?? 100
        locationManager.activityType = CLActivityType(rawValue: await services.config.getValue(for: .activityType) ?? 0) ?? .other
        locationManager.pausesLocationUpdatesAutomatically = await services.config.getValue(for: .pausesLocationUpdatesAutomatically) ?? true
        locationManager.allowsBackgroundLocationUpdates = await services.config.getValue(for: .allowsBackgroundLocationUpdates) ?? false
    }
    
    // MARK: - Service Protocol
    public func start() async throws {
        await requestAuthorization()
    }
    
    public func stop() async {
        locationManager.stopUpdatingLocation()
        for region in monitoredRegions {
            await stopMonitoring(region: region)
        }
    }
    
    // MARK: - CLLocationManagerDelegate
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        currentLocation = location
        locationUpdateHandler?(location)
        locationSubject.send(location)
        Task {
            await services.logger.log(.debug, "Location updated: \(location.coordinate)")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await services.logger.log(.error, "Location update failed: \(error.localizedDescription)")
            await services.errorHandler.handle(error)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        authorizationStatus = status
        authorizationSubject.send(status)
        Task {
            await services.logger.log(.info, "Location authorization status changed: \(status.rawValue)")
            
            switch status {
            case .authorizedWhenInUse, .authorizedAlways:
                if isMonitoringLocation {
                    Task {
                        await startMonitoringLocation()
                    }
                }
            case .denied, .restricted:
                Task {
                    await stopMonitoringLocation()
                }
            case .notDetermined:
                break
            @unknown default:
                break
            }
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Task {
            await services.logger.log(.info, "Started monitoring region: \(region.identifier)")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task {
            await services.logger.log(.info, "Entered region: \(region.identifier)")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task {
            await services.logger.log(.info, "Exited region: \(region.identifier)")
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task {
            if let region = region {
                await services.logger.log(.error, "Region monitoring failed for \(region.identifier): \(error.localizedDescription)")
            } else {
                await services.logger.log(.error, "Region monitoring failed: \(error.localizedDescription)")
            }
            await services.errorHandler.handle(error)
        }
    }
} 