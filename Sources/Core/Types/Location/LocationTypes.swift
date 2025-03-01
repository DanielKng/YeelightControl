import Foundation
import CoreLocation
import Combine

// MARK: - Location Types
public struct Core_Location: Codable, Hashable {
    public let latitude: Double
    public let longitude: Double
    public let altitude: Double?
    public let horizontalAccuracy: Double?
    public let verticalAccuracy: Double?
    public let timestamp: Date
    public let name: String?
    public let address: String?
    
    public init(
        latitude: Double,
        longitude: Double,
        altitude: Double? = nil,
        horizontalAccuracy: Double? = nil,
        verticalAccuracy: Double? = nil,
        timestamp: Date = Date(),
        name: String? = nil,
        address: String? = nil
    ) {
        self.latitude = latitude
        self.longitude = longitude
        self.altitude = altitude
        self.horizontalAccuracy = horizontalAccuracy
        self.verticalAccuracy = verticalAccuracy
        self.timestamp = timestamp
        self.name = name
        self.address = address
    }
    
    public init(from clLocation: CLLocation, name: String? = nil, address: String? = nil) {
        self.latitude = clLocation.coordinate.latitude
        self.longitude = clLocation.coordinate.longitude
        self.altitude = clLocation.altitude
        self.horizontalAccuracy = clLocation.horizontalAccuracy
        self.verticalAccuracy = clLocation.verticalAccuracy
        self.timestamp = clLocation.timestamp
        self.name = name
        self.address = address
    }
}

// Note: Core_LocationManaging is defined in UnifiedLocationManager.swift 