import Foundation
import SwiftUI

extension YeelightManager {
    enum Scene: Codable {
        case color(red: Int, green: Int, blue: Int, brightness: Int)
        case colorTemperature(temperature: Int, brightness: Int)
        case colorFlow(params: YeelightDevice.FlowParams)
        case multiLight(MultiLightScene)
        case stripEffect(StripEffect)
        
        private enum CodingKeys: String, CodingKey {
            case type, red, green, blue, brightness, temperature, params, multiScene, stripEffect
        }
        
        private enum SceneType: String, Codable {
            case color, temperature, flow, multiLight, stripEffect
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let type = try container.decode(SceneType.self, forKey: .type)
            
            switch type {
            case .color:
                let red = try container.decode(Int.self, forKey: .red)
                let green = try container.decode(Int.self, forKey: .green)
                let blue = try container.decode(Int.self, forKey: .blue)
                let brightness = try container.decode(Int.self, forKey: .brightness)
                self = .color(red: red, green: green, blue: blue, brightness: brightness)
                
            case .temperature:
                let temperature = try container.decode(Int.self, forKey: .temperature)
                let brightness = try container.decode(Int.self, forKey: .brightness)
                self = .colorTemperature(temperature: temperature, brightness: brightness)
                
            case .flow:
                let params = try container.decode(YeelightDevice.FlowParams.self, forKey: .params)
                self = .colorFlow(params: params)
                
            case .multiLight:
                let multiScene = try container.decode(MultiLightScene.self, forKey: .multiScene)
                self = .multiLight(multiScene)
                
            case .stripEffect:
                let effect = try container.decode(StripEffect.self, forKey: .stripEffect)
                self = .stripEffect(effect)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            switch self {
            case .color(let red, let green, let blue, let brightness):
                try container.encode(SceneType.color, forKey: .type)
                try container.encode(red, forKey: .red)
                try container.encode(green, forKey: .green)
                try container.encode(blue, forKey: .blue)
                try container.encode(brightness, forKey: .brightness)
                
            case .colorTemperature(let temperature, let brightness):
                try container.encode(SceneType.temperature, forKey: .type)
                try container.encode(temperature, forKey: .temperature)
                try container.encode(brightness, forKey: .brightness)
                
            case .colorFlow(let params):
                try container.encode(SceneType.flow, forKey: .type)
                try container.encode(params, forKey: .params)
                
            case .multiLight(let multiScene):
                try container.encode(SceneType.multiLight, forKey: .type)
                try container.encode(multiScene, forKey: .multiScene)
                
            case .stripEffect(let effect):
                try container.encode(SceneType.stripEffect, forKey: .type)
                try container.encode(effect, forKey: .stripEffect)
            }
        }
        
        var previewColor: Color {
            switch self {
            case .color(let red, let green, let blue, _):
                return Color(red: Double(red)/255, green: Double(green)/255, blue: Double(blue)/255)
            case .colorTemperature(let temp, _):
                return temp > 4000 ? .blue : .orange
            case .colorFlow:
                return .purple
            case .multiLight:
                return .green
            case .stripEffect:
                return .blue
            }
        }
        
        var icon: String {
            switch self {
            case .color:
                return "paintpalette"
            case .colorTemperature:
                return "sun.max"
            case .colorFlow:
                return "waveform"
            case .multiLight:
                return "lightbulb.2"
            case .stripEffect:
                return "light.strip"
            }
        }
    }
    
    enum MultiLightScene: String, Codable {
        case hollywood = "Hollywood"
        case dualTone = "Dual Tone"
        case rainbow = "Rainbow"
        case nightClub = "Night Club"
        case fireplace = "Fireplace"
    }
    
    enum StripEffect: String, Codable {
        case colorWave = "Color Wave"
        case rainbowWave = "Rainbow Wave"
        case chaseLights = "Chase Lights"
        case matrix = "Matrix"
        case fire = "Fire"
    }
} 