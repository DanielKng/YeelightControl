import Foundation

public enum EffectUpdate: Codable, Hashable, Equatable {
    case created(Effect)
    case updated(Effect)
    case deleted(String)
    case started(Effect)
    case stopped(Effect)
    case allStopped
    
    private enum CodingKeys: String, CodingKey {
        case type
        case effect
        case effectId
    }
    
    private enum UpdateType: String, Codable {
        case created
        case updated
        case deleted
        case started
        case stopped
        case allStopped
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(UpdateType.self, forKey: .type)
        
        switch type {
        case .created:
            let effect = try container.decode(Effect.self, forKey: .effect)
            self = .created(effect)
        case .updated:
            let effect = try container.decode(Effect.self, forKey: .effect)
            self = .updated(effect)
        case .deleted:
            let effectId = try container.decode(String.self, forKey: .effectId)
            self = .deleted(effectId)
        case .started:
            let effect = try container.decode(Effect.self, forKey: .effect)
            self = .started(effect)
        case .stopped:
            let effect = try container.decode(Effect.self, forKey: .effect)
            self = .stopped(effect)
        case .allStopped:
            self = .allStopped
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        
        switch self {
        case .created(let effect):
            try container.encode(UpdateType.created, forKey: .type)
            try container.encode(effect, forKey: .effect)
        case .updated(let effect):
            try container.encode(UpdateType.updated, forKey: .type)
            try container.encode(effect, forKey: .effect)
        case .deleted(let effectId):
            try container.encode(UpdateType.deleted, forKey: .type)
            try container.encode(effectId, forKey: .effectId)
        case .started(let effect):
            try container.encode(UpdateType.started, forKey: .type)
            try container.encode(effect, forKey: .effect)
        case .stopped(let effect):
            try container.encode(UpdateType.stopped, forKey: .type)
            try container.encode(effect, forKey: .effect)
        case .allStopped:
            try container.encode(UpdateType.allStopped, forKey: .type)
        }
    }
} 