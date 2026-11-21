import Foundation
import Testing
@testable import LunaHearth

struct HouseholdSmartsTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "UTC")!; return calendar
    }()
    /// Wednesday 18 November 2026, 10:00 UTC.
    private static let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 10))!
    private func day(_ value: Int, month: Int = 11) -> Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: month, day: value))!
    }

    // MARK: Repeats

    @Test func repeatRulesRoundTripAndRejectNonsense() {
        let weekly = TaskRepeat(.weekly, every: 2)
        #expect(weekly.rule == "FREQ=WEEKLY;INTERVAL=2" && TaskRepeat(rule: weekly.rule) == weekly)
        #expect(weekly.label == "Every 2 weeks" && TaskRepeat(.daily).label == "Every day")
        #expect(TaskRepeat(rule: "FREQ=HOURLY") == nil && TaskRepeat(rule: "FREQ=DAILY;INTERVAL=0") == nil && TaskRepeat(rule: nil) == nil)
    }

    @Test func spokenRepeats() {
        func read(_ text: String) -> TaskRepeat? { TaskRepeat.read(text, now: Self.now, calendar: Self.calendar)?.repeat }
        #expect(read("water the plants every day") == TaskRepeat(.daily))
        #expect(read("take out trash weekly") == TaskRepeat(.weekly))
        #expect(read("change filter every 3 months") == TaskRepeat(.monthly, every: 3))
        #expect(read("mop every other week") == TaskRepeat(.weekly, every: 2))
        #expect(read("pay rent monthly") == TaskRepeat(.monthly))
        #expect(read("buy milk") == nil)
        let sunday = TaskRepeat.read("clean bathroom every Sunday", now: Self.now, calendar: Self.calendar)
        #expect(sunday?.repeat == TaskRepeat(.weekly) && sunday?.firstDue == day(22) && sunday?.rest == "clean bathroom")
    }

    @Test func nextDueSkipsPastMissedWeeks() {
        let weekly = TaskRepeat(.weekly)
        #expect(weekly.nextDue(after: day(18), completedAt: Self.now, calendar: Self.calendar) == day(25))
        #expect(weekly.nextDue(after: day(1), completedAt: Self.now, calendar: Self.calendar) == day(22))
        #expect(TaskRepeat(.monthly).nextDue(after: day(31, month: 10), completedAt: Self.now, calendar: Self.calendar) == day(30))
    }

    @Test func notesReadRepeatsAndPeople() {
        let items = QuickCaptureRules.parse("Ravi: take out trash every Sunday, clean bathroom weekly, Priya, buy cake for Ravi",
                                            now: Self.now, calendar: Self.calendar, memberNames: ["Ravi", "Priya"])
        #expect(items.count == 3)
        #expect(items[0].title == "Take out trash" && items[0].memberName == "Ravi" && items[0].repeatRule == TaskRepeat(.weekly) && items[0].date == day(22))
        #expect(items[1].title == "Clean bathroom" && items[1].memberName == "Priya")
        #expect(items[2].kind == .shopping && items[2].title == "Cake for Ravi" && items[2].memberName.isEmpty)
        let draft = items[0].entryDraft(now: Self.now, calendar: Self.calendar, memberID: UUID())
        #expect(draft?.recurrenceRule == "FREQ=WEEKLY;INTERVAL=1" && draft?.memberID != nil)
        #expect(QuickCaptureRules.assignee("call the plumber for Ravi", names: ["Ravi"]) == ("Ravi", "call the plumber"))
    }

    // MARK: Task order

    @Test func tasksGroupByUrgency() {
        struct Item { let title: String; let due: Date?; let done: Bool }
        let items = [Item(title: "Later", due: day(30), done: false), Item(title: "Today", due: day(18), done: false),
                     Item(title: "Overdue", due: day(10), done: false), Item(title: "Week", due: day(20), done: false),
                     Item(title: "Free", due: nil, done: false), Item(title: "Done", due: day(1), done: true)]
        let groups = TaskUrgency.grouped(items, due: \.due, completed: \.done, title: \.title, now: Self.now, calendar: Self.calendar)
        #expect(groups.map(\.0) == [.overdue, .today, .soon, .later, .anytime, .done])
        #expect(groups.map { $0.1[0].title } == ["Overdue", "Today", "Week", "Later", "Free", "Done"])
    }

    @Test func shoppingFollowsTheAisles() {
        let names = ["Dish soap", "Chicken", "Milk", "Bread", "Bananas", "Zucchini"]
        let sorted = ShoppingAisle.sorted(names, name: { $0 }, category: { PantryVisualRules.category($0) })
        #expect(sorted == ["Bananas", "Zucchini", "Bread", "Milk", "Chicken", "Dish soap"])
    }

    // MARK: Expenses

    private func expense(_ merchant: String, _ day: String, _ amount: Int, _ category: ExpenseCategory, refund: Bool = false) -> ExpenseReportItem {
        ExpenseReportItem(id: UUID(), merchant: merchant, day: day, amount: amount, currency: "USD", category: category, isRefund: refund, notes: "")
    }

    @Test func categoryComesFromPastChoicesThenTheName() {
        let history = [expense("Costco", "2026-10-02", 100, .home), expense("COSTCO", "2026-10-09", 100, .home), expense("Costco", "2026-10-12", 100, .groceries)]
        #expect(ExpenseInsights.suggestedCategory(for: "costco", history: history)?.category == .home)
        #expect(ExpenseInsights.suggestedCategory(for: "costco", history: history)?.source == .memory)
        #expect(ExpenseInsights.suggestedCategory(for: "Shell gas", history: [])?.category == .transport)
        #expect(ExpenseInsights.suggestedCategory(for: "Shell gas", history: [])?.source == .rule)
        #expect(ExpenseInsights.suggestedCategory(for: "Aunt May", history: []) == nil)
    }

    @Test func possibleDuplicateCharges() {
        let a = expense("Shell", "2026-11-17", 4500, .transport), b = expense("shell", "2026-11-18", 4500, .transport)
        let c = expense("Shell", "2026-11-25", 4500, .transport), refund = expense("Shell", "2026-11-18", 4500, .transport, refund: true)
        let other = expense("Shell", "2026-11-17", 3000, .transport)
        #expect(ExpenseInsights.possibleDuplicates([a, b, c, refund, other]) == [a.id, b.id])
    }

    @Test func monthInPlainWords() {
        let october = ExpenseMonthSummary(month: "2026-10", currency: "USD", items: [expense("Kroger", "2026-10-05", 10_000, .groceries)])
        let november = ExpenseMonthSummary(month: "2026-11", currency: "USD", items: [
            expense("Costco", "2026-11-03", 9_000, .groceries), expense("Kroger", "2026-11-10", 3_000, .groceries)])
        #expect(ExpenseInsights.monthSentence(november, previous: october, previousLabel: "October", inProgress: false)
                == "Groceries up 20% vs October, mostly Costco.")
        #expect(ExpenseInsights.monthSentence(november, previous: october, previousLabel: "October", inProgress: true)
                == "So far, Groceries up 20% vs October, mostly Costco.")
        let quiet = ExpenseMonthSummary(month: "2026-11", currency: "USD", items: [expense("Kroger", "2026-11-03", 5_000, .groceries)])
        #expect(ExpenseInsights.monthSentence(quiet, previous: october, previousLabel: "October", inProgress: true)
                == "So far, Groceries is your biggest spend.", "a half-finished month is never called 'down'")
        let empty = ExpenseMonthSummary(month: "2026-11", currency: "USD", items: [])
        #expect(ExpenseInsights.monthSentence(empty, previous: october, previousLabel: "October", inProgress: true) == nil)
    }
}

