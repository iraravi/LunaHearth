import SwiftUI

struct DangerZoneView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var preview: HouseholdCleanupPreview?
    @State private var error: String?
    @State private var status: String?
    var body: some View {
        List {
            Section {
                Label("Clear one area at a time", systemImage: "exclamationmark.triangle").font(.headline)
                Text(repository.household?.name ?? "Your household").font(.subheadline)
                Text("Choose an area, review its contents, then confirm. These changes cannot be undone in the app.").foregroundStyle(.secondary)
            }
            if let status { Section { Label(status, systemImage: "checkmark.circle").accessibilityIdentifier("cleanup.status") } }
            Section {
                ForEach(HouseholdCleanupScope.allCases) { scope in
                    let count = (try? repository.cleanupPreview(scope).count) ?? 0
                    Button {
                        do { preview = try repository.cleanupPreview(scope) } catch { self.error = userFacingError(error) }
                    } label: {
                        HStack(spacing: 14) {
                            Image(systemName: scope.symbol).foregroundStyle(.red).frame(width: 30).accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Clear \(scope.rawValue.lowercased())").font(.headline).foregroundStyle(.primary)
                                Text("\(count) \(scope.countLabel)").font(.subheadline).foregroundStyle(.secondary)
                            }
                            Spacer(); Image(systemName: "chevron.right").font(.caption).foregroundStyle(.secondary)
                        }.padding(.vertical, 6).frame(minHeight: 44)
                    }.disabled(count == 0 || repository.syncConfiguration?.readOnly == true || repository.syncConfiguration?.recovery == true)
                        .accessibilityIdentifier("cleanup.\(scope.rawValue.lowercased())")
                }
            } footer: {
                Text("When iCloud sync is enabled, deletions also sync to this household’s shared devices. Saved backup snapshots are separate and remain unchanged. Apple Reminders-only lists are not included.")
            }
        }.navigationTitle("Danger Zone").navigationBarTitleDisplayMode(.inline)
            .sheet(item: $preview) { item in CleanupConfirmationView(preview: item) { status = "\(item.scope.rawValue) cleared from this household.\(repository.syncConfiguration?.enabled == true ? " iCloud changes will sync when connected." : "")" } }
            .saveError($error)
    }
}
private struct CleanupConfirmationView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let preview: HouseholdCleanupPreview
    let onCleared: () -> Void
    @State private var confirmation = ""
    @State private var error: String?
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Label("Clear \(preview.scope.rawValue.lowercased())", systemImage: "trash").font(AppTheme.sectionTitle).foregroundStyle(.red)
                    Text(preview.householdName).font(.headline)
                    Text("\(preview.count) \(preview.scope.countLabel)\(preview.linkedTaskIDs.isEmpty ? "" : " and \(preview.linkedTaskIDs.count) preparation tasks") will be removed.")
                    Text(preview.scope.detail)
                }
                Section {
                    Text("This affects the selected household. If sync is enabled, the deletions reach iCloud and shared devices when connected. Backup snapshots remain unchanged.").font(.subheadline)
                    TextField("Type CLEAR", text: $confirmation).textInputAutocapitalization(.characters).autocorrectionDisabled().accessibilityIdentifier("cleanup.confirmation")
                    Button("Clear \(preview.scope.rawValue.lowercased()) now", role: .destructive) {
                        do { try repository.clearCategory(preview, confirmation: confirmation); onCleared(); dismiss() }
                        catch { self.error = userFacingError(error) }
                    }.disabled(confirmation != "CLEAR").accessibilityIdentifier("cleanup.confirm")
                } footer: { Text("There is no undo. Your home, family, rooms, other areas and reminder settings stay.") }
            }.navigationTitle("Review cleanup").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .saveError($error)
        }
    }
}
