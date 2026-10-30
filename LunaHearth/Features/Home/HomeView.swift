import SwiftUI

struct HomeSpacesView: View {
    var isWorkspace = false
    @Environment(\.dismiss) private var dismiss
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.horizontalSizeClass) private var sizeClass
    @Environment(\.featureCanvasCoordinator) private var canvas
    @State private var selectedRoomID: UUID?
    @State private var adding: EntryKind?
    @State private var parentID: UUID?
    @State private var search = ""
    @State private var editingFloor: EntryDraft?
    @State private var showAllItems = false

    private var matchingAssets: [HomeAsset] {
        repository.assets.filter { search.isEmpty || $0.name.localizedStandardContains(search) ||
            ($0.modelNumber ?? "").localizedStandardContains(search) || ($0.serialNumber ?? "").localizedStandardContains(search) }
    }

    var body: some View {
        Group {
            if sizeClass == .regular && isWorkspace {
                NavigationSplitView { sidebar } detail: { roomDetail }
            } else if isWorkspace {
                NavigationStack { sidebar }
            } else {
                // Home already owns the compact navigation stack. Nesting a split
                // view here prevents value links from opening their selected room.
                sidebar
            }
        }
        .sheet(item: $adding) { QuickAddView(kind: $0, parentID: parentID, fixedKind: true) }
        .sheet(item: $editingFloor) { QuickAddView(draft: $0) }
    }

    private var sidebar: some View {
        List(selection: $selectedRoomID) {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    HearthArtwork(name: "WelcomeResidence", height: 110)
                        .accessibilityHidden(true)
                    Text(repository.household?.name ?? "Your home")
                        .font(AppTheme.sectionTitle).foregroundStyle(AppTheme.ink)
                    Text("Rooms, belongings and home care.")
                        .font(.subheadline).foregroundStyle(AppTheme.muted)
                }.padding(.vertical, 4)
            }.listRowBackground(Color.clear).listRowSeparator(.hidden)

            Section {
                if repository.rooms.isEmpty {
                    Text("Start with a kitchen, bathroom or bedroom. Add belongings inside each room.")
                        .font(.subheadline).foregroundStyle(AppTheme.muted)
                }
                ForEach(repository.floors) { floor in
                    let rooms = repository.rooms.filter { $0.floorID == floor.id }
                    if !rooms.isEmpty {
                        Text(floor.name).font(.caption.weight(.semibold))
                            .foregroundStyle(AppTheme.muted).accessibilityAddTraits(.isHeader)
                        roomRows(rooms)
                    }
                }
                roomRows(repository.rooms.filter { $0.floorID == nil })
                Button { add(.room, parent: repository.floors.count == 1 ? repository.floors.first?.id : nil) } label: {
                    Label("Add a room", systemImage: "plus")
                        .frame(minHeight: 44, alignment: .leading)
                }.accessibilityIdentifier("home.addRoom")
                NavigationLink { HomeLayoutView() } label: {
                    HomeActionRow(title: "Floor plan", detail: "Arrange your rooms in 2D or explore in 3D", symbol: "square.3.layers.3d")
                }.accessibilityIdentifier("home.layout")
            } header: {
                Text("Rooms · \(repository.rooms.count)")
            }

            Section("Belongings") {
                DisclosureGroup(isExpanded: $showAllItems) {
                    if matchingAssets.isEmpty {
                        Text(search.isEmpty ? "Add appliances, furniture and other belongings here or inside a room." : "No matching items.")
                            .font(.subheadline).foregroundStyle(AppTheme.muted)
                    }
                    ForEach(matchingAssets) { asset in
                        NavigationLink { AssetDetailView(asset: asset) } label: {
                            HomeActionRow(title: asset.name,
                                detail: repository.rooms.first(where: { $0.id == asset.roomID })?.name ?? "No room assigned",
                                symbol: (AssetCategory(rawValue: asset.categoryRawValue) ?? .other).symbol)
                        }.accessibilityIdentifier("home.item.\(asset.id)")
                    }
                    Button { add(.asset, parent: repository.rooms.count == 1 ? repository.rooms.first?.id : nil) } label: {
                        Label("Add an item", systemImage: "plus").frame(minHeight: 44, alignment: .leading)
                    }.accessibilityIdentifier("home.addItem")
                } label: {
                    HomeActionRow(title: "All belongings", detail: "\(repository.assets.count) items across your home", symbol: "shippingbox")
                }.accessibilityIdentifier("home.belongings")
            }
            Section("Home care") {
                NavigationLink { HomeAlertsView() } label: {
                    HomeActionRow(title: "Maintenance & warranties", detail: "Service dates and cover for your belongings", symbol: "wrench.and.screwdriver")
                }.accessibilityIdentifier("home.care")
            }
        }
        .hearthList(canvas: canvas?.color(for: .home) ?? AppTheme.canvas)
        .hearthNavigationMaterial(canvas?.color(for: .home) ?? AppTheme.canvas, for: .navigationBar)
        .searchable(text: $search, prompt: "Find a room or item")
        .onChange(of: search) { _, value in if !value.isEmpty { showAllItems = true } }
        .navigationTitle("Rooms & belongings").navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if isWorkspace {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }.accessibilityIdentifier("home.closeSpaces")
                }
            }
            ToolbarItem(placement: .primaryAction) {
            Menu {
                Button("Add a floor", systemImage: "square.3.layers.3d") { add(.floor) }
                    .accessibilityIdentifier("home.addFloor")
                ForEach(repository.floors) { floor in
                    Button("Edit \(floor.name)") { editingFloor = .editing(floor) }
                }
            } label: { Label("Home settings", systemImage: "ellipsis") }.accessibilityIdentifier("home.add")
            }
        }
    }

    private var roomDetail: some View {
        NavigationStack {
            if let room = repository.rooms.first(where: { $0.id == selectedRoomID }) {
                RoomDetailView(room: room)
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        HearthArtwork(name: "WelcomeResidence", height: 240).accessibilityHidden(true)
                        Text("A place for everything.").font(AppTheme.displayTitle)
                        Text("Open a room to look after the things inside it.")
                            .font(.title3).foregroundStyle(AppTheme.muted)
                        Label("Rooms first. Floor plans whenever you’re ready.", systemImage: "square.3.layers.3d")
                            .font(.subheadline).foregroundStyle(AppTheme.muted)
                    }.frame(maxWidth: 660, alignment: .leading).padding(28).frame(maxWidth: .infinity)
                }.background(canvas?.color(for: .home) ?? AppTheme.canvas)

            }
        }
    }

    private func add(_ kind: EntryKind, parent: UUID? = nil) {
        parentID = parent
        adding = kind
    }

    @ViewBuilder private func roomRows(_ rooms: [Room]) -> some View {
        ForEach(rooms.filter { search.isEmpty || $0.name.localizedStandardContains(search) }) { room in
            roomLink(room) {
                HStack(spacing: 14) {
                    HearthIcon(symbol: "door.left.hand.open")
                    VStack(alignment: .leading, spacing: 4) {
                        Text(room.name).font(.headline).foregroundStyle(AppTheme.ink)
                        let count = repository.assets.filter { $0.roomID == room.id }.count
                        Text(count == 0 ? "Open to add your first item" : "\(count) items · Open to view")
                            .font(.subheadline).foregroundStyle(AppTheme.muted)
                    }
                }.padding(.vertical, 5)
            }.accessibilityIdentifier("home.room.\(room.id)")
        }
    }
    @ViewBuilder private func roomLink<Label: View>(_ room: Room, @ViewBuilder label: () -> Label) -> some View {
        if sizeClass == .regular && isWorkspace {
            NavigationLink(value: room.id, label: label)
        } else {
            NavigationLink { RoomDetailView(room: room) } label: { label() }
        }
    }

}

