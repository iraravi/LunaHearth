import XCTest

@MainActor
final class VisualFlowTests: XCTestCase {
    private func capture(_ name: String, app: XCUIApplication) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    private func createHousehold(_ app: XCUIApplication) {
        let start = app.buttons["setup.start"]
        XCTAssertTrue(start.waitForExistence(timeout: 10))
        start.tap()
        let create = app.buttons["setup.create"]
        XCTAssertTrue(create.waitForExistence(timeout: 5))
        create.tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        app.tabBars.buttons["Today"].tap()
        XCTAssertTrue(app.buttons["today.quickAdd"].waitForExistence(timeout: 5))
    }

    private func tapVisible(_ id: String, app: XCUIApplication) {
        let element = app.descendants(matching: .any)[id].firstMatch
        for _ in 0..<5 {
            if element.exists && element.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(id)")
        element.tap()
    }

    private func saveEntry(_ name: String, app: XCUIApplication) {
        let title = app.textFields["quickAdd.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText(name)
        app.buttons["quickAdd.save"].tap()
    }

    func testHomeEndToEndRoomItemWarrantyAndMaintenance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        createHousehold(app)
        app.tabBars.buttons["Home"].tap()
        capture("19-Home-Start", app: app)
        tapVisible("home.addFloor", app: app)
        saveEntry("Ground floor", app: app)
        app.swipeDown()
        tapVisible("home.addRoom", app: app)
        saveEntry("Kitchen", app: app)
        let kitchen = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.room.", "Kitchen")).firstMatch
        XCTAssertTrue(kitchen.waitForExistence(timeout: 5))
        kitchen.tap()
        XCTAssertTrue(app.buttons["room.addItem"].waitForExistence(timeout: 5))
        capture("20-Room-Add-Item", app: app)
        app.buttons["room.addItem"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["item.roomContext"].firstMatch.label.contains("Kitchen"))
        XCTAssertFalse(app.buttons["quickAdd.kind"].exists)
        let title = app.textFields["quickAdd.title"]
        title.tap(); title.typeText("Fridge")
        app.textFields["Manufacturer"].tap(); app.textFields["Manufacturer"].typeText("Acme")
        capture("21-Add-Item-To-Room", app: app)
        app.buttons["quickAdd.save"].tap()
        let fridge = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "room.item.", "Fridge")).firstMatch
        XCTAssertTrue(fridge.waitForExistence(timeout: 5))
        fridge.tap()
        tapVisible("item.addWarranty", app: app)
        saveEntry("Appliance cover", app: app)
        XCTAssertTrue(app.staticTexts["Appliance cover"].waitForExistence(timeout: 5))
        tapVisible("item.addMaintenance", app: app)
        let planTitle = app.textFields["quickAdd.title"]
        XCTAssertTrue(planTitle.waitForExistence(timeout: 5))
        planTitle.tap(); planTitle.typeText("Clean filter")
        app.buttons["quickAdd.keyboardDone"].tap()
        let repeatSwitch = app.switches["Repeat after completion"]
        XCTAssertTrue(repeatSwitch.waitForExistence(timeout: 5))
        repeatSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.93, dy: 0.5)).tap()
        XCTAssertEqual(repeatSwitch.value as? String, "1")
        let replacement = app.textFields["Replacement shopping item (optional)"]
        replacement.tap(); replacement.typeText("Water filter")
        app.buttons["quickAdd.save"].tap()
        capture("22-Item-Warranty-Maintenance", app: app)
        app.buttons["Clean filter"].tap()
        app.buttons["maintenance.complete"].tap()
        app.buttons["Record Completion"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["maintenance.nextDue"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Add replacement to groceries"].tap()
        XCTAssertTrue(app.buttons["Replacement is on your grocery list"].waitForExistence(timeout: 5))
        capture("23-Home-Care-Completed", app: app)
    }

    func testSetupRestoreAndCloudUnavailableKeepLocalHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        app.buttons["setup.restore"].tap()
        app.buttons["backup.find"].tap()
        XCTAssertTrue(app.staticTexts["backup.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["backup.status"].label.contains("unavailable"))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["setup.start"].tap()
        capture("24-Home-Setup", app: app)
        app.buttons["setup.firstRoom"].tap()
        app.buttons["Kitchen"].tap()
        app.buttons["setup.create"].tap()
        XCTAssertTrue(app.buttons["home.addRoom"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.room.", "Kitchen")).firstMatch.waitForExistence(timeout: 5))
        app.tabBars.buttons["More"].tap()
        tapVisible("more.backup", app: app)
        capture("25-iCloud-Backup", app: app)
        app.buttons["backup.upload"].tap()
        app.buttons["Save backup"].tap()
        XCTAssertTrue(app.staticTexts["backup.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["backup.status"].label.contains("unavailable"))
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.room.", "Kitchen")).firstMatch.exists)
    }

    func testLightModeScreensAndQuickAdd() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        capture("01-Welcome-Light", app: app)
        createHousehold(app)
        capture("02-Today-Light", app: app)
        app.buttons["today.primaryAdd"].tap()
        let title = app.textFields["quickAdd.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Water the plants")
        capture("03-Quick-Add", app: app)
        app.buttons["quickAdd.save"].tap()
        XCTAssertTrue(app.buttons["today.quickAdd"].waitForExistence(timeout: 5))
        for tab in ["Calendar", "Home", "Lists", "More"] {
            app.tabBars.buttons[tab].tap()
            capture("04-\(tab)-Light", app: app)
        }
        app.tabBars.buttons["Lists"].tap()
        app.staticTexts["Tasks & chores"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Water the plants")).firstMatch.waitForExistence(timeout: 5))
        capture("05-Tasks-Light", app: app)
    }

    func testBuildHomeLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing"]
        app.launch()
        createHousehold(app)
        app.tabBars.buttons["Home"].tap()
        tapVisible("home.layout", app: app)
        XCTAssertTrue(app.buttons["layout.addRoom"].waitForExistence(timeout: 5))
        capture("10-Layout-Empty", app: app)
        app.buttons["layout.addRoom"].tap()
        XCTAssertTrue(app.buttons["layout.save"].waitForExistence(timeout: 5))
        capture("11-Room-Editor", app: app)
        app.swipeUp()
        let width = app.textFields["Width in meters"]
        XCTAssertTrue(width.waitForExistence(timeout: 5))
        width.tap()
        width.typeText(XCUIKeyboardKey.delete.rawValue + "5.25")
        app.buttons["layout.save"].tap()
        XCTAssertTrue(app.buttons["layout.addRoom"].waitForExistence(timeout: 5))
        app.buttons["layout.addRoom"].tap()
        app.buttons["layout.preset.Bedroom"].tap()
        app.buttons["layout.save"].tap()
        XCTAssertTrue(app.buttons["layout.addRoom"].waitForExistence(timeout: 5))
        capture("12-Home-3D", app: app)
        let orbit = app.descendants(matching: .any)["layout.orbit"].firstMatch
        XCTAssertTrue(orbit.waitForExistence(timeout: 5))
        let oldAngle = orbit.value as? String
        let orbitStart = orbit.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.6))
        orbitStart.press(forDuration: 0.1, thenDragTo: orbitStart.withOffset(CGVector(dx: 120, dy: -40)))
        XCTAssertNotEqual(orbit.value as? String, oldAngle)
        capture("18-Home-Rotated", app: app)
        app.segmentedControls["layout.mode"].buttons["2D Plan"].tap()
        capture("13-Home-2D", app: app)
        let tile = app.descendants(matching: .any)["layout.dragRoom.Bedroom"].firstMatch
        XCTAssertTrue(tile.waitForExistence(timeout: 5), app.debugDescription)
        let originalPosition = tile.value as? String
        let start = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.2, thenDragTo: start.withOffset(CGVector(dx: -60, dy: 0)))
        XCTAssertEqual(tile.value as? String, originalPosition)
        XCTAssertTrue(app.descendants(matching: .any)["layout.moveStatus"].firstMatch.label.contains("returned"))
        let next = tile.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        next.press(forDuration: 0.2, thenDragTo: next.withOffset(CGVector(dx: 0, dy: 70)))
        XCTAssertNotEqual(tile.value as? String, originalPosition)
        XCTAssertTrue(app.descendants(matching: .any)["layout.moveStatus"].firstMatch.label.contains("moved and saved"))
        capture("17-Room-Drag", app: app)
        app.swipeUp()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "layout.room.", "Bedroom")).firstMatch.waitForExistence(timeout: 5))
        app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "layout.room.", "Bedroom")).firstMatch.tap()
        XCTAssertEqual(app.textFields["layout.roomName"].value as? String, "Bedroom")
        app.buttons["Cancel"].tap()
    }

    func testLayoutAppearanceAndAccessibilityText() {
        for appearance in ["--dark", "--large-text"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-testing", appearance]
            app.launch()
            createHousehold(app)
            app.tabBars.buttons["Home"].tap()
            tapVisible("home.layout", app: app)
            XCTAssertTrue(app.buttons["layout.toolbarAdd"].waitForExistence(timeout: 5))
            app.buttons["layout.toolbarAdd"].tap()
            XCTAssertTrue(app.buttons["layout.save"].waitForExistence(timeout: 5))
            capture(appearance == "--dark" ? "14-Room-Dark" : "15-Room-Large-Text", app: app)
            if appearance == "--large-text" {
                app.swipeUp()
                capture("16-Room-Large-Measurements", app: app)
            }
            app.buttons["layout.save"].tap()
            XCTAssertTrue(app.buttons["layout.toolbarAdd"].waitForExistence(timeout: 5))
            app.terminate()
        }
    }

    func testDarkModeAndLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--dark"]
        app.launch()
        createHousehold(app)
        capture("06-Today-Dark", app: app)
        app.tabBars.buttons["Lists"].tap()
        capture("07-Lists-Dark", app: app)
        app.terminate()
        app.launchArguments = ["--ui-testing", "--large-text"]
        app.launch()
        createHousehold(app)
        capture("08-Today-Large-Text", app: app)
        app.swipeUp()
        capture("09-Today-Large-Text-Scrolled", app: app)
    }
}
