import Foundation
import Testing
@testable import LunaHearth

struct QuickCaptureTests {
    private static let calendar: Calendar = {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = TimeZone(identifier: "UTC")!; return calendar
    }()
    /// Wednesday 18 November 2026, 10:00 UTC.
    private static let now = calendar.date(from: DateComponents(year: 2026, month: 11, day: 18, hour: 10))!
    private func day(_ value: Int, hour: Int? = nil) -> Date {
        Self.calendar.date(from: DateComponents(year: 2026, month: 11, day: value, hour: hour ?? 0))!
    }
    private func parse(_ text: String) -> [QuickCaptureItem] {
        QuickCaptureRules.parse(text, now: Self.now, calendar: Self.calendar)
    }

    @Test func oneNoteBecomesShoppingTaskEventAndExpense() {
        let items = parse("Costco Saturday, milk, 2 kg rice, change upstairs filter, $45 gas yesterday")
        #expect(items.map(\.kind) == [.event, .shopping, .shopping, .task, .expense])
        #expect(items[0].title == "Costco trip" && items[0].date == day(21))
        #expect(items[1].title == "Milk" && items[1].store == "Costco" && items[1].date == day(21))
        #expect(items[2].title == "Rice" && items[2].quantity == "2 kg")
        #expect(items[3].title == "Change upstairs filter" && items[3].date == nil)
        #expect(items[4].title == "Gas" && items[4].amount == "45" && items[4].currency == "USD")
        #expect(items[4].category == .transport && items[4].date == day(17))
        #expect(items.allSatisfy { $0.source == .rule })
    }

    @Test func andInsideANameStaysOneItem() {
        let items = parse("mac and cheese\nbread")
        #expect(items.map(\.title) == ["Mac and cheese", "Bread"])
    }

    @Test func remindersAndTimesBecomeDatedTasks() {
        let item = parse("remind me to call mom tomorrow at 5").first
        #expect(item?.kind == .task && item?.title == "Call mom")
        #expect(item?.date == day(19, hour: 17) && item?.hasTime == true)
    }

    @Test func appointmentsWithADayAreEvents() {
        let item = parse("Dentist appointment Friday 3pm").first
        #expect(item?.kind == .event && item?.title == "Dentist appointment")
        #expect(item?.date == day(20, hour: 15))
        #expect(parse("dentist appointment").first?.kind == .task)
    }

    @Test func pastSpendingReadsTheLastWeekday() {
        let item = parse("spent $30 at Starbucks Saturday").first
        #expect(item?.title == "Starbucks" && item?.category == .dining && item?.date == day(14))
    }

    @Test func rupeesAndWrittenCurrencies() {
        let items = parse("₹250 auto; paid 1,200 rs for electricity bill")
        #expect(items.map(\.amount) == ["250", "1200"])
        #expect(items.map(\.currency) == ["INR", "INR"])
        #expect(items.map(\.category) == [.transport, .utilities])
        #expect(items[1].title == "Electricity bill")
    }

    @Test func weightsAreNotMoney() {
        let item = parse("2 pounds of rice").first
        #expect(item?.kind == .shopping && item?.title == "Rice" && item?.quantity == "2 pounds")
    }

    @Test func quantitiesInEveryUsualForm() {
        #expect(QuickCaptureRules.quantityAndName("milk x2") == ("2", "milk"))
        #expect(QuickCaptureRules.quantityAndName("a dozen eggs") == ("12", "eggs"))
        #expect(QuickCaptureRules.quantityAndName("a loaf of bread") == ("1 loaf", "bread"))
        #expect(QuickCaptureRules.quantityAndName("3 bananas") == ("3", "bananas"))
        #expect(QuickCaptureRules.quantityAndName("an apple") == ("", "apple"))
    }

    @Test func buyWordsAndStoresAreTrimmedFromItems() {
        let item = parse("buy some paper towels from Target").first
        #expect(item?.kind == .shopping && item?.title == "Paper towels")
        #expect(parse("go to Trader Joe's").isEmpty)
    }

    @Test func modelItemsMustBeGroundedInTheNote() {
        let note = "milk, $45 gas yesterday"
        let candidates = [
            QuickCaptureCandidate(kind: "shopping", title: "Milk", quantity: "2 gallons"),
            QuickCaptureCandidate(kind: "expense", title: "Gas", when: "yesterday", amount: "45"),
            QuickCaptureCandidate(kind: "expense", title: "Gas", amount: "60"),
            QuickCaptureCandidate(kind: "shopping", title: "Organic bananas"),
            QuickCaptureCandidate(kind: "recipe", title: "Milk"),
        ]
        let items = QuickCaptureValidation.items(candidates, text: note, now: Self.now, calendar: Self.calendar)
        #expect(items.map(\.kind) == [.shopping, .expense])
        #expect(items[0].quantity == "", "a quantity the person never wrote is dropped")
        #expect(items[1].amount == "45" && items[1].date == day(17) && items[1].currency == "USD")
        #expect(items.allSatisfy { $0.source == .ai })
    }

    @Test func eachWrittenAmountIsUsedOnce() {
        let candidates = [QuickCaptureCandidate(kind: "expense", title: "Gas", amount: "45"),
                          QuickCaptureCandidate(kind: "expense", title: "Gas again", amount: "45")]
        #expect(QuickCaptureValidation.items(candidates, text: "$45 gas", now: Self.now).count == 1)
    }

    @Test func itemsSaveAsTheRightHouseholdRecords() {
        let items = parse("Costco Saturday, milk, call plumber tomorrow, piano class Friday, $12.50 coffee")
        let milk = items.first { $0.title == "Milk" }?.entryDraft(now: Self.now, calendar: Self.calendar)
        #expect(milk?.kind == .grocery && milk?.storeName == "Costco" && milk?.neededLater == true && milk?.shoppingDate == day(21))
        let call = items.first { $0.kind == .task }?.entryDraft(now: Self.now, calendar: Self.calendar)
        #expect(call?.hasDate == true && call?.date == day(19))
        let piano = items.first { $0.title == "Piano class" }?.entryDraft(now: Self.now, calendar: Self.calendar)
        #expect(piano?.kind == .event && piano?.date == day(20, hour: 9) && piano?.endDate == day(20, hour: 10))
        let coffee = items.first { $0.kind == .expense }
        #expect(coffee?.entryDraft() == nil)
        let expense = coffee?.expenseDraft(defaultCurrency: "INR", now: Self.now)
        #expect(expense?.amount == "12.50" && expense?.currency == "USD" && expense?.category == .dining)
        #expect((try? ExpenseRules.validate(expense!)) != nil)
    }

    @Test func spokenShoppingList() {
        #expect(ShoppingListSummary.spoken([]) == "Your shopping list is clear.")
        let names = ShoppingListSummary.neededNow(["Milk", "milk ", "Eggs", "Bread", "Rice", "Tea", "Sugar", "Salt"])
        #expect(names == ["Milk", "Eggs", "Bread", "Rice", "Tea", "Sugar", "Salt"])
        #expect(ShoppingListSummary.spoken(names) == "You need Milk, Eggs, Bread, Rice, Tea, Sugar and 1 more.")
    }

    @Test func captureLinksRoundTripAndStayBounded() throws {
        let url = try #require(CaptureLink.url(text: "milk, eggs & $5 coffee"))
        #expect(CaptureLink(url: url)?.text == "milk, eggs & $5 coffee")
        #expect(CaptureLink(url: URL(string: "lunahearth://calendar?text=x")!) == nil)
        #expect(QuickCaptureRules.pieces(String(repeating: "a, ", count: 100)).count == QuickCaptureRules.maxItems)
    }
}