private struct HomeActionRow: View {
    let title: String
    let detail: String
    let symbol: String
    var body: some View {
        HStack(spacing: 14) {
            HearthIcon(symbol: symbol)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline).foregroundStyle(AppTheme.ink)
                Text(detail).font(.subheadline).foregroundStyle(AppTheme.muted)
            }
            Spacer(minLength: 0)
        }.padding(.vertical, 6)
    }
}

struct RoomDetailView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let room: Room
    @State private var adding = false
    @State private var editing = false
    @State private var editingLayout = false
    private var assets: [HomeAsset] { repository.assets.filter { $0.roomID == room.id } }

    var body: some View {
        List {
            Section {
                ScreenIntro(eyebrow: repository.floors.first(where: { $0.id == room.floorID })?.name ?? "Your home",
                            title: room.name, subtitle: "\(assets.count) items in this room")
                Button { adding = true } label: {
                    Label("Add an item to \(room.name)", systemImage: "plus.circle.fill")
                        .font(.headline).frame(maxWidth: .infinity, minHeight: 48, alignment: .leading)
                }.accessibilityIdentifier("room.addItem")
            }.listRowBackground(Color.clear)
            Section("Items in \(room.name)") {
                if assets.isEmpty {
                    Text("Add a fridge, sofa, lamp, or anything else in this room. You can then track its warranty and maintenance.")
                        .foregroundStyle(AppTheme.muted)
                }
                ForEach(assets) { asset in
                    NavigationLink { AssetDetailView(asset: asset) } label: {
                        HStack(spacing: 14) {
                            HearthIcon(symbol: (AssetCategory(rawValue: asset.categoryRawValue) ?? .other).symbol)
                            VStack(alignment: .leading, spacing: 4) {
                                Text(asset.name).font(.headline).foregroundStyle(AppTheme.ink)
                                Text("Details · Warranty · Maintenance").font(.caption).foregroundStyle(AppTheme.muted)
                            }
                        }.padding(.vertical, 5)
                    }.accessibilityIdentifier("room.item.\(asset.id)")
                }
            }
            Section("Room settings") {
                Button("Edit name or floor", systemImage: "pencil") { editing = true }
                Button(room.footprint == nil ? "Create a 2D / 3D layout" : "Edit room layout", systemImage: "square.3.layers.3d") { editingLayout = true }
            }
        }.hearthList().navigationTitle(room.name).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Add Item", systemImage: "plus") { adding = true } }
            .sheet(isPresented: $editingLayout) { RoomLayoutEditor(roomID: room.id, floorID: room.floorID) }
            .sheet(isPresented: $editing) { QuickAddView(draft: .editing(room)) }
            .sheet(isPresented: $adding) { QuickAddView(kind: .asset, parentID: room.id, fixedKind: true) }
    }
}

