import SwiftUI
import PhotosUI

struct PantryPhotoImportView: View {
    @Environment(PublicConfigurationStore.self) private var publicStatus
    let householdID: UUID
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var textSize
    @State private var photo: PhotosPickerItem?
    @State private var preview: UIImage?
    @State private var rows: [PantryPhotoItem] = []
    @State private var status: String?
    @State private var error: String?
    @State private var busy = false
    @State private var camera = false
    @State private var receipt = false
    @State private var task: Task<Void, Never>?
    @State private var generation = UUID()
    @State private var saved: Int?
    private let scanner: any PantryPhotoScanning = OnDevicePantryPhotoScanner()
    private func alreadyHome(_ name: String) -> Bool {
        repository.inventory.contains { !$0.isUsedUp && IngredientMatching.same($0.name, name) }
    }
    private var selectedCount: Int { rows.filter { $0.included && !alreadyHome($0.name) }.count }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if saved == nil { ReviewSafetyNotice(context: .photo) }
                    if let saved {
                        Label(saved == 1 ? "1 item added" : "\(saved) items added", systemImage: "checkmark.circle.fill")
                            .font(AppTheme.sectionTitle).accessibilityIdentifier("pantryPhoto.success")
                        Text("Existing pantry entries were kept. You can change amounts and dates in Pantry.").foregroundStyle(.secondary)
                        Button("Done") { dismiss() }.frame(minHeight: 44)
                    } else {
                        if let preview, !textSize.isAccessibilitySize {
                            Image(uiImage: preview).resizable().scaledToFit().frame(maxHeight: rows.isEmpty ? 180 : 100)
                                .frame(maxWidth: .infinity).clipShape(RoundedRectangle(cornerRadius: 20))
                                .accessibilityLabel("Your selected kitchen photo")
                        }
                        if busy {
                            ProgressView("Looking at your photo…").accessibilityIdentifier("pantryPhoto.reading")
                            Button("Cancel scan") { cancel(); status = "Scan cancelled. Nothing was saved." }.frame(minHeight: 44)
                        } else if status == nil && rows.isEmpty {
                            captureControls
                        }
                        if let status { Text(status).font(.subheadline).foregroundStyle(.secondary).accessibilityIdentifier("pantryPhoto.status") }
                        if status != nil && rows.isEmpty && !busy {
                            ContentUnavailableView("No clear items yet", systemImage: "viewfinder", description: Text("Try a closer photo of one shelf with labels facing forward, or add the names below."))
                        }
                        if !rows.isEmpty {
                            Text("Review items").font(.title3.bold())
                            ViewThatFits(in: .horizontal) {
                                HStack { selectionActions }
                                VStack(alignment: .leading) { selectionActions }
                            }
                            Text("Select what you have. Edit names or add optional details.").font(.subheadline).foregroundStyle(.secondary)
                        }
                        ForEach(rows) { row in
                            PantryPhotoReviewRow(row: binding(for: row), alreadyHome: alreadyHome(row.name))
                        }
                        if !busy {
                            if status != nil || !rows.isEmpty { DisclosureGroup("Use another photo") { captureControls } }
                            Button("Add a missed item", systemImage: "plus") { rows.append(PantryPhotoItem(name: "", included: true)) }
                                .frame(minHeight: 44).disabled(rows.count >= 50).accessibilityIdentifier("pantryPhoto.manual")
                        }
                    }
                }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
            }.background(InventoryTheme.canvas).tint(InventoryTheme.accent)
                .featureAvailability(.pantryPhoto).navigationTitle("Scan pantry").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Close") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        if saved == nil && (publicStatus.configuration?.allows(.pantryPhoto) ?? true) {
                            Button("Add \(selectedCount)") { save() }.disabled(busy || selectedCount == 0)
                                .accessibilityIdentifier("pantryPhoto.save")
                        }
                    }
                }
                .sheet(isPresented: $camera) {
                    PantryPhotoCamera { data in camera = false; if let data { start(data) } }.ignoresSafeArea()
                }
                .sheet(isPresented: $receipt) { ReceiptImportView(householdID: householdID) }
                .task {
                    #if DEBUG
                    if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
                       ProcessInfo.processInfo.arguments.contains("--pantry-photo-fixture"),
                       let data = PantryPhotoTestFixture.data() { start(data) }
                    #endif
                }
                .onChange(of: photo) { _, item in
                    guard let item else { return }
                    cancel(); busy = true
                    let token = generation
                    task = Task {
                        do {
                            guard let data = try await item.loadTransferable(type: Data.self) else { throw ReceiptImportError.unreadable }
                            try Task.checkCancellation()
                            guard token == generation else { return }
                            start(data)
                        } catch { if token == generation && !Task.isCancelled { busy = false; self.error = "This photo could not be opened. Try another image." } }
                    }
                }
                .onChange(of: repository.household?.id) { _, newID in if newID != householdID { cancel(); dismiss() } }
                .onDisappear { cancel(); preview = nil }
                .saveError($error)
        }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            if status != nil || !rows.isEmpty {
                Text("Check what’s at home.").font(AppTheme.sectionTitle)
                Label("Photo stays on this device", systemImage: "lock.shield").font(.subheadline)
            } else {
            if preview == nil && !textSize.isAccessibilitySize { HearthArtwork(name: "EditorialPantry", height: 130) }
            Text("One shelf. Less typing.").font(AppTheme.sectionTitle)
            Text("Photograph food you already have, then review the suggested list.").foregroundStyle(.secondary)
            Label("Processed on this device", systemImage: "lock.shield").font(.subheadline.weight(.medium))
            Text("Nam Illam does not retain or upload the photo. Confirmed items use your home's existing sync settings.").font(.footnote).foregroundStyle(.secondary)
            }
        }
    }
    private var captureControls: some View {
        VStack(alignment: .leading, spacing: 6) {
            PhotosPicker(selection: $photo, matching: .images) { Label("Choose kitchen photo", systemImage: "photo.on.rectangle").frame(minHeight: 44) }
                .accessibilityIdentifier("pantryPhoto.choose")
            if PantryPhotoCamera.isSupported {
                Button("Take a photo", systemImage: "camera") {
                    Task { if await PantryPhotoCamera.authorize() { camera = true } else { error = "Camera access is off. Allow it in Settings, or choose a photo." } }
                }.frame(minHeight: 44)
            }
            if rows.isEmpty { Button("Scan receipt", systemImage: "receipt") { receipt = true }.frame(minHeight: 44).accessibilityIdentifier("pantryPhoto.receipt") }
        }
    }
    @ViewBuilder private var selectionActions: some View {
        Button("Add all", systemImage: "checkmark.circle.fill") {
            for index in rows.indices { rows[index].included = !alreadyHome(rows[index].name) }
        }.buttonStyle(.borderedProminent).tint(InventoryTheme.ink).foregroundStyle(InventoryTheme.canvas)
            .controlSize(.large).accessibilityIdentifier("pantryPhoto.selection")
            .accessibilityLabel("Select all new pantry items")
        Button("Clear selection") {
            for index in rows.indices { rows[index].included = false }
        }.buttonStyle(.bordered).controlSize(.large).disabled(selectedCount == 0)
            .accessibilityIdentifier("pantryPhoto.clearSelection")
    }
    private func binding(for item: PantryPhotoItem) -> Binding<PantryPhotoItem> {
        Binding(get: { rows.first { $0.id == item.id } ?? item }, set: { updated in
            if let index = rows.firstIndex(where: { $0.id == item.id }) { rows[index] = updated }
        })
    }
    private func cancel() { task?.cancel(); task = nil; generation = UUID(); busy = false }
    private func start(_ data: Data) {
        cancel(); busy = true; rows = []; status = nil
        let token = generation
        // Preview is ephemeral and not attached to any saved inventory record.
        preview = PantryPhotoPreview.make(data)
        task = Task {
            do {
                let result = try await scanner.scan(imageData: data)
                try Task.checkCancellation()
                guard token == generation, repository.household?.id == householdID else { return }
                rows = result.names.map { PantryPhotoItem(name: $0) }
                status = result.explanation; busy = false
            } catch {
                if token == generation && !Task.isCancelled { busy = false; self.error = "Couldn’t read this photo. Use a clear image under 20 MB, or add names manually." }
            }
        }
    }
    private func save() {
        do { saved = try repository.importPantryPhoto(rows, householdID: householdID); preview = nil; rows = [] }
        catch { self.error = error.localizedDescription }
    }
}

private struct PantryPhotoReviewRow: View {
    @Binding var row: PantryPhotoItem
    let alreadyHome: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
                                HStack(alignment: .top, spacing: 12) {
                                    Toggle("Include item", isOn: $row.included).labelsHidden()
                                        .disabled(alreadyHome).accessibilityLabel("Include \(row.name.isEmpty ? "new item" : row.name)")
                                        .accessibilityIdentifier("pantryPhoto.include.\(row.id)")
                                    TextField("Item name", text: $row.name).font(.headline).textFieldStyle(.roundedBorder)
                                        .accessibilityIdentifier("pantryPhoto.name")
                                }
                                if alreadyHome {
                                    Label("Already at home · kept unchanged", systemImage: "checkmark.circle").font(.subheadline)
                                } else {
                                    DisclosureGroup("Amount & expiry · optional") {
                                        TextField("Amount, e.g. 2 packs or 500 g", text: $row.quantity).textFieldStyle(.roundedBorder)
                                        Toggle("Set expiry from the pack", isOn: $row.hasExpiry)
                                        if row.hasExpiry { DatePicker("Expiry", selection: $row.expiry, displayedComponents: .date) }
                                    }.font(.subheadline)
                                }
                            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                                .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
