import Foundation
import SwiftUI
import XCTest
@testable import YeelightControl

final class MusicSyncUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
        
        // Navigate to Effects tab
        app.tabBars.buttons["Lights"].tap()
        let deviceCard = app.collectionViews.cells.firstMatch
        deviceCard.tap()
        
        let segmentedControl = app.segmentedControls.firstMatch
        segmentedControl.buttons["Effects"].tap()
    }
    
    func testMusicSyncControls() {
        // Switch to Music Mode
        let modePicker = app.segmentedControls["Effect Type"]
        XCTAssertTrue(modePicker.exists)
        modePicker.buttons["Music Mode"].tap()
        
        // Test enable/disable
        let enableToggle = app.switches["Enable Music Mode"]
        XCTAssertTrue(enableToggle.exists)
        enableToggle.tap()
        
        // Verify controls appear
        XCTAssertTrue(app.sliders["Sensitivity"].exists)
        XCTAssertTrue(app.segmentedControls["Color Style"].exists)
        
        // Test sensitivity adjustment
        let sensitivitySlider = app.sliders["Sensitivity"]
        sensitivitySlider.adjust(toNormalizedSliderPosition: 0.75)
        
        // Test color style selection
        let colorStylePicker = app.segmentedControls["Color Style"]
        colorStylePicker.buttons["Spectrum"].tap()
        colorStylePicker.buttons["Pulse"].tap()
        colorStylePicker.buttons["Custom"].tap()
    }
    
    func testMusicSyncVisualization() {
        // Enable Music Mode
        let modePicker = app.segmentedControls["Effect Type"]
        modePicker.buttons["Music Mode"].tap()
        
        let enableToggle = app.switches["Enable Music Mode"]
        enableToggle.tap()
        
        // Verify visualization appears
        XCTAssertTrue(app.otherElements["AudioVisualization"].waitForExistence(timeout: 3))
        
        // Test visualization updates
        let visualization = app.otherElements["AudioVisualization"]
        XCTAssertTrue(visualization.exists)
        
        // Wait for some updates
        let expectation = XCTestExpectation(description: "Visualization updates")
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 6)
    }
    
    func testMusicSyncPermissions() {
        // Enable Music Mode
        let modePicker = app.segmentedControls["Effect Type"]
        modePicker.buttons["Music Mode"].tap()
        
        let enableToggle = app.switches["Enable Music Mode"]
        enableToggle.tap()
        
        // Verify permissions alert appears
        let alert = app.alerts.firstMatch
        XCTAssertTrue(alert.waitForExistence(timeout: 3))
        XCTAssertTrue(alert.staticTexts["Microphone Access Required"].exists)
        
        // Accept permissions
        alert.buttons["Allow"].tap()
        
        // Verify sync starts
        XCTAssertTrue(app.otherElements["AudioVisualization"].waitForExistence(timeout: 3))
    }
    
    func testColorPaletteCustomization() {
        // Enable Music Mode
        let modePicker = app.segmentedControls["Effect Type"]
        modePicker.buttons["Music Mode"].tap()
        
        let enableToggle = app.switches["Enable Music Mode"]
        enableToggle.tap()
        
        // Switch to custom colors
        let colorStylePicker = app.segmentedControls["Color Style"]
        colorStylePicker.buttons["Custom"].tap()
        
        // Add custom color
        let addColorButton = app.buttons["Add Color"]
        XCTAssertTrue(addColorButton.exists)
        addColorButton.tap()
        
        // Verify color picker appears
        let colorPicker = app.colorWells.firstMatch
        XCTAssertTrue(colorPicker.exists)
        colorPicker.tap()
        
        // Select a color
        let redColor = app.buttons["Red color"]
        XCTAssertTrue(redColor.exists)
        redColor.tap()
        
        // Verify color is added
        XCTAssertTrue(app.buttons["Remove Color"].exists)
    }
    
    func testDeviceSelection() {
        // Enable Music Mode
        let modePicker = app.segmentedControls["Effect Type"]
        modePicker.buttons["Music Mode"].tap()
        
        // Open device selection
        let deviceButton = app.buttons["Select Devices"]
        XCTAssertTrue(deviceButton.exists)
        deviceButton.tap()
        
        // Select devices
        let deviceList = app.tables["DeviceList"]
        XCTAssertTrue(deviceList.exists)
        
        let firstDevice = deviceList.cells.firstMatch
        XCTAssertTrue(firstDevice.exists)
        firstDevice.tap()
        
        // Save selection
        app.buttons["Done"].tap()
        
        // Verify device is selected
        XCTAssertTrue(app.staticTexts.containing(NSPredicate(format: "label CONTAINS 'devices selected'")).firstMatch.exists)
    }
} 