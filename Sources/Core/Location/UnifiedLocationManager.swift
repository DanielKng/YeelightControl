import CoreLocation
import Foundation
import Combine
import SwiftUI
import OSLog

// Add explicit imports for the types

// MARK: - Location Managing Protocol
@preconcurrency public protocol Core_LocationManaging: Core_BaseService {
    nonisolated var currentLocation: CLLocation? { get async }
    nonisolated var locationUpdates: AnyPublisher<CLLocation, Never> { get }
    nonisolated var authorizationStatus: CLAuthorizationStatus { get async }
    nonisolated var isMonitoringAvailable: Bool { get }
    nonisolated var monitoredRegions: Set<CLRegion> { get }
    
    nonisolated func requestAuthorization()
    nonisolated func startUpdatingLocation()
    nonisolated func stopUpdatingLocation()
    nonisolated func startMonitoring(for region: CLRegion)
    nonisolated func stopMonitoring(for region: CLRegion)
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
        Task {
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

public actor UnifiedLocationManager: Core_LocationManaging, Core_BaseService {
    // MARK: - Core_BaseService
    public var serviceIdentifier: String {
        return "core.location"
    }
    
    private var _isEnabled: Bool = true
    
    public nonisolated var isEnabled: Bool {
        get {
            // Using a non-async approach to access the property
            // This is a simplification - in a real app, you might need a more robust solution
            return _isEnabled
        }
    }
    
    // MARK: - Properties
    private var _currentLocation: CLLocation?
    private var _authorizationStatus: CLAuthorizationStatus = .notDetermined
    private var _isMonitoringLocation = false
    
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
    private let services: Core_ServiceContainer
    private let locationManager: CLLocationManager
    private let locationSubject = PassthroughSubject<CLLocation, Never>()
    private let authorizationSubject = PassthroughSubject<CLAuthorizationStatus, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var locationUpdateHandler: ((CLLocation) -> Void)?
    private var locationDelegate: LocationManagerDelegate!
    private var isMonitoring: Bool = false
    
    // MARK: - Singleton
    public static let shared = UnifiedLocationManager(services: ServiceContainer.shared)
    
    // MARK: - Initialization
    public init(services: Core_ServiceContainer) {
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
    
    // MARK: - Core_LocationManaging
    
    public nonisolated var currentLocation: CLLocation? {
        get async {
            return await _currentLocation
        }
    }
    
    public nonisolated var authorizationStatus: CLAuthorizationStatus {
        get async {
            return await _authorizationStatus
        }
    }
    
    // MARK: - Public Methods
    public nonisolated func requestAuthorization() {
        locationManager.requestWhenInUseAuthorization()
    }
    
    public nonisolated func startMonitoringLocation() async {
        await startMonitoringLocationInternal()
    }
    
    private func startMonitoringLocationInternal() async {
        guard CLLocationManager.locationServicesEnabled() else {
            // TODO: Fix this when logger is updated
            // await services.logger.warning("Location services are disabled", category: .location)
            return
        }
        
        guard _authorizationStatus == .authorizedWhenInUse || _authorizationStatus == .authorizedAlways else {
            // TODO: Fix this when logger is updated
            // await services.logger.warning("Location authorization not granted", category: .location)
            return
        }
        
        await startMonitoring()
    }
    
    public nonisolated func stopMonitoringLocation() async {
        await stopMonitoring()
    }
    
    public nonisolated func getCurrentLocation() async throws -> CLLocation {
        return try await withCheckedThrowingContinuation { continuation in
            Task {
                await setLocationUpdateHandler { location in
                    continuation.resume(returning: location)
                }
                
                await startMonitoringLocationInternal()
                
                // Set a timeout
                try? await Task.sleep(nanoseconds: 10_000_000_000) // 10 seconds
                
                if await hasLocationUpdateHandler() {
                    await clearLocationUpdateHandler()
                    
                    if let location = await _currentLocation {
                        continuation.resume(returning: location)
                    } else {
                        continuation.resume(throwing: NSError(domain: "LocationError", code: 1, userInfo: [NSLocalizedDescriptionKey: "Failed to get location"]))
                    }
                }
            }
        }
    }
    
    private func setLocationUpdateHandler(_ handler: @escaping (CLLocation) -> Void) {
        locationUpdateHandler = handler
    }
    
    private func hasLocationUpdateHandler() -> Bool {
        return locationUpdateHandler != nil
    }
    
    private func clearLocationUpdateHandler() {
        locationUpdateHandler = nil
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
                // TODO: Fix this when logger is updated
                // await services.logger.error("Region monitoring is not available for \(type(of: region))", category: .location)
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
        // TODO: Fix this when config is updated
        /*
        await services.config.configurationUpdates
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.updateLocationManagerConfiguration()
                }
            }
            .store(in: &cancellables)
        */
    }
    
    private func updateLocationManagerConfiguration() async {
        // TODO: Fix this when config is updated
        /*
        locationManager.desiredAccuracy = try? await services.config.getValue(for: .desiredAccuracy) ?? kCLLocationAccuracyHundredMeters
        locationManager.distanceFilter = try? await services.config.getValue(for: .distanceFilter) ?? 100
        locationManager.activityType = CLActivityType(rawValue: try? await services.config.getValue(for: .activityType) ?? 0) ?? .other
        locationManager.pausesLocationUpdatesAutomatically = try? await services.config.getValue(for: .pausesLocationUpdatesAutomatically) ?? true
        locationManager.allowsBackgroundLocationUpdates = try? await services.config.getValue(for: .allowsBackgroundLocationUpdates) ?? false
        */
    }
    
    private func startMonitoring() {
        isMonitoring = true
        _isMonitoringLocation = true
        locationManager.startUpdatingLocation()
    }
    
    private func stopMonitoring() {
        isMonitoring = false
        _isMonitoringLocation = false
        locationManager.stopUpdatingLocation()
    }
    
    // MARK: - Delegate Handler Methods
    func handleLocationUpdate(_ location: CLLocation) async {
        _currentLocation = location
        locationSubject.send(location)
        // TODO: Fix this when logger is updated
        // await services.logger.info("Location updated: \(location.coordinate)", category: .location)
        
        if let handler = locationUpdateHandler {
            locationUpdateHandler = nil
            handler(location)
        }
    }
    
    func handleLocationError(_ error: Error) async {
        // TODO: Fix this when logger is updated
        // await services.logger.error("Location update failed: \(error.localizedDescription)", category: .location)
    }
    
    func handleAuthorizationChange(_ status: CLAuthorizationStatus) async {
        _authorizationStatus = status
        authorizationSubject.send(status)
        
        switch status {
        case .authorizedWhenInUse, .authorizedAlways:
            if _isMonitoringLocation {
                await startMonitoring()
            }
        case .denied, .restricted:
            await stopMonitoring()
        default:
            break
        }
    }
    
    func handleStartMonitoring(_ region: CLRegion) async {
        // TODO: Fix this when logger is updated
        // await services.logger.info("Started monitoring region: \(region.identifier)", category: .location)
    }
    
    func handleRegionEnter(_ region: CLRegion) async {
        // TODO: Fix this when logger is updated
        // await services.logger.info("Entered region: \(region.identifier)", category: .location)
    }
    
    func handleRegionExit(_ region: CLRegion) async {
        // TODO: Fix this when logger is updated
        // await services.logger.info("Exited region: \(region.identifier)", category: .location)
    }
    
    func handleMonitoringFailure(_ region: CLRegion?, error: Error) async {
        if let region = region {
            // TODO: Fix this when logger is updated
            // await services.logger.error("Failed to monitor region \(region.identifier): \(error.localizedDescription)", category: .location)
        } else {
            // TODO: Fix this when logger is updated
            // await services.logger.error("Failed to monitor region: \(error.localizedDescription)", category: .location)
        }
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
