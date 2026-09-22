import SwiftUI

struct BackupView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @AppStorage("backup.lastHousehold") private var lastHousehold = ""
    @AppStorage("backup.lastSavedAt") private var lastSavedAt = 0.0
    @State private var busy = false
    @State private var message: String?
    @State private var candidate: HouseholdBackup?
    @State private var confirmDelete = false
    @State private var confirmUpload = false
    private let service: any HouseholdBackupService
    private let onRestore: () -> Void

    init(service: any HouseholdBackupService = CloudKitBackupService(), onRestore: @escaping () -> Void = {}) {
        self.service = service
        self.onRestore = onRestore
    }

    var body: some View {
        List {
            Section {
                ScreenIntro(eyebrow: "Private iCloud storage", title: "A copy of home.",
                            subtitle: "Save a backup to your Apple Account, then restore it when setting up another device.")
                    .padding(.vertical, 12)
            }.listRowBackground(Color.clear)
            Section {
                Label("Your home always saves on this device first", systemImage: "iphone")
                Label("Only your Apple Account can access this backup", systemImage: "lock.icloud")
                Text("Includes rooms, layouts, items, family profiles, plans, warranties and maintenance. Document and room-scan files are not supported yet.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if repository.household != nil {
                Section {
                    if lastHousehold == repository.household?.id.uuidString, lastSavedAt > 0 {
                        LabeledContent("Last backup from this device", value: Date(timeIntervalSince1970: lastSavedAt).formatted(date: .abbreviated, time: .shortened))
                    }
                    Button("Back up to iCloud", systemImage: "icloud.and.arrow.up") { confirmUpload = true }
                        .accessibilityIdentifier("backup.upload").disabled(busy)
                } footer: {
                    Text("Manual backups replace the previous backup in this Apple Account. These snapshots are separate from live sync and family sharing.")
                }
            } else {
                Section {
                    Button("Find my iCloud backup", systemImage: "icloud.and.arrow.down") { findBackup() }
                        .accessibilityIdentifier("backup.find").disabled(busy)
                } footer: { Text("Nothing is restored until you review the backup below. An internet connection is needed for this step.") }
            }
            Section {
                Button("Delete private iCloud backups", role: .destructive) { confirmDelete = true }
                    .accessibilityIdentifier("backup.delete").disabled(busy)
                Text("Deletes LunaHearth manual backups in this Apple Account. Your local data and live shared homes are kept.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if busy { Section { ProgressView("Connecting to iCloud…").accessibilityIdentifier("backup.progress") } }
            if let message {
                Section { Text(message).accessibilityIdentifier("backup.status").textSelection(.enabled) }
            }
            if let candidate, repository.household == nil {
                Section("Ready to restore") {
                    LabeledContent("Home", value: candidate.name)
                    LabeledContent("Backed up", value: candidate.savedAt.formatted(date: .abbreviated, time: .shortened))
                    LabeledContent("Records", value: "\(candidate.records.count)")
                    Button("Restore this home") {
                        do { try repository.restoreBackup(candidate); onRestore() }
                        catch { message = "The backup could not be restored. Your device was not changed." }
                    }.accessibilityIdentifier("backup.restore").disabled(busy)
                }
            }
        }.hearthList().navigationTitle("iCloud backup").navigationBarTitleDisplayMode(.inline)
            .confirmationDialog("Delete private iCloud backups?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete backups", role: .destructive) { deleteBackups() }
            } message: { Text("Permanently deletes all LunaHearth manual backup generations currently stored in this Apple Account, including older snapshots. You cannot restore them afterward. Local homes, live household sync and Apple Reminders are unchanged.") }
            .confirmationDialog("Save this home to your private iCloud storage?", isPresented: $confirmUpload, titleVisibility: .visible) {
                Button("Save backup") { upload() }
            } message: {
                Text("Household names, profiles, schedules, item details and notes will be sent to Apple iCloud. This replaces your previous LunaHearth backup.")
            }
    }

    private func deleteBackups() {
        guard !busy else { return }
        busy = true; message = nil; candidate = nil
        Task { @MainActor in
            defer { busy = false }
            do {
                try await service.deleteBackups()
                lastHousehold = ""; lastSavedAt = 0
                message = "Private backups deleted. Local data and live shared homes are unchanged."
            } catch { message = "Backup deletion was not confirmed; some snapshots may remain. Retry to finish. " + cloudMessage(error) }
        }
    }

    private func upload() {
        busy = true; message = nil
        Task { @MainActor in
            defer { busy = false }
            do {
                let backup = try repository.makeBackup()
                try await service.upload(backup)
                lastHousehold = backup.householdID.uuidString
                lastSavedAt = backup.savedAt.timeIntervalSince1970
                message = "Backup saved to iCloud at \(backup.savedAt.formatted(date: .abbreviated, time: .shortened)). Later changes need another backup."
            } catch { message = cloudMessage(error) }
        }
    }

    private func findBackup() {
        busy = true; message = nil; candidate = nil
        Task { @MainActor in
            defer { busy = false }
            do {
                let backup = try await service.download()
                try repository.validateBackup(backup)
                candidate = backup
            } catch { message = cloudMessage(error) }
        }
    }

    private func cloudMessage(_ error: Error) -> String {
        if let backupError = error as? BackupError { return backupError.localizedDescription }
        return "iCloud couldn't complete this request. Check your connection and iCloud storage, then try again. Your local home has not been changed."
    }
}
