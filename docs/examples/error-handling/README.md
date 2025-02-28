# Error Handling Example

This example demonstrates comprehensive error handling strategies using the YeelightControl API.

## Features
- Error types
- Error recovery
- Retry strategies
- Logging
- Debugging

## Implementation

### Basic Error Handling
```swift
import YeelightControl

// Initialize managers
let deviceManager = try DeviceManager()
let errorHandler = ErrorHandler()

// Handle device errors
do {
    try await deviceManager.connect(to: deviceId)
} catch DeviceError.deviceNotFound {
    print("Device not found")
} catch DeviceError.connectionFailed(let reason) {
    print("Connection failed: \(reason)")
} catch DeviceError.timeout {
    print("Connection timed out")
} catch {
    print("Unknown error: \(error)")
}
```

### Retry Strategy
```swift
// Define retry policy
struct RetryPolicy {
    let maxAttempts: Int
    let delay: TimeInterval
    let backoff: Double
    
    static let `default` = RetryPolicy(
        maxAttempts: 3,
        delay: 1.0,
        backoff: 2.0
    )
}

// Implement retry logic
func withRetry<T>(
    policy: RetryPolicy = .default,
    operation: () async throws -> T
) async throws -> T {
    var attempts = 0
    var delay = policy.delay
    
    while true {
        do {
            return try await operation()
        } catch {
            attempts += 1
            guard attempts < policy.maxAttempts else {
                throw error
            }
            
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            delay *= policy.backoff
        }
    }
}

// Use retry logic
try await withRetry {
    try await deviceManager.connect(to: deviceId)
}
```

### Error Recovery
```swift
// Define recovery strategies
protocol ErrorRecoverable {
    func attemptRecovery(from error: Error) async throws
}

// Implement device recovery
struct DeviceRecovery: ErrorRecoverable {
    let deviceManager: DeviceManager
    
    func attemptRecovery(from error: Error) async throws {
        switch error {
        case DeviceError.connectionFailed:
            try await deviceManager.reconnect()
        case DeviceError.timeout:
            try await deviceManager.resetConnection()
        case DeviceError.deviceUnresponsive:
            try await deviceManager.restartDevice()
        default:
            throw error
        }
    }
}

// Use recovery
let recovery = DeviceRecovery(deviceManager: deviceManager)
do {
    try await deviceManager.connect(to: deviceId)
} catch {
    try await recovery.attemptRecovery(from: error)
}
```

### Error Logging
```swift
// Define log levels
enum LogLevel {
    case debug
    case info
    case warning
    case error
    case critical
}

// Implement logger
struct Logger {
    static let shared = Logger()
    
    func log(
        _ message: String,
        level: LogLevel,
        error: Error? = nil,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        let timestamp = ISO8601DateFormatter().string(from: Date())
        let location = "\(file):\(line) \(function)"
        let errorDetails = error.map { String(describing: $0) } ?? "none"
        
        print("[\(timestamp)] [\(level)] \(location) - \(message) - Error: \(errorDetails)")
    }
}

// Use logger
do {
    try await deviceManager.connect(to: deviceId)
} catch {
    Logger.shared.log(
        "Failed to connect to device",
        level: .error,
        error: error
    )
}
```

### Debugging Support
```swift
// Debug configuration
struct DebugConfig {
    var isEnabled: Bool
    var logLevel: LogLevel
    var includeStackTrace: Bool
    var networkLogging: Bool
}

// Debug helper
struct DebugHelper {
    static let shared = DebugHelper()
    let config: DebugConfig
    
    func dumpDeviceState(_ deviceId: String) async {
        do {
            let state = try await deviceManager.getState(for: deviceId)
            Logger.shared.log(
                "Device state: \(state)",
                level: .debug
            )
        } catch {
            Logger.shared.log(
                "Failed to get device state",
                level: .error,
                error: error
            )
        }
    }
    
    func monitorDevice(_ deviceId: String) {
        deviceManager.observeState(for: deviceId) { state in
            Logger.shared.log(
                "State changed: \(state)",
                level: .debug
            )
        }
    }
}
```

### Comprehensive Example
```swift
// Error handling coordinator
class ErrorCoordinator {
    let deviceManager: DeviceManager
    let recovery: DeviceRecovery
    let logger: Logger
    let debug: DebugHelper
    
    func performOperation() async throws {
        do {
            try await withRetry {
                try await deviceManager.connect(to: deviceId)
            }
        } catch {
            logger.log(
                "Operation failed",
                level: .error,
                error: error
            )
            
            try await recovery.attemptRecovery(from: error)
            await debug.dumpDeviceState(deviceId)
        }
    }
}
```

## Usage
1. Copy the example code
2. Add necessary imports
3. Initialize components
4. Implement error handling
5. Test error scenarios

## Notes
- Handle all error cases
- Implement proper logging
- Use appropriate retry policies
- Monitor error patterns
- Document error handling 