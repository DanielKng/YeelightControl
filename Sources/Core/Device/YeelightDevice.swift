import Foundation
import Combine

class YeelightDevice: Identifiable, ObservableObject {
    let id = UUID()
    let ip: String
    let port: Int
    
    // Basic properties
    @Published var isOn: Bool = false
    @Published var brightness: Int = 100 // 1-100
    @Published var colorTemperature: Int = 4000 // 1700-6500K
    @Published var colorMode: ColorMode = .temperature
    @Published var connectionState: ConnectionState = .disconnected
    @Published var name: String = "Yeelight"
    
    // Advanced properties
    @Published var rgb: RGB = RGB(red: 255, green: 255, blue: 255)
    @Published var hue: Int = 0 // 0-359
    @Published var saturation: Int = 0 // 0-100
    @Published var flowing: Bool = false
    @Published var flowParams: FlowParams = FlowParams()
    @Published var powerMode: PowerMode = .normal
    @Published var musicMode: Bool = false
    
    private var cancellables = Set<AnyCancellable>()
    
    enum ConnectionState: Equatable {
        case connected
        case disconnected
        case connecting
        case error(String)
        
        static func == (lhs: ConnectionState, rhs: ConnectionState) -> Bool {
            switch (lhs, rhs) {
            case (.connected, .connected),
                 (.disconnected, .disconnected),
                 (.connecting, .connecting):
                return true
            case (.error(let lhsError), .error(let rhsError)):
                return lhsError == rhsError
            default:
                return false
            }
        }
    }
    
    enum ColorMode: Int {
        case rgb = 1
        case temperature = 2
        case hsv = 3
    }
    
    enum PowerMode: Int {
        case normal = 0
        case ct = 1
        case rgb = 2
        case hsv = 3
        case colorFlow = 4
        case nightLight = 5
    }
    
    struct RGB {
        var red: Int // 0-255
        var green: Int // 0-255
        var blue: Int // 0-255
        
        var rgbValue: Int {
            return (red * 65536) + (green * 256) + blue
        }
        
        static func from(rgb: Int) -> RGB {
            let red = (rgb >> 16) & 0xFF
            let green = (rgb >> 8) & 0xFF
            let blue = rgb & 0xFF
            return RGB(red: red, green: green, blue: blue)
        }
    }
    
    struct FlowParams {
        var count: Int = 0 // 0 for infinite
        var action: FlowAction = .recover
        var transitions: [FlowTransition] = []
        
        enum FlowAction: Int {
            case recover = 0
            case stay = 1
            case turnOff = 2
        }
        
        struct FlowTransition {
            var duration: Int // milliseconds
            var mode: Int // 1: color, 2: temperature, 7: sleep
            var value: Int
            var brightness: Int
        }
    }
    
    init(ip: String, port: Int) {
        self.ip = ip
        self.port = port
        
        // Monitor state changes for sync
        setupStateMonitoring()
    }
    
    private func setupStateMonitoring() {
        Publishers.MergeMany(
            $isOn.dropFirst(),
            $brightness.dropFirst(),
            $colorTemperature.dropFirst(),
            $rgb.dropFirst(),
            $hue.dropFirst(),
            $saturation.dropFirst()
        )
        .debounce(for: .milliseconds(100), scheduler: DispatchQueue.main)
        .sink { [weak self] _ in
            self?.updateState()
        }
        .store(in: &cancellables)
    }
    
    private func updateState() {
        // Implement state synchronization
    }
}

// MARK: - Property Validation
extension YeelightDevice {
    func validateBrightness(_ value: Int) -> Int {
        min(max(value, 1), 100)
    }
    
    func validateColorTemp(_ value: Int) -> Int {
        min(max(value, 1700), 6500)
    }
    
    func validateHue(_ value: Int) -> Int {
        value % 360
    }
    
    func validateSaturation(_ value: Int) -> Int {
        min(max(value, 0), 100)
    }
}

