import Foundation

extension LocalHouseholdRepository {
    func cleanupPreview(_ scope: HouseholdCleanupScope) throws -> HouseholdCleanupPreview {
        guard let household else { throw HouseholdValidation.invalidReference }
        let ids: Set<UUID>
        var linked = Set<UUID>()
        switch scope {
        case .pantry: ids = Set(inventory.map(\.id))
        case .shopping: ids = Set(groceries.map(\.id))
        case .meals:
            ids = Set(meals.map(\.id))
            linked = Set(tasks.filter { $0.mealID.map { ids.contains($0) } ?? false }.map(\.id))
        case .expenses: ids = Set(expenses.map(\.id))
        case .tasks: ids = Set(tasks.map(\.id))
        }
        return HouseholdCleanupPreview(householdID: household.id, householdName: household.name, scope: scope, recordIDs: ids, linkedTaskIDs: linked)
    }
    func clearCategory(_ preview: HouseholdCleanupPreview, confirmation: String) throws {
        guard confirmation == "CLEAR" else { throw HouseholdCleanupError.confirmation }
        guard household?.id == preview.householdID else { throw HouseholdCleanupError.changed }
        let current = try cleanupPreview(preview.scope)
        guard current.recordIDs == preview.recordIDs, current.linkedTaskIDs == preview.linkedTaskIDs else { throw HouseholdCleanupError.changed }
        try commit {
            switch preview.scope {
            case .pantry: for item in inventory { context.delete(item) }
            case .shopping: for item in groceries { context.delete(item) }
            case .expenses: for item in expenses { context.delete(item) }
            case .meals:
                for item in meals { context.delete(item) }
                for task in tasks where preview.linkedTaskIDs.contains(task.id) { context.delete(task) }
            case .tasks: for task in tasks { context.delete(task) }
            }
            let removedTasks = preview.scope == .tasks ? preview.recordIDs : preview.linkedTaskIDs
            for link in reminderDeliveryLinks where removedTasks.contains(link.taskID) { context.delete(link) }
        }
    }
}
