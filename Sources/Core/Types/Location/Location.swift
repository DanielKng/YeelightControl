import CoreLocation
import Foundation

// Already defined elsewhere - commenting out to avoid redeclaration
/*
// Commented out to avoid ambiguity
// // Commented out to avoid ambiguity
// public struct Location: Codable, Hashable {
    public var name: String
    public var coordinates: CLLocationCoordinate2D
    public var radius: CLLocationDistance
    public var address: String?

    public init(name: String,
                coordinates: CLLocationCoordinate2D,
                radius: CLLocationDistance = 50,
                address: String? = nil) {
        self.name = name
        self.coordinates = coordinates
        self.radius = radius
        self.address = address
    }
}
*/

public struct LocationCoordinate: Hashable, Codable {
    public let latitude: CLLocationDegrees
    public let longitude: CLLocationDegrees

    public init(latitude: CLLocationDegrees, longitude: CLLocationDegrees) {
        self.latitude = latitude
        self.longitude = longitude
    }

    public init(_ coordinate: CLLocationCoordinate2D) {
        self.latitude = coordinate.latitude
        self.longitude = coordinate.longitude
    }

    public var clCoordinate: CLLocationCoordinate2D {
        CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}

extension CLLocationCoordinate2D: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let latitude = try container.decode(CLLocationDegrees.self, forKey: .latitude)
        let longitude = try container.decode(CLLocationDegrees.self, forKey: .longitude)
        self.init(latitude: latitude, longitude: longitude)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(latitude, forKey: .latitude)
        try container.encode(longitude, forKey: .longitude)
    }

    private enum CodingKeys: String, CodingKey {
        case latitude
        case longitude
    }
}

extension CLLocationCoordinate2D: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(latitude)
        hasher.combine(longitude)
    }

    public static func == (lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
        return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
    }
} 