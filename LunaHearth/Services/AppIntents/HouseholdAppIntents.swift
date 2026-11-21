import AppIntents
import Foundation

/// The household store Siri reads and writes. It is nil while the saved data can't be opened,
/// so Siri never writes into the temporary recovery store.
@MainActor final class HouseholdIntentStore {
    let repository: LocalHouseholdRepository?
    init(repository: LocalHouseholdRepository?) { self.repository = repository }

    func home() throws -> LocalHouseholdRepository {
        guard let repository else { throw HouseholdIntentError.unavailable }
        try repository.reload()
        guard repository.household != nil else { throw HouseholdIntentError.noHome }
        return repository
    }
}

enum HouseholdIntentError: Error, CustomLocalizedStringResourceConvertible {
    case unavailable, noHome, invalid(String)
    var localizedStringResource: LocalizedStringResource {
        switch self {
        case .unavailable: "Nam Illam can’t open its saved data right now. Open the app and try again."
        case .noHome: "Create or join a home in Nam Illam first."
        case .invalid(let message): "\(message)"
        }
    }
}

/// Words spoken to Siri are the person's own, so these save directly and say what was saved.
/// Anything that needs reading or sorting opens the review screen instead.
struct AddShoppingItemIntent: AppIntent {
    static let title: LocalizedStringResource = "Add to shopping list"
    static let description = IntentDescription("Add an item to your household shopping list.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Item", requestValueDialog: "What do you need?") var item: String
    @Parameter(title: "Amount", default: "") var amount: String
    @Dependency private var store: HouseholdIntentStore
    static var parameterSummary: some ParameterSummary { Summary("Add \(\.$item) to shopping") { \.$amount } }

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = try store.home()
        let parsed = QuickCaptureRules.quantityAndName(item)
        let name = QuickCaptureRules.tidy(parsed.1)
        guard name.contains(where: \.isLetter) else { throw HouseholdIntentError.invalid("Say the item’s name.") }
        if repository.groceries.contains(where: { !$0.isCompleted && IngredientMatching.same($0.name, name) }) {
            return .result(dialog: "\(name) is already on your shopping list.")
        }
        let quantity = amount.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? parsed.0 : amount
        do { try repository.add(EntryDraft(kind: .grocery, title: name, quantity: String(quantity.prefix(40)), quantityUnit: .custom)) }
        catch { throw HouseholdIntentError.invalid(userFacingError(error)) }
        return .result(dialog: "Added \(name) to your shopping list.")
    }
}

struct AddTaskIntent: AppIntent {
    static let title: LocalizedStringResource = "Add a household task"
    static let description = IntentDescription("Add a task to your household list, with an optional due date.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Task", requestValueDialog: "What needs doing?") var task: String
    @Parameter(title: "Due") var due: Date?
    @Dependency private var store: HouseholdIntentStore
    static var parameterSummary: some ParameterSummary { Summary("Add \(\.$task)") { \.$due } }

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = try store.home()
        let reading = QuickCaptureRules.extractDate(task, now: .now, calendar: .current, past: false)
        let title = QuickCaptureRules.taskTitle(reading.rest) ?? QuickCaptureRules.tidy(reading.rest)
        guard title.contains(where: \.isLetter) else { throw HouseholdIntentError.invalid("Say what needs doing.") }
        var draft = EntryDraft(kind: .task, title: title)
        if let date = due ?? reading.date { draft.hasDate = true; draft.date = date }
        do { try repository.add(draft) } catch { throw HouseholdIntentError.invalid(userFacingError(error)) }
        let when = draft.hasDate ? ", due \(draft.date.formatted(.dateTime.weekday(.wide).month().day()))" : ""
        return .result(dialog: "Added “\(title)”\(when).")
    }
}

struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Add an expense"
    static let description = IntentDescription("Record money spent in your household expenses.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Amount", inclusiveRange: (0.01, 9_999_999), requestValueDialog: "How much was it?") var amount: Double
    @Parameter(title: "Where or what", requestValueDialog: "Where or what was it for?") var merchant: String
    @Parameter(title: "Date") var date: Date?
    @Dependency private var store: HouseholdIntentStore
    static var parameterSummary: some ParameterSummary { Summary("Add \(\.$amount) at \(\.$merchant)") { \.$date } }

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = try store.home()
        var draft = ExpenseDraft()
        draft.merchant = QuickCaptureRules.tidy(String(merchant.prefix(200)))
        draft.amount = String(format: "%.2f", locale: Locale(identifier: "en_US_POSIX"), amount)
        draft.currency = QuickCaptureView.householdCurrency(repository.expenses)
        draft.category = QuickCaptureRules.category(for: merchant)
        draft.date = date ?? .now
        do { try repository.saveExpense(draft) } catch { throw HouseholdIntentError.invalid(userFacingError(error)) }
        let money = (try? ExpenseRules.minorUnits(draft.amount)).map { ExpenseRules.money($0, currency: draft.currency) } ?? draft.amount
        return .result(dialog: "Added \(money) at \(draft.merchant) to \(draft.category.rawValue).")
    }
}

struct ShowShoppingListIntent: AppIntent {
    static let title: LocalizedStringResource = "What’s on my shopping list"
    static let description = IntentDescription("Hear what your household needs to buy now.")
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Dependency private var store: HouseholdIntentStore

    @MainActor func perform() async throws -> some IntentResult & ProvidesDialog {
        let repository = try store.home()
        let names = ShoppingListSummary.neededNow(repository.groceries.filter { !$0.isCompleted && $0.neededLater != true }.map(\.name))
        return .result(dialog: "\(ShoppingListSummary.spoken(names))")
    }
}

/// "Add to Nam Illam": a whole note goes to the review screen, where rules (and AI, if chosen) sort it.
struct QuickCaptureIntent: AppIntent {
    static let title: LocalizedStringResource = "Add several things"
    static let description = IntentDescription("Say a note with shopping, tasks, plans and expenses, then review it in the app.")
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Note", requestValueDialog: "What would you like to add?") var note: String
    static var parameterSummary: some ParameterSummary { Summary("Review \(\.$note)") }

    func perform() async throws -> some IntentResult & OpensIntent {
        guard let url = CaptureLink.url(text: note) else { throw HouseholdIntentError.invalid("Try saying that again.") }
        return .result(opensIntent: OpenURLIntent(url))
    }
}

enum ShoppingListSummary {
    /// Unique names in list order, so a spoken list doesn't repeat itself.
    static func neededNow(_ names: [String]) -> [String] {
        var seen = Set<String>()
        return names.map { QuickCaptureRules.tidySpaces($0) }.filter { !$0.isEmpty && seen.insert($0.lowercased()).inserted }
    }

    static func spoken(_ names: [String], limit: Int = 6) -> String {
        guard !names.isEmpty else { return "Your shopping list is clear." }
        let shown = Array(names.prefix(limit))
        let more = names.count - shown.count
        let list = more > 0 ? shown.joined(separator: ", ") + " and \(more) more" : ListFormatter.localizedString(byJoining: shown)
        return "You need \(list)."
    }
}

struct HouseholdShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: AddShoppingItemIntent(), phrases: ["Add to my shopping list in \(.applicationName)", "Add to \(.applicationName) shopping"], shortTitle: "Add shopping", systemImageName: "cart.badge.plus")
        AppShortcut(intent: ShowShoppingListIntent(), phrases: ["What’s on my shopping list in \(.applicationName)", "What do we need from \(.applicationName)"], shortTitle: "Shopping list", systemImageName: "cart")
        AppShortcut(intent: AddTaskIntent(), phrases: ["Add a task in \(.applicationName)", "Add a household task in \(.applicationName)"], shortTitle: "Add task", systemImageName: "checklist")
        AppShortcut(intent: AddExpenseIntent(), phrases: ["Add an expense in \(.applicationName)", "Log spending in \(.applicationName)"], shortTitle: "Add expense", systemImageName: "creditcard")
        AppShortcut(intent: QuickCaptureIntent(), phrases: ["Add several things in \(.applicationName)", "Quick add in \(.applicationName)"], shortTitle: "Add several", systemImageName: "text.badge.plus")
        AppShortcut(intent: DraftAppointmentIntent(), phrases: ["Plan an appointment in \(.applicationName)"], shortTitle: "Plan appointment", systemImageName: "calendar.badge.plus")
        AppShortcut(intent: ShowFamilyCalendarIntent(), phrases: ["Show my family calendar in \(.applicationName)"], shortTitle: "Family calendar", systemImageName: "calendar")
    }
}
