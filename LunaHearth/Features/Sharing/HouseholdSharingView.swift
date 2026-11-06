import SwiftUI

struct HouseholdSharingView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(HouseholdSharingController.self) private var sharing
    @State private var deleting: SyncDestination?
    @State private var enabling = false
    @State private var resolution: Bool?
    @State private var joining: CloudHome?
    @State private var localError: String?
    var body: some View {
        @Bindable var sharing = sharing
        List {
            Section {
                Label("iCloud sync & data", systemImage: "icloud").font(AppTheme.sectionTitle)
                Text("Check syncing, switch homes or manage cloud storage.").foregroundStyle(.secondary)
            }.listRowBackground(Color.clear)
            if let configuration = repository.syncConfiguration {
                Section("This home") {
                    LabeledContent("Home", value: repository.household?.name ?? "Home")
                    LabeledContent("Access", value: configuration.recovery ? "Recovery · local data preserved" : configuration.readOnly ? "Read only" : configuration.isOwner ? "Owner" : "Participant")
                    if let date = configuration.lastSyncedAt { LabeledContent("Last synced", value: date.formatted(date: .abbreviated, time: .shortened)) }
                    Text("\(sharing.pendingCount) changes waiting to upload").font(.footnote)
                    Button("Sync now", systemImage: "arrow.triangle.2.circlepath") { Task { await sharing.sync(repository, force: true) } }
                        .accessibilityIdentifier("sharing.sync")

                }
            } else if repository.household != nil {
                Section {
                    Button("Enable private iCloud sync", systemImage: "icloud") { enabling = true }.accessibilityIdentifier("sharing.enable")
                    Text("Your household uploads only after you enable sync. Invite people from More → Family.").font(.footnote).foregroundStyle(.secondary)
                }
            }
            if sharing.working { ProgressView("Working with iCloud…") }
            if let message = sharing.message { Section { Text(message).accessibilityIdentifier("sharing.status") } }
            conflictSection
            homePicker
            if let configuration = repository.syncConfiguration, configuration.isOwner {
                Section {
                    Button("Delete this home from iCloud", role: .destructive) { deleting = configuration.destination }
                        .accessibilityIdentifier("sharing.delete")
                    Text("Keeps this device’s home. Removes the synced cloud home and stops access for everyone sharing it. Private backups are managed separately in iCloud backup.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            }
            Section("Private by design") {
                Label("Only invited people can access a shared home.", systemImage: "lock.shield")
                Text("The owner’s private iCloud storage holds this home. Participants use CloudKit’s shared database. Apple Accounts and iCloud are needed for sharing; no Nam Illam account is required.")
                Text("Changes sync automatically while the app is open and when you return. Offline edits stay on this device until a successful sync. Background delivery is not guaranteed.")
                Text("Share only with people you trust: invitees can see this home’s plans, lists, rooms, belongings and warranty details. Document and room-scan files are not supported yet.")
            }.font(.footnote).foregroundStyle(.secondary)
        }.hearthList().navigationTitle("iCloud sync & data").navigationBarTitleDisplayMode(.inline)
            .disabled(sharing.working)
            .saveError($localError)
            .confirmationDialog("Delete this home from iCloud?", isPresented: Binding(get: { deleting != nil }, set: { if !$0 { deleting = nil } }), titleVisibility: .visible, presenting: deleting) { destination in
                Button("Delete cloud home", role: .destructive) { deleting = nil; Task { await sharing.deleteCloudHome(repository, destination: destination) } }
            } message: { _ in Text("Permanently removes this synced home from your private iCloud storage and ends family sharing. Local copies on devices are not remotely erased. This device keeps its home with sync off. Separate private backups and Apple Reminders are unchanged.") }
            .confirmationDialog("Enable private iCloud sync?", isPresented: $enabling, titleVisibility: .visible) {
                Button("Upload and enable sync") { Task { await sharing.enable(repository) } }
            } message: { Text("Uploads this home’s plans, lists, members, rooms, belongings, warranties and maintenance to your private iCloud storage. No one else gets access until you invite them.") }
            .confirmationDialog("Apply the selected versions?", isPresented: Binding(get: { resolution != nil }, set: { if !$0 { resolution = nil } }), titleVisibility: .visible, presenting: resolution) { useCloud in
                Button("Apply reviewed versions") { resolution = nil; Task { await sharing.resolveConflicts(useCloud: useCloud, repository: repository) } }
            } message: { _ in Text("This resolves only the conflicting records shown above. The selected versions will become the shared values.") }
            .confirmationDialog("Open this iCloud home?", isPresented: Binding(get: { joining != nil }, set: { if !$0 { joining = nil } }), titleVisibility: .visible, presenting: joining) { home in
                Button("Open home") { joining = nil; Task { await sharing.open(home.destination, repository: repository) } }
            } message: { _ in Text("Your current home is kept separately on this device. You can switch between homes here.") }
            .sheet(item: $sharing.shareTicket, onDismiss: { Task { await sharing.sync(repository, force: true) } }) { ticket in
                if let service = sharing.service as? CloudKitHouseholdService {
                    CloudSharingSheet(ticket: ticket, service: service,
                                      onError: { sharing.report($0, repository: repository) },
                                      onChanged: { Task { await sharing.sync(repository, force: true) } })
                }
            }
    }
    private var homePicker: some View {
            Section("Open another home") {
                ForEach(repository.households, id: \.id) { home in
                    Button {
                        do { try repository.activateHousehold(home.id) } catch { localError = userFacingError(error) }
                    } label: {
                        HStack { Text(home.name); Spacer(); if repository.household?.id == home.id { Image(systemName: "checkmark") } }
                    }
                }
                Button("Find my iCloud homes", systemImage: "icloud.and.arrow.down") { Task { await sharing.findHomes(repository) } }
                    .accessibilityIdentifier("sharing.find")
                ForEach(sharing.availableHomes) { home in
                    Button("Open \(home.name)") { joining = home }
                }
                if sharing.searched && sharing.availableHomes.isEmpty && sharing.message == nil { Text("No synced homes found. Accept an invitation or enable sync for this home.").font(.footnote) }
            }
    }
    @ViewBuilder private var conflictSection: some View {
            if !repository.syncBaselines.filter(\.conflict).isEmpty {
                Section("Review conflicting changes") {
                    Text("These records changed on this device and in iCloud. Review both versions, then choose which set to keep. Other records are not affected by this choice.").font(.footnote)
                    ForEach(repository.syncBaselines.filter(\.conflict), id: \.entityID) { baseline in
                        if let remote = try? JSONDecoder().decode(RemoteHouseholdRecord.self, from: baseline.remoteData),
                           let local = try? repository.makeBackup(refresh: false) {
                            VStack(alignment: .leading, spacing: 12) {
                                Text(remote.entity.record.kind.replacingOccurrences(of: "Household", with: "")).font(.headline)
                                ConflictVersionView(title: "On this device", record: local.records.first { $0.id == baseline.entityID })
                                Divider()
                                ConflictVersionView(title: "In iCloud", record: remote.entity.deleted ? nil : remote.entity.record)
                            }.padding(.vertical, 8)
                        }
                    }
                    Button("Keep this device’s versions") { resolution = false }
                    Button("Use iCloud’s versions") { resolution = true }
                }
            }
    }

}

struct HouseholdInvitationView: View {
    let invitation: HouseholdInvitation
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(HouseholdSharingController.self) private var sharing
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    HearthArtwork(name: "WelcomeResidence", height: 180)
                    Text("Join \(invitation.title)").font(AppTheme.displayTitle)
                    Text("Open this shared household using your Apple Account. Its plans, lists and home details will be saved on this device and kept in sync through iCloud.")
                    Text("Your existing home stays separate. Joining does not upload your current home or merge its contents.").font(.subheadline).foregroundStyle(.secondary)
                    if let message = sharing.message { Text(message) }
                    if sharing.working { ProgressView("Joining home…") }
                    Button("Join shared home") { Task { await sharing.acceptInvitation(repository) } }.accessibilityIdentifier("sharing.accept")
                        .hearthGlassButton(prominent: true, glassInLight: false).controlSize(.large).disabled(sharing.working)
                }.padding(24)
            }.background(AppTheme.canvas)
                .toolbar { Button("Not now") { sharing.invitation = nil }.disabled(sharing.working) }
        }.interactiveDismissDisabled(sharing.working)
    }
}

