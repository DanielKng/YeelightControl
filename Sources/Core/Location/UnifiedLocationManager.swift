import CoreLocation
import Foundation
import Combine
import SwiftUI
import OSLog

// Add explicit imports for the types

// MARK: - Location Managing Protocol
public protocol LocationManaging: AnyObject {
    var currentLocation: CLLocation? { get }
    var locationUpdates: AnyPublisher<CLLocation, Never> { get }
    var authorizationStatus: CLAuthorizationStatus { get }
    var isMonitoringAvailable: Bool { get }
    var monitoredRegions: Set<CLRegion> { get }
    
    func requestAuthorization()
    func startUpdatingLocation()
    func stopUpdatingLocation()
    func startMonitoring(for region: CLRegion)
    func stopMonitoring(for region: CLRegion)
}

// Create a separate delegate class to handle CLLocationManagerDelegate
private class LocationManagerDelegate: NSObject, CLLocationManagerDelegate {
    weak var manager: UnifiedLocationManager?
    
    init(manager: UnifiedLocationManager) {
        self.manager = manager
        super.init()
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        Task { @MainActor in
            await self.manager?.handleLocationUpdate(location)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        Task {
            await self.manager?.handleLocationError(error)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        Task {
            await self.manager?.handleAuthorizationChange(status)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        Task {
            await self.manager?.handleStartMonitoring(region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        Task {
            await self.manager?.handleRegionEnter(region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        Task {
            await self.manager?.handleRegionExit(region)
        }
    }
    
    func locationManager(_ manager: CLLocationManager, monitoringDidFailFor region: CLRegion?, withError error: Error) {
        Task {
            await self.manager?.handleMonitoringFailure(region, error: error)
        }
    }
}

public actor UnifiedLocationManager: LocationManaging {
    public let id = "location.manager"
    public var isEnabled: Bool = true
    
    // Use MainActor for published properties
    @MainActor @Published public private(set) var currentLocation: CLLocation?
    @MainActor @Published public private(set) var authorizationStatus: CLAuthorizationStatus = .notDetermined
    @MainActor @Published public private(set) var isMonitoringLocation = false
    
    // MARK: - Publishers
    public nonisolated var locationUpdates: AnyPublisher<CLLocation, Never> {
        locationSubject.eraseToAnyPublisher()
    }
    
    public nonisolated var authorizationUpdates: AnyPublisher<CLAuthorizationStatus, Never> {
        authorizationSubject.eraseToAnyPublisher()
    }
    
    public nonisolated var isMonitoringAvailable: Bool {
        CLLocationManager.isMonitoringAvailable(for: CLCircularRegion.self)
    }
    
    public nonisolated var monitoredRegions: Set<CLRegion> {
        locationManager.monitoredRegions
    }
    
    // MARK: - Private Properties
    private let services: BaseServiceContainer
    private let locationManager: CLLocationManager
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let authorizationSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    private var locationDelegate: LocationManagerDelegate!
    private var isMonitoring: Bool = false
    
    // MARK: - Singleton
    public static let shared = UnifiedLocationManager()
    
    // MARK: - Initialization
    public init(services: BaseServiceContainer = .shared) {
        self.services = services
        self.locationManager = CLLocationManager()
        
        // Create the delegate and set it
        self.locationDelegate = LocationManagerDelegate(manager: self)
        self.locationManager.delegate = self.locationDelegate
        
        self.locationManager.desiredAccuracy = kCLLocationAccuracyBest
        self.locationManager.distanceFilter = kCLDistanceFilterNone
        self.locationManager.allowsBackgroundLocationUpdates = true
        self.locationManager.pausesLocationUpdatesAutomatically = false
        
        // Setup configuration observer in a task
        Task {
            await setupConfigurationObserver()
        }
    }
    
    // MARK: - Public Methods
    public nonisolated func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public func startMonitoringLocation() async {
        guard CLLocationManager.locationServicesEnabled() else {
            await services.logger.warning("Location services are disabled", category: .location)
            return
        }
        
        let status = await MainActor.run { authorizationStatus }
        guard status == .authorizedWhenInUse || status == .authorizedAlways else {
            await services.logger.warning("Location authorization not granted", category: .location)
            return
        }
        
        await startMonitoring()
    }
    
    public func stopMonitoringLocation() async {
        await stopMonitoring()
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
                    let location = await MainActor.run { self.currentLocation ?? CLLocation() }
                    handler(location)
                }
            }
        }
    }
    
    public nonisolated func startUpdatingLocation() {
        locationManager.startUpdatingLocation()
    }
    
    public nonisolated func stopUpdatingLocation() {
        locationManager.stopUpdatingLocation()
    }
    
    public nonisolated func startMonitoring(for region: CLRegion) {
        guard CLLocationManager.isMonitoringAvailable(for: type(of: region)) else {
            Task {
                await services.logger.error("Region monitoring is not available for \(type(of: region))", category: .location)
            }
            return
        }
        locationManager.startMonitoring(for: region)
    }
    
    public nonisolated func stopMonitoring(for region: CLRegion) {
        locationManager.stopMonitoring(for: region)
    }
    
    public nonisolated func requestLocation() {
        locationManager.requestLocation()
    }
    
    // MARK: - Private Methods
    private func setupConfigurationObserver() async {
        await services.config.configurationUpdates
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
    
    // MARK: - Delegate Handler Methods
    @MainActor
    func handleLocationUpdate(_ location: CLLocation) async {
        currentLocation = location
        locationSubject.send(location)
        await services.logger.info("Location updated: \(location.coordinate)", category: .location)
        
        if let handler = locationUpdateHandler {
            locationUpdateHandler = nil
            handler(location)
        }
    }
    
    func handleLocationError(_ error: Error) async {
        await services.logger.error("Location update failed: \(error.localizedDescription)", category: .location)
    }
    
    @MainActor
    func handleAuthorizationChange(_ status: CLAuthorizationStatus) async {
        authorizationStatus = status
        authorizationSubject.send(status)
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if isMonitoringLocation {
                await startMonitoringLocation()
            }
        case .denied, .restricted:
            await stopMonitoringLocation()
        case .notDetermined:
            break
        @unknown default:
            break
        }
    }
    
    func handleStartMonitoring(_ region: CLRegion) async {
        await services.logger.info("Started monitoring region: \(region.identifier)", category: .location)
    }
    
    func handleRegionEnter(_ region: CLRegion) async {
        await services.logger.info("Entered region: \(region.identifier)", category: .location)
    }
    
    func handleRegionExit(_ region: CLRegion) async {
        await services.logger.info("Exited region: \(region.identifier)", category: .location)
    }
    
    func handleMonitoringFailure(_ region: CLRegion?, error: Error) async {
        if let region = region {
            await services.logger.error("Monitoring failed for region \(region.identifier): \(error.localizedDescription)", category: .location)
        } else {
            await services.logger.error("Monitoring failed: \(error.localizedDescription)", category: .location)
        }
        await services.errorHandler.handle(error)
    }
    
    private func startMonitoring() async {
        guard !isMonitoring else { return }
        
        isMonitoring = true
        await services.logger.info("Started location monitoring", category: .location)
        
        locationManager.startUpdatingLocation()
    }
    
    private func stopMonitoring() async {
        guard isMonitoring else { return }
        
        isMonitoring = false
        await services.logger.info("Stopped location monitoring", category: .location)
        
        locationManager.stopUpdatingLocation()
    }
}

public enum LocationEvent {
    case locationUpdated(CLLocation)
    case permissionGranted
    case permissionDenied
    case permissionNotDetermined
    case error(Error)
}

public enum LocationError: LocalizedError {
    case permissionDenied
    case locationUnavailable
    case monitoringFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .permissionDenied:
            return "Location permission denied"
        case .locationUnavailable:
            return "Location services unavailable"
        case .monitoringFailed(let error):
            return "Location monitoring failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - Service Protocol
extension UnifiedLocationManager {
    public func start() async {
        await requestAuthorization()
    }
    
    public func stop() async {
        locationManager.stopUpdatingLocation()
        for region in monitoredRegions {
            await stopMonitoring(for: region)
        }
    }
} 
