import Foundation
import WatchConnectivity

/// The iPhone end of the watch link. It sends the watch a small snapshot whenever the home
/// changes and saves what the watch sends back. Nothing leaves the user's own devices.
@MainActor final class PhoneWatchConnector: NSObject {
    static let shared = PhoneWatchConnector()

    private var repository: LocalHouseholdRepository?
    private(set) var applied: [UUID] = []
    private var lastSent: WatchSnapshot?
    private let defaults: UserDefaults
    private static let appliedKey = "watch.appliedActions.v1"

    /// `repository` is set directly only by tests, which never start the watch session.
    init(repository: LocalHouseholdRepository? = nil, defaults: UserDefaults = .standard) {
        self.repository = repository
        self.defaults = defaults
        super.init()
    }

    /// Starts the link. `repository` is nil while saved data can't be opened, so the watch
    /// never writes into the temporary recovery store.
    func start(repository: LocalHouseholdRepository?) {
        guard WCSession.isSupported(), let repository else { return }
        self.repository = repository
        applied = (defaults.array(forKey: Self.appliedKey) as? [String] ?? []).compactMap(UUID.init(uuidString:))
        let session = WCSession.default
        session.delegate = self
        session.activate()
    }

    /// Sends the latest snapshot if the watch app is installed and something changed.
    func push() {
        guard let repository, WCSession.isSupported() else { return }
        let session = WCSession.default
        guard session.activationState == .activated, session.isPaired, session.isWatchAppInstalled else { return }
        let snapshot = Self.snapshot(repository, applied: applied)
        var comparable = snapshot; comparable.updatedAt = lastSent?.updatedAt ?? snapshot.updatedAt
        guard comparable != lastSent else { return }
        do {
            try session.updateApplicationContext([WatchLink.snapshotKey: snapshot.encoded()])
            lastSent = snapshot
        } catch {
            // The watch keeps its last snapshot; the next change tries again.
        }
    }

    static func snapshot(_ repository: LocalHouseholdRepository, applied: [UUID], now: Date = .now) -> WatchSnapshot {
        let memory = PantryCategoryMemory.decode(UserDefaults.standard.string(forKey: PantryCategoryMemory.storageKey) ?? "")
        let shopping = repository.groceries.map { item in
            WatchSnapshotRules.ShoppingInput(
                id: item.id, name: item.name, quantity: item.quantityText,
                store: { let name = repository.shoppingStoreName(for: item); return name.isEmpty ? nil : name }(),
                neededLater: item.neededLater == true, isCompleted: item.isCompleted, modifiedAt: item.modifiedAt,
                category: PantryVisualRules.category(item.name, memory: memory))
        }
        let tasks = repository.tasks.map { task in
            WatchSnapshotRules.TaskInput(id: task.id, title: task.title, dueAt: task.dueAt,
                                         person: task.assignedMemberID.map { repository.memberName($0) },
                                         isCompleted: task.isCompleted, modifiedAt: task.modifiedAt)
        }
        return WatchSnapshotRules.snapshot(homeName: repository.household?.name, shopping: shopping, tasks: tasks,
                                           applied: applied, now: now)
    }

    /// Saves one watch action. Actions state the end result, so a repeat delivery is harmless;
    /// adds are remembered by ID so they are never saved twice.
    func apply(_ action: WatchAction) {
        guard let repository, !applied.contains(action.id) else { push(); return }
        try? repository.reload()
        guard repository.household != nil else { return }
        do {
            switch action.kind {
            case .setBought(let id, let bought):
                if let item = repository.groceries.first(where: { $0.id == id }), item.isCompleted != bought { try repository.toggle(item) }
            case .setDone(let id, let done):
                if let task = repository.tasks.first(where: { $0.id == id }), task.isCompleted != done { try repository.toggle(task) }
            case .add(let text):
                try add(text, to: repository)
            }
        } catch {
            // Leave the action unapplied; the watch shows it as waiting and the iPhone list is unchanged.
            push(); return
        }
        applied.append(action.id)
        applied = Array(applied.suffix(100))
        defaults.set(applied.map(\.uuidString), forKey: Self.appliedKey)
        push()
    }

    private func add(_ text: String, to repository: LocalHouseholdRepository) throws {
        let list = WatchSnapshotRules.dictatedList(text)
        let items = QuickCaptureRules.parse(list, savedStores: repository.shoppingStoreNames,
                                            memberNames: repository.members.map(\.displayName))
        let currency = QuickCaptureView.householdCurrency(repository.expenses)
        for item in items {
            if item.kind == .shopping,
               repository.groceries.contains(where: { !$0.isCompleted && IngredientMatching.same($0.name, item.title) }) { continue }
            if let draft = item.expenseDraft(defaultCurrency: currency) { try repository.saveExpense(draft); continue }
            let people = repository.members.filter { $0.displayName.caseInsensitiveCompare(item.memberName) == .orderedSame }
            if let draft = item.entryDraft(memberID: people.count == 1 ? people[0].id : nil) { try repository.add(draft) }
        }
    }
}

extension PhoneWatchConnector: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        Task { @MainActor in self.push() }
    }
    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        // Switching to another watch: start again so the new watch gets a snapshot.
        session.activate()
    }
    nonisolated func sessionWatchStateDidChange(_ session: WCSession) {
        Task { @MainActor in self.lastSent = nil; self.push() }
    }
    nonisolated func session(_ session: WCSession, didReceiveMessage message: [String: Any]) {
        receive(message[WatchLink.actionKey] as? Data)
    }
    nonisolated func session(_ session: WCSession, didReceiveUserInfo userInfo: [String: Any] = [:]) {
        receive(userInfo[WatchLink.actionKey] as? Data)
    }
    nonisolated private func receive(_ data: Data?) {
        guard let data, let action = try? WatchAction.decoded(data) else { return }
        Task { @MainActor in self.apply(action) }
    }
}
