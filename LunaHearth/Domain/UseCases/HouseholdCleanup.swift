import Foundation

enum HouseholdCleanupScope: String, CaseIterable, Identifiable {
    case pantry = "Pantry", shopping = "Shopping", meals = "Meals", expenses = "Expenses", tasks = "Tasks"
    var id: String { rawValue }
    var countLabel: String { switch self { case .pantry: "packs"; case .shopping: "items"; case .meals: "meal plans"; case .expenses: "expenses"; case .tasks: "tasks" } }
    var symbol: String { switch self { case .pantry: "cabinet"; case .shopping: "basket"; case .meals: "fork.knife"; case .expenses: "receipt"; case .tasks: "checklist" } }
    var detail: String { switch self {
    case .pantry: "All packs, amounts, expiry dates and stock flags. Shopping and purchase history stay."
    case .shopping: "All pending and bought household shopping items. Pantry, saved stores and purchase history stay."
    case .meals: "All saved meal plans and their linked preparation tasks. Pantry and shopping stay."
    case .expenses: "All expense and refund entries. Purchase history, pantry and shopping stay."
    case .tasks: "All household tasks, including meal preparation tasks. Meal plans stay. Connected Apple Reminders are not erased."
    } }
}
struct HouseholdCleanupPreview: Identifiable {
    let id = UUID()
    let householdID: UUID
    let householdName: String
    let scope: HouseholdCleanupScope
    let recordIDs: Set<UUID>
    let linkedTaskIDs: Set<UUID>
    var count: Int { recordIDs.count }
}
enum HouseholdCleanupError: LocalizedError {
    case changed, confirmation
    var errorDescription: String? { switch self {
    case .changed: "This household or list changed. Close the confirmation and review the new counts before clearing."
    case .confirmation: "Type CLEAR to confirm this cleanup."
    } }
}
