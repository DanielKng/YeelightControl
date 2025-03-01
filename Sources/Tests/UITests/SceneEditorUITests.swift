i; mport SwiftUI
i; ; mport SwiftUI
i; ; ; mport SwiftUI
i; ; ; ; mport SwiftUI
i; ; ; ; mport XCTest
@; ; ; ; testable import YeelightControl

f; ; ; ; inal class SceneEditorUITests: XCTestCase {
 ; ; ; ; var app: XCUIApplication!
    
 ; ; ; ; override func setUp() {
        super.setUp()
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["UI_TESTING"]
        app.launch()
        
        //; ; ; ; Navigate to ; ; ; ; Scenes tab ; ; ; ; and open editor
        app.tabBars.buttons["Scenes"].tap()
        app.navigationBars.buttons["Add"].tap()
    }
    
 ; ; ; ; func testBasicSceneCreation() {
        //; ; ; ; Fill scene details
 ; ; ; ; let nameField = app.textFields["; ; ; ; Scene Name"]
        XCTAssertTrue(nameField.exists)
        nameField.tap()
        nameField.typeText("; ; ; ; Test Scene")
        
        //; ; ; ; Select devices
 ; ; ; ; let deviceList = app.tables["DeviceList"]
        XCTAssertTrue(deviceList.exists)
        deviceList.cells.firstMatch.switches.firstMatch.tap()
        
        //; ; ; ; Adjust brightness
 ; ; ; ; let brightnessSlider = app.sliders["Brightness"]
        XCTAssertTrue(brightnessSlider.exists)
        brightnessSlider.adjust(toNormalizedSliderPosition: 0.75)
        
        //; ; ; ; Save scene
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Verify scene ; ; ; ; appears in gallery
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS '; ; ; ; Test Scene'")).firstMatch.exists)
    }
    
 ; ; ; ; func testColorSceneCreation() {
        //; ; ; ; Select Color type
 ; ; ; ; let typePicker = app.pickers["Type"]
        typePicker.pickerWheels.element.adjust(toPickerWheelValue: "Color")
        
        //; ; ; ; Set scene name
        app.textFields["; ; ; ; Scene Name"].tap()
        app.textFields["; ; ; ; Scene Name"].typeText("; ; ; ; Color Scene")
        
        //; ; ; ; Select color
 ; ; ; ; let colorPicker = app.colorWells["Color"]
        XCTAssertTrue(colorPicker.exists)
        colorPicker.tap()
        
 ; ; ; ; let redColor = app.buttons["; ; ; ; Red color"]
        XCTAssertTrue(redColor.exists)
        redColor.tap()
        
        //; ; ; ; Select device
        app.tables["DeviceList"].cells.firstMatch.switches.firstMatch.tap()
        
        //; ; ; ; Preview scene
        app.buttons["Preview"].tap()
        
        //; ; ; ; Save scene
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Verify scene ; ; ; ; was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS '; ; ; ; Color Scene'")).firstMatch.exists)
    }
    
 ; ; ; ; func testFlowEffectCreation() {
        //; ; ; ; Select Flow ; ; ; ; Effect type
 ; ; ; ; let typePicker = app.pickers["Type"]
        typePicker.pickerWheels.element.adjust(toPickerWheelValue: "; ; ; ; Flow Effect")
        
        //; ; ; ; Set scene name
        app.textFields["; ; ; ; Scene Name"].tap()
        app.textFields["; ; ; ; Scene Name"].typeText("; ; ; ; Flow Effect")
        
        //; ; ; ; Configure flow effect
        app.buttons["; ; ; ; Configure Flow Effect"].tap()
        
        //; ; ; ; Add transitions
        app.buttons["; ; ; ; Add Transition"].tap()
        
        //; ; ; ; Configure transition
 ; ; ; ; let durationSlider = app.sliders["Duration"]
        XCTAssertTrue(durationSlider.exists)
        durationSlider.adjust(toNormalizedSliderPosition: 0.5)
        
 ; ; ; ; let colorPicker = app.colorWells.firstMatch
        colorPicker.tap()
        app.buttons["; ; ; ; Red color"].tap()
        
        //; ; ; ; Save transition
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Select device
        app.tables["DeviceList"].cells.firstMatch.switches.firstMatch.tap()
        
        //; ; ; ; Save scene
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Verify scene ; ; ; ; was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS '; ; ; ; Flow Effect'")).firstMatch.exists)
    }
    
 ; ; ; ; func testMultiDeviceSceneCreation() {
        //; ; ; ; Select Multi-; ; ; ; Device type
 ; ; ; ; let typePicker = app.pickers["Type"]
        typePicker.pickerWheels.element.adjust(toPickerWheelValue: "Multi-Device")
        
        //; ; ; ; Set scene name
        app.textFields["; ; ; ; Scene Name"].tap()
        app.textFields["; ; ; ; Scene Name"].typeText("Multi-; ; ; ; Device Scene")
        
        //; ; ; ; Select multiple devices
 ; ; ; ; let deviceList = app.tables["DeviceList"]
 ; ; ; ; let devices = deviceList.cells.allElementsBoundByIndex
        XCTAssertTrue(devices.count >= 2, "; ; ; ; Need at least 2; ; ; ; devices for multi-; ; ; ; device scene")
        
        devices[0].switches.firstMatch.tap()
        devices[1].switches.firstMatch.tap()
        
        //; ; ; ; Configure multi-; ; ; ; device effect
        app.buttons["; ; ; ; Configure Multi-; ; ; ; Device Effect"].tap()
        
        //; ; ; ; Select effect type
 ; ; ; ; let effectPicker = app.pickers["; ; ; ; Effect Type"]
        effectPicker.pickerWheels.element.adjust(toPickerWheelValue: "Wave")
        
        //; ; ; ; Adjust speed
 ; ; ; ; let speedSlider = app.sliders["Speed"]
        speedSlider.adjust(toNormalizedSliderPosition: 0.5)
        
        //; ; ; ; Save effect
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Save scene
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Verify scene ; ; ; ; was created
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS 'Multi-; ; ; ; Device Scene'")).firstMatch.exists)
    }
    
 ; ; ; ; func testSceneEditing() {
        //; ; ; ; Create initial scene
        testBasicSceneCreation()
        
        //; ; ; ; Find and ; ; ; ; edit scene
 ; ; ; ; let sceneCell = app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS '; ; ; ; Test Scene'")).firstMatch
        sceneCell.press(forDuration: 1.0)
        
        app.buttons["Edit"].tap()
        
        //; ; ; ; Modify scene name
 ; ; ; ; let nameField = app.textFields["; ; ; ; Scene Name"]
        nameField.tap()
        nameField.clearText()
        nameField.typeText("; ; ; ; Updated Scene")
        
        //; ; ; ; Change brightness
 ; ; ; ; let brightnessSlider = app.sliders["Brightness"]
        brightnessSlider.adjust(toNormalizedSliderPosition: 0.25)
        
        //; ; ; ; Save changes
        app.navigationBars.buttons["Save"].tap()
        
        //; ; ; ; Verify scene ; ; ; ; was updated
        XCTAssertTrue(app.collectionViews.cells.containing(NSPredicate(format: "; ; ; ; label CONTAINS '; ; ; ; Updated Scene'")).firstMatch.exists)
    }
}

e; ; ; ; xtension XCUIElement {
 ; ; ; ; func clearText() {
 ; ; ; ; guard let stringValue = self.; ; ; ; value as?; ; ; ; String else {
            return
        }
        
        //; ; ; ; First tap ; ; ; ; to position cursor
        tap()
        
        //; ; ; ; Select all text
        press(forDuration: 1.0)
        
        //; ; ; ; Delete selection
        typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: stringValue.count))
    }
} 