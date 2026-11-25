import Foundation
import Observation
import WatchConnectivity
import WidgetKit

/// The watch's copy of the home. Taps show straight away and are queued until the iPhone
/// confirms them, so the list works in a store with no signal and catches up later.
@MainActor @Observable final class WatchStore: NSObject {
    private(set) var snapshot: WatchSnapshot
    private(set) var pending: [WatchAction]
    private let defaults: UserDefaults

    override init() {
        let defaults = UserDefaults.standard
        self.defaults = defaults
        snapshot = WatchSharedSnapshot.load() ?? .empty
        pending = (defaults.array(forKey: WatchLink.pendingActionsKey) as? [Data] ?? []).compactMap { try? WatchAction.decoded($0) }
        super.init()
    }

    func start() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }

    /// The snapshot with this watch's unconfirmed taps on top.
    var shown: WatchSnapshot { pending.reduce(snapshot) { $0.applying($1) } }
    var hasSynced: Bool { snapshot.updatedAt > .distantPast }
    var waitingAdds: [String] {
        pending.compactMap { if case .add(let text) = $0.kind { text } else { nil } }
    }

    func setBought(_ item: WatchSnapshot.Item, _ bought: Bool) { send(WatchAction(kind: .setBought(item.id, bought))) }
    func setDone(_ task: WatchSnapshot.Task, _ done: Bool) { send(WatchAction(kind: .setDone(task.id, done))) }
    func add(_ text: String) {
        let trimmed = String(text.prefix(WatchLink.maxAddLength)).trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        send(WatchAction(kind: .add(trimmed)))
    }

    private func send(_ action: WatchAction) {
        pending.append(action)
        save()
        deliver(action)
    }

    /// A live message when the iPhone is reachable; otherwise a queued transfer the system
    /// delivers when the devices reconnect.
    private func deliver(_ action: WatchAction) {
        guard WCSession.isSupported(), WCSession.default.activationState == .activated,
              let data = try? action.encoded() else { return }
        let payload = [WatchLink.actionKey: data]
        if WCSession.default.isReachable {
            WCSession.default.sendMessage(payload, replyHandler: nil) { _ in
                Task { @MainActor in _ = WCSession.default.transferUserInfo(payload) }
            }
        } else {
            _ = WCSession.default.transferUserInfo(payload)
        }
    }

    /// Sends anything still waiting, for example after the app was closed before delivery.
    private func resend() {
        let queued = Set(WCSession.default.outstandingUserInfoTransfers.compactMap {
            ($0.userInfo[WatchLink.actionKey] as? Data).flatMap { try? WatchAction.decoded($0) }?.id
        })
        for action in pending where !queued.contains(action.id) { deliver(action) }
    }

    fileprivate func receive(_ snapshot: WatchSnapshot) {
        guard snapshot.updatedAt >= self.snapshot.updatedAt else { return }
        self.snapshot = snapshot
        let confirmed = Set(snapshot.appliedActionIDs)
        pending.removeAll { confirmed.contains($0.id) }
        save()
        WidgetCenter.shared.reloadAllTimelines()
    }

    private func save() {
        WatchSharedSnapshot.save(snapshot)
        defaults.set(pending.compactMap { try? $0.encoded() }, forKey: WatchLink.pendingActionsKey)
    }
}

extension WatchStore: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: (any Error)?) {
        let data = session.receivedApplicationContext[WatchLink.snapshotKey] as? Data
        Task { @MainActor in
            if let data, let snapshot = try? WatchSnapshot.decoded(data) { self.receive(snapshot) }
            if activationState == .activated { self.resend() }
        }
    }
    nonisolated func session(_ session: WCSession, didReceiveApplicationContext applicationContext: [String: Any]) {
        guard let data = applicationContext[WatchLink.snapshotKey] as? Data, let snapshot = try? WatchSnapshot.decoded(data) else { return }
        Task { @MainActor in self.receive(snapshot) }
    }
    nonisolated func sessionReachabilityDidChange(_ session: WCSession) {
        guard session.isReachable else { return }
        Task { @MainActor in self.resend() }
    }
}