@MainActor struct RepeatingTaskStoreTests {
    @Test func completingARepeatingTaskAddsTheNextOneOnce() throws {
        let repository = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repository.createHousehold(name: "Home", owner: "Sam", members: [("Kim", .adult)])
        let kim = try #require(repository.members.first { $0.displayName == "Kim" })
        var draft = EntryDraft(kind: .task, title: "Take out trash", hasDate: true, memberID: kim.id)
        draft.date = Calendar.current.startOfDay(for: .now); draft.recurrenceRule = TaskRepeat(.weekly).rule
        try repository.add(draft)
        let task = try #require(repository.tasks.first)
        try repository.toggle(task)
        let next = try #require(repository.tasks.first { !$0.isCompleted })
        #expect(repository.tasks.count == 2)
        #expect(next.title == "Take out trash" && next.assignedMemberID == kim.id && next.recurrenceRule == task.recurrenceRule)
        #expect(next.dueAt == Calendar.current.date(byAdding: .weekOfYear, value: 1, to: draft.date))
        try repository.toggle(task); try repository.toggle(task)
        #expect(repository.tasks.count == 2, "re-completing never adds a second copy")
        var plain = EntryDraft(kind: .task, title: "Call plumber"); plain.hasDate = false
        try repository.add(plain)
        try repository.toggle(try #require(repository.tasks.first { $0.title == "Call plumber" }))
        #expect(repository.tasks.count == 3)
    }
}
