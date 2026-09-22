import Foundation
import Observation

@MainActor @Observable final class HouseholdSharingController {
    let service: any HouseholdSharingService
    private(set) var working = false
    private(set) var message: String?
    private(set) var pendingCount = 0
    private(set) var availableHomes: [CloudHome] = []
    private(set) var searched = false
    private(set) var layoutProposals: [BackupRecord] = []
    var invitationError: String?
    private(set) var lookingUpInvitation = false
    var invitation: HouseholdInvitation?
    var shareTicket: HouseholdShareTicket?
    private var retryAt = Date.distantPast
    private var failures = 0

    init(service: any HouseholdSharingService) { self.service = service }

    func sync(_ repository: LocalHouseholdRepository, force: Bool = false) async {
        guard !working, repository.syncConfiguration?.enabled == true,
              force || Date.now >= retryAt else { return }
        working = true
        defer { working = false }
        do { try await performSync(repository) }
        catch is CancellationError { return }
        catch { handle(error, repository: repository) }
    }

    private func performSync(_ repository: LocalHouseholdRepository) async throws {
        guard let configuration = repository.syncConfiguration else { throw HouseholdSharingError.notReady }
        guard !repository.syncBaselines.contains(where: \.conflict) else { throw HouseholdSharingError.conflicts }
        let destination = configuration.destination
        let initial = try repository.makeBackup()
        let baseline = try repository.cloudBaselines()
        pendingCount = HouseholdSyncMerge.plan(local: initial.records, baseline: baseline, remote: baseline).upload.count
        let changes = try await service.changes(in: destination, since: configuration.changeToken)
        try Task.checkCancellation()
        guard repository.household?.id == destination.householdID else { throw HouseholdSharingError.notReady }
        var remote = changes.reset ? [:] : Dictionary(uniqueKeysWithValues: baseline.map { ($0.entity.record.id, $0) })
        for record in changes.records {
            if let previous = baseline.first(where: { $0.entity.record.id == record.entity.record.id }),
               previous.entity.record.kind != record.entity.record.kind || previous.entity.record.householdID != record.entity.record.householdID {
                throw HouseholdSharingError.invalidData
            }
            remote[record.entity.record.id] = record
        }
        if changes.reset, !Set(baseline.map { $0.entity.record.id }).isSubset(of: Set(remote.keys)) {
            throw HouseholdSharingError.accessLost
        }
        // Re-read after the network wait so an edit made while fetching is included.
        let local = try repository.makeBackup()
        let plan = HouseholdSyncMerge.plan(local: local.records, baseline: baseline, remote: Array(remote.values))
        do {
            try repository.applyCloudChanges(plan, remote: Array(remote.values), token: changes.token, writable: changes.writable)
            layoutProposals = []
        } catch LayoutError.overlap {
            layoutProposals = plan.apply.filter { $0.record.kind == "Room" && !$0.deleted }.map(\.record)
            throw LayoutError.overlap
        }
        guard plan.conflicts.isEmpty else { throw HouseholdSharingError.conflicts }
        if !changes.writable {
            pendingCount = plan.upload.count
            try repository.acknowledgeCloudWrites([], completed: pendingCount == 0)
            message = pendingCount == 0 ? "Read-only shared home. Updates download automatically." : "Read-only access. Earlier edits remain on this device and have not been uploaded."
            return
        }
        var upload = plan.upload
        if service.linksCurrentMemberAutomatically, try repository.ensureCurrentCloudMember() {
            let refreshed = try repository.makeBackup(), baselines = try repository.cloudBaselines()
            upload = HouseholdSyncMerge.plan(local: refreshed.records, baseline: baselines, remote: baselines).upload
        }
        let result = try await service.save(upload, in: destination)
        guard repository.household?.id == destination.householdID else { throw HouseholdSharingError.notReady }
        try repository.acknowledgeCloudWrites(result.saved, completed: !result.needsRetry)
        let fresh = try repository.makeBackup(), currentBase = try repository.cloudBaselines()
        pendingCount = HouseholdSyncMerge.plan(local: fresh.records, baseline: currentBase, remote: currentBase).upload.count
        failures = 0; retryAt = .distantPast
        message = result.needsRetry ? "Another device made changes. Sync will reconcile them on the next pass." : nil
    }

    func deleteCloudHome(_ repository: LocalHouseholdRepository, destination: SyncDestination) async {
        guard !working else { return }
        working = true; message = nil
        defer { working = false }
        do {
            try repository.pauseForCloudDeletion(destination)
            try await service.deleteHome(in: destination)
            try repository.finishCloudDeletion(destination)
            pendingCount = 0; layoutProposals = []; shareTicket = nil
            availableHomes.removeAll { $0.destination == destination }
            message = "This home was deleted from iCloud. Your local home is kept and sync is off. Private backups are separate; delete them in iCloud backup if needed."
        } catch {
            message = "Deletion was not confirmed. Sync remains paused for this home; retry when iCloud is available. Local data is preserved. " + HouseholdSharingFailure(error).message
        }
    }

    func enable(_ repository: LocalHouseholdRepository) async {
        guard !working, repository.syncConfiguration == nil else { return }
        working = true; message = nil
        defer { working = false }
        do {
            let backup = try repository.makeBackup()
            let destination = try await service.createHome(householdID: backup.householdID)
            try repository.configureSharing(destination)
            try await performSync(repository)
        } catch { handle(error, repository: repository) }
    }

    func findHomes(_ repository: LocalHouseholdRepository) async {
        guard !working else { return }
        working = true; message = nil
        defer { working = false; searched = true }
        do { availableHomes = try await service.availableHomes() }
        catch { handle(error, repository: repository) }
    }