struct AssetDetailView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let asset: HomeAsset
    @State private var adding: EntryKind?
    @State private var revealSerial = false
    @State private var editing = false
    @State private var error: String?
    var body: some View {
        List {
            Section {
                HStack(alignment: .top, spacing: 16) {
                    HearthIcon(symbol: (AssetCategory(rawValue: asset.categoryRawValue) ?? .other).symbol)
                    ScreenIntro(eyebrow: asset.categoryRawValue, title: asset.name,
                                subtitle: "Item details and upcoming maintenance.")
                }.padding(.vertical, 8)
            }.listRowBackground(Color.clear)
            Section("Overview") {
                LabeledContent("Category", value: asset.categoryRawValue.capitalized)
                if let manufacturer = asset.manufacturer, !manufacturer.isEmpty { LabeledContent("Manufacturer", value: manufacturer) }
                if let model = asset.modelNumber, !model.isEmpty { LabeledContent("Model", value: model) }
                if let serial = asset.serialNumber, !serial.isEmpty {
                    Button(revealSerial ? "Serial: \(serial)" : "Reveal serial number") { revealSerial.toggle() }
                }
                Picker("Room", selection: Binding(get: { asset.roomID }, set: { id in
                    do { try repository.move(asset, to: id) } catch { self.error = userFacingError(error) }
                })) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(repository.rooms) { Text($0.name).tag(Optional($0.id)) }
                }
                if let notes = asset.notes, !notes.isEmpty { Text(notes) }
            }
            Section("Warranties") {
                ForEach(repository.warranties.filter { $0.assetID == asset.id }) { warranty in
                    VStack(alignment: .leading) {
                        Text(warranty.provider ?? "Warranty").font(.headline)
                        if let date = warranty.endDate {
                            Text("\(date < Calendar.current.startOfDay(for: .now) ? "Expired" : "Ends") \(date.formatted(date: .abbreviated, time: .omitted))").foregroundStyle(.secondary)
                        } else { Text("No expiration recorded").foregroundStyle(.secondary) }
                        if let notes = warranty.notes, !notes.isEmpty { Text(notes).font(.subheadline) }
                    }.entryActions(.editing(warranty))
                }
                Button("Add Warranty", systemImage: "plus") { adding = .warranty }.accessibilityIdentifier("item.addWarranty")
            }
            Section("Maintenance") {
                ForEach(repository.maintenance.filter { $0.assetID == asset.id }) { plan in
                    NavigationLink(plan.title) { MaintenanceDetailView(plan: plan) }
                }
                Button("Add Maintenance", systemImage: "plus") { adding = .maintenance }.accessibilityIdentifier("item.addMaintenance")
            }
        }
        .hearthList()
        .navigationTitle(asset.name).navigationBarTitleDisplayMode(.inline)
        .toolbar { Button("Edit Item") { editing = true } }
        .sheet(isPresented: $editing) { QuickAddView(draft: .editing(asset)) }
        .sheet(item: $adding) { QuickAddView(kind: $0, parentID: asset.id, fixedKind: true) }
        .saveError($error)
    }
}

