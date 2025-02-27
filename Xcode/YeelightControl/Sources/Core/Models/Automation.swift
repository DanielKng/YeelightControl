import Foundation
import CoreLocation

struct Automation: Identifiable, Codable {
    let id: UUID
    var name: String
    var isEnabled: Bool
    var trigger: Trigger
    var actions: [Action]
    var lastTriggered: Date?
    
    init(id: UUID = UUID(), name: String, isEnabled: Bool = true, trigger: Trigger, action: Action) {
        self.id = id
        self.name = name
        self.isEnabled = isEnabled
        self.trigger = trigger
        self.actions = [action]
    }
    
    enum Trigger: Codable {
        case time(Date)
        case location(Location)
        case sunset
        case sunrise
        
        private enum CodingKeys: String, CodingKey {
            case type, date, location
        }
        
        private enum TriggerType: String, Codable {
            case time, location, sunset, sunrise
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(TriggerType.self, forKey: .type)
            
            switch type {
            case .time:
                let date = try container.decode(Date.self, forKey: .date)
                self = .time(date)
            case .location:
                let location = try container.decode(Location.self, forKey: .location)
                self = .location(location)
            case .sunset:
                self = .sunset
            case .sunrise:
                self = .sunrise
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .time(let date):
                try container.encode(TriggerType.time, forKey: .type)
                try container.encode(date, forKey: .date)
            case .location(let location):
                try container.encode(TriggerType.location, forKey: .type)
                try container.encode(location, forKey: .location)
            case .sunset:
                try container.encode(TriggerType.sunset, forKey: .type)
            case .sunrise:
                try container.encode(TriggerType.sunrise, forKey: .type)
            }
        }
    }
    
    struct Location: Codable {
        let latitude: Double
        let longitude: Double
        let radius: Double
        let name: String
        
        init(coordinate: CLLocationCoordinate2D, radius: Double, name: String) {
            self.latitude = coordinate.latitude
            self.longitude = coordinate.longitude
            self.radius = radius
            self.name = name
        }
        
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        }
    }
    
    enum Action: Codable {
        case setPower(deviceIPs: [String], on: Bool)
        case setScene(deviceIPs: [String], scene: YeelightManager.Scene)
        case setBrightness(deviceIPs: [String], level: Int)
        case setGroup(groupID: UUID, scene: YeelightManager.Scene)
        
        private enum CodingKeys: String, CodingKey {
            case type, deviceIPs, on, scene, level, groupID
        }
        
        private enum ActionType: String, Codable {
            case power, scene, brightness, group
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(ActionType.self, forKey: .type)
            
            switch type {
            case .power:
                let deviceIPs = try container.decode([String].self, forKey: .deviceIPs)
                let on = try container.decode(Bool.self, forKey: .on)
                self = .setPower(deviceIPs: deviceIPs, on: on)
            case .scene:
                let deviceIPs = try container.decode([String].self, forKey: .deviceIPs)
                let scene = try container.decode(YeelightManager.Scene.self, forKey: .scene)
                self = .setScene(deviceIPs: deviceIPs, scene: scene)
            case .brightness:
                let deviceIPs = try container.decode([String].self, forKey: .deviceIPs)
                let level = try container.decode(Int.self, forKey: .level)
                self = .setBrightness(deviceIPs: deviceIPs, level: level)
            case .group:
                let groupID = try container.decode(UUID.self, forKey: .groupID)
                let scene = try container.decode(YeelightManager.Scene.self, forKey: .scene)
                self = .setGroup(groupID: groupID, scene: scene)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .setPower(let deviceIPs, let on):
                try container.encode(ActionType.power, forKey: .type)
                try container.encode(deviceIPs, forKey: .deviceIPs)
                try container.encode(on, forKey: .on)
            case .setScene(let deviceIPs, let scene):
                try container.encode(ActionType.scene, forKey: .type)
                try container.encode(deviceIPs, forKey: .deviceIPs)
                try container.encode(scene, forKey: .scene)
            case .setBrightness(let deviceIPs, let level):
                try container.encode(ActionType.brightness, forKey: .type)
                try container.encode(deviceIPs, forKey: .deviceIPs)
                try container.encode(level, forKey: .level)
            case .setGroup(let groupID, let scene):
                try container.encode(ActionType.group, forKey: .type)
                try container.encode(groupID, forKey: .groupID)
                try container.encode(scene, forKey: .scene)
            }
        }
    }
} 