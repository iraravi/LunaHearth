import Foundation

@MainActor
extension EntryDraft {
    static func editing(_ event: FamilyEvent) -> EntryDraft {
        EntryDraft(kind: .event, title: event.title, date: event.startAt, endDate: event.endAt,
                   memberID: event.assignedMemberID, notes: event.notes ?? "", recordID: event.id)
    }
    static func editing(_ task: HouseholdTask) -> EntryDraft {
        EntryDraft(kind: .task, title: task.title, date: task.dueAt ?? .now, hasDate: task.dueAt != nil,
                   memberID: task.assignedMemberID, recordID: task.id)
    }
    static func editing(_ item: GroceryItem) -> EntryDraft {
        EntryDraft(kind: .grocery, title: item.name, quantity: item.quantityText ?? "", recordID: item.id)
    }
    static func editing(_ meal: MealPlanEntry) -> EntryDraft {
        var date = meal.date
        if let key = meal.dateKey {
            let parts = key.split(separator: "-").compactMap { Int($0) }
            if parts.count == 3 {
                var calendar = Calendar(identifier: .gregorian)
                calendar.timeZone = .current
                date = calendar.date(from: DateComponents(year: parts[0], month: parts[1], day: parts[2], hour: 12)) ?? meal.date
            }
        }
        return EntryDraft(kind: .meal, title: meal.title, date: date, notes: meal.notes ?? "", mealType: meal.mealType, recordID: meal.id)
    }
    static func editing(_ room: Room) -> EntryDraft {
        EntryDraft(kind: .room, title: room.name, parentID: room.floorID, recordID: room.id)
    }
    static func editing(_ floor: HomeFloor) -> EntryDraft {
        EntryDraft(kind: .floor, title: floor.name, recordID: floor.id)
    }
    static func editing(_ asset: HomeAsset) -> EntryDraft {
        EntryDraft(kind: .asset, title: asset.name, parentID: asset.roomID, notes: asset.notes ?? "",
                   category: AssetCategory(rawValue: asset.categoryRawValue) ?? .other,
                   manufacturer: asset.manufacturer ?? "", modelNumber: asset.modelNumber ?? "",
                   serialNumber: asset.serialNumber ?? "", recordID: asset.id)
    }
    static func editing(_ warranty: Warranty) -> EntryDraft {
        EntryDraft(kind: .warranty, title: warranty.provider ?? "Warranty", date: warranty.endDate ?? .now,
                   hasDate: warranty.endDate != nil, parentID: warranty.assetID, notes: warranty.notes ?? "", recordID: warranty.id)
    }
    static func editing(_ plan: MaintenancePlan) -> EntryDraft {
        EntryDraft(kind: .maintenance, title: plan.title, date: plan.nextDueAt ?? .now,
                   hasDate: plan.nextDueAt != nil, parentID: plan.assetID, intervalDays: plan.intervalDays ?? 90,
                   repeats: plan.intervalDays != nil, shoppingItem: plan.shoppingItemTemplate ?? "", recordID: plan.id)
    }
}