extension YeelightDevice.FlowParams {
    static var candlelight: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 2000, mode: 2, value: 2700, brightness: 50),
                .init(duration: 1000, mode: 2, value: 2400, brightness: 30),
                .init(duration: 1000, mode: 2, value: 2700, brightness: 40)
            ]
        )
    }
    
    static var sunset: Self {
        .init(
            count: 1, // Run once
            action: .stay,
            transitions: [
                .init(duration: 3000, mode: 1, value: 0xFF6600, brightness: 100), // Bright orange
                .init(duration: 3000, mode: 1, value: 0xFF2200, brightness: 60),  // Deep orange
                .init(duration: 4000, mode: 1, value: 0x220066, brightness: 20)   // Dark purple
            ]
        )
    }
    
    static var pulse: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 1000, mode: 1, value: 0x800080, brightness: 100), // Bright purple
                .init(duration: 1000, mode: 1, value: 0x400040, brightness: 30),  // Dim purple
            ]
        )
    }
    
    static var partyMode: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 1000, mode: 1, value: 0xFF0000, brightness: 100), // Red
                .init(duration: 1000, mode: 1, value: 0x00FF00, brightness: 100), // Green
                .init(duration: 1000, mode: 1, value: 0x0000FF, brightness: 100), // Blue
                .init(duration: 1000, mode: 1, value: 0xFF00FF, brightness: 100), // Purple
                .init(duration: 1000, mode: 1, value: 0xFFFF00, brightness: 100)  // Yellow
            ]
        )
    }
    
    static var oceanWave: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 3000, mode: 1, value: 0x0077BE, brightness: 80), // Deep blue
                .init(duration: 3000, mode: 1, value: 0x40E0D0, brightness: 70), // Turquoise
                .init(duration: 3000, mode: 1, value: 0x0077BE, brightness: 60)  // Deep blue
            ]
        )
    }
    
    static var aurora: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 4000, mode: 1, value: 0x00FF87, brightness: 50), // Green
                .init(duration: 4000, mode: 1, value: 0x8A2BE2, brightness: 40), // Purple
                .init(duration: 4000, mode: 1, value: 0x00FFFF, brightness: 45)  // Cyan
            ]
        )
    }
    
    static var thunderstorm: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 100, mode: 1, value: 0xFFFFFF, brightness: 100),  // Flash
                .init(duration: 200, mode: 1, value: 0x191970, brightness: 20),   // Dark
                .init(duration: 50, mode: 1, value: 0xFFFFFF, brightness: 90),    // Flash
                .init(duration: 3000, mode: 1, value: 0x191970, brightness: 15)   // Dark
            ]
        )
    }
    
    static var christmasLights: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 1000, mode: 1, value: 0xFF0000, brightness: 80), // Red
                .init(duration: 1000, mode: 1, value: 0x00FF00, brightness: 80), // Green
                .init(duration: 1000, mode: 1, value: 0xFFD700, brightness: 80)  // Gold
            ]
        )
    }
    
    // LED Strip-style effects
    static func colorWave(position: Int, totalLights: Int) -> Self {
        let phase = (Double(position) / Double(totalLights)) * 2 * .pi
        let duration = 2000 // Base duration for one cycle
        let phaseDuration = Int(Double(duration) * (Double(position) / Double(totalLights)))
        
        return .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: duration + phaseDuration, mode: 1, value: 0xFF0000, brightness: 80), // Red
                .init(duration: duration + phaseDuration, mode: 1, value: 0x00FF00, brightness: 80), // Green
                .init(duration: duration + phaseDuration, mode: 1, value: 0x0000FF, brightness: 80)  // Blue
            ]
        )
    }
    
    static func rainbowWave(position: Int, totalLights: Int) -> Self {
        let baseHue = (360 / totalLights) * position
        return .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 0, mode: 3, value: baseHue, brightness: 80),
                .init(duration: 1000, mode: 3, value: (baseHue + 120) % 360, brightness: 80),
                .init(duration: 1000, mode: 3, value: (baseHue + 240) % 360, brightness: 80)
            ]
        )
    }
} 