import Foundation
import AVFoundation
import Accelerate

class MusicSyncManager: NSObject, ObservableObject {
    static let shared = MusicSyncManager()
    
    @Published private(set) var isRunning = false
    @Published private(set) var currentAmplitude: Float = 0
    @Published private(set) var dominantFrequency: Float = 0
    @Published private(set) var beatDetected = false
    
    private let audioEngine = AVAudioEngine()
    private let inputNode: AVAudioInputNode
    private let mixer = AVAudioMixerNode()
    private var displayLink: CADisplayLink?
    private var lastUpdateTime = CFAbsoluteTimeGetCurrent()
    private let updateInterval: CFTimeInterval = 1.0 / 30.0 // 30 fps
    
    private var fftSetup: vDSP_DFT_Setup?
    private let fftSize = 1024
    private var hannWindow: [Float] = []
    
    private var deviceManager: YeelightManager?
    private var syncMode: SyncMode = .amplitude
    private var colorPalette: [Color] = [.red, .green, .blue]
    private var sensitivity: Float = 0.5
    
    enum SyncMode {
        case amplitude
        case frequency
        case beat
    }
    
    override init() {
        inputNode = audioEngine.inputNode
        super.init()
        setupAudio()
        setupFFT()
    }
    
    private func setupAudio() {
        let format = inputNode.inputFormat(forBus: 0)
        
        // Configure audio format for processing
        let processingFormat = AVAudioFormat(
            standardFormatWithSampleRate: format.sampleRate,
            channels: 1
        )
        
        // Add mixer node
        audioEngine.attach(mixer)
        audioEngine.connect(inputNode, to: mixer, format: format)
        
        // Install tap on mixer node
        mixer.installTap(onBus: 0, bufferSize: UInt32(fftSize), format: processingFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
        }
    }
    
    private func setupFFT() {
        fftSetup = vDSP_DFT_zop_CreateSetup(
            nil,
            UInt(fftSize),
            vDSP_DFT_Direction.FORWARD
        )
        
        // Create Hann window for better frequency analysis
        hannWindow = [Float](repeating: 0, count: fftSize)
        vDSP_hann_window(&hannWindow, UInt(fftSize), Int32(vDSP_HANN_NORM))
    }
    
    func start(mode: SyncMode = .amplitude, colors: [Color] = [.red, .green, .blue], sensitivity: Float = 0.5) {
        guard !isRunning else { return }
        
        do {
            try AVAudioSession.sharedInstance().setCategory(.playAndRecord)
            try AVAudioSession.sharedInstance().setActive(true)
            try audioEngine.start()
            
            syncMode = mode
            colorPalette = colors
            self.sensitivity = sensitivity
            deviceManager = YeelightManager.shared
            isRunning = true
            
            // Start display link for UI updates
            displayLink = CADisplayLink(target: self, selector: #selector(displayLinkCallback))
            displayLink?.add(to: .main, forMode: .common)
            
        } catch {
            print("Failed to start audio engine: \(error)")
        }
    }
    
    func stop() {
        audioEngine.stop()
        displayLink?.invalidate()
        displayLink = nil
        isRunning = false
        currentAmplitude = 0
        dominantFrequency = 0
        beatDetected = false
    }
    
    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        
        // Calculate amplitude with sensitivity
        var rms: Float = 0
        vDSP_rmsqv(channelData, 1, &rms, UInt(frameCount))
        currentAmplitude = rms * sensitivity * 2 // Multiply by 2 to compensate for sensitivity reduction
        
        // Apply window function
        var windowedData = [Float](repeating: 0, count: fftSize)
        vDSP_vmul(channelData, 1, hannWindow, 1, &windowedData, 1, UInt(fftSize))
        
        // Perform FFT
        var realPart = [Float](repeating: 0, count: fftSize/2)
        var imagPart = [Float](repeating: 0, count: fftSize/2)
        
        windowedData.withUnsafeMutableBufferPointer { windowedPtr in
            realPart.withUnsafeMutableBufferPointer { realPtr in
                imagPart.withUnsafeMutableBufferPointer { imagPtr in
                    vDSP_DFT_Execute(
                        fftSetup!,
                        windowedPtr.baseAddress!,
                        realPtr.baseAddress!,
                        imagPtr.baseAddress!
                    )
                }
            }
        }
        
        // Calculate magnitude spectrum
        var magnitudes = [Float](repeating: 0, count: fftSize/2)
        vDSP_zvmags(&realPart, 1, &magnitudes, 1, UInt(fftSize/2))
        
        // Find dominant frequency
        var maxMagnitude: Float = 0
        var maxIndex: vDSP_Length = 0
        vDSP_maxvi(magnitudes, 1, &maxMagnitude, &maxIndex, UInt(fftSize/2))
        
        let sampleRate = Float(buffer.format.sampleRate)
        dominantFrequency = Float(maxIndex) * sampleRate / Float(fftSize)
        
        // Beat detection with sensitivity
        let beatThreshold = 0.1 * (1.0 / sensitivity)
        beatDetected = currentAmplitude > beatThreshold
    }
    
    @objc private func displayLinkCallback() {
        let currentTime = CFAbsoluteTimeGetCurrent()
        guard currentTime - lastUpdateTime >= updateInterval else { return }
        lastUpdateTime = currentTime
        
        updateLights()
    }
    
    private func updateLights() {
        guard let deviceManager = deviceManager else { return }
        
        switch syncMode {
        case .amplitude:
            updateLightsWithAmplitude(deviceManager)
        case .frequency:
            updateLightsWithFrequency(deviceManager)
        case .beat:
            updateLightsWithBeat(deviceManager)
        }
    }
    
    private func updateLightsWithAmplitude(_ manager: YeelightManager) {
        let brightness = Int(currentAmplitude * 100)
        let colorIndex = Int(currentAmplitude * Float(colorPalette.count)) % colorPalette.count
        let color = colorPalette[colorIndex]
        
        for device in manager.devices {
            let components = color.components
            manager.setRGB(
                device,
                red: components.red,
                green: components.green,
                blue: components.blue
            )
            manager.setBrightness(device, brightness: max(1, min(100, brightness)))
        }
    }
    
    private func updateLightsWithFrequency(_ manager: YeelightManager) {
        // Map frequency ranges to colors
        let hue = (dominantFrequency.truncatingRemainder(dividingBy: 1000)) / 1000 * 360
        
        for device in manager.devices {
            manager.setHSV(device, hue: Int(hue), saturation: 100)
        }
    }
    
    private func updateLightsWithBeat(_ manager: YeelightManager) {
        if beatDetected {
            let colorIndex = Int.random(in: 0..<colorPalette.count)
            let color = colorPalette[colorIndex]
            let components = color.components
            
            for device in manager.devices {
                manager.setRGB(
                    device,
                    red: components.red,
                    green: components.green,
                    blue: components.blue
                )
            }
        }
    }
    
    deinit {
        stop()
        fftSetup = nil
    }
} 