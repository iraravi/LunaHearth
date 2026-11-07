import SwiftUI
import UniformTypeIdentifiers

extension UTType {
    static let householdBackup = UTType(exportedAs: "com.neuralluna.household-backup", conformingTo: .data)
}

struct EncryptedBackupDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.householdBackup] }
    let data: Data
    init(data: Data) { self.data = data }
    init(configuration: ReadConfiguration) throws {
        guard let data = configuration.file.regularFileContents, data.count <= BackupEncryption.maximumBytes else { throw PortableBackupError.tooLarge }
        self.data = data
    }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: data) }
}

struct PortableBackupView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var password = ""
    @State private var confirmation = ""
    @State private var busy = false
    @State private var message: String?
    @State private var importing = false
    @State private var exporting = false
    @State private var encryptedInput: Data?
    @State private var document: EncryptedBackupDocument?
    @State private var candidate: PortableBackup?
    @State private var confirmRestore = false
    @State private var operation: Task<Void, Never>?
    private let encryption = BackupEncryption()
    private let files = PortableBackupFiles()
    var onRestore: () -> Void = {}

    var body: some View {
        Form {
            Section {
                Label("A backup you control", systemImage: "lock.doc")
                    .font(.headline)
                Text("Save an encrypted .nlbackup file to Files, a computer or an external drive. No iCloud space or app account is needed. Choose a destination outside this phone for protection if it is lost.")
                Text("Includes the selected home’s records and saved attachments. Apple permissions, calendar/reminder connections and family-sharing access must be set up again after restore.")
                    .font(.footnote).foregroundStyle(.secondary)
            }
            if repository.household != nil {
                Section {
                    Text(repository.household?.name ?? "Home")
                    SecureField("Backup password (12+ characters)", text: $password)
                        .textContentType(.newPassword).accessibilityIdentifier("backup.file.password")
                    SecureField("Confirm backup password", text: $confirmation)
                        .textContentType(.newPassword).accessibilityIdentifier("backup.file.confirmPassword")
                    Button("Export encrypted backup", systemImage: "square.and.arrow.up") { exportBackup() }
                        .disabled(busy || password.count < 12 || password != confirmation)
                        .accessibilityIdentifier("backup.file.export")
                } header: { Text("Export this home") } footer: {
                    Text("Use a long, unique password and store it safely. We cannot recover a forgotten password. This is a manual snapshot; export again after making changes.")
                }
                Section { Text("Restore is available during setup on an empty installation. Your current home will never be overwritten by an imported file.") }
            } else {
                Section("Restore from a file") {
                    Button("Choose backup file", systemImage: "folder") { importing = true }
                        .disabled(busy).accessibilityIdentifier("backup.file.choose")
                    if encryptedInput != nil {
                        SecureField("Backup password", text: $password).accessibilityIdentifier("backup.file.password")
                        Button("Unlock and preview") { unlockBackup() }
                            .disabled(busy || password.isEmpty).accessibilityIdentifier("backup.file.unlock")
                    }
                }
                if let candidate {
                    Section("Review before restoring") {
                        LabeledContent("Home", value: candidate.household.name)
                        LabeledContent("Saved", value: candidate.household.savedAt.formatted(date: .abbreviated, time: .shortened))
                        LabeledContent("Records", value: String(candidate.household.records.count + candidate.documents.count))
                        LabeledContent("Files", value: String(candidate.files.count))
                        Button("Restore this home") { confirmRestore = true }
                            .disabled(busy).accessibilityIdentifier("backup.file.restore")
                    }
                }
            }
            if busy { Section { ProgressView("Preparing backup…").accessibilityIdentifier("backup.file.progress") } }
            if let message { Section { Text(message).textSelection(.enabled).accessibilityIdentifier("backup.file.status") } }
        }
        .navigationTitle("Encrypted backup")
        .navigationBarTitleDisplayMode(.inline)
        .fileExporter(isPresented: $exporting, document: document, contentType: .householdBackup,
                      defaultFilename: "Home-backup") { result in
            switch result {
            case .success: message = "Encrypted backup exported. Keep the file and its password somewhere safe."
            case .failure: message = "The backup was not exported. Your home has not changed. Try another destination with enough storage."
            }
            document = nil
        }
        .fileImporter(isPresented: $importing, allowedContentTypes: [.householdBackup, .data]) { result in
            guard case let .success(url) = result else { return }
            candidate = nil; encryptedInput = nil; password = ""; message = nil; busy = true
            operation = Task { @MainActor in
                defer { busy = false }
                do { let data = try await files.readBackup(at: url); try Task.checkCancellation(); encryptedInput = data }
                catch { show(error) }
            }
        }
        .confirmationDialog("Restore this home?", isPresented: $confirmRestore, titleVisibility: .visible) {
            Button("Restore home") { restoreBackup() }
        } message: { Text("Creates a local home from this backup. It does not reconnect Apple services or automatically share the home.") }
        .onDisappear {
            operation?.cancel(); password = ""; confirmation = ""; candidate = nil; encryptedInput = nil; document = nil
        }
    }

    private func exportBackup() {
        guard !busy else { return }
        busy = true; message = nil
        let secret = password
        password = ""; confirmation = ""
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let (records, metadata, sources) = try repository.portableBackupSources()
                let attachments = try await files.collect(sources)
                try Task.checkCancellation()
                let backup = PortableBackup(formatVersion: 1, household: records, documents: metadata, files: attachments)
                try repository.validatePortableBackup(backup)
                let data = try await encodeAndEncrypt(backup, password: secret)
                try Task.checkCancellation()
                document = EncryptedBackupDocument(data: data); exporting = true
            } catch { show(error) }
        }
    }

    private func unlockBackup() {
        guard !busy, let input = encryptedInput else { return }
        busy = true; message = nil; candidate = nil
        let secret = password; password = ""
        operation = Task { @MainActor in
            defer { busy = false }
            do {
                let backup = try await decryptAndDecode(input, password: secret)
                try Task.checkCancellation()
                try repository.validatePortableBackup(backup)
                candidate = backup; encryptedInput = nil
            } catch { show(error) }
        }
    }

    private func restoreBackup() {
        guard !busy, let backup = candidate else { return }
        busy = true; message = nil
        operation = Task { @MainActor in
            defer { busy = false }
            var directory: String?
            do {
                try repository.validatePortableBackup(backup)
                try Task.checkCancellation()
                let installed = try await files.install(backup.files)
                directory = installed
                try Task.checkCancellation()
                try repository.restorePortableBackup(backup, directory: installed)
                directory = nil // Files are now referenced by a committed store.
                candidate = nil; message = "Home restored. Reconnect optional Apple services when you’re ready."
                if repository.household != nil { onRestore() }
                else { message = "Your backup was saved, but the home could not be opened. Close and reopen the app. Keep it installed to preserve your restored data." }
            } catch {
                if let directory { try? await files.discardInstallation(directory) }
                show(error)
            }
        }
    }

    nonisolated private func encodeAndEncrypt(_ backup: PortableBackup, password: String) async throws -> Data {
        let encoder = JSONEncoder(); encoder.outputFormatting = .sortedKeys
        return try await encryption.encrypt(encoder.encode(backup), password: password)
    }
    nonisolated private func decryptAndDecode(_ data: Data, password: String) async throws -> PortableBackup {
        let plaintext = try await encryption.decrypt(data, password: password)
        return try JSONDecoder().decode(PortableBackup.self, from: plaintext)
    }
    private func show(_ error: Error) {
        if error is CancellationError { return }
        message = (error as? PortableBackupError)?.localizedDescription
            ?? (error as? BackupError)?.localizedDescription
            ?? "The backup operation could not finish. No existing home was replaced. Check the file and available storage, then try again."
    }
}