private struct ConflictVersionView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let title: String
    let record: BackupRecord?
    private var fields: [(String, String)] {
        guard let record, let object = try? JSONSerialization.jsonObject(with: record.payload) as? [String: Any] else { return [] }
        let names = ["isLowStock": "Low stock", "isUsedUp": "Used up", "expiryDay": "Expiry", "packedDay": "Packed", "purchasedDay": "Purchased", "amountMinorUnits": "Amount", "quantity": "Quantity", "stockAction": "Stock action", "merchant": "Store", "day": "Day", "isRefund": "Refund", "name": "Name", "title": "Title", "displayName": "Name", "provider": "Provider", "notes": "Notes", "quantityText": "Quantity", "storeName": "Store", "neededLater": "Needed later", "isCompleted": "Completed", "dueAt": "Due", "startAt": "Starts", "endAt": "Ends", "date": "Date", "dateKey": "Day", "mealType": "Meal", "manufacturer": "Manufacturer", "modelNumber": "Model", "serialNumber": "Serial number", "policyNumber": "Policy", "nextDueAt": "Next due", "lastCompletedAt": "Last completed", "intervalDays": "Repeat interval (days)", "shoppingItemTemplate": "Replacement", "categoryRawValue": "Category", "startDate": "Starts", "endDate": "Expires", "purchaseDate": "Purchased", "layoutX": "Position X (m)", "layoutZ": "Position Z (m)", "layoutWidth": "Width (m)", "layoutDepth": "Depth (m)", "layoutHeight": "Height (m)", "roleRawValue": "Profile", "recurrenceRule": "Repeat", "completedAt": "Completed on", "assignedMemberID": "Assigned to", "relatedAssetID": "Related item", "assetID": "Home item", "roomID": "Room", "floorID": "Floor", "planID": "Maintenance", "sortIndex": "Order", "layoutPreset": "Room type", "colorToken": "Profile color", "category": "Category", "currencyCode": "Currency", "purchasePriceMinorUnits": "Purchase price", "sourceRawValue": "Source"]
        let dates: Set<String> = ["dueAt", "startAt", "endAt", "date", "nextDueAt", "lastCompletedAt", "startDate", "endDate", "purchaseDate", "completedAt"]
        return object.keys.sorted().compactMap { key in
            guard let label = names[key], let value = object[key], !(value is NSNull) else { return nil }
            if ["assignedMemberID", "relatedAssetID", "assetID", "roomID", "floorID", "planID"].contains(key), let text = value as? String, let id = UUID(uuidString: text) {
                let name: String
                switch key {
                case "assignedMemberID": name = repository.memberName(id)
                case "relatedAssetID", "assetID": name = repository.assetName(id)
                case "roomID": name = repository.rooms.first { $0.id == id }?.name ?? "Unlisted room"
                case "floorID": name = repository.floors.first { $0.id == id }?.name ?? "Unlisted floor"
                default: name = repository.maintenance.first { $0.id == id }?.title ?? "Unlisted maintenance"
                }
                return (label, name)
            }
            if ["purchasePriceMinorUnits", "amountMinorUnits"].contains(key), let amount = value as? Int {
                let currency = object["currencyCode"] as? String ?? "USD"
                return (label, (Decimal(amount) / 100).formatted(.currency(code: currency)))
            }
            if ["isCompleted", "neededLater", "isLowStock", "isUsedUp", "isRefund"].contains(key), let value = value as? Bool { return (label, value ? "Yes" : "No") }
            if dates.contains(key), let value = value as? Double { return (label, Date(timeIntervalSinceReferenceDate: value).formatted(date: .abbreviated, time: .shortened)) }
            return (label, String(describing: value))
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.subheadline.bold())
            if record == nil { Text("Deleted").font(.footnote) }
            ForEach(fields, id: \.0) { field in Text("\(field.0): \(field.1)").font(.footnote) }
        }
    }
}
