import Foundation

extension YeelightDevice.FlowParams {
    static var partyMode: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 1000, mode: 1, value: 0xFF0000, brightness: 100), // Red
                .init(duration: 1000, mode: 1, value: 0x00FF00, brightness: 100), // Green
                .init(duration: 1000, mode: 1, value: 0x0000FF, brightness: 100)  // Blue
            ]
        )
    }
    
    static var candlelight: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 800, mode: 2, value: 2700, brightness: 50),
                .init(duration: 800, mode: 2, value: 2400, brightness: 30),
                .init(duration: 1200, mode: 2, value: 2700, brightness: 45),
                .init(duration: 800, mode: 2, value: 2400, brightness: 35)
            ]
        )
    }
    
    static var sunset: Self {
        .init(
            count: 1, // Run once
            action: .stay,
            transitions: [
                .init(duration: 3000, mode: 2, value: 4000, brightness: 80),
                .init(duration: 3000, mode: 2, value: 3000, brightness: 50),
                .init(duration: 3000, mode: 2, value: 2700, brightness: 30),
                .init(duration: 3000, mode: 2, value: 2400, brightness: 15)
            ]
        )
    }
    
    static var pulse: Self {
        .init(
            count: 0,
            action: .recover,
            transitions: [
                .init(duration: 1000, mode: 1, value: 0x800080, brightness: 100), // Purple
                .init(duration: 1000, mode: 1, value: 0x400040, brightness: 50)   // Dim purple
            ]
        )
    }
} 