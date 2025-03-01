import Foundation
import SwiftUI
import XCTest
@testable import YeelightControl

final class SceneEditorUITests: XCTestCase {
    var app: XCUIApplication!
    
    override func setUp() {
        super.setUp()
        app = XCUIApplication()
        app.launch()
        
        // Navigate to Scenes tab and open editor
        app.tabBars.buttons["Scenes"].tap()
        app.buttons["Create Scene"].tap()
    }
    
    func testBasicSceneCreation() {
        // Fill scene details
        let nameField = app.textFields["Scene Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("Test Scene")
        
        // Select devices
        let deviceList = app.tables["DeviceList"]
        deviceList.cells.firstMatch.tap()
        
        // Adjust brightness
        let brightnessSlider = app.sliders["Brightness"]
        brightnessSlider.adjust(toNormalizedSliderPosition: 0.75)
        
        // Save scene
        app.buttons["Save"].tap()
        
        // Verify scene appears in gallery
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "label CONTAINS 'Test Scene'")).firstMatch.exists)
    }
    
    func testColorSceneCreation() {
        // Select Color type
        let typePicker = app.pickers["Type"]
        typePicker.pickerWheels.element.adjust(toPickerWheelValue: "Color")
        
        // Set scene name
        app.textFields["Scene Name"].tap()
        app.textFields["Scene Name"].typeText("Color Scene")
        
        // Select color
        let colorPicker = app.colorWells["Color"]
        colorPicker.tap()
        
        let redColor = app.buttons["Red color"]
        redColor.tap()
        
        // Select device
        app.tables["DeviceList"].cells.firstMatch.tap()
        
        // Preview scene
        app.buttons["Preview"].tap()
        
        // Save scene
        app.buttons["Save"].tap()
        
        // Verify scene was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "label CONTAINS 'Color Scene'")).firstMatch.exists)
    }
    
    func testFlowEffectCreation() {
        // Select Flow Effect type
        let typePicker = app.pickers["Type"]
        typePicker.pickerWheels.element.adjust(toPickerWheelValue: "Flow Effect")
        
        // Set scene name
        app.textFields["Scene Name"].tap()
        app.textFields["Scene Name"].typeText("Flow Effect")
        
        // Configure flow effect
        app.buttons["Configure Flow Effect"].tap()
        
        // Add transitions
        app.buttons["Add Transition"].tap()
        
        // Configure transition
        let durationSlider = app.sliders["Duration"]
        durationSlider.adjust(toNormalizedSliderPosition: 0.5)
        
        let colorPicker = app.colorWells.firstMatch
        colorPicker.tap()
        app.buttons["Red color"].tap()
        
        // Save transition
        app.buttons["Save Transition"].tap()
        
        // Select device
        app.tables["DeviceList"].cells.firstMatch.tap()
        
        // Save scene
        app.buttons["Save"].tap()
        
        // Verify scene was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "label CONTAINS 'Flow Effect'")).firstMatch.exists)
    }
    
    func testMultiDeviceSceneCreation() {
        // Select Multi-Device type
        // ... rest of the test
    }
}

extension XCUIElement {
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }
        
        // First tap to position cursor
        tap()
        
        // Select all text
        press(forDuration: 1.0)
        
        // Delete selection
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count))
    }
} 