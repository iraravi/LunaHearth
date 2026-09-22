import SwiftUI

struct HomeLayoutView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var floorID: UUID?
    @State private var is3D = true
    @State private var angle = 35.0
    @State private var elevation = 35.0
    @State private var editing: RoomLayoutSelection?
    @State private var addingFloor = false
    @State private var initialized = false
    private var rooms: [Room] { repository.rooms.filter { $0.floorID == floorID } }
    private var planned: [LayoutRoom] { rooms.compactMap(\.layoutRoom) }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 22) {
                ScreenIntro(eyebrow: "YOUR SPACE, MADE SIMPLE", title: "Build your home.",
                            subtitle: "Add a room. Set its size. See it come together.")
                HStack {
                    Picker("Floor", selection: $floorID) {
                        Text("Unassigned rooms").tag(nil as UUID?)
                        ForEach(repository.floors) { Text($0.name).tag(Optional($0.id)) }
                    }.tint(AppTheme.ink).accessibilityIdentifier("layout.floor")
                    Spacer()
                    Button("Add floor", systemImage: "plus") { addingFloor = true }.font(.subheadline)
                }
                Picker("View", selection: $is3D) {
                    Text("3D Home").tag(true)
                    Text("2D Plan").tag(false)
                }.pickerStyle(.segmented).accessibilityIdentifier("layout.mode")
                if planned.isEmpty {
                    VStack(spacing: 18) {
                        Image(systemName: "square.3.layers.3d").font(.system(size: 64)).foregroundStyle(Color("IllustrationBlue"))
                        Text("Start with one room").font(AppTheme.sectionTitle)
                        Text("Choose a room below or add a new one.\nYour layout takes shape as you go.")
                            .font(.subheadline).foregroundStyle(AppTheme.muted).multilineTextAlignment(.center)
                    }.frame(maxWidth: .infinity).padding(.vertical, 44)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                } else {
                    if is3D {
                        OrbitingHomePreview(rooms: planned, angle: $angle, elevation: $elevation).frame(height: 240)
                        Text("Drag to rotate 360°. Drag up or down to tilt.").font(.footnote).foregroundStyle(AppTheme.muted)
                        Button("Arrange rooms", systemImage: "hand.draw") { is3D = false }
                    } else {
                        InteractiveFloorPlan(rooms: planned, onMove: { id, footprint in
                            guard let room = rooms.first(where: { $0.id == id }) else { throw LayoutError.missingRoom }
                            try repository.saveRoomLayout(id: id, name: room.name, floorID: room.floorID,
                                                          preset: RoomPreset(rawValue: room.layoutPreset ?? "") ?? .other,
                                                          footprint: footprint)
                        }, onEdit: { editing = RoomLayoutSelection(roomID: $0) }).id(floorID)
                    }
                    if is3D {
                        HStack {
                            Image(systemName: "rotate.3d").accessibilityHidden(true)
                            Slider(value: $angle, in: 0...360, step: 5).accessibilityLabel("Rotate home")
                            Button("Reset") { angle = 35; elevation = 35 }.font(.subheadline)
                        }
                    }
                    HStack {
                        Label("\(planned.count) rooms", systemImage: "square.grid.2x2")
                        Spacer()
                        Text("\(planned.reduce(0) { $0 + $1.footprint.area }, specifier: "%.1f") m²")
                    }.font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.muted)
                }
                Button { editing = RoomLayoutSelection(roomID: nil) } label: {
                    HStack { Image(systemName: "plus"); Text("Add a room"); Spacer(); Image(systemName: "arrow.right") }
                        .font(.headline).padding(20).foregroundStyle(AppTheme.canvas)
                        .background(AppTheme.ink, in: RoundedRectangle(cornerRadius: 16))
                }.accessibilityIdentifier("layout.addRoom")
                if !rooms.isEmpty {
                    Text("Rooms on this floor").font(AppTheme.sectionTitle)
                    ForEach(rooms) { room in
                        Button { editing = RoomLayoutSelection(roomID: room.id) } label: {
                            HStack(spacing: 14) {
                                let preset = RoomPreset(rawValue: room.layoutPreset ?? "") ?? .other
                                Image(systemName: preset.symbol).font(.title2).foregroundStyle(HomeLayoutPreview.color(preset))
                                    .frame(width: 48, height: 48).background(HomeLayoutPreview.color(preset).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                                VStack(alignment: .leading, spacing: 5) {
                                    Text(room.name).font(.headline).foregroundStyle(AppTheme.ink)
                                    if let r = room.footprint {
                                        Text("\(r.width, specifier: "%.1f") × \(r.depth, specifier: "%.1f") m · \(r.area, specifier: "%.1f") m²")
                                            .font(.subheadline).foregroundStyle(AppTheme.muted)
                                    } else {
                                        Text("Set dimensions to add to the layout").font(.subheadline).foregroundStyle(AppTheme.muted)
                                    }
                                }
                                Spacer()
                                Image(systemName: "chevron.right").foregroundStyle(AppTheme.muted)
                            }.padding(16).background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 16))
                        }.buttonStyle(.plain).accessibilityIdentifier("layout.room.\(room.id)")
                    }
                }
                Text("A simple rectangular layout from your measurements. Saved on this device.")
                    .font(.footnote).foregroundStyle(AppTheme.muted)
            }.padding(20).frame(maxWidth: 900).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).navigationTitle("Home layout").navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Add room", systemImage: "plus") { editing = RoomLayoutSelection(roomID: nil) }
                    .accessibilityIdentifier("layout.toolbarAdd")
            }
            .sheet(item: $editing) { selection in RoomLayoutEditor(roomID: selection.roomID, floorID: floorID) }
            .sheet(isPresented: $addingFloor) { QuickAddView(kind: .floor) }
            .onAppear { if !initialized { floorID = repository.floors.first?.id; initialized = true } }
    }
}

