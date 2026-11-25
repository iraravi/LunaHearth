import Foundation
import Testing
@testable import LunaHearth

struct WatchLinkTests {
    let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "America/Chicago")!; return calendar
    }()
    var now: Date { calendar.date(from: DateComponents(year: 2026, month: 11, day: 24, hour: 15))! }

    func item(_ name: String, _ category: PantryCategory, completed: Bool = false, later: Bool = false, modified: Date? = nil) -> WatchSnapshotRules.ShoppingInput {
        .init(id: UUID(), name: name, quantity: nil, store: nil, neededLater: later, isCompleted: completed,
              modifiedAt: modified ?? now.addingTimeInterval(-86_400 * 3), category: category)
    }

    @Test func shoppingKeepsNeededNowAndTodaysBoughtGroupedByAisle() {
        let yesterday = now.addingTimeInterval(-86_400)
        let snapshot = WatchSnapshotRules.snapshot(homeName: "Home", shopping: [
            item("Rice", .grains), item("Bananas", .produce), item("Milk", .chilled),
            item("Party plates", .other, later: true),
            item("Eggs", .chilled, completed: true, modified: now.addingTimeInterval(-600)),
            item("Old bread", .grains, completed: true, modified: yesterday)
        ], tasks: [], applied: [], now: now, calendar: calendar)

        #expect(Set(snapshot.shopping.map(\.name)) == ["Rice", "Bananas", "Milk", "Eggs"])
        #expect(snapshot.itemsLeft == 3)
        // Fresh food first, then dry goods; bought items last.
        #expect(snapshot.aisles.map(\.name) == ["Fruit & vegetables", "Dairy & eggs", "Rice & grains", "Bought"])
        #expect(snapshot.aisles.last?.items.map(\.name) == ["Eggs"])
    }

    @Test func detailJoinsAmountAndStore() {
        var input = item("Milk", .chilled)
        input.quantity = "2 gal"; input.store = "Costco"
        let snapshot = WatchSnapshotRules.snapshot(homeName: nil, shopping: [input], tasks: [], applied: [], now: now, calendar: calendar)
        #expect(snapshot.shopping.first?.detail == "2 gal · Costco")
    }

    @Test func tasksAreDueTodayOrOverdue() {
        let today = calendar.startOfDay(for: now)
        func task(_ title: String, due: Date?, done: Bool = false, modified: Date? = nil) -> WatchSnapshotRules.TaskInput {
            .init(id: UUID(), title: title, dueAt: due, person: nil, isCompleted: done, modifiedAt: modified ?? today.addingTimeInterval(-86_400 * 5))
        }
        let snapshot = WatchSnapshotRules.snapshot(homeName: nil, shopping: [], tasks: [
            task("Today", due: today.addingTimeInterval(3600 * 18)),
            task("Overdue", due: today.addingTimeInterval(-86_400)),
            task("Tomorrow", due: today.addingTimeInterval(86_400 + 3600)),
            task("Someday", due: nil),
            task("Done today", due: today, done: true, modified: now),
            task("Done long ago", due: today.addingTimeInterval(-86_400 * 4), done: true)
        ], applied: [], now: now, calendar: calendar)
        #expect(snapshot.tasks.map(\.title) == ["Overdue", "Done today", "Today"])
        #expect(snapshot.tasksLeft == 2)
        #expect(snapshot.nextTask?.title == "Overdue")
    }

    @Test func watchTapsShowBeforeTheIPhoneConfirms() {
        let snapshot = WatchSnapshotRules.snapshot(homeName: nil, shopping: [item("Milk", .chilled)], tasks: [], applied: [], now: now, calendar: calendar)
        let milk = snapshot.shopping[0]
        let bought = snapshot.applying(WatchAction(kind: .setBought(milk.id, true)))
        #expect(bought.itemsLeft == 0)
        #expect(bought.applying(WatchAction(kind: .setBought(milk.id, false))).itemsLeft == 1)
        // An unknown ID changes nothing.
        #expect(snapshot.applying(WatchAction(kind: .setDone(UUID(), true))) == snapshot)
    }

    @Test func snapshotAndActionsSurviveTheTrip() throws {
        let snapshot = WatchSnapshotRules.snapshot(homeName: "Home", shopping: [item("Milk", .chilled)], tasks: [],
                                                   applied: [UUID()], now: now, calendar: calendar)
        #expect(try WatchSnapshot.decoded(snapshot.encoded()) == snapshot)
        for kind in [WatchAction.Kind.add("milk and bread"), .setBought(UUID(), true), .setDone(UUID(), false)] {
            let action = WatchAction(kind: kind, createdAt: now)
            #expect(try WatchAction.decoded(action.encoded()) == action)
        }
    }

    @Test func onlyTheLatestFiftyAppliedIDsAreSent() {
        let ids = (0..<80).map { _ in UUID() }
        let snapshot = WatchSnapshotRules.snapshot(homeName: nil, shopping: [], tasks: [], applied: ids, now: now, calendar: calendar)
        #expect(snapshot.appliedActionIDs == Array(ids.suffix(50)))
    }

    @Test func dictationSplitsOnAndButKeepsFoodPairs() {
        #expect(WatchSnapshotRules.dictatedList("milk and bread") == "milk, bread")
        #expect(WatchSnapshotRules.dictatedList("Milk and bread and eggs") == "Milk, bread, eggs")
        #expect(WatchSnapshotRules.dictatedList("mac and cheese and apples") == "mac and cheese, apples")
        #expect(WatchSnapshotRules.dictatedList("Half and Half") == "Half and Half")
        // Typed text with commas is left alone.
        #expect(WatchSnapshotRules.dictatedList("bread and butter, jam") == "bread and butter, jam")
        #expect(WatchSnapshotRules.dictatedList("  sandwiches  ") == "sandwiches")
    }

    @Test func dictatedListBecomesSeparateShoppingItems() {
        let items = QuickCaptureRules.parse(WatchSnapshotRules.dictatedList("milk and bread"))
        #expect(items.map(\.title) == ["Milk", "Bread"])
        #expect(items.allSatisfy { $0.kind == .shopping })
    }

    @Test func mealPrepReminderIDsReadSnoozedOnesToo() {
        let home = UUID(), task = UUID()
        #expect(MealPrepReminder.taskID(in: "meal.prep.\(home).\(task)") == task)
        #expect(MealPrepReminder.taskID(in: "meal.prep.\(home).\(task)\(MealPrepReminder.snoozedSuffix)") == task)
        #expect(MealPrepReminder.taskID(in: "meal.prep.daily") == nil)
        let actions = MealPrepReminder.notificationCategory.actions.map(\.identifier)
        #expect(actions == [MealPrepReminder.doneAction, MealPrepReminder.snoozeAction])
    }
}