    func open(_ destination: SyncDestination, repository: LocalHouseholdRepository) async {
        guard !working else { return }
        working = true; message = nil
        defer { working = false }
        do { try await load(destination, repository: repository) }
        catch { handle(error, repository: repository) }
    }

    private func load(_ destination: SyncDestination, repository: LocalHouseholdRepository) async throws {
        var initialUploadError: (any Error)?
        if repository.households.contains(where: { $0.id == destination.householdID }) {
            try repository.activateHousehold(destination.householdID)
            try repository.configureSharing(destination)
            try await performSync(repository)
        } else {
            let changes = try await service.changes(in: destination, since: nil)
            try repository.importSharedHome(destination, changes: changes)
            if service.linksCurrentMemberAutomatically {
                // Joining already succeeded; retain the local profile if its first upload is offline.
                _ = try repository.ensureCurrentCloudMember()
                do { try await performSync(repository) }
                catch { initialUploadError = error }
            }
        }
        invitation = nil; message = nil; retryAt = .distantPast
        if let initialUploadError { handle(initialUploadError, repository: repository) }
    }

    func lookupInvitation(_ text: String) async {
        guard !lookingUpInvitation else { return }
        guard let url = HouseholdInvitationLink.url(from: text), let lookup = service as? any HouseholdInvitationLookupService else {
            invitationError = "Use the iCloud household invitation link from the email or message."; return
        }
        lookingUpInvitation = true; invitationError = nil
        defer { lookingUpInvitation = false }
        do {
            let resolved = try await lookup.invitation(for: url)
            try Task.checkCancellation()
            invitation = resolved
        } catch { if !Task.isCancelled { invitationError = HouseholdSharingFailure(error).message } }
    }

    func acceptInvitation(_ repository: LocalHouseholdRepository) async {
        guard !working, let invitation else { return }
        working = true; message = nil
        defer { working = false }
        do {
            let destination = try await service.accept(invitation)
            try await load(destination, repository: repository)
        } catch { handle(error, repository: repository) }
    }

    func prepareNamedInvitation(ownerName: String, name: String, email: String,
                                repository: LocalHouseholdRepository) async throws -> URL {
        // Background sync must not make an otherwise valid invitation a silent no-op.
        // Wait without overlapping writes, then revalidate the same home's access.
        let requestedDestination = repository.syncConfiguration?.destination
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        while working {
            guard ContinuousClock.now < deadline else { throw HouseholdSharingError.notReady }
            try await Task.sleep(for: .milliseconds(100))
        }
        try Task.checkCancellation()
        guard repository.syncConfiguration?.destination == requestedDestination,
              let configuration = repository.syncConfiguration,
              configuration.enabled, configuration.isOwner, !configuration.recovery, !configuration.readOnly,
              let service = service as? any NamedHouseholdInvitationService else { throw HouseholdSharingError.notReady }
        _ = try HouseholdRules.requiredName(ownerName)
        _ = try HouseholdRules.requiredName(name)
        guard email.contains("@"), !email.contains(where: \.isWhitespace) else { throw NamedInvitationError.recipientUnavailable }
        working = true; message = nil
        defer { working = false }
        let destination = configuration.destination
        let account = try await service.resolveRecipient(email: email, in: destination)
        guard repository.syncConfiguration?.destination == destination else { throw HouseholdSharingError.notReady }
        try repository.prepareNamedMembers(ownerName: ownerName, recipientName: name, accountID: account)
        // Upload the named profile before granting access so the first import contains it.
        try await performSync(repository)
        guard pendingCount == 0, repository.syncConfiguration?.destination == destination else { throw HouseholdSharingError.notReady }
        return try await service.inviteRecipient(accountID: account, in: destination, title: repository.household?.name ?? "Our Home")
    }

    func prepareInvitation(_ repository: LocalHouseholdRepository) async {
        let requestedDestination = repository.syncConfiguration?.destination
        let deadline = ContinuousClock.now.advanced(by: .seconds(30))
        do {
            while working {
                guard ContinuousClock.now < deadline else { throw HouseholdSharingError.notReady }
                try await Task.sleep(for: .milliseconds(100))
            }
            try Task.checkCancellation()
            guard repository.syncConfiguration?.destination == requestedDestination else { throw HouseholdSharingError.notReady }
        } catch { message = error.localizedDescription; return }
        shareTicket = nil
        await sync(repository, force: true)
        guard !working else { return }
        guard pendingCount == 0, let configuration = repository.syncConfiguration,
              message == nil || configuration.readOnly,
              !configuration.recovery, !repository.syncBaselines.contains(where: \.conflict) else {
            if message == nil { message = HouseholdSharingError.notReady.localizedDescription }
            return
        }
        working = true
        defer { working = false }
        do { shareTicket = try await service.prepareShare(in: configuration.destination, title: repository.household?.name ?? "Our Home") }
        catch { handle(error, repository: repository) }
    }

    func resolveConflicts(useCloud: Bool, repository: LocalHouseholdRepository) async {
        guard !working else { return }
        do {
            try repository.resolveCloudConflicts(useCloud: useCloud)
            message = nil
            await sync(repository, force: true)
        } catch { handle(error, repository: repository) }
    }

    func report(_ error: Error, repository: LocalHouseholdRepository) { handle(error, repository: repository) }
    private func handle(_ error: Error, repository: LocalHouseholdRepository) {
        let failure = HouseholdSharingFailure(error)
        message = failure.message
        failures = min(failures + 1, 5)
        retryAt = .now.addingTimeInterval(max(failure.retryAfter, min(300, pow(2, Double(failures)) * 5)))
        if failure.recovery { try? repository.markCloudRecovery() }
    }
}
