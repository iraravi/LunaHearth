import XCTest

@MainActor
final class VisualFlowTests: XCTestCase {
    func testNotificationForAnotherHomeDoesNotShowCurrentAssignments() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--notification-shopping", "--notification-other-home"]
        app.launch()
        XCTAssertTrue(app.staticTexts["Another home’s notification"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.descendants(matching: .any)["assignment.arrival.shopping"].firstMatch.exists)
        app.buttons["Done"].firstMatch.tap()
    }

    func testAssignmentArrivalAndReducedMotion() { assignmentArrival(reduced: true) }
    func testAssignmentArrivalWithMotion() { assignmentArrival(reduced: false) }
    private func assignmentArrival(reduced: Bool) {
        for focus in ["tasks", "shopping"] {
            let app = XCUIApplication()
            app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--notification-" + focus] + (reduced ? ["--reduce-motion", "--large-text"] : [])
            app.launch()
            let banner = app.descendants(matching: .any)["assignment.arrival." + focus].firstMatch
            XCTAssertTrue(banner.waitForExistence(timeout: 10))
            XCTAssertTrue(banner.isHittable)
            capture("Assignment-Arrival-" + focus, app: app)
            app.buttons["Done"].firstMatch.tap()
        }
    }

    func testPublicSettingsPreserveManualShopping() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--ui-testing-known-groceries", "--ui-testing-ai-ready", "--ui-testing-public-settings"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        app.staticTexts["Shopping"].tap()
        XCTAssertTrue(app.buttons["shopping.add"].waitForExistence(timeout: 5))
        app.buttons["shopping.tools"].tap()
        XCTAssertFalse(app.buttons["shopping.organizeAI"].exists)
        app.buttons["shopping.tools.done"].tap()
        tapVisible("shopping.scanReceipt", app: app)
        XCTAssertTrue(app.staticTexts["Receipt scanning is temporarily paused. Manual entry is available."].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["receipt.confirm"].exists)
        capture("Public-Settings-Paused-Receipt", app: app)
        app.buttons["Close"].firstMatch.tap()
        app.buttons["More"].firstMatch.tap()
        XCTAssertFalse(app.buttons["more.appStatus"].exists)
        XCTAssertFalse(app.buttons["appStatus.refresh"].exists)
        tapVisible("more.help", app: app)
        XCTAssertTrue(app.staticTexts["Your saved household records remain available."].waitForExistence(timeout: 5))
        capture("Publisher-Guidance", app: app)
    }

    func testUnavailableAIKeepsShoppingAndPantryUsable() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--ui-testing-known-groceries", "--ui-testing-ai-unavailable"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        app.staticTexts["Shopping"].tap()
        XCTAssertTrue(app.buttons["shopping.tools"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["shopping.tools"].label, "Filters")
        XCTAssertTrue(app.buttons["shopping.add"].exists)
        XCTAssertTrue(app.buttons["shopping.ai.open"].exists, "Built-in ideas remain available")
        app.buttons["shopping.tools"].tap()
        XCTAssertTrue(app.buttons["shopping.tools.done"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["shopping.organizeAI"].exists)
        XCTAssertFalse(app.buttons["shopping.resetAICategories"].exists)
        XCTAssertTrue(app.buttons["shopping.reviewDuplicates"].exists)
        capture("Shopping-Without-AI", app: app)
        app.buttons["shopping.tools.done"].tap()
        tapVisible("shopping.inventory", app: app)
        XCTAssertTrue(app.buttons["inventory.tools"].waitForExistence(timeout: 5))
        app.buttons["inventory.tools"].tap()
        XCTAssertTrue(app.buttons["inventory.tools.done"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["inventory.organizeAI"].exists)
        app.buttons["inventory.tools.done"].tap()
        tapVisible("inventory.ideas", app: app)
        XCTAssertTrue(app.buttons["inventory.ideasStyle"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["inventory.generateIdeas"].exists)
        XCTAssertFalse(app.textFields["inventory.ideasRequest"].exists)
        capture("Pantry-Templates-Without-AI", app: app)
    }

    func testContextHelpAndChecklistRecovery() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--ui-testing-ai-unavailable"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.setupOptions", app: app)
        app.buttons["Hide setup checklist"].tap()
        XCTAssertFalse(app.buttons["home.setupGuide"].exists)
        tapVisible("help.open.home", app: app)
        XCTAssertTrue(app.buttons["help.done"].waitForExistence(timeout: 5))
        capture("Help-Home-Quick-Guide", app: app)
        app.buttons["help.done"].tap()
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.help", app: app)
        XCTAssertTrue(app.buttons["help.setup"].waitForExistence(timeout: 5))
        capture("Help-Center", app: app)
        let search = app.searchFields.firstMatch
        search.tap()
        search.typeText("another device")
        XCTAssertTrue(app.buttons["help.answer.sync"].waitForExistence(timeout: 5))
        app.buttons["help.answer.sync"].tap()
        capture("Help-Sync-Answer", app: app)
        search.buttons["Clear text"].tap()
        tapVisible("help.setup", app: app)
        let restore = app.switches["guide.showOnHome"]
        for _ in 0..<5 {
            if restore.exists && restore.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(restore.waitForExistence(timeout: 5))
        if restore.switches.firstMatch.exists { restore.switches.firstMatch.tap() }
        else { restore.tap() }
        XCTAssertEqual(restore.value as? String, "1")
        capture("Help-Checklist-Restored", app: app)
        app.buttons["Home"].firstMatch.tap()
        XCTAssertTrue(app.buttons["home.setupGuide"].waitForExistence(timeout: 5))
        tapVisible("home.shopping", app: app)
        tapVisible("help.open.shopping", app: app)
        XCTAssertTrue(app.buttons["help.done"].waitForExistence(timeout: 5))
        capture("Help-Shopping-Quick-Guide", app: app)
        app.buttons["help.done"].tap()
        XCTAssertTrue(app.buttons["shopping.add"].waitForExistence(timeout: 5))
    }

    func testHelpAtAccessibilityTextSize() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-pantry", "--large-text"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.help", app: app)
        tapVisible("help.topic.connected", app: app)
        XCTAssertTrue(app.navigationBars["Quick guide"].waitForExistence(timeout: 5))
        capture("Help-Connected-Large-Text", app: app)
        app.swipeUp()
        app.swipeUp()
        capture("Help-Connected-Large-Text-End", app: app)
        XCTAssertTrue(app.staticTexts["Nothing is imported by reading this guide. Scanned or generated suggestions need your review."].exists)
    }

    func testLaunchPerformance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--store-screenshots"]
        let options = XCTMeasureOptions()
        options.iterationCount = 3
        measure(metrics: [XCTApplicationLaunchMetric()], options: options) {
            app.launch()
            XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
            app.terminate()
        }
    }

    func testWelcomeWalkthrough() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-walkthrough", "--ui-testing-reset-walkthrough"]
        app.launch()
        XCTAssertTrue(app.buttons["tour.next"].waitForExistence(timeout: 10))
        capture("Welcome-Overview", app: app)
        for index in 0..<4 {
            app.buttons["tour.next"].tap()
            if index == 0 { capture("Welcome-Receipt", app: app) }
        }
        XCTAssertTrue(app.staticTexts["tour.title"].label.contains("Turn what you have"))
        capture("Welcome-Meals", app: app)
        app.buttons["tour.next"].tap()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 5))
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-walkthrough"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["tour.next"].exists)
    }

    func testWelcomeAccessibilityDark() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-walkthrough", "--ui-testing-reset-walkthrough", "--large-text", "--dark"]
        app.launch()
        XCTAssertTrue(app.buttons["tour.next"].waitForExistence(timeout: 10))
        capture("Premium-Welcome-Accessibility-Dark", app: app)
        app.buttons["tour.next"].tap()
        capture("Premium-Receipt-Accessibility-Dark", app: app)
        for _ in 0..<3 { app.buttons["tour.next"].tap() }
        XCTAssertTrue(app.buttons["tour.next"].isHittable)
        capture("Premium-Meals-Accessibility-Dark", app: app)
        app.buttons["tour.next"].tap()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 5))
    }

    func testWalkthroughReplayLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--large-text"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.help", app: app)
        tapVisible("help.replay", app: app)
        XCTAssertTrue(app.buttons["tour.next"].waitForExistence(timeout: 5))
        app.buttons["tour.next"].tap()
        capture("Welcome-Receipt-Large", app: app)
        app.buttons["tour.skip"].tap()
        XCTAssertTrue(app.buttons["help.replay"].waitForExistence(timeout: 5))
    }

    /// Capture real views with a fictional in-memory household; never production data.
    func testAppStoreScreenshots() {
        XCUIDevice.shared.orientation = .portrait
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--store-screenshots"]
        app.launch()
        XCTAssertTrue(app.buttons["Today"].firstMatch.waitForExistence(timeout: 10))
        capture("Store-01-Today", app: app)
        app.buttons["Home"].firstMatch.tap()
        XCTAssertTrue(app.buttons["home.inventory"].waitForExistence(timeout: 5))
        capture("Store-02-Home", app: app)
        tapVisible("home.shopping", app: app)
        XCTAssertTrue(app.buttons["shopping.item.Tomatoes"].waitForExistence(timeout: 5))
        capture("Store-03-Shopping", app: app)
        tapVisible("shopping.inventory", app: app)
        XCTAssertTrue(app.buttons["inventory.item.Basmati rice"].waitForExistence(timeout: 5))
        capture("Store-04-Pantry", app: app)
        app.buttons["Calendar"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Garden walk"].waitForExistence(timeout: 5))
        capture("Store-05-Calendar", app: app)
        app.terminate(); app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.expenses", app: app)
        XCTAssertTrue(app.staticTexts["expenses.total"].waitForExistence(timeout: 5))
        capture("Store-06-Expenses", app: app)
    }

    func testStoreFailureNeverShowsNewHomeSetup() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-store-failure"]
        app.launch()
        XCTAssertTrue(app.descendants(matching: .any)["storage.recovery"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.buttons["Get started"].exists)
        capture("Storage-Recovery", app: app)
    }

    func testReceiptLinksBoughtItemWithoutRestocking() { receiptLink(largeText: false) }
    func testReceiptLinkLargeText() { receiptLink(largeText: true) }
    private func receiptLink(largeText: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-receipt", "--ui-testing-receipt-link"]
        if largeText { app.launchArguments.append("--large-text") }
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.scanReceipt", app: app)
        XCTAssertTrue(app.buttons["receipt.confirm"].waitForExistence(timeout: 5))
        tapVisible("receipt.usePurchase.Curd", app: app)
        XCTAssertEqual(app.buttons["receipt.usePurchase.Curd"].value as? String, "Selected")
        capture("Receipt-Existing-Purchase", app: app)
        app.buttons["receipt.confirm"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["receipt.success"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Close"].firstMatch.tap()
        tapVisible("inventory.item.Curd", app: app)
        // The existing tub has its original quantity after attaching receipt evidence.
        tapVisible("inventory.details", app: app)
        let quantity = app.textFields["inventory.quantity"]
        XCTAssertTrue(quantity.waitForExistence(timeout: 5))
        XCTAssertEqual(quantity.value as? String, "1 tub")
        capture("Receipt-Linked-Pantry", app: app)
    }

    func testLinkedAppleCalendarFlow() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar", "--ui-testing-calendar-delivery"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        app.buttons["calendar.member.Kira"].tap()
        tapVisible("calendar.addMember.Kira", app: app)
        let title = app.textFields["appointment.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Linked lesson")
        app.buttons["Done"].firstMatch.tap()
        let toggle = app.switches["appointment.appleEnabled"].firstMatch
        reveal(toggle, app: app)
        XCTAssertTrue(toggle.exists)
        toggle.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        tapVisible("appointment.appleCalendar", app: app)
        app.buttons["Family test calendar · Test account"].tap()
        capture("Apple-Calendar-Checkbox", app: app)
        app.buttons["appointment.save"].tap()
        XCTAssertTrue(app.buttons["calendar.add"].waitForExistence(timeout: 5))
        let event = app.staticTexts["Linked lesson"]
        for _ in 0..<5 where !event.isHittable { app.swipeUp() }
        XCTAssertTrue(event.exists); event.tap()
        XCTAssertTrue(app.staticTexts["Last update sent"].waitForExistence(timeout: 5))
        app.buttons["Edit"].tap()
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap()
        title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: "Linked lesson".count)); title.typeText("Updated lesson")
        app.buttons["appointment.save"].tap()
        XCTAssertTrue(app.staticTexts["Last update sent"].waitForExistence(timeout: 5))
        capture("Apple-Calendar-Linked-Update", app: app)
    }

    func testSiriAppointmentDraftLink() throws {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar"]
        app.launch()
        let url = try XCTUnwrap(URL(string: "lunahearth://calendar?title=Shortcuts%20review&date=1800000000&member=Kira&create=1"))
        app.open(url)
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        if springboard.buttons["Open"].waitForExistence(timeout: 2) { springboard.buttons["Open"].tap() }
        let title = app.textFields["appointment.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 8))
        XCTAssertEqual(title.value as? String, "Shortcuts review")
        XCTAssertTrue(app.buttons["appointment.member"].label.contains("Kira"))
        capture("Siri-Appointment-Review", app: app)
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.staticTexts["Shortcuts review"].exists)
    }

    func testAppointmentEditor() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        tapVisible("calendar.addMember.Kira", app: app)
        let title = app.textFields["appointment.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5)); title.tap(); title.typeText("Dental checkup")
        app.buttons["Done"].firstMatch.tap()
        tapVisible("appointment.kind", app: app)
        app.buttons["Doctor"].firstMatch.tap()
        capture("Appointment-Editor", app: app)
        tapVisible("appointment.repeat", app: app)
        app.buttons["Weeks"].firstMatch.tap()
        tapVisible("appointment.reminder", app: app)
        app.buttons["15 minutes before"].firstMatch.tap()
        capture("Appointment-Repeat-Reminder", app: app)
        app.buttons["appointment.save"].tap()
        if app.alerts["Overlapping appointments"].waitForExistence(timeout: 2) { app.alerts.buttons["Save anyway"].tap() }
        XCTAssertTrue(app.buttons["calendar.add"].waitForExistence(timeout: 5))
        app.swipeDown()
        app.buttons["calendar.member.Kira"].tap()
        let event = app.staticTexts["Dental checkup"]
        for _ in 0..<4 where !event.isHittable { app.swipeUp() }
        XCTAssertTrue(event.exists); event.tap()
        XCTAssertTrue(app.staticTexts["Doctor"].waitForExistence(timeout: 5))
        capture("Appointment-Saved", app: app)
    }

    func testCalendarLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        testHouseholdCalendar()
    }

    func testCalendarLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar", "--large-text"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        tapVisible("calendar.member.Kira", app: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Afternoon appointment"].waitForExistence(timeout: 5))
        capture("Calendar-Large-Text", app: app)
    }

    func testFamilyWeekLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar", "--large-text"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        tapVisible("calendar.week", app: app)
        tapVisible("familyWeek.day.1", app: app)
        capture("Family-Week-Large-Text", app: app)
        tapVisible("familyWeek.shopping", app: app)
        XCTAssertTrue(app.navigationBars["Weekly shopping"].waitForExistence(timeout: 5))
    }

    func testFamilyWeekPlanning() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        tapVisible("calendar.week", app: app)
        XCTAssertTrue(app.navigationBars["Family week"].waitForExistence(timeout: 5))
        capture("Family-Week-Overview", app: app)
        tapVisible("familyWeek.member.Kira", app: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Afternoon appointment"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Morning appointment"].exists)
        app.staticTexts["Afternoon appointment"].tap()
        XCTAssertTrue(app.navigationBars["Afternoon appointment"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        app.swipeDown(); app.swipeDown()
        tapVisible("familyWeek.next", app: app)
        tapVisible("familyWeek.plan", app: app)
        tapVisible("week.style", app: app)
        app.buttons["South Indian"].tap()
        app.swipeDown(); app.swipeDown()
        XCTAssertTrue(app.switches["familyWeek.meal.Breakfast"].exists)
        XCTAssertTrue(app.switches["familyWeek.meal.Lunch"].exists)
        let prep = app.switches["familyWeek.prep"]
        for _ in 0..<4 where !prep.isHittable { app.swipeUp() }
        XCTAssertTrue(prep.waitForExistence(timeout: 5))
        prep.coordinate(withNormalizedOffset: CGVector(dx: 0.9, dy: 0.5)).tap()
        tapVisible("week.generate", app: app)
        XCTAssertTrue(app.buttons["week.save"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["week.save"].isEnabled)
        app.swipeUp()
        capture("Family-Week-Review", app: app)
        app.buttons["week.save"].tap()
        XCTAssertTrue(app.navigationBars["Family week"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Prepare for ")).firstMatch.waitForExistence(timeout: 5))
        capture("Family-Week-Planned", app: app)
        tapVisible("familyWeek.shopping", app: app)
        XCTAssertTrue(app.navigationBars["Weekly shopping"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["week.addShopping"].isEnabled)
    }

    func testHouseholdCalendar() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-calendar"]
        app.launch()
        XCTAssertTrue(app.buttons["Calendar"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Calendar"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["Morning appointment"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Afternoon appointment"].exists)
        capture("Calendar-Everyone", app: app)
        app.buttons["calendar.member.Kira"].tap()
        XCTAssertFalse(app.staticTexts["Morning appointment"].exists)
        XCTAssertTrue(app.staticTexts["Afternoon appointment"].exists)
        capture("Calendar-Kira", app: app)
        app.staticTexts["Afternoon appointment"].tap()
        XCTAssertTrue(app.buttons["event.export"].waitForExistence(timeout: 5))
    }

    func testOfflinePrivacyPolicy() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.privacy", app: app)
        tapVisible("more.privacyPolicy", app: app)
        XCTAssertTrue(app.staticTexts["privacyPolicy.draft"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Your household information"].exists)
        capture("Privacy-Policy-Offline", app: app)
    }

    func testRealPantryMealIdeas() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.meals", app: app)
        XCTAssertFalse(app.buttons["meals.suggest"].isEnabled)
        tapVisible("meals.cookingStyle", app: app)
        app.buttons["South Indian"].tap()
        let preferences = app.descendants(matching: .any)["meals.context"].firstMatch
        XCTAssertTrue(preferences.waitForExistence(timeout: 5))
        preferences.tap(); preferences.typeText("Mild spice, dinner for four")
        app.buttons["meals.keyboardDone"].tap()
        capture("Meal-Style-And-Preferences", app: app)
        tapVisible("meals.suggest", app: app)
        XCTAssertTrue(app.descendants(matching: .any)["reviewSafety.meal"].firstMatch.exists)
        let review = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Review and plan")).firstMatch
        XCTAssertTrue(review.waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Your extra notes were not applied")).firstMatch.exists)
        for _ in 0..<4 { if review.isHittable { break }; app.swipeUp() }
        capture("Real-Pantry-Meal-Ideas", app: app)
        review.tap()
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
        let title = app.textFields["quickAdd.title"].value as? String ?? ""
        app.buttons["quickAdd.save"].tap()
        tapVisible("View saved meal plans", app: app)
        XCTAssertFalse(title.isEmpty)
        XCTAssertTrue(app.staticTexts[title].waitForExistence(timeout: 5))
        capture("Real-Meal-Plan-Saved", app: app)
        app.staticTexts[title].tap()
        XCTAssertFalse(app.staticTexts["Cooking steps"].exists)
        XCTAssertFalse(app.buttons["Add recipe steps"].exists)
        capture("Meal-Ingredients-Redesigned", app: app)
        tapVisible("meal.missing", app: app)
        app.buttons["meal.addMissing"].tap()
        XCTAssertEqual(app.staticTexts["meal.ingredientStatus.Curd"].label, "Already in shopping")
        XCTAssertFalse(app.buttons["meal.missing"].exists)
        capture("Meal-Already-In-Shopping", app: app)
        tapVisible("meal.prep", app: app)
        let prep = app.textFields["meal.prepTitle"]
        XCTAssertTrue(prep.waitForExistence(timeout: 5)); prep.tap(); prep.typeText("Wash rice")
        app.buttons["meal.savePrep"].tap()
        tapVisible("meal.finish", app: app)
        tapVisible("meal.packAction.Rice", app: app)
        app.buttons["Use an amount"].tap()
        let amount = app.textFields["meal.usedAmount.Rice"]
        XCTAssertTrue(amount.waitForExistence(timeout: 5)); amount.tap(); amount.typeText("100")
        capture("Cooking-Pantry-Review", app: app)
        app.buttons["meal.confirmCooked"].tap()
        XCTAssertTrue(app.staticTexts["Cooked"].waitForExistence(timeout: 5))
        capture("Cooking-Finished", app: app)
    }

    func testMealPerServingQuantityEntry() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.meals", app: app)
        tapVisible("Plan a meal myself", app: app)
        let title = app.textFields["quickAdd.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText("Rice dinner")
        app.buttons["quickAdd.keyboardDone"].tap()
        let ingredients = app.descendants(matching: .any)["meal.ingredients"].firstMatch
        ingredients.tap(); ingredients.typeText("Rice")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("Amounts per serving · optional", app: app)
        tapVisible("meal.amount.Rice", app: app)
        app.textFields["meal.amount.Rice"].typeText("100 g")
        app.buttons["quickAdd.keyboardDone"].tap()
        capture("Meal-Per-Serving-Quantity", app: app)
        app.buttons["quickAdd.save"].tap()
        tapVisible("View saved meal plans", app: app)
        app.staticTexts["Rice dinner"].tap()
        XCTAssertTrue(app.staticTexts["Need 200 g · 100 g per serving"].waitForExistence(timeout: 5))
        capture("Meal-Scaled-Amount", app: app)
    }

    func testWeeklyMealPlanningAndShoppingReview() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.meals", app: app)
        tapVisible("meals.week", app: app)
        XCTAssertTrue(app.navigationBars["Weekly meals"].waitForExistence(timeout: 5))
        capture("Weekly-Empty", app: app)
        tapVisible("week.suggest", app: app)
        tapVisible("week.style", app: app)
        app.buttons["South Indian"].tap()
        tapVisible("week.generate", app: app)
        XCTAssertTrue(app.buttons["week.save"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.buttons["week.save"].isEnabled)
        capture("Weekly-Draft-Review", app: app)
        app.buttons["week.save"].tap()
        XCTAssertTrue(app.navigationBars["Weekly meals"].waitForExistence(timeout: 5))
        capture("Weekly-Planned", app: app)
        tapVisible("week.shopping", app: app)
        XCTAssertTrue(app.navigationBars["Weekly shopping"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["week.addShopping"].isEnabled)
        let curd = app.buttons["week.need.Curd"]
        XCTAssertTrue(curd.waitForExistence(timeout: 5))
        curd.tap()
        XCTAssertTrue(app.buttons["week.addShopping"].isEnabled)
        capture("Weekly-Shopping-Review", app: app)
        app.buttons["week.addShopping"].tap()
        tapVisible("week.shopping", app: app)
        XCTAssertFalse(app.buttons["week.need.Curd"].exists)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "Already in shopping")).firstMatch.exists)
    }

    func testListsMealsRowOpens() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        capture("Lists-Redesigned", app: app)
        let meals = app.buttons["home.meals"]
        XCTAssertTrue(meals.waitForExistence(timeout: 5))
        meals.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.8)).tap()
        XCTAssertTrue(app.navigationBars["Meal ideas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["meals.cookingStyle"].exists)
        capture("Lists-Meals-Opened", app: app)
    }

    func testHomeMealsCardOpens() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        let meals = app.buttons["home.meals"]
        XCTAssertTrue(meals.waitForExistence(timeout: 5))
        // Touch the visible card, rather than invoking an accessibility action.
        meals.coordinate(withNormalizedOffset: CGVector(dx: 0.85, dy: 0.8)).tap()
        XCTAssertTrue(app.navigationBars["Meal ideas"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["meals.cookingStyle"].exists)
        capture("Home-Meals-Opened", app: app)
    }

    func testHomeDashboardAndCleanup() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        XCTAssertTrue(app.staticTexts["What you have"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["What to buy"].exists)
        capture("Home-Visual-Dashboard", app: app)
        tapVisible("home.spaces", app: app)
        tapVisible("home.addRoom", app: app)
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.privacy", app: app)
        tapVisible("more.dangerZone", app: app)
        tapVisible("cleanup.shopping", app: app)
        XCTAssertFalse(app.buttons["cleanup.confirm"].isEnabled)
        app.buttons["Cancel"].tap()
        tapVisible("cleanup.pantry", app: app)
        let confirmation = app.textFields["cleanup.confirmation"]
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        confirmation.tap(); confirmation.typeText("CLEAR")
        capture("Danger-Zone-Review", app: app)
        app.buttons["cleanup.confirm"].tap()
        XCTAssertTrue(app.staticTexts["cleanup.status"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["cleanup.pantry"].isEnabled)
        XCTAssertTrue(app.buttons["cleanup.shopping"].isEnabled)
    }

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
        let homeName = app.textFields["setup.householdName"]
        XCTAssertTrue(homeName.waitForExistence(timeout: 5))
        tapVisible("setup.householdName", app: app); homeName.typeText("Our Home")
        app.buttons["setup.keyboardDone"].tap()
        create.tap()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 5))
        app.buttons["Today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["today.quickAdd"].waitForExistence(timeout: 5))
    }

    private func tapVisible(_ id: String, app: XCUIApplication) {
        let element = app.descendants(matching: .any)[id].firstMatch
        reveal(element, app: app)
        XCTAssertTrue(element.waitForExistence(timeout: 5), "Missing \(id)")
        element.tap()
    }

    /// Swipe inside the foreground form, not the whole window: adaptive sheets
    /// can be shorter than the window and whole-app swipes hit the backdrop.
    private func reveal(_ element: XCUIElement, app: XCUIApplication) {
        _ = element.waitForExistence(timeout: 2)
        for _ in 0..<12 {
            guard let snapshot = try? app.snapshot() else { return }
            func descendants(_ node: XCUIElementSnapshot) -> [XCUIElementSnapshot] {
                [node] + node.children.flatMap(descendants)
            }
            let nodes = descendants(snapshot)
            let window = nodes.first { $0.elementType == .window }?.frame ?? app.frame
            let scrollTypes: [XCUIElement.ElementType] = [.scrollView, .collectionView]
            let foreground = nodes.last { scrollTypes.contains($0.elementType)
                && $0.frame.intersection(window).height > 150 }
            let bounds = (foreground?.frame.intersection(window) ?? window).insetBy(dx: 8, dy: 20)
            let top = nodes.filter { $0.elementType == .navigationBar }
                .map { $0.frame.maxY }.max() ?? bounds.minY
            if element.exists && element.isHittable
                && element.frame.midY >= max(top, bounds.minY)
                && element.frame.midY < bounds.maxY { return }
            let down = element.exists && element.frame.midY < max(top, bounds.minY)
            // Resolve only the selected container when gesturing; enumerating live
            // element frames races with SwiftUI replacing the previous screen.
            let surface: XCUIElement
            if let foreground {
                let peers = nodes.filter { $0.elementType == foreground.elementType }
                let index = peers.lastIndex { $0.frame == foreground.frame } ?? 0
                surface = app.descendants(matching: foreground.elementType).element(boundBy: index)
            } else { surface = app }
            guard surface.exists else { continue }
            surface.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.3 : 0.8))
                .press(forDuration: 0.05, thenDragTo: surface.coordinate(
                    withNormalizedOffset: CGVector(dx: 0.5, dy: down ? 0.8 : 0.3)))
        }
    }

    private func saveEntry(_ name: String, app: XCUIApplication) {
        let title = app.textFields["quickAdd.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap(); title.typeText(name)
        app.buttons["quickAdd.save"].tap()
    }

    func testFamilyOwnerCanNameProfile() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.family", app: app)
        let rename = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "family.rename.")).firstMatch
        XCTAssertTrue(rename.waitForExistence(timeout: 5)); rename.tap()
        let name = app.textFields["family.renameName"]
        XCTAssertTrue(name.waitForExistence(timeout: 5))
        name.tap()
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 4) + "Kira")
        app.buttons["family.renameSave"].tap()
        XCTAssertTrue(app.staticTexts["Kira"].firstMatch.waitForExistence(timeout: 5))
        capture("Family-Profile-Name", app: app)
    }

    func testFamilyNativeInvitationUnavailableShowsError() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.family", app: app)
        tapVisible("family.invite", app: app)
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["sharing.named.email"].exists)
        capture("Family-Apple-Sharing-Unavailable", app: app)
        app.alerts.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["family.invite"].isEnabled)
    }

    func testGuidedSetupSavesProgressAndKeepsSkipsSeparate() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.setupGuide", app: app)
        XCTAssertTrue(app.navigationBars["Set up your home"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 of 7 steps reviewed"].waitForExistence(timeout: 5))
        capture("Setup49-Guide", app: app)
        tapVisible("guide.open.pantry", app: app)
        XCTAssertTrue(app.buttons["inventory.add"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["1 of 7 steps reviewed"].waitForExistence(timeout: 5))
        tapVisible("guide.open.pantry", app: app)
        tapVisible("inventory.add", app: app)
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Rice")
        app.buttons["inventory.save"].tap()
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.staticTexts["2 of 7 steps reviewed"].waitForExistence(timeout: 5))
        for _ in 0..<5 { tapVisible("guide.skip", app: app) }
        XCTAssertTrue(app.staticTexts["7 of 7 steps reviewed"].exists)
        XCTAssertTrue(app.staticTexts["2 completed · 5 left for later. Revisit any step below."].exists)
        capture("Setup49-Finished", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertFalse(app.buttons["home.setupGuide"].exists)
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.preferences", app: app)
        tapVisible("more.setupGuide", app: app)
        XCTAssertTrue(app.staticTexts["7 of 7 steps reviewed"].waitForExistence(timeout: 5))
    }

    func testPantryCuminSearchExcludesRiceAndStorageMatches() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.inventory", app: app)
        for name in ["Jeera", "Rice"] {
            tapVisible("inventory.add", app: app)
            app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText(name)
            if name == "Rice" {
                tapVisible("inventory.details", app: app)
                tapVisible("inventory.location", app: app)
                app.textFields["inventory.location"].typeText("Cumin shelf")
            }
            app.buttons["inventory.save"].tap()
        }
        tapVisible("inventory.category.grains", app: app)
        if !app.searchFields.firstMatch.isHittable {
            if app.buttons["Search"].firstMatch.exists { app.buttons["Search"].firstMatch.tap() }
            else { app.swipeDown() }
        }
        XCTAssertTrue(app.searchFields.firstMatch.waitForExistence(timeout: 5))
        app.searchFields.firstMatch.tap(); app.searchFields.firstMatch.typeText("cumin")
        XCTAssertTrue(app.buttons["inventory.item.Jeera"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["inventory.item.Rice"].exists)
        XCTAssertTrue(app.buttons["inventory.item.Jeera"].isHittable)
        XCTAssertTrue(app.staticTexts["1 matching item"].exists)
        capture("Pantry52-CuminSearch", app: app)
    }

    func testAIStatusNavigationAndRefresh() {
        checkAIStatus(largeText: false)
    }
    func testAIStatusLargeText() {
        checkAIStatus(largeText: true)
    }
    private func checkAIStatus(largeText: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"] + (largeText ? ["--large-text", "--dark"] : [])
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.aiStatus", app: app)
        XCTAssertTrue(app.staticTexts["aiStatus.availability"].waitForExistence(timeout: 5))
        tapVisible("aiStatus.refresh", app: app)
        capture(largeText ? "AIStatus51-LargeText" : "AIStatus51", app: app)
        for _ in 0..<6 {
            if app.staticTexts["aiStatus.pantryMode"].exists && app.staticTexts["aiStatus.pantryMode"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["aiStatus.pantryMode"].exists)
        for _ in 0..<6 {
            if app.staticTexts["Last AI results on this device"].isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(app.staticTexts["Last AI results on this device"].exists)
    }

    func testPantryPhotoReviewKeepsExistingStock() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--pantry-photo-fixture"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.inventory", app: app)
        tapVisible("inventory.add", app: app)
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Rice")
        app.buttons["inventory.save"].tap()
        tapVisible("inventory.scanPhoto", app: app)
        XCTAssertTrue(app.staticTexts["pantryPhoto.status"].waitForExistence(timeout: 30))
        XCTAssertFalse(app.buttons["pantryPhoto.save"].isEnabled)
        XCTAssertTrue(app.staticTexts["Already at home · kept unchanged"].exists)
        capture("PantryPhoto50-Review", app: app)
        tapVisible("pantryPhoto.selection", app: app)
        app.buttons["Select new items"].tap()
        app.buttons["pantryPhoto.save"].tap()
        XCTAssertTrue(app.staticTexts["pantryPhoto.success"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["1 item added"].exists)
    }

    func testPantryPhotoLargeTextManualFallback() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--large-text", "--dark"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.inventory", app: app)
        tapVisible("inventory.scanPhoto", app: app)
        capture("PantryPhoto50-LargeText", app: app)
        tapVisible("pantryPhoto.manual", app: app)
        tapVisible("pantryPhoto.name", app: app)
        app.textFields["pantryPhoto.name"].typeText("Banana")
        app.buttons["pantryPhoto.save"].tap()
        XCTAssertTrue(app.staticTexts["pantryPhoto.success"].waitForExistence(timeout: 5))
    }

    func testGuidedSetupLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--large-text", "--dark"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.setupGuide", app: app)
        XCTAssertTrue(app.navigationBars["Set up your home"].waitForExistence(timeout: 5))
        capture("Setup49-LargeText", app: app)
        tapVisible("guide.open.pantry", app: app)
        XCTAssertTrue(app.navigationBars["Groceries at home"].waitForExistence(timeout: 5))
    }

    func testFourTabsAndHomeReminders() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.tabBars.buttons["Lists"].exists)
        app.buttons["Home"].firstMatch.tap()
        XCTAssertFalse(app.buttons["Lists"].exists)
        tapVisible("home.tasks", app: app)
        XCTAssertTrue(app.navigationBars["Tasks & Chores"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.firstMatch.tap()
        tapVisible("home.meals", app: app)
        XCTAssertTrue(app.navigationBars["Meal ideas"].waitForExistence(timeout: 5))
        capture("Four-Tabs-Meals", app: app)
    }

    func testMoreRedesignNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        XCTAssertTrue(app.buttons["more.family"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["more.sharing"].exists)
        XCTAssertFalse(app.staticTexts["Family profiles"].exists)
        XCTAssertFalse(app.staticTexts["Documents"].exists)
        XCTAssertFalse(app.buttons["more.backup"].exists)
        XCTAssertFalse(app.buttons["more.dangerZone"].exists)
        XCTAssertFalse(app.buttons["more.welcome"].exists)
        capture("More-Redesign", app: app)
        tapVisible("more.preferences", app: app)
        XCTAssertTrue(app.buttons["more.warrantyHorizon"].waitForExistence(timeout: 5))
        capture("Preferences-Cards", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        tapVisible("more.privacy", app: app)
        XCTAssertTrue(app.staticTexts["Your home works offline"].waitForExistence(timeout: 5))
        capture("Privacy-Cards", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        tapVisible("more.family", app: app)
        XCTAssertTrue(app.buttons["family.invite"].waitForExistence(timeout: 5))
    }

    func testMoreRedesignLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite", "--large-text", "--dark"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        capture("More-Redesign-Large-Text", app: app)
        tapVisible("more.connections", app: app)
        XCTAssertTrue(app.navigationBars["Connections"].waitForExistence(timeout: 5))
        capture("Connections-Cards", app: app)
    }

    func testFamilyOwnerInvitationDirection() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.family", app: app)
        XCTAssertTrue(app.buttons["family.invite"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["Display name"].exists)
        XCTAssertTrue(app.navigationBars.buttons.firstMatch.isHittable)
        capture("Family-Owner", app: app)
        app.buttons["family.invite"].tap()
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
        XCTAssertFalse(app.textFields["sharing.named.email"].exists)
    }

    func testFamilyOfflineProfileDirection() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.family", app: app)
        XCTAssertFalse(app.buttons["family.invite"].exists)
        XCTAssertTrue(app.buttons["family.sharing"].exists)
        capture("Family-Empty", app: app)
        tapVisible("family.addProfile", app: app)
        XCTAssertFalse(app.buttons["family.saveProfile"].isEnabled)
        app.textFields["family.profileName"].tap()
        app.textFields["family.profileName"].typeText("Kira")
        app.buttons["family.saveProfile"].tap()
        XCTAssertTrue(app.buttons["family.addProfile"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.otherElements["family.empty"].exists)
        capture("Family-Profile-Saved", app: app)
    }

    func testFamilyLargeDark() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-named-invite", "--large-text", "--dark"]
        app.launch()
        XCTAssertTrue(app.buttons["More"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["More"].firstMatch.tap()
        tapVisible("more.family", app: app)
        capture("Family-Large-Dark", app: app)
        tapVisible("family.invite", app: app)
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 10))
    }


    func testIngredientDuplicateWarningAndSeparatePack() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); tapVisible("home.inventory", app: app)
        app.buttons["inventory.add"].tap()
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Cumin")
        app.buttons["inventory.save"].tap()
        app.buttons["inventory.add"].tap()
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Cumin seeds")
        app.buttons["inventory.keyboardDone"].tap()
        XCTAssertTrue(app.staticTexts["Already at home: Cumin"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["inventory.save"].isEnabled)
        tapVisible("inventory.compareAI", app: app)
        XCTAssertTrue(app.staticTexts["On-device AI is unavailable. Offline name and alias checks are still active."].waitForExistence(timeout: 5))
        capture("67-Ingredient-Duplicate-Warning", app: app)
        let separate = app.switches["inventory.separatePack"]
        separate.switches.firstMatch.tap()
        XCTAssertTrue(app.buttons["inventory.save"].isEnabled)
        app.buttons["inventory.save"].tap()
        tapVisible("inventory.reviewDuplicates", app: app)
        XCTAssertTrue(app.staticTexts["Cumin seeds"].waitForExistence(timeout: 5))
        capture("68-Ingredient-Duplicate-Review", app: app)
        app.buttons["Remove extra"].firstMatch.tap()
        app.buttons["Remove Cumin"].tap()
        XCTAssertTrue(app.staticTexts["No matching duplicates"].waitForExistence(timeout: 5))
    }

    func testVisualPantryShelvesAndList() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.ideas", app: app)
        for name in ["Rice", "Toor dal", "Urad dal", "Cumin seeds", "Coconut"] { tapVisible("inventory.idea.\(name)", app: app) }
        app.buttons["inventory.addIdeas"].tap()
        app.buttons["inventory.confirmIdeas"].tap()
        let change = app.buttons["inventory.changeView"]
        if change.label == "Shelves" { change.tap() }
        app.swipeUp()
        XCTAssertTrue(app.buttons["inventory.item.Rice"].waitForExistence(timeout: 5))
        capture("69-Visual-Pantry-Shelves", app: app)
        app.swipeDown(); app.swipeDown()
        capture("70-Visual-Pantry-Overview", app: app)
        tapVisible("inventory.item.Rice", app: app)
        XCTAssertTrue(app.textFields["inventory.name"].waitForExistence(timeout: 5))
        app.buttons["Cancel"].tap()
        app.swipeDown(); app.swipeDown()
        app.buttons["inventory.changeView"].tap()
        XCTAssertEqual(app.buttons["inventory.changeView"].label, "Shelves")
        app.buttons["inventory.changeView"].tap()
        app.buttons["inventory.add"].tap()
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Family special")
        app.buttons["inventory.save"].tap()
        tapVisible("inventory.organizeAI", app: app)
        XCTAssertTrue(app.staticTexts["On-device AI is unavailable. Your visual pantry still works with offline categories."].waitForExistence(timeout: 5))
    }

    func testInventoryExpiryAndLowStock() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); tapVisible("home.inventory", app: app)
        if app.buttons["inventory.changeView"].label == "Shelves" { app.buttons["inventory.changeView"].tap() }
        tapVisible("inventory.attentionDates", app: app)
        app.swipeUp()
        XCTAssertTrue(app.staticTexts["Past expiry"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Expires soon"].exists)
        capture("71-Inventory-Expiry-Colors", app: app)
        app.swipeDown(); app.swipeDown()
        tapVisible("inventory.attentionLow", app: app)
        tapVisible("inventory.item.Rice", app: app)
        let low = app.switches["inventory.lowStock"]
        XCTAssertTrue(low.waitForExistence(timeout: 5))
        XCTAssertEqual(low.value as? String, "1")
        low.switches.firstMatch.tap()
        app.buttons["inventory.save"].tap()
        XCTAssertFalse(app.buttons["inventory.attentionLow"].exists)
    }

    func testLowStockDarkShelf() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--dark"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.attentionLow", app: app)
        app.swipeUp()
        XCTAssertTrue(app.buttons["inventory.item.Rice"].waitForExistence(timeout: 5))
        capture("74-Low-Stock-Dark", app: app)
    }

    func testMatchingShoppingAndInventoryLayout() { matchingShelfLayout(largeText: false) }

    func testTodayAttentionFlow() { todayAttentionFlow(interactive: true) }
    func testTodayAttentionDark() { todayAttentionFlow(dark: true) }
    func testTodayAttentionLargeText() { todayAttentionFlow(largeText: true) }
    func testTodayAttentionLandscape() { todayAttentionFlow(landscape: true) }

    private func todayAttentionFlow(interactive: Bool = false, dark: Bool = false, largeText: Bool = false, landscape: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-today", "--ui-testing-known-groceries"]
        if dark { app.launchArguments.append("--dark") }
        if largeText { app.launchArguments.append("--large-text") }
        if landscape { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { if landscape { XCUIDevice.shared.orientation = .portrait } }
        app.launch()
        XCTAssertTrue(app.buttons["Today"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Today"].firstMatch.tap()
        XCTAssertTrue(app.buttons["today.quickAdd"].waitForExistence(timeout: 5))
        let appearance = landscape ? "Landscape" : largeText ? "Large" : dark ? "Dark" : "Light"
        capture("97-Today-\(appearance)", app: app)
        if interactive {
            tapVisible("today.buy.Milk", app: app)
            tapVisible("shopping.keepInventory.existing", app: app)
            XCTAssertFalse(app.buttons["today.buy.Milk"].exists)
        }
        func select(_ key: String) {
            app.swipeDown(); app.swipeDown(); app.swipeDown()
            if app.buttons["today.priority.\(key)"].exists { tapVisible("today.priority.\(key)", app: app) }
        }
        select("dates")
        let dated = app.buttons["today.dates.Milk"]
        for _ in 0..<6 { if dated.exists && dated.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(dated.exists)
        XCTAssertTrue(dated.label.contains("Past expiry"))
        capture("98-Today-Dates-\(appearance)", app: app)
        if interactive {
            tapVisible("today.dates.Paneer", app: app)
            XCTAssertEqual(app.textFields["inventory.name"].value as? String, "Paneer")
            app.buttons["Cancel"].tap()
        }
        select("restock")
        let restock = app.buttons["today.restock.Rice"]
        for _ in 0..<6 { if restock.exists && restock.isHittable { break }; app.swipeUp() }
        XCTAssertTrue(restock.exists)
        if interactive {
            restock.tap()
            XCTAssertFalse(restock.isEnabled)
            XCTAssertTrue(restock.label.contains("On shopping list"))
        }
        capture("99-Today-Restock-\(appearance)", app: app)
        tapVisible("today.summarize", app: app)
        XCTAssertTrue(app.staticTexts["today.briefSource"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["today.briefSource"].label.contains("Saved-list summary"))
        app.swipeUp()
        capture("100-Today-Brief-\(appearance)", app: app)
        app.swipeUp()
        capture("101-Today-Day-\(appearance)", app: app)
    }

    func testTodayEmptyState() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        XCTAssertTrue(app.staticTexts["No shopping needed now. Later items stay on your list."].exists)
        tapVisible("today.summarize", app: app)
        XCTAssertEqual(app.staticTexts["today.briefText"].label, "Nothing needs attention in your saved lists today.")
        app.buttons["today.quickAdd"].tap()
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
    }

    func testShoppingShelfActionsBelongToOneItem() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        if app.buttons["shopping.changeView"].label == "Shelves" { app.buttons["shopping.changeView"].tap() }
        app.swipeUp()
        let tomato = app.buttons["shopping.item.Tomatoes"]
        for _ in 0..<4 {
            if tomato.exists && tomato.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(tomato.waitForExistence(timeout: 5))
        tapVisible("entry.actions.Tomatoes", app: app)
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "Edit").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "Delete").count, 1)
        capture("96-Shopping-Single-Shelf-Actions", app: app)
        app.buttons["Edit"].tap()
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["quickAdd.title"].value as? String, "Tomatoes")
        app.buttons["Cancel"].tap()
        tomato.swipeLeft()
        XCTAssertEqual(app.buttons.matching(identifier: "Edit").count, 0)
        XCTAssertEqual(app.buttons.matching(identifier: "Delete").count, 0)
    }

    func testShoppingListKeepsSingleSwipeActions() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        if app.buttons["shopping.changeView"].label == "List" { app.buttons["shopping.changeView"].tap() }
        XCTAssertEqual(app.buttons["shopping.changeView"].label, "Shelves")
        app.swipeUp()
        let row = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tomatoes,")).firstMatch
        for _ in 0..<4 {
            if row.exists && row.isHittable { break }
            app.swipeUp()
        }
        row.swipeLeft()
        XCTAssertTrue(app.buttons["Edit"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(identifier: "Edit").count, 1)
        XCTAssertEqual(app.buttons.matching(identifier: "Delete").count, 1)
    }

    func testRedesignedGroceryTools() { redesignedGroceryTools() }
    func testRedesignedGroceryToolsDark() { redesignedGroceryTools(dark: true) }
    func testRedesignedGroceryToolsLargeText() { redesignedGroceryTools(largeText: true) }
    func testRedesignedGroceryToolsLandscape() { redesignedGroceryTools(landscape: true) }

    private func redesignedGroceryTools(largeText: Bool = false, dark: Bool = false, landscape: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-category-hints"]
        if largeText { app.launchArguments.append("--large-text") }
        if dark { app.launchArguments.append("--dark") }
        if landscape { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { if landscape { XCUIDevice.shared.orientation = .portrait } }
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap(); app.staticTexts["Shopping"].tap()
        let appearance = largeText ? "Large" : (dark ? "Dark" : (landscape ? "Landscape" : "Light"))

        for screen in ["shopping", "inventory"] {
            if screen == "inventory" { app.buttons["shopping.inventory"].tap() }
            app.buttons["\(screen).tools"].tap()
            let organize = app.buttons["\(screen).organizeAI"]
            XCTAssertTrue(organize.waitForExistence(timeout: 5))
            let filterCard = app.otherElements["\(screen).filterCard"]
            let organizationCard = app.otherElements["\(screen).organizationCard"]
            XCTAssertTrue(filterCard.exists)
            XCTAssertTrue(organizationCard.exists)
            XCTAssertEqual(filterCard.frame.width, organizationCard.frame.width, accuracy: 1,
                           "Both tool cards must fill the same column")
            XCTAssertEqual(filterCard.frame.minX, organizationCard.frame.minX, accuracy: 1)
            if !largeText {
                XCTAssertGreaterThanOrEqual(organize.frame.height, 44)
                XCTAssertLessThanOrEqual(organize.frame.height, 50, "The AI action must remain compact")
                XCTAssertTrue(app.buttons["\(screen).reviewDuplicates"].isHittable)
            }
            capture("94-\(screen)-Tools-\(appearance)", app: app)

            let filterID = screen == "shopping" ? "shopping.filterWhen" : "inventory.filter"
            tapVisible(filterID, app: app)
            app.buttons[screen == "shopping" ? "Later" : "Low stock"].tap()
            XCTAssertTrue(app.buttons["\(screen).resetFilters"].waitForExistence(timeout: 5))
            if screen == "shopping" {
                app.buttons["shopping.filterBuyer"].tap(); app.buttons["Ravi"].tap()
                XCTAssertEqual(app.buttons["shopping.filterBuyer"].value as? String, "Ravi")
                let bought = app.switches["shopping.showChecked"]
                bought.switches.firstMatch.tap()
                XCTAssertEqual(bought.value as? String, "1")
            }
            app.buttons["\(screen).resetFilters"].tap()
            XCTAssertEqual(app.buttons[filterID].value as? String, screen == "shopping" ? "All" : "At home")
            if screen == "shopping" {
                XCTAssertEqual(app.buttons["shopping.filterBuyer"].value as? String, "Everyone")
                XCTAssertEqual(app.switches["shopping.showChecked"].value as? String, "0")
            }
            XCTAssertFalse(app.buttons["\(screen).resetFilters"].exists)
            tapVisible("\(screen).organizeAI", app: app)
            XCTAssertTrue(app.buttons["\(screen).resetAICategories"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["\(screen).organizationStatus"].exists)
            capture("95-\(screen)-Tools-Applied-\(appearance)", app: app)
            tapVisible("\(screen).resetAICategories", app: app)
            XCTAssertFalse(app.buttons["\(screen).resetAICategories"].exists)
            tapVisible("\(screen).reviewDuplicates", app: app)
            XCTAssertTrue(app.staticTexts["No matching duplicates"].waitForExistence(timeout: 5))
            let navigationTitle = screen == "shopping" ? "Similar shopping items" : "Similar items"
            app.navigationBars[navigationTitle].buttons["Done"].tap()
            XCTAssertTrue(app.buttons["\(screen).tools.done"].waitForExistence(timeout: 5))
            app.buttons["\(screen).tools.done"].tap()
            XCTAssertTrue(app.buttons["\(screen).tools"].waitForExistence(timeout: 5))
        }
    }

    func testMatchingShoppingAndInventoryLargeText() { matchingShelfLayout(largeText: true) }
    func testMatchingShelvesDark() { matchingShelfLayout(largeText: false, dark: true) }
    func testMatchingShelvesLandscape() { matchingShelfLayout(largeText: false, landscape: true) }
    private func matchingShelfLayout(largeText: Bool, dark: Bool = false, landscape: Bool = false) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-known-groceries"]
        if largeText { app.launchArguments.append("--large-text") }
        if dark { app.launchArguments.append("--dark") }
        if landscape { XCUIDevice.shared.orientation = .landscapeLeft }
        defer { if landscape { XCUIDevice.shared.orientation = .portrait } }
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap(); app.staticTexts["Shopping"].tap()
        for screen in ["shopping", "inventory"] {
            if screen == "inventory" { app.buttons["shopping.inventory"].tap() }
            if app.buttons["\(screen).changeView"].label == "Shelves" { app.buttons["\(screen).changeView"].tap() }
            XCTAssertTrue(app.buttons["\(screen).tools"].waitForExistence(timeout: 5))
            XCTAssertFalse(app.buttons["\(screen).organizeAI"].exists)
            XCTAssertTrue(app.buttons["\(screen).category.all"].exists)
            let name = screen == "shopping" ? "Cumin seeds" : "Rice"
            let item = app.buttons["\(screen).item.\(name)"]
            XCTAssertTrue(item.waitForExistence(timeout: 5))
            XCTAssertLessThan(item.frame.minY, app.frame.maxY - 100)
            capture("92-\(screen)-Polish-\(dark ? "Dark" : (landscape ? "Landscape" : (largeText ? "Large" : "Standard")))", app: app)
            app.buttons["\(screen).tools"].tap()
            XCTAssertTrue(app.buttons["\(screen).organizeAI"].waitForExistence(timeout: 5))
            if dark { capture("93-\(screen)-Tools-Dark", app: app) }
            app.buttons["\(screen).tools.done"].tap()
            XCTAssertTrue(app.buttons["\(screen).tools"].waitForExistence(timeout: 5))
        }
    }

    func testCompactShoppingLayout() { compactShoppingLayout(largeText: false) }
    func testCompactShoppingAccessibilityLayout() { compactShoppingLayout(largeText: true) }
    private func compactShoppingLayout(largeText: Bool) {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-known-groceries"]
        if largeText { app.launchArguments.append("--large-text") }
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap(); app.staticTexts["Shopping"].tap()
        if app.buttons["shopping.changeView"].label == "Shelves" { app.buttons["shopping.changeView"].tap() }
        let item = app.buttons["shopping.item.Cumin seeds"]
        XCTAssertTrue(item.waitForExistence(timeout: 5))
        XCTAssertLessThan(item.frame.minY, app.frame.maxY - 100, "First shopping item should begin in the initial viewport")
        XCTAssertTrue(app.buttons["shopping.add"].isHittable)
        capture(largeText ? "85-Compact-Shopping-Accessibility" : "84-Compact-Shopping", app: app)
        app.buttons["shopping.tools"].tap()
        if largeText {
            for _ in 0..<5 {
                if app.buttons["shopping.organizeAI"].exists && app.buttons["shopping.organizeAI"].isHittable { break }
                app.swipeUp()
            }
        }
        XCTAssertTrue(app.buttons["shopping.organizeAI"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["shopping.resetAICategories"].exists)
        capture(largeText ? "87-Shopping-Tools-Accessibility" : "86-Shopping-Tools", app: app)
        app.buttons["shopping.tools.done"].tap()
        XCTAssertTrue(app.buttons["shopping.tools"].waitForExistence(timeout: 5))
    }

    func testShoppingOrganizationControlsStayVisibleForKnownItems() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-known-groceries"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        for screen in ["shopping", "inventory"] {
            if screen == "inventory" {
                if app.buttons["shopping.tools.done"].exists { app.buttons["shopping.tools.done"].tap() }
                app.buttons["shopping.inventory"].tap()
                app.buttons["inventory.tools"].tap()
            } else { app.buttons["shopping.tools"].tap() }
            XCTAssertTrue(app.buttons["\(screen).organizeAI"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.buttons["\(screen).organizeAI"].isEnabled)
            app.buttons["\(screen).organizeAI"].tap()
            XCTAssertTrue(app.staticTexts["\(screen).organizationStatus"].waitForExistence(timeout: 5))
            XCTAssertTrue(app.staticTexts["\(screen).organizationStatus"].label.contains("No AI changes were needed"))
            XCTAssertFalse(app.buttons["\(screen).resetAICategories"].exists)
            capture(screen == "shopping" ? "82-Shopping-AI-Always-Visible" : "83-Inventory-AI-Always-Visible", app: app)
        }
    }

    func testShoppingInventoryCategoryParityAndReset() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-category-hints"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        for screen in ["shopping", "inventory"] {
            if screen == "inventory" {
                if app.buttons["shopping.tools.done"].exists { app.buttons["shopping.tools.done"].tap() }
                app.buttons["shopping.inventory"].tap()
                app.buttons["inventory.tools"].tap()
            } else { app.buttons["shopping.tools"].tap() }
            tapVisible("\(screen).organizeAI", app: app)
            XCTAssertTrue(app.buttons["\(screen).resetAICategories"].waitForExistence(timeout: 5))
            tapVisible("\(screen).category.grains", app: app)
            XCTAssertTrue(app.buttons["\(screen).category.grains"].isSelected)
            capture(screen == "shopping" ? "80-Shopping-Category-Controls" : "81-Inventory-Category-Controls", app: app)
            app.swipeDown(); app.swipeDown()
            tapVisible("\(screen).resetAICategories", app: app)
            XCTAssertFalse(app.buttons["\(screen).resetAICategories"].exists)
            app.buttons["\(screen).tools.done"].tap()
            XCTAssertTrue(app.buttons["\(screen).category.all"].isSelected)
            XCTAssertTrue(app.buttons["\(screen).category.all"].label.contains("4"))
        }
    }

    func testShoppingShelvesPurchaseAndAI() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        if app.buttons["shopping.changeView"].label == "Shelves" { app.buttons["shopping.changeView"].tap() }
        tapVisible("shopping.organizeAI", app: app)
        XCTAssertTrue(app.staticTexts["On-device AI is unavailable. Offline shopping shelves are still available."].waitForExistence(timeout: 5))
        app.swipeDown(); app.swipeDown()
        tapVisible("shopping.changeView", app: app)
        XCTAssertEqual(app.buttons["shopping.changeView"].label, "Shelves")
        tapVisible("shopping.changeView", app: app)
        capture("72-Shopping-Shelves-Header", app: app)
        app.swipeUp()
        tapVisible("shopping.item.Cumin seeds", app: app)
        XCTAssertTrue(app.buttons["shopping.purchaseInventory"].waitForExistence(timeout: 5))
        app.buttons["shopping.purchaseInventory"].tap()
        app.swipeDown(); app.swipeDown()
        tapVisible("shopping.showChecked", app: app)
        app.swipeUp()
        capture("73-Shopping-Shelves-Cards", app: app)
        if app.buttons["shopping.tools.done"].exists { app.buttons["shopping.tools.done"].tap() }
        app.buttons["shopping.inventory"].tap()
        tapVisible("inventory.item.Cumin seeds", app: app)
        XCTAssertTrue(app.textFields["inventory.name"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["inventory.name"].value as? String, "Cumin seeds")
    }

    func testShoppingDuplicateAIAndReview() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        XCTAssertTrue(app.buttons["shopping.add"].waitForExistence(timeout: 5))
        app.buttons["shopping.add"].tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Jeera")
        app.buttons["quickAdd.keyboardDone"].tap()
        XCTAssertTrue(app.staticTexts["Already on your list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["quickAdd.save"].isEnabled)
        tapVisible("shopping.compareAI", app: app)
        XCTAssertTrue(app.staticTexts["shopping.comparisonStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["shopping.comparisonStatus"].label.contains("unavailable"))
        capture("75-Shopping-Duplicate-AI", app: app)
        let separate = app.switches["shopping.allowDuplicate"]
        separate.switches.firstMatch.tap()
        XCTAssertTrue(app.buttons["quickAdd.save"].isEnabled)
        app.buttons["quickAdd.save"].tap()
        tapVisible("shopping.reviewDuplicates", app: app)
        XCTAssertTrue(app.staticTexts["Jeera"].waitForExistence(timeout: 5))
        capture("76-Shopping-Duplicate-Review", app: app)
        app.buttons.matching(NSPredicate(format: "label == %@", "Remove extra")).element(boundBy: 1).tap()
        app.buttons["Remove Jeera"].tap()
        XCTAssertTrue(app.staticTexts["No matching duplicates"].waitForExistence(timeout: 5))
        app.buttons["Done"].tap()
        app.buttons["shopping.add"].tap()
        let title = app.textFields["quickAdd.title"]
        title.tap(); title.typeText("Cummin")
        app.buttons["quickAdd.keyboardDone"].tap()
        XCTAssertTrue(app.staticTexts["Possibly the same item"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["quickAdd.save"].isEnabled)
        title.tap(); title.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 6) + "Ground cumin")
        app.buttons["quickAdd.keyboardDone"].tap()
        XCTAssertTrue(app.buttons["quickAdd.save"].isEnabled)
    }

    func testExpensesUseSavedShoppingStores() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.expenses", app: app)
        tapVisible("expenses.add", app: app)
        let saved = app.buttons["expense.storeSuggestion.Walmart"]
        XCTAssertTrue(saved.waitForExistence(timeout: 5))
        saved.tap()
        XCTAssertEqual(app.textFields["expense.merchant"].value as? String, "Walmart")
        XCTAssertTrue(app.descendants(matching: .any)["expense.storeMatch"].firstMatch.exists)
        capture("Expense-Saved-Shopping-Store", app: app)
        let amount = app.textFields["expense.amount"]; amount.tap(); amount.typeText("12.50")
        app.buttons["expense.save"].tap()
        XCTAssertTrue(app.staticTexts["expenses.total"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["expenses.total"].label.contains("12.50"))
    }

    func testExpenseDashboardMonthlyTracking() { expenseDashboard(largeText: false) }
    func testExpenseDashboardLargeText() { expenseDashboard(largeText: true) }
    private func expenseDashboard(largeText: Bool) {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        if largeText { app.launchArguments += ["--large-text", "--dark"] }
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.expenses", app: app)
        XCTAssertTrue(app.buttons["expenses.add"].waitForExistence(timeout: 5))
        capture("Expenses-Empty", app: app)
        app.buttons["expenses.add"].tap()
        let merchant = app.textFields["expense.merchant"]
        XCTAssertTrue(merchant.waitForExistence(timeout: 5)); merchant.tap(); merchant.typeText("Costco")
        let amount = app.textFields["expense.amount"]; amount.tap(); amount.typeText("42.50")
        app.buttons["expense.save"].tap()
        XCTAssertTrue(app.staticTexts["expenses.total"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["expenses.total"].label.contains("42.50"))
        capture("Expenses-Monthly-Dashboard", app: app)
        app.buttons["expenses.previousMonth"].tap()
        XCTAssertFalse(app.staticTexts["expenses.total"].label.contains("42.50"))
        app.buttons["expenses.nextMonth"].tap()
        XCTAssertTrue(app.staticTexts["expenses.total"].label.contains("42.50"))
    }

    func testDemoAnimationPlaysWithoutSaving() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.connectedDemo", app: app)
        let caption = app.staticTexts["demo.animationCaption"]
        XCTAssertTrue(caption.waitForExistence(timeout: 5))
        let initial = caption.label
        expectation(for: NSPredicate(format: "label != %@", initial), evaluatedWith: caption)
        waitForExpectations(timeout: 8)
        capture("Demo-Animation-In-Motion", app: app)
        app.buttons["demo.play"].tap()
        let paused = caption.label
        app.buttons["demo.next"].tap()
        XCTAssertNotEqual(caption.label, paused)
        capture("Demo-Animation-Next-Scene", app: app)
    }

    func testConnectedDemoFlow() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.connectedDemo", app: app)
        tapVisible("demo.loadReceipt", app: app)
        XCTAssertTrue(app.buttons["receipt.confirm"].waitForExistence(timeout: 20))
        let confirm = app.buttons["receipt.confirm"]
        let ready = NSPredicate(format: "enabled == true")
        expectation(for: ready, evaluatedWith: confirm)
        waitForExpectations(timeout: 30)
        confirm.tap()
        XCTAssertTrue(app.descendants(matching: .any)["receipt.success"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Done"].firstMatch.tap()
        for _ in 0..<4 {
            if app.buttons["demo.next"].isHittable { break }
            app.swipeDown()
        }
        tapVisible("demo.next", app: app)
        capture("Connected-Demo-Flow", app: app)
        tapVisible("demo.tomorrow", app: app)
        XCTAssertTrue(app.staticTexts["demo.mealIdeas"].waitForExistence(timeout: 5))
        capture("Connected-Demo-Meals", app: app)
    }

    func testReceiptReviewAndImport() { receiptReview(largeText: false) }
    func testReceiptReviewLargeText() { receiptReview(largeText: true) }
    func testReceiptReviewLandscape() {
        XCUIDevice.shared.orientation = .landscapeLeft
        defer { XCUIDevice.shared.orientation = .portrait }
        receiptReview(largeText: false)
    }
    private func receiptReview(largeText: Bool) {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-receipt"]
        if largeText { app.launchArguments.append("--large-text") }
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.scanReceipt", app: app)
        XCTAssertTrue(app.buttons["receipt.confirm"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["receipt.confirm"].label, "Save receipt")
        tapVisible("receipt.decodeNames", app: app)
        let decodeStatus = app.staticTexts["receipt.decodeStatus"]
        XCTAssertTrue(decodeStatus.waitForExistence(timeout: 5))
        XCTAssertTrue(decodeStatus.label.contains("unavailable in this test"))
        capture("Receipt-Review", app: app)
        app.buttons["receipt.confirm"].tap()
        XCTAssertTrue(app.descendants(matching: .any)["receipt.success"].firstMatch.waitForExistence(timeout: 5))
        capture("Receipt-Saved", app: app)
        tapVisible("receipt.purchaseDetails", app: app)
        XCTAssertTrue(app.buttons["purchase.expense"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["Purchased items"].exists)
        capture("Purchase-Linked-Details", app: app)
        app.buttons["purchase.expense"].tap()
        XCTAssertTrue(app.buttons["expense.save"].waitForExistence(timeout: 5))
        capture("Purchase-Linked-Expense", app: app)
        if !largeText {
            tapVisible("expense.purchases", app: app)
            XCTAssertTrue(app.staticTexts["Your purchases"].waitForExistence(timeout: 5))
            capture("Purchase-History-Cards", app: app)
        }
    }

    func testMeasuredShoppingRestockUpdatesPantry() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-restock-count"]
        app.launch()
        XCTAssertTrue(app.buttons["Home"].firstMatch.waitForExistence(timeout: 10))
        app.buttons["Home"].firstMatch.tap()
        tapVisible("home.shopping", app: app)
        tapVisible("shopping.item.Rice", app: app)
        XCTAssertTrue(app.staticTexts.matching(NSPredicate(format: "label CONTAINS %@", "1500 g")).firstMatch.waitForExistence(timeout: 5))
        capture("Restock-Quantity-Review", app: app)
        tapVisible("shopping.keepInventory.existing", app: app)
        XCTAssertTrue(app.descendants(matching: .any)["shopping.purchaseConfirmation"].firstMatch.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Dismiss purchase confirmation"].isHittable)
        app.buttons["Dismiss purchase confirmation"].tap()
        tapVisible("shopping.inventory", app: app)
        tapVisible("inventory.item.Rice", app: app)
        tapVisible("inventory.details", app: app)
        let amount = app.textFields["inventory.measuredAmount"]
        for _ in 0..<4 where !amount.isHittable { app.swipeUp() }
        XCTAssertTrue(amount.waitForExistence(timeout: 5))
        XCTAssertEqual(amount.value as? String, "1500")
        capture("Restock-Quantity-Saved", app: app)
    }

    func testShoppingKeepsExistingMilkInventory() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-fresh-milk"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.swipeUp(); app.swipeUp()
        tapVisible("shopping.item.Milk", app: app)
        let keep = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "shopping.keepInventory.")).firstMatch
        XCTAssertTrue(keep.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shopping.separateInventory"].exists)
        capture("77-Shopping-Existing-Inventory", app: app)
        keep.tap()
        app.buttons["shopping.inventory"].tap()
        app.swipeUp()
        XCTAssertEqual(app.buttons.matching(identifier: "inventory.item.Milk").count, 1)
    }

    func testOneExistingMilkActionAndCleanup() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-duplicate-milk"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.swipeUp(); app.swipeUp(); tapVisible("shopping.item.Milk", app: app)
        let existing = app.buttons["shopping.keepInventory.existing"]
        XCTAssertTrue(existing.waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "shopping.keepInventory.")).count, 1)
        capture("78-One-Existing-Milk-Action", app: app)
        existing.tap()
        XCTAssertTrue(app.buttons["shopping.existingPack.1"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["shopping.useSelectedInventory"].isEnabled)
        capture("79-Existing-Milk-Cleanup", app: app)
        app.buttons["shopping.removeExistingPack.0"].tap()
        app.buttons["Remove duplicate"].tap()
        app.buttons["shopping.existingPack.0"].tap()
        XCTAssertEqual(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "shopping.existingPack.")).count, 1)
        XCTAssertTrue(app.buttons["shopping.useSelectedInventory"].isEnabled)
        app.buttons["shopping.useSelectedInventory"].tap()
        XCTAssertTrue(app.buttons["shopping.inventory"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["shopping.inventory"].isHittable)
    }

    func testPantryAndShoppingCanvasTransition() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        capture("Pantry-Unified-Canvas", app: app)
        tapVisible("Open shopping list", app: app)
        XCTAssertTrue(app.buttons["shopping.inventory"].waitForExistence(timeout: 5))
        capture("Shopping-Unified-Canvas", app: app)
        app.navigationBars["Groceries"].buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons["inventory.ideas"].waitForExistence(timeout: 5))
        capture("Pantry-Restored-Canvas", app: app)
    }

    func testKitchenTemplateBulkReview() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.ideas", app: app)
        tapVisible("inventory.selectAllIdeas", app: app)
        let review = app.buttons["inventory.addIdeas"]
        XCTAssertTrue(review.isEnabled)
        let count = Int(review.label.replacingOccurrences(of: "Review ", with: "")) ?? 0
        XCTAssertGreaterThanOrEqual(count, 100)
        review.tap()
        XCTAssertTrue(app.buttons["inventory.confirmIdeas"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.buttons["inventory.confirmIdeas"].label, "Add \(count)")
        tapVisible("inventory.reviewRemove.Rice", app: app)
        XCTAssertEqual(app.buttons["inventory.confirmIdeas"].label, "Add \(count - 1)")
        capture("Pantry-Template-Bulk-Review", app: app)
        app.buttons["inventory.confirmIdeas"].tap()
        XCTAssertTrue(app.buttons["inventory.ideas"].waitForExistence(timeout: 5))
        capture("Pantry-Template-Added", app: app)
    }

    func testEmptyPantryIdeasAreSuggestionsNotSavedStock() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        tapVisible("inventory.ideas", app: app)
        XCTAssertTrue(app.staticTexts["inventory.savedCount"].label.contains("0 ingredients"))
        XCTAssertTrue(app.staticTexts["Starter suggestions"].firstMatch.exists)
        XCTAssertFalse(app.buttons["inventory.addIdeas"].isEnabled)
        tapVisible("inventory.generateIdeas", app: app)
        XCTAssertTrue(app.staticTexts["inventory.ideasStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["inventory.ideasStatus"].label.contains("custom instructions were not applied"))
        XCTAssertFalse(app.buttons["inventory.addIdeas"].isEnabled)
        capture("Pantry-Ideas-Empty-Home", app: app)
    }

    func testInventoryNameOnlyAndSouthIndianReview() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.buttons["Home"].firstMatch.tap(); tapVisible("home.inventory", app: app)
        app.buttons["inventory.add"].tap()
        XCTAssertFalse(app.buttons["inventory.save"].isEnabled)
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Rice")
        app.buttons["inventory.save"].tap()
        XCTAssertTrue(app.buttons["inventory.item.Rice"].waitForExistence(timeout: 5))
        tapVisible("inventory.ideas", app: app)
        XCTAssertFalse(app.buttons["inventory.addIdeas"].isEnabled)
        XCTAssertTrue(app.staticTexts["Starter suggestions"].firstMatch.exists)
        XCTAssertFalse(app.staticTexts["What’s already at home?"].exists)
        XCTAssertTrue(app.staticTexts["inventory.savedCount"].label.contains("1 ingredient"))
        XCTAssertFalse(app.buttons["inventory.idea.Rice"].exists)
        tapVisible("inventory.generateIdeas", app: app)
        XCTAssertTrue(app.staticTexts["inventory.ideasStatus"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["inventory.ideasStatus"].label.contains("starter ideas"))
        tapVisible("inventory.idea.Toor dal", app: app)
        tapVisible("inventory.idea.Urad dal", app: app)
        XCTAssertEqual(app.buttons["inventory.addIdeas"].label, "Review 2")
        capture("62-South-Indian-Pantry-Ideas", app: app)
        app.buttons["inventory.addIdeas"].tap()
        app.buttons["inventory.confirmIdeas"].tap()
        app.swipeUp()
        XCTAssertTrue(app.buttons["inventory.item.Toor dal"].waitForExistence(timeout: 5))
        capture("63-Home-Grocery-Inventory", app: app)
    }

    func testInventoryDarkAndLargeText() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--dark", "--large-text"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); tapVisible("home.inventory", app: app)
        capture("65-Inventory-Large-Dark", app: app)
        app.buttons["inventory.add"].tap()
        app.textFields["inventory.name"].tap(); app.textFields["inventory.name"].typeText("Toor dal")
        app.buttons["inventory.keyboardDone"].tap()
        tapVisible("inventory.details", app: app)
        let expiry = app.switches["inventory.hasExpiryDate"]
        for _ in 0..<8 {
            if expiry.exists && expiry.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(expiry.waitForExistence(timeout: 5))
        expiry.switches.firstMatch.tap()
        XCTAssertEqual(expiry.value as? String, "1")
        XCTAssertTrue(app.datePickers["inventory.expiryDate"].waitForExistence(timeout: 5))
        capture("66-Inventory-Optional-Dates-Dark", app: app)
        app.buttons["inventory.save"].tap()
        XCTAssertTrue(app.navigationBars["Groceries at home"].waitForExistence(timeout: 5))
    }

    func testShoppingPurchaseInventoryAndFriends() {
        let app = XCUIApplication(); app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        for (name, choice) in [("Milk", "shopping.purchaseInventory"), ("Gift chocolates", "shopping.purchaseOnly")] {
            app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
            saveEntry(name, app: app)
            app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", name + ",")).firstMatch.tap()
            if name == "Milk" { capture("64-Shopping-Purchase-Choice", app: app) }
            tapVisible(choice, app: app)
        }
        tapVisible("shopping.inventory", app: app)
        XCTAssertTrue(app.buttons["inventory.item.Milk"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["inventory.item.Gift chocolates"].exists)
        tapVisible("inventory.item.Milk", app: app)
        tapVisible("inventory.usedUp", app: app)
        app.segmentedControls["inventory.filter"].buttons["Used up"].tap()
        tapVisible("inventory.item.Milk", app: app)
        tapVisible("inventory.restock", app: app)
        app.navigationBars.buttons.firstMatch.tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Milk,")).firstMatch.waitForExistence(timeout: 5))
    }

    func testShoppingIdeasReviewBeforeAddingAndFallback() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        tapVisible("shopping.ai.open", app: app)
        capture("44-Shopping-Ideas-Start", app: app)
        app.buttons["shopping.ai.generate"].tap()
        XCTAssertTrue(app.staticTexts["shopping.ai.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["shopping.ai.status"].label.contains("not AI-generated"))
        capture("43-Shopping-Ideas-Review", app: app)
        app.buttons["Cancel"].tap()
        XCTAssertFalse(app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Milk,")).firstMatch.exists)
        tapVisible("shopping.ai.open", app: app)
        app.buttons["shopping.ai.generate"].tap()
        tapVisible("shopping.ai.add", app: app)
        XCTAssertTrue(app.navigationBars["Groceries"].waitForExistence(timeout: 5))
        let milk = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Milk,")).firstMatch
        for _ in 0..<4 { if milk.exists { break }; app.swipeUp() }
        XCTAssertTrue(milk.exists)
    }

    func testShoppingFormDarkAndLargeText() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--dark", "--large-text"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap()
        let shopping = app.staticTexts["Shopping"]
        for _ in 0..<4 { if shopping.isHittable { break }; app.swipeUp() }
        shopping.tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
        capture("45-Shopping-Form-Large-Dark", app: app)
        XCTAssertTrue(app.buttons["quickAdd.save"].isHittable)
        XCTAssertFalse(app.buttons["quickAdd.save"].isEnabled)
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.navigationBars["Groceries"].waitForExistence(timeout: 5))
        capture("46-Shopping-Large-Dark", app: app)
    }

    func testStoreAutofillPersistsAfterCancelAndCompactAction() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        XCTAssertLessThanOrEqual(app.buttons["quickAdd.save"].frame.height, 48)
        tapVisible("shopping.store", app: app)
        app.textFields["shopping.store"].typeText("wal mart")
        capture("61-Store-Keyboard-Autofill", app: app)
        app.buttons["shopping.keyboardStoreSuggestion"].tap()
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Walmart")
        app.buttons["Cancel"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        tapVisible("shopping.savedStoresHeading", app: app)
        XCTAssertTrue(app.staticTexts["shopping.savedStoresHeading"].label.contains("1"))
        app.swipeUp()
        XCTAssertTrue(app.buttons["shopping.storeSuggestion.Walmart"].isHittable)
        capture("60-Saved-Store-Autofill", app: app)
        app.buttons["shopping.storeSuggestion.Walmart"].tap()
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Walmart")
        XCTAssertTrue(app.descendants(matching: .any)["shopping.storeMatch"].firstMatch.exists)
        app.buttons["Cancel"].tap()
        app.tabBars.buttons["Today"].tap(); app.buttons["today.quickAdd"].tap()
        tapVisible("quickAdd.kind", app: app); app.buttons["Shopping item"].tap()
        tapVisible("shopping.store", app: app); app.textFields["shopping.store"].typeText("cos")
        app.buttons["shopping.keyboardStoreSuggestion"].tap()
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Costco")
    }

    func testShoppingInlineStoreUnitsDateAndDuplicateWarning() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Tomato")
        app.textFields["shopping.quantity"].tap(); app.textFields["shopping.quantity"].typeText("2")
        app.buttons["quickAdd.keyboardDone"].tap()
        app.segmentedControls["shopping.when"].buttons["Later"].tap()
        XCTAssertTrue(app.datePickers["shopping.plannedDate"].exists)
        capture("53-Shopping-Amount-And-Date", app: app)
        tapVisible("shopping.store", app: app); app.textFields["shopping.store"].typeText("wal mart")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("shopping.storeSuggestion.Walmart", app: app)
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Walmart")
        capture("54-Shopping-Inline-Store", app: app)
        app.buttons["quickAdd.save"].tap()
        let tomato = app.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Tomato,")).firstMatch
        XCTAssertTrue(tomato.waitForExistence(timeout: 5))
        XCTAssertTrue(tomato.label.contains("2 pieces"))
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Tomato")
        app.buttons["quickAdd.keyboardDone"].tap()
        XCTAssertTrue(app.staticTexts["Already on your list"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["quickAdd.save"].isEnabled)
        capture("55-Shopping-Duplicate-Warning", app: app)
    }

    func testPrivateStoreCreationSurvivesCancelledShoppingItem() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        tapVisible("shopping.browseStores", app: app)
        app.searchFields.firstMatch.tap(); app.searchFields.firstMatch.typeText("Anand Stores")
        tapVisible("shopping.useStore", app: app)
        XCTAssertTrue(app.textFields["shopping.storeName"].waitForExistence(timeout: 5))
        capture("51-Private-Store-Create", app: app)
        app.textFields["shopping.storeBranch"].tap(); app.textFields["shopping.storeBranch"].typeText("Adyar")
        app.buttons["shopping.saveStore"].tap()
        XCTAssertTrue(app.textFields["shopping.store"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Anand Stores · Adyar")
        app.buttons["Cancel"].tap()
        XCTAssertTrue(app.staticTexts["A fresh list"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        tapVisible("shopping.browseStores", app: app)
        XCTAssertTrue(app.staticTexts["Anand Stores · Adyar"].waitForExistence(timeout: 5))
        capture("52-Private-Saved-Stores", app: app)
        app.searchFields.firstMatch.tap(); app.searchFields.firstMatch.typeText("Another store")
        tapVisible("shopping.useStore", app: app)
        let name = app.textFields["shopping.storeName"]
        name.tap(); name.press(forDuration: 1)
        if app.menuItems["Select All"].exists { app.menuItems["Select All"].tap() }
        else { name.tap(withNumberOfTaps: 3, numberOfTouches: 1) }
        name.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: 30) + "Anand Stores")
        app.textFields["shopping.storeBranch"].tap(); app.textFields["shopping.storeBranch"].typeText("Adyar")
        XCTAssertEqual(app.buttons["shopping.saveStore"].label, "Use existing")
        app.buttons["shopping.saveStore"].tap()
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Anand Stores · Adyar")

    }

    func testShoppingStoreCatalogInDarkMode() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--dark"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        capture("49-Shopping-Sage-Dark", app: app)
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Milk")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("shopping.browseStores", app: app)
        XCTAssertTrue(app.navigationBars["Choose a store"].waitForExistence(timeout: 5))
        app.searchFields.firstMatch.tap(); app.searchFields.firstMatch.typeText("wal mart")
        XCTAssertTrue(app.buttons.containing(.staticText, identifier: "Walmart").firstMatch.waitForExistence(timeout: 5))
        capture("50-Shopping-Store-Search", app: app)
        app.buttons.containing(.staticText, identifier: "Walmart").firstMatch.tap()
        XCTAssertEqual(app.textFields["shopping.store"].value as? String, "Walmart")
        app.buttons["quickAdd.save"].tap()
        XCTAssertTrue(app.staticTexts["Walmart"].waitForExistence(timeout: 5))
    }

    func testInvitationTakesPriorityOverNewHomeSetup() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-invitation"]
        app.launch()
        XCTAssertTrue(app.buttons["sharing.accept"].waitForExistence(timeout: 10))
        XCTAssertTrue(app.staticTexts["Join Kira Home"].exists)
        XCTAssertFalse(app.buttons["setup.start"].exists)
        capture("103-Join-Kira-Home", app: app)
        app.buttons["Not now"].tap()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 5))
        tapVisible("setup.join", app: app)
        XCTAssertTrue(app.textFields["sharing.invitationLink"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["sharing.openLink"].isEnabled)
        XCTAssertTrue(app.buttons["sharing.findJoined"].exists)
        capture("104-Join-Home-Fallback", app: app)
    }

    func testAssignedTaskAppearsAndCompletes() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-pantry", "--ui-testing-assignments"]
        app.launch()
        XCTAssertTrue(app.tabBars.buttons["Today"].waitForExistence(timeout: 10))
        app.tabBars.buttons["Today"].tap()
        tapVisible("today.personalShopping", app: app)
        tapVisible("shopping.personalMember", app: app)
        app.buttons["Ravi"].tap()
        tapVisible("personal.task.Take bins out", app: app)
        XCTAssertTrue(app.buttons["Mark completed"].waitForExistence(timeout: 5))
        app.buttons["Mark completed"].tap()
        XCTAssertTrue(app.buttons["Reopen task"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        XCTAssertTrue(app.staticTexts["No tasks assigned to you."].waitForExistence(timeout: 5))
        capture("102-Personal-Tasks", app: app)
    }

    func testPersonalShoppingSummaryAndCompletion() { personalShoppingFlow(largeDark: false) }
    func testPersonalShoppingLargeDark() { personalShoppingFlow(largeDark: true) }
    private func personalShoppingFlow(largeDark: Bool) {
        let app = XCUIApplication()
        app.launchArguments = largeDark ? ["--ui-testing", "--ui-testing-ai-ready", "--dark", "--large-text"] : ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap(); app.buttons["more.family"].tap()
        tapVisible("family.addProfile", app: app)
        app.textFields["Display name"].tap(); app.textFields["Display name"].typeText("Kira")
        app.buttons["Add Person"].tap()
        app.tabBars.buttons["Home"].tap(); app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Milk")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("shopping.buyer", app: app); app.buttons["Kira"].tap()
        app.buttons["quickAdd.save"].tap()
        app.tabBars.buttons["Today"].tap()
        tapVisible("today.personalShopping", app: app)
        tapVisible("shopping.personalMember", app: app); app.buttons["Kira"].tap()
        XCTAssertTrue(app.staticTexts["shopping.personalCount"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["shopping.personalCount"].label.contains("1 item"))
        tapVisible("shopping.personalSummary", app: app)
        XCTAssertTrue(app.staticTexts["List summary · On-device AI isn’t available right now."].waitForExistence(timeout: 5))
        capture(largeDark ? "58-Personal-Shopping-Large-Dark" : "56-Personal-Shopping", app: app)
        tapVisible("shopping.personalComplete.Milk", app: app)
        tapVisible("shopping.purchaseOnly", app: app)
        XCTAssertTrue(app.staticTexts["All caught up"].waitForExistence(timeout: 5))
        capture(largeDark ? "59-Personal-Shopping-Completed-Dark" : "57-Personal-Shopping-Completed", app: app)
    }

    func testShoppingStoreAndBuyer() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap()
        app.buttons["more.family"].tap()
        tapVisible("family.addProfile", app: app)
        app.textFields["Display name"].tap(); app.textFields["Display name"].typeText("Ravi")
        app.buttons["Add Person"].tap()
        app.tabBars.buttons["Home"].tap()
        app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        app.textFields["quickAdd.title"].tap(); app.textFields["quickAdd.title"].typeText("Milk")
        app.textFields["shopping.quantity"].tap(); app.textFields["shopping.quantity"].typeText("2")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("shopping.unit", app: app); app.buttons["cartons"].tap()
        tapVisible("shopping.store", app: app); app.textFields["shopping.store"].typeText("Fresh Market")
        app.buttons["quickAdd.keyboardDone"].tap()
        tapVisible("shopping.buyer", app: app)
        app.buttons["Ravi"].tap()
        app.swipeDown()
        app.segmentedControls["shopping.when"].buttons["Later"].tap()
        capture("41-Shopping-Details", app: app)
        app.buttons["quickAdd.save"].tap()
        XCTAssertTrue(app.staticTexts["Fresh Market"].waitForExistence(timeout: 5))
        let milk = app.buttons.matching(NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", "Milk", "Ravi")).firstMatch
        XCTAssertTrue(milk.waitForExistence(timeout: 5))
        XCTAssertTrue(milk.label.contains("needed later"))
        capture("42-Shopping-By-Store", app: app)
        milk.tap()
        tapVisible("shopping.purchaseOnly", app: app)
        XCTAssertTrue(app.staticTexts["A fresh list"].waitForExistence(timeout: 5))
    }

    func testPrivateBackupDeletionRequiresConfirmationAndKeepsLocalHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.privacy", app: app)
        tapVisible("more.backup", app: app)
        tapVisible("backup.delete", app: app)
        XCTAssertTrue(app.buttons["Delete backups"].waitForExistence(timeout: 5))
        app.navigationBars["iCloud backup"].tap()
        XCTAssertFalse(app.staticTexts["backup.status"].exists)
        tapVisible("backup.delete", app: app)
        app.buttons["Delete backups"].tap()
        XCTAssertTrue(app.staticTexts["backup.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["backup.status"].label.contains("not confirmed"))
        capture("40-Private-Cloud-Deletion", app: app)
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.staticTexts["Our Home"].firstMatch.waitForExistence(timeout: 5))
    }

    func testLiveSharingUnavailablePreservesLocalHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.privacy", app: app)
        tapVisible("more.sync", app: app)
        capture("38-iCloud-Sharing", app: app)
        tapVisible("sharing.enable", app: app)
        app.buttons["Upload and enable sync"].tap()
        XCTAssertTrue(app.staticTexts["sharing.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["sharing.status"].label.contains("unavailable"))
        app.tabBars.buttons["Home"].tap()
        app.buttons["Quick Add"].tap()
        saveEntry("Still works offline", app: app)
        app.staticTexts["Reminders"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Still works offline")).firstMatch.waitForExistence(timeout: 5))
    }

    func testSimpleHomeSetupAndOfflineShopping() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        app.buttons["setup.start"].tap()
        XCTAssertFalse(app.buttons["setup.personal"].exists)
        XCTAssertFalse(app.buttons["setup.family"].exists)
        XCTAssertFalse(app.textFields["setup.owner"].exists)
        XCTAssertFalse(app.buttons["setup.firstRoom"].exists)
        app.textFields["setup.householdName"].tap()
        app.textFields["setup.householdName"].typeText("My Home")
        capture("34-Personal-Setup", app: app)
        app.buttons["setup.create"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
        app.tabBars.buttons["Home"].tap()
        app.staticTexts["Shopping"].tap()
        app.navigationBars.buttons.matching(NSPredicate(format: "label BEGINSWITH %@", "Add")).firstMatch.tap()
        saveEntry("Milk for breakfast", app: app)
        let milk = app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Milk for breakfast")).firstMatch
        XCTAssertTrue(milk.waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["connections.reminders.connect"].exists)
        capture("35-Offline-Shopping", app: app)
        milk.tap()
        tapVisible("shopping.purchaseOnly", app: app)
        XCTAssertTrue(app.staticTexts["A fresh list"].waitForExistence(timeout: 5))
        app.tabBars.buttons["More"].tap()
        tapVisible("more.preferences", app: app)
        tapVisible("more.welcome", app: app)
        XCTAssertTrue(app.buttons["Back to my home"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.create"].exists)
        app.buttons["setup.preview"].tap()
        XCTAssertTrue(app.textFields["setup.householdName"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["setup.create"].exists)
        capture("39-Setup-Preview", app: app)
        app.buttons["Back to my home"].tap()
        XCTAssertTrue(app.tabBars.buttons["Home"].waitForExistence(timeout: 5))
    }

    func testAppleOnlyReminderCreationAndCompletion() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-reminder-sync"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.connections", app: app)
        tapVisible("connections.reminders.open", app: app)
        tapVisible("connections.reminders.connect", app: app)
        tapVisible("reminders.setup.browse", app: app)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Test household")).firstMatch.tap()
        tapVisible("reminders.setup.use", app: app)
        tapVisible("reminders.chooseList", app: app)
        tapVisible("reminders.setup.create", app: app)
        tapVisible("reminders.account", app: app)
        app.buttons["Test household · Test account"].tap()
        tapVisible("reminders.createList", app: app)
        XCTAssertTrue(app.buttons["reminders.chooseList"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminders.chooseList"].label.contains("LunaHearth"))
        tapVisible("reminders.add", app: app)
        saveEntry("Water the plants", app: app)
        let reminder = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "appleReminder.", "Water the plants")).firstMatch
        XCTAssertTrue(reminder.waitForExistence(timeout: 10))
        XCTAssertFalse(app.staticTexts["Existing household tasks"].exists)
        capture("30-Apple-Only-Reminders", app: app)
        tapVisible("reminders.share", app: app)
        XCTAssertTrue(app.staticTexts["reminders.sharing.explanation"].waitForExistence(timeout: 5))
        capture("32-Apple-List-Sharing", app: app)
        app.buttons["Done"].tap()
        reminder.tap()
        XCTAssertTrue(app.staticTexts["A clear list"].waitForExistence(timeout: 5))
    }

    func testShoppingSetupCreatesOnlyAppleItems() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--ui-testing-reminder-sync"]
        app.launch(); createHousehold(app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.connections", app: app)
        tapVisible("connections.shopping.open", app: app)
        tapVisible("connections.reminders.connect", app: app)
        XCTAssertTrue(app.staticTexts["reminders.setup.message"].waitForExistence(timeout: 5))
        capture("31-Apple-List-Setup", app: app)
        tapVisible("reminders.setup.create", app: app)
        tapVisible("reminders.account", app: app)
        app.buttons["Test household · Test account"].tap()
        tapVisible("reminders.createList", app: app)
        XCTAssertTrue(app.buttons["reminders.chooseList"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["reminders.chooseList"].label.contains("LunaHearth Shopping"))
        tapVisible("reminders.add", app: app)
        saveEntry("Milk", app: app)
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "appleReminder.", "Milk")).firstMatch.waitForExistence(timeout: 5))
        XCTAssertFalse(app.staticTexts["Previous shopping items"].exists)
        capture("33-Apple-Shopping", app: app)
    }

    func testOrganizedHomeNavigation() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        createHousehold(app)
        app.buttons["Home"].firstMatch.tap()
        XCTAssertTrue(app.buttons["home.inventory"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["home.shopping"].exists)
        XCTAssertFalse(app.staticTexts["Start here"].exists)
        capture("Home-Organized-Overview", app: app)
        tapVisible("home.addRoom", app: app)
        saveEntry("Bathroom", app: app)
        let room = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.room.", "Bathroom")).firstMatch
        XCTAssertTrue(room.waitForExistence(timeout: 5))
        room.tap()
        XCTAssertTrue(app.buttons["room.addItem"].waitForExistence(timeout: 5))
        capture("Home-Organized-Bathroom", app: app)
    }

    func testHomeEndToEndRoomItemWarrantyAndMaintenance() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        createHousehold(app)
        app.tabBars.buttons["Home"].tap()
        capture("19-Home-Start", app: app)
        tapVisible("home.spaces", app: app)
        tapVisible("home.add", app: app)
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
        tapVisible("maintenance.shopping", app: app)
        XCTAssertTrue(app.textFields["quickAdd.title"].waitForExistence(timeout: 5))
        XCTAssertEqual(app.textFields["quickAdd.title"].value as? String, "Water filter")
        XCTAssertTrue(app.buttons["quickAdd.save"].isEnabled)
        app.buttons["quickAdd.save"].tap()
        capture("23-Home-Care-Completed", app: app)
    }

    func testSetupRestoreAndCloudUnavailableKeepLocalHome() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        app.buttons["setup.restore"].tap()
        app.buttons["backup.find"].tap()
        XCTAssertTrue(app.staticTexts["backup.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["backup.status"].label.contains("unavailable"))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        app.buttons["setup.start"].tap()
        capture("24-Home-Setup", app: app)
        XCTAssertFalse(app.buttons["setup.firstRoom"].exists)
        app.textFields["setup.householdName"].tap()
        app.textFields["setup.householdName"].typeText("Our Home")
        app.buttons["setup.create"].tap()
        XCTAssertTrue(app.buttons["home.addRoom"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.tabBars.buttons["Home"].isSelected)
        tapVisible("home.addRoom", app: app)
        saveEntry("Kitchen", app: app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.privacy", app: app)
        tapVisible("more.backup", app: app)
        capture("25-iCloud-Backup", app: app)
        app.buttons["backup.upload"].tap()
        app.buttons["Save backup"].tap()
        XCTAssertTrue(app.staticTexts["backup.status"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["backup.status"].label.contains("unavailable"))
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@ AND label CONTAINS %@", "home.room.", "Kitchen")).firstMatch.exists)
    }

    func testAppleConnectionsAndNotesDraftKeepLocalModeAvailable() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        createHousehold(app)
        app.tabBars.buttons["More"].tap()
        tapVisible("more.connections", app: app)
        capture("26-Apple-Connections", app: app)
        tapVisible("connections.calendar.connect", app: app)
        XCTAssertTrue(app.staticTexts["connections.calendar.error"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["connections.calendar.error"].label.contains("unavailable"))
        tapVisible("connections.reminders.open", app: app)
        tapVisible("connections.reminders.connect", app: app)
        XCTAssertTrue(app.staticTexts["connections.reminders.error"].waitForExistence(timeout: 5))
        app.navigationBars.buttons.element(boundBy: 0).tap()
        tapVisible("connections.notes", app: app)
        let note = app.textViews["notes.text"]
        XCTAssertTrue(note.waitForExistence(timeout: 5))
        note.tap(); note.typeText("Kitchen filter checklist")
        XCTAssertTrue(app.buttons["notes.share"].isEnabled)
        capture("27-Notes-Sharing", app: app)
        app.tabBars.buttons["Home"].tap()
        XCTAssertTrue(app.buttons["home.addRoom"].waitForExistence(timeout: 5))
    }

    func testLightModeScreensAndQuickAdd() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        capture("01-Welcome-Light", app: app)
        createHousehold(app)
        capture("02-Today-Light", app: app)
        app.buttons["today.quickAdd"].tap()
        let title = app.textFields["quickAdd.title"]
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        title.tap()
        title.typeText("Water the plants")
        capture("03-Quick-Add", app: app)
        XCTAssertTrue(app.buttons["quickAdd.save"].isEnabled)
        app.buttons["quickAdd.save"].tap()
        XCTAssertTrue(app.buttons["today.quickAdd"].waitForExistence(timeout: 5))
        for tab in ["Calendar", "Home", "More"] {
            app.tabBars.buttons[tab].tap()
            capture("04-\(tab)-Light", app: app)
        }
        app.tabBars.buttons["Home"].tap()
        app.staticTexts["Reminders"].tap()
        XCTAssertTrue(app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "Water the plants")).firstMatch.waitForExistence(timeout: 5))
        capture("05-Tasks-Light", app: app)
    }

    func testBuildHomeLayout() {
        let app = XCUIApplication()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready"]
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
            app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", appearance]
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
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--dark"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        capture("36-Welcome-Dark", app: app)
        createHousehold(app)
        capture("06-Today-Dark", app: app)
        app.tabBars.buttons["Home"].tap()
        capture("07-Lists-Dark", app: app)
        app.terminate()
        app.launchArguments = ["--ui-testing", "--ui-testing-ai-ready", "--large-text"]
        app.launch()
        XCTAssertTrue(app.buttons["setup.start"].waitForExistence(timeout: 10))
        capture("37-Welcome-Large-Text", app: app)
        createHousehold(app)
        capture("08-Today-Large-Text", app: app)
        app.swipeUp()
        capture("09-Today-Large-Text-Scrolled", app: app)
    }
}
