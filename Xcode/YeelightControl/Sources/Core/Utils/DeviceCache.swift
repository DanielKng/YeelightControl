import Foundation

class DeviceCache {
    static let shared = DeviceCache()
    private let cache = NSCache<NSString, CachedDevice>()
    private let fileManager = FileManager.default
    private let cacheDirectory: URL
    private let logger = Logger.shared
    
    private init() {
        cache.countLimit = 100 // Maximum number of devices to cache
        
        // Set up cache directory
        let directory = fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first!
            .appendingPathComponent("DeviceCache", isDirectory: true)
        
        if !fileManager.fileExists(atPath: directory.path) {
            try? fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
        }
        
        self.cacheDirectory = directory
        
        // Clean old cache files on init
        cleanOldCacheFiles()
    }
    
    // MARK: - Cache Management
    
    func cacheDevice(_ device: YeelightDevice) {
        let cachedDevice = CachedDevice(
            ip: device.ip,
            port: device.port,
            name: device.name,
            state: DeviceState(
                isOn: device.isOn,
                brightness: device.brightness,
                colorTemperature: device.colorTemperature,
                colorMode: device.colorMode.rawValue,
                powerMode: device.powerMode.rawValue
            ),
            timestamp: Date()
        )
        
        // Cache in memory
        cache.setObject(cachedDevice, forKey: device.ip as NSString)
        
        // Cache to disk
        saveToDisk(cachedDevice)
    }
    
    func getCachedDevice(ip: String) -> YeelightDevice? {
        // Try memory cache first
        if let cached = cache.object(forKey: ip as NSString) {
            return createDevice(from: cached)
        }
        
        // Try disk cache
        return loadFromDisk(ip: ip).map(createDevice)
    }
    
    func clearCache() {
        // Clear memory cache
        cache.removeAllObjects()
        
        // Clear disk cache
        try? fileManager.removeItem(at: cacheDirectory)
        try? fileManager.createDirectory(at: cacheDirectory, withIntermediateDirectories: true)
    }
    
    // MARK: - Private Methods
    
    private func saveToDisk(_ device: CachedDevice) {
        let fileURL = cacheDirectory.appendingPathComponent("\(device.ip).cache")
        
        do {
            let data = try JSONEncoder().encode(device)
            try data.write(to: fileURL)
        } catch {
            logger.log("Failed to save device cache: \(error)", level: .error, category: .device)
        }
    }
    
    private func loadFromDisk(ip: String) -> CachedDevice? {
        let fileURL = cacheDirectory.appendingPathComponent("\(ip).cache")
        
        guard let data = try? Data(contentsOf: fileURL),
              let device = try? JSONDecoder().decode(CachedDevice.self, from: data)
        else {
            return nil
        }
        
        // Update memory cache
        cache.setObject(device, forKey: ip as NSString)
        return device
    }
    
    private func cleanOldCacheFiles() {
        let maxAge: TimeInterval = 7 * 24 * 60 * 60 // 7 days
        
        guard let files = try? fileManager.contentsOfDirectory(
            at: cacheDirectory,
            includingPropertiesForKeys: [.contentModificationDateKey]
        ) else { return }
        
        let oldFiles = files.filter { file in
            guard let attributes = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
                  let modificationDate = attributes.contentModificationDate
            else { return false }
            
            return Date().timeIntervalSince(modificationDate) > maxAge
        }
        
        for file in oldFiles {
            try? fileManager.removeItem(at: file)
        }
    }
    
    private func createDevice(from cached: CachedDevice) -> YeelightDevice {
        let device = YeelightDevice(ip: cached.ip, port: cached.port)
        device.name = cached.name
        device.isOn = cached.state.isOn
        device.brightness = cached.state.brightness
        device.colorTemperature = cached.state.colorTemperature
        device.colorMode = ColorMode(rawValue: cached.state.colorMode) ?? .temperature
        device.powerMode = PowerMode(rawValue: cached.state.powerMode) ?? .normal
        return device
    }
}

// MARK: - Models

private struct CachedDevice: Codable {
    let ip: String
    let port: Int
    let name: String
    let state: DeviceState
    let timestamp: Date
}

private struct DeviceState: Codable {
    let isOn: Bool
    let brightness: Int
    let colorTemperature: Int
    let colorMode: Int
    let powerMode: Int
} 