private struct RoomLayoutSelection: Identifiable {
    let id = UUID()
    let roomID: UUID?
}

struct RoomLayoutEditor: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    let roomID: UUID?
    @State var floorID: UUID?
    @State private var name = "Living room"
    @State private var preset = RoomPreset.living
    @State private var footprint = RoomFootprint(width: 5, depth: 4)
    @State private var error: String?
    @State private var loaded = false
    @State private var feet = false
    @State private var previewAngle = 35.0
    @State private var previewElevation = 35.0
    private var neighbors: [LayoutRoom] {
        repository.rooms.filter { $0.floorID == floorID && $0.id != roomID }.compactMap(\.layoutRoom)
    }
    private let previewID = UUID()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    OrbitingHomePreview(rooms: neighbors + [LayoutRoom(id: previewID, name: name, preset: preset, footprint: footprint)], angle: $previewAngle, elevation: $previewElevation, selectedID: previewID)
                        .frame(height: 220).listRowInsets(EdgeInsets())
                }.listRowBackground(Color.clear)
                Section("Choose a room") {
                    ScrollView(.horizontal) {
                        HStack(spacing: 10) {
                            ForEach(RoomPreset.allCases) { option in
                                Button {
                                    preset = option
                                    name = option.rawValue
                                    footprint.width = option.size.0
                                    footprint.depth = option.size.1
                                    placeAutomatically()
                                } label: {
                                    VStack(spacing: 8) {
                                        Image(systemName: option.symbol).font(.title2).foregroundStyle(HomeLayoutPreview.color(option))
                                        Text(option.rawValue).font(.caption.weight(.semibold)).foregroundStyle(AppTheme.ink)
                                    }.frame(minWidth: 100).padding(14)
                                        .background(preset == option ? AppTheme.secondarySurface : AppTheme.canvas, in: RoundedRectangle(cornerRadius: 14))
                                        .overlay(RoundedRectangle(cornerRadius: 14).stroke(preset == option ? AppTheme.ink : .clear, lineWidth: 2))
                                }.buttonStyle(.plain).accessibilityLabel(option.rawValue).accessibilityAddTraits(preset == option ? .isSelected : [])
                                    .accessibilityIdentifier("layout.preset.\(option.rawValue)")
                            }
                        }.padding(3)
                    }.listRowInsets(EdgeInsets(top: 10, leading: 0, bottom: 10, trailing: 0))
                    TextField("Room name", text: $name).accessibilityIdentifier("layout.roomName")
                    Picker("Floor", selection: $floorID) {
                        Text("Unassigned").tag(nil as UUID?)
                        ForEach(repository.floors) { Text($0.name).tag(Optional($0.id)) }
                    }.onChange(of: floorID) { placeAutomatically() }
                }
                Section("Room size") {
                    Picker("Units", selection: $feet) { Text("Meters").tag(false); Text("Feet").tag(true) }.pickerStyle(.segmented)
                    dimension("Width", value: $footprint.width, range: 1...30)
                    dimension("Length", value: $footprint.depth, range: 1...30)
                    dimension("Ceiling", value: $footprint.height, range: 2...6)
                }
                Section {
                    dimension("Across", value: $footprint.x, range: 0...100)
                    dimension("Down", value: $footprint.z, range: 0...100)
                    Button("Find an open spot", systemImage: "square.dashed") { placeAutomatically() }
                } header: { Text("Position on floor") } footer: {
                    Text("Across and down are measured from the floor’s top-left corner in 2D. Rooms can touch, but cannot overlap.")
                }
                if neighbors.contains(where: { footprint.overlaps($0.footprint) }) {
                    Section { Label("Rooms overlap. Adjust the position or find an open spot.", systemImage: "exclamationmark.triangle").foregroundStyle(.red) }
                }
            }.hearthList().navigationTitle(roomID == nil ? "Add a room" : "Edit room layout")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Save") {
                            do {
                                try repository.saveRoomLayout(id: roomID, name: name, floorID: floorID, preset: preset, footprint: footprint)
                                dismiss()
                            } catch { self.error = userFacingError(error) }
                        }.fontWeight(.bold).accessibilityIdentifier("layout.save")
                    }
                }.saveError($error)
                .onAppear {
                    guard !loaded else { return }; loaded = true
                    if let room = repository.rooms.first(where: { $0.id == roomID }) {
                        name = room.name; floorID = room.floorID
                        preset = RoomPreset(rawValue: room.layoutPreset ?? "") ?? .other
                        if let saved = room.footprint { footprint = saved } else { placeAutomatically() }
                    } else { placeAutomatically() }
                }
        }
        #if DEBUG
        .modifier(UITestAppearance())
        #endif
    }

    private func dimension(_ title: String, value: Binding<Double>, range: ClosedRange<Double>) -> some View {
        RoomDimensionControl(title: title, value: value, range: range, feet: feet)
    }

    private func placeAutomatically() {
        let placement = RoomFootprint.nextPlacement(among: neighbors.map(\.footprint), width: footprint.width, depth: footprint.depth)
        footprint.x = placement.x; footprint.z = placement.z
    }
}

private struct RoomDimensionControl: View {
    let title: String
    @Binding var value: Double
    let range: ClosedRange<Double>
    let feet: Bool
    @Environment(\.dynamicTypeSize) private var typeSize
    private var factor: Double { feet ? 3.280839895 : 1 }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if typeSize.isAccessibilitySize { Text(title) }
            Stepper(value: $value, in: range, step: feet ? 0.5 / factor : 0.25) {
                HStack {
                    if !typeSize.isAccessibilitySize { Text(title) }
                    Spacer(minLength: 4)
                    TextField(title, value: Binding(get: { value * factor }, set: { value = $0 / factor }),
                              format: .number.precision(.fractionLength(0...2)))
                        .keyboardType(.decimalPad).multilineTextAlignment(.trailing)
                        .frame(minWidth: 50, maxWidth: typeSize.isAccessibilitySize ? .infinity : 85)
                        .monospacedDigit().accessibilityLabel("\(title) in \(feet ? "feet" : "meters")")
                    Text(feet ? "ft" : "m").foregroundStyle(AppTheme.muted)
                }
            }.accessibilityIdentifier("layout.dimension.\(title)")
        }
    }
}
