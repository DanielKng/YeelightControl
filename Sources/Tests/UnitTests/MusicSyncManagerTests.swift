import XCTest
import AVFoundation
@testable import YeelightControl

final class MusicSyncManagerTests: XCTestCase {
    var syncManager: MusicSyncManager!
    
    override func setUp() {
        super.setUp()
        syncManager = MusicSyncManager.shared
    }
    
    override func tearDown() {
        syncManager.stop()
        super.tearDown()
    }
    
    func testStartStop() {
        // Given
        XCTAssertFalse(syncManager.isRunning)
        
        // When
        syncManager.start()
        
        // Then
        XCTAssertTrue(syncManager.isRunning)
        
        // When
        syncManager.stop()
        
        // Then
        XCTAssertFalse(syncManager.isRunning)
    }
    
    func testAmplitudeMode() {
        // Given
        let expectation = XCTestExpectation(description: "Amplitude updates")
        var amplitudeUpdates = 0
        
        // When
        syncManager.start(mode: .amplitude)
        
        let cancellable = syncManager.$currentAmplitude
            .sink { amplitude in
                if amplitude > 0 {
                    amplitudeUpdates += 1
                    if amplitudeUpdates >= 5 {
                        expectation.fulfill()
                    }
                }
            }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(amplitudeUpdates, 0)
        cancellable.cancel()
    }
    
    func testFrequencyMode() {
        // Given
        let expectation = XCTestExpectation(description: "Frequency updates")
        var frequencyUpdates = 0
        
        // When
        syncManager.start(mode: .frequency)
        
        let cancellable = syncManager.$dominantFrequency
            .sink { frequency in
                if frequency > 0 {
                    frequencyUpdates += 1
                    if frequencyUpdates >= 5 {
                        expectation.fulfill()
                    }
                }
            }
        
        // Then
        wait(for: [expectation], timeout: 5.0)
        XCTAssertGreaterThan(frequencyUpdates, 0)
        cancellable.cancel()
    }
    
    func testBeatMode() {
        // Given
        let expectation = XCTestExpectation(description: "Beat detection")
        var beatDetections = 0
        
        // When
        syncManager.start(mode: .beat)
        
        let cancellable = syncManager.$beatDetected
            .sink { detected in
                if detected {
                    beatDetections += 1
                    if beatDetections >= 3 {
                        expectation.fulfill()
                    }
                }
            }
        
        // Then
        wait(for: [expectation], timeout: 10.0)
        XCTAssertGreaterThan(beatDetections, 0)
        cancellable.cancel()
    }
    
    func testSensitivityControl() {
        // Given
        let expectation = XCTestExpectation(description: "Sensitivity control")
        var amplitudes: [Float] = []
        
        // When - High sensitivity
        syncManager.start(mode: .amplitude, sensitivity: 1.0)
        
        let highSensitivityCancellable = syncManager.$currentAmplitude
            .sink { amplitude in
                amplitudes.append(amplitude)
                if amplitudes.count >= 10 {
                    expectation.fulfill()
                }
            }
        
        wait(for: [expectation], timeout: 5.0)
        let highSensitivityAverage = amplitudes.reduce(0, +) / Float(amplitudes.count)
        
        // Reset
        amplitudes = []
        let lowSensitivityExpectation = XCTestExpectation(description: "Low sensitivity")
        
        // When - Low sensitivity
        syncManager.start(mode: .amplitude, sensitivity: 0.2)
        
        let lowSensitivityCancellable = syncManager.$currentAmplitude
            .sink { amplitude in
                amplitudes.append(amplitude)
                if amplitudes.count >= 10 {
                    lowSensitivityExpectation.fulfill()
                }
            }
        
        wait(for: [lowSensitivityExpectation], timeout: 5.0)
        let lowSensitivityAverage = amplitudes.reduce(0, +) / Float(amplitudes.count)
        
        // Then
        XCTAssertGreaterThan(highSensitivityAverage, lowSensitivityAverage)
        
        highSensitivityCancellable.cancel()
        lowSensitivityCancellable.cancel()
    }
    
    func testCustomColorPalette() {
        // Given
        let colors: [Color] = [.red, .blue, .green]
        let expectation = XCTestExpectation(description: "Color updates")
        
        // When
        syncManager.start(mode: .amplitude, colors: colors)
        
        // Then
        // Note: We can't directly test the color output as it depends on audio input
        // Instead, we verify the setup completes without errors
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: 3.0)
        XCTAssertTrue(syncManager.isRunning)
    }
} 