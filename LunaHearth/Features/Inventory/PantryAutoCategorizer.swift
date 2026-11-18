import SwiftUI

/// Quietly asks the on-device model to place pantry and shopping items the word list
/// does not recognise, then remembers the answer on this phone. Visual only: no network,
/// no record changes, and nothing happens when on-device AI is unavailable or switched off.
private struct PantryAutoCategorizer: ViewModifier {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @AppStorage(PantryCategoryMemory.storageKey) private var stored = ""
    private let service: any PantryCategorizationService = OnDevicePantryCategorizationService()

    private var pending: [String] {
        let names = repository.inventory.filter { !$0.isUsedUp }.map(\.name)
            + repository.groceries.filter { !$0.isCompleted }.map(\.name)
        return PantryCategoryMemory.unknown(names, memory: PantryCategoryMemory.decode(stored))
    }

    func body(content: Content) -> some View {
        content.task(id: pending) {
            let names = pending
            guard !names.isEmpty, aiAvailability.showsAIActions,
                  publicStatus.configuration?.allows(.aiCategories) ?? true else { return }
            // Let quick successive edits settle before asking.
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled,
                  let suggestions = try? await service.categorize(names), !Task.isCancelled else { return }
            stored = PantryCategoryMemory.remember(names, suggestions: suggestions, stored: stored)
        }
    }
}

extension View {
    func pantryAutoCategorizer() -> some View { modifier(PantryAutoCategorizer()) }
}
