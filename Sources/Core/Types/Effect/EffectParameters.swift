import Foundation

public struct EffectParameters: Codable, Hashable, Equatable {
    public var duration: Int // milliseconds
    public var brightness: [Int]
    public var colorTemperature: [Int]?
    public var colors: [[Int]]? // RGB arrays
    public var `repeat`: Bool
    
    public init(
        duration: Int,
        brightness: [Int],
        colorTemperature: [Int]? = nil,
        colors: [[Int]]? = nil,
        repeat: Bool
    ) {
        self.duration = duration
        self.brightness = brightness
        self.colorTemperature = colorTemperature
        self.colors = colors
        self.repeat = `repeat`
    }
} 