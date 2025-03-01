import SwiftUI
import XCTest
@testable import YeelightControl

final class MainViewUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
    }
    
    func testTabNavigation() {
        // Test Lights tab
        app.tabBars.buttons["Lights"].tap()
        XCTAssertTrue(app.navigationBars["My Lights"].exists)
        
        // Test Scenes tab
        app.tabBars.buttons["Scenes"].tap()
        XCTAssertTrue(app.navigationBars["Scenes"].exists)
        
        // Test Automation tab
        app.tabBars.buttons["Automation"].tap()
        XCTAssertTrue(app.navigationBars["Automation"].exists)
    }
    
    func testDeviceDiscovery() {
        // Start discovery
        app.tabBars.buttons["Lights"].tap()
        app.buttons["Discover Devices"].tap()
        
        // Verify discovery progress indicator
        XCTAssertTrue(app.progressIndicators["Discovering devices..."].exists)
        
        // Wait for discovery to complete
        let deviceList = app.collectionViews.firstMatch
        XCTAssertTrue(deviceList.waitForExistence(timeout: 10))
    }
    
    func testRoomFiltering() {
        app.tabBars.buttons["Lights"].tap()
        
        // Test room selection
        let roomsScrollView = app.scrollViews["RoomSelector"]
        XCTAssertTrue(roomsScrollView.exists)
        
        // Tap "Living Room"
        let livingRoomButton = roomsScrollView.buttons["Living Room"]
        livingRoomButton.tap()
        
        // Verify filtered devices
        let deviceList = app.collectionViews.firstMatch
        XCTAssertTrue(deviceList.waitForExistence(timeout: 5))
    }
    
    func testDeviceControls() {
        app.tabBars.buttons["Lights"].tap()
        
        // Find first device card
        let deviceCard = app.collectionViews.cells.firstMatch
        guard deviceCard.waitForExistence(timeout: 5) else {
            XCTFail("No devices found")
            return
        }
        
        // Test power toggle
        let powerToggle = deviceCard.switches.firstMatch
        powerToggle.tap()
        
        // Test brightness slider
        let brightnessSlider = deviceCard.sliders.firstMatch
        brightnessSlider.adjust(toNormalizedSliderPosition: 0.75)
    }
    
    func testDeviceDetails() {
        app.tabBars.buttons["Lights"].tap()
        
        // Open device details
        let deviceCard = app.collectionViews.cells.firstMatch
        guard deviceCard.waitForExistence(timeout: 5) else {
            XCTFail("No devices found")
            return
        }
        
        deviceCard.tap()
        
        // Verify device details view
        XCTAssertTrue(app.navigationBars.element.exists)
        
        // Test mode switching
        let segmentedControl = app.segmentedControls.firstMatch
        XCTAssertTrue(segmentedControl.exists)
        
        // Test each mode
        segmentedControl.buttons["Color"].tap()
        XCTAssertTrue(app.otherElements["ColorPicker"].exists)
        
        segmentedControl.buttons["White"].tap()
        XCTAssertTrue(app.sliders["ColorTemperature"].exists)
        
        segmentedControl.buttons["Effects"].tap()
        XCTAssertTrue(app.buttons["Start Effect"].exists)
    }
    
    func testSceneCreation() {
        app.tabBars.buttons["Scenes"].tap()
        
        // Tap create scene button
        app.buttons["Create Scene"].tap()
        
        // Fill scene details
        let nameField = app.textFields["Scene Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Scene")
        
        // Select scene type
        let typePicker = app.pickers["Type"]
        typePicker.tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Evening")
        
        // Select a device
        let deviceList = app.tables["DeviceList"]
        deviceList.cells.firstMatch.tap()
        
        // Save scene
        app.buttons["Save"].tap()
        
        // Verify scene was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "label CONTAINS 'Test Scene'")).firstMatch.exists)
    }
    
    func testAutomationCreation() {
        app.tabBars.buttons["Automation"].tap()
        
        // Tap create automation button
        app.buttons["Create Automation"].tap()
        
        // Fill automation details
        let nameField = app.textFields["Automation Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Automation")
        
        // Select trigger type
        let triggerPicker = app.pickers["Trigger"]
        triggerPicker.tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Time")
        
        // Set time
        let timePicker = app.datePickers["Time"]
        timePicker.tap()
        
        // Select action
        let actionPicker = app.pickers["Action"]
        actionPicker.tap()
        app.pickerWheels.element.adjust(toPickerWheelValue: "Scene")
        
        // Save automation
        app.buttons["Save"].tap()
        
        // Verify automation was created
        XCTAssertTrue(app.tables.cells.containing(NSPredicate(format: "label CONTAINS 'Test Automation'")).firstMatch.exists)
    }
} 