struct HomeAlertsView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    var body: some View {
        List {
            Section("Maintenance") {
                if repository.maintenance.isEmpty { Text("Add a maintenance plan from a home item's detail page.").foregroundStyle(.secondary) }
                ForEach(repository.maintenance) { plan in
                    NavigationLink { MaintenanceDetailView(plan: plan) } label: {
                        VStack(alignment: .leading) {
                            Text(plan.title)
                            if let date = plan.nextDueAt { Text("Due \(date.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary) }
                        }
                    }
                }
            }
            Section("Warranties") {
                if repository.warranties.isEmpty { Text("Add a warranty from a home item's detail page.").foregroundStyle(.secondary) }
                ForEach(repository.warranties) { warranty in
                    VStack(alignment: .leading) {
                        Text(repository.assetName(warranty.assetID))
                        Text(warranty.provider ?? "Warranty").font(.subheadline)
                        if let end = warranty.endDate { Text("Ends \(end.formatted(date: .abbreviated, time: .omitted))").font(.caption).foregroundStyle(.secondary) }
                    }
                }
            }
        }.hearthList().navigationTitle("Home Alerts")
    }
}

struct MaintenanceDetailView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let plan: MaintenancePlan
    @State private var addingShopping = false
    @State private var error: String?
    @State private var confirming = false
    @State private var editing = false
    var body: some View {
        List {
            Section {
                LabeledContent("Item", value: repository.assetName(plan.assetID))
                if let due = plan.nextDueAt { LabeledContent("Next due", value: due.formatted(date: .abbreviated, time: .omitted)).accessibilityElement(children: .combine).accessibilityIdentifier("maintenance.nextDue") }
                if let interval = plan.intervalDays { Text("Repeats \(interval) days after completion") }
                if let last = plan.lastCompletedAt { LabeledContent("Last completed", value: last.formatted(date: .abbreviated, time: .shortened)) }
            }
            Section {
                Button("Mark Completed", systemImage: "checkmark.circle") { confirming = true }
                    .disabled(plan.lastCompletedAt != nil && plan.nextDueAt == nil)
                    .accessibilityIdentifier("maintenance.complete")
                if let shopping = plan.shoppingItemTemplate, !shopping.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    Button("Add replacement to shopping", systemImage: "cart.badge.plus") { addingShopping = true }
                        .accessibilityIdentifier("maintenance.shopping")
                    Text(shopping).font(.subheadline).foregroundStyle(.secondary)
                }
            }
            Section("Service history") {
                let entries = repository.history.filter { $0.planID == plan.id }
                if entries.isEmpty { Text("Completions will appear here.").foregroundStyle(.secondary) }
                ForEach(entries) { entry in Label(entry.completedAt.formatted(date: .abbreviated, time: .shortened), systemImage: "checkmark") }
            }
        }.hearthList().navigationTitle(plan.title)
            .toolbar { Button("Edit") { editing = true } }
            .sheet(isPresented: $addingShopping) { QuickAddView(draft: EntryDraft(kind: .grocery, title: plan.shoppingItemTemplate ?? "", parentID: plan.assetID)) }
            .sheet(isPresented: $editing) { QuickAddView(draft: .editing(plan)) }
            .confirmationDialog("Record this maintenance as completed now?", isPresented: $confirming, titleVisibility: .visible) {
                Button("Record Completion") {
                    do { try repository.completeMaintenance(plan) } catch { self.error = userFacingError(error) }
                }
            }
            .saveError($error)
    }
}
