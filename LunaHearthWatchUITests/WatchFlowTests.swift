import XCTest

/// Taps through the watch app against a running iPhone simulator. Start the paired iPhone app
/// first (`--ui-testing --ui-testing-pantry --store-screenshots`); without it the test skips.
/// Leaves one item bought and one task done so the iPhone side can be checked afterwards.
final class WatchFlowTests: XCTestCase {
    override func setUp() { continueAfterFailure = false }

    func testTickItemAndTaskFromWatch() throws {
        let app = XCUIApplication()
        app.launch()

        let toBuy = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", to buy")).firstMatch
        guard toBuy.waitForExistence(timeout: 30) else {
            throw XCTSkip("No shopping items from the iPhone; start the iPhone app first.")
        }
        let left = try itemsLeft(app)
        attach(app, "1-shopping")
        let label = toBuy.label
        let itemName = String(label.split(separator: ",").first ?? "")
        toBuy.tap()
        // A bought item moves to the "Bought" group at the end of the list.
        XCTAssertTrue(app.buttons[label].waitForNonExistence(timeout: 5), "\(itemName) should leave the to-buy list")
        XCTAssertEqual(try itemsLeft(app), left - 1)
        attach(app, "2-bought")

        // Tasks page (the debug argument opens it directly; swiping there needs the crown).
        app.terminate()
        app.launchArguments = ["--watch-tasks"]
        app.launch()
        let open = app.buttons.matching(NSPredicate(format: "label ENDSWITH %@", ", not done")).firstMatch
        XCTAssertTrue(open.waitForExistence(timeout: 15), "an open task should be listed")
        let title = String(open.label.dropLast(", not done".count))
        open.tap()
        XCTAssertTrue(app.buttons["\(title), done"].waitForExistence(timeout: 5), "\(title) should show as done")
        attach(app, "3-task-done")
        print("WATCH-TEST item=\(itemName) task=\(title)")

        // Give the iPhone time to save and send back a snapshot listing both actions.
        sleep(6)
        app.terminate()
        app.launchArguments = []
        app.launch()
        XCTAssertTrue(app.staticTexts["Shopping · \(left - 1)"].waitForExistence(timeout: 15), "\(itemName) should still be bought after relaunch")
        XCTAssertFalse(app.buttons[label].exists)
        attach(app, "4-after-relaunch")
    }

    private func itemsLeft(_ app: XCUIApplication) throws -> Int {
        let title = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Shopping · ")).firstMatch
        XCTAssertTrue(title.waitForExistence(timeout: 5))
        return try XCTUnwrap(Int(title.label.dropFirst("Shopping · ".count)))
    }

    private func attach(_ app: XCUIApplication, _ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