@MainActor
struct PhoneWatchConnectorTests {
    func make() throws -> (LocalHouseholdRepository, PhoneWatchConnector) {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Sam", members: [("Kim", .adult)])
        let defaults = try #require(UserDefaults(suiteName: "WatchTests.\(UUID().uuidString)"))
        return (repository, PhoneWatchConnector(repository: repository, defaults: defaults))
    }

    @Test func watchTicksSaveOnThePhone() throws {
        let (repository, connector) = try make()
        try repository.add(EntryDraft(kind: .grocery, title: "Milk"))
        try repository.add(EntryDraft(kind: .task, title: "Water plants", date: .now, hasDate: true))
        let milk = try #require(repository.groceries.first), task = try #require(repository.tasks.first)

        connector.apply(WatchAction(kind: .setBought(milk.id, true)))
        connector.apply(WatchAction(kind: .setDone(task.id, true)))
        #expect(milk.isCompleted && task.isCompleted)
        // Actions carry the end state, so a repeat changes nothing.
        connector.apply(WatchAction(kind: .setBought(milk.id, true)))
        #expect(milk.isCompleted)
        connector.apply(WatchAction(kind: .setBought(milk.id, false)))
        #expect(!milk.isCompleted)
        #expect(connector.applied.count == 4)
    }

    @Test func dictationAddsSeparateItemsOnceAndSkipsDuplicates() throws {
        let (repository, connector) = try make()
        try repository.add(EntryDraft(kind: .grocery, title: "Bread"))
        let action = WatchAction(kind: .add("milk and bread and call the plumber"))
        connector.apply(action)
        connector.apply(action)   // delivered twice
        #expect(repository.groceries.map(\.name).sorted() == ["Bread", "Milk"])
        #expect(repository.tasks.map(\.title) == ["Call the plumber"])
        let snapshot = PhoneWatchConnector.snapshot(repository, applied: connector.applied)
        #expect(snapshot.appliedActionIDs == [action.id])
        #expect(snapshot.itemsLeft == 2)
    }
}
