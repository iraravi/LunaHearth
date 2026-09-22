import SwiftUI

struct InteractiveFloorPlan: View {
    let rooms: [LayoutRoom]
    let onMove: (UUID, RoomFootprint) throws -> Void
    let onEdit: (UUID) -> Void
    @State private var selectedID: UUID?
    @State private var span = 16.0
    @State private var message = "Drag a room to move it. Tap to select."
    @State private var failed = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            GeometryReader { geometry in
                let scale = max(1, (geometry.size.width - 32) / span)
                ZStack(alignment: .topLeading) {
                    Canvas { context, size in
                        let step = scale
                        var grid = Path()
                        for x in stride(from: 16.0, through: size.width, by: step) {
                            grid.move(to: CGPoint(x: x, y: 0)); grid.addLine(to: CGPoint(x: x, y: size.height))
                        }
                        for y in stride(from: 16.0, through: size.height, by: step) {
                            grid.move(to: CGPoint(x: 0, y: y)); grid.addLine(to: CGPoint(x: size.width, y: y))
                        }
                        context.stroke(grid, with: .color(.black.opacity(0.07)), lineWidth: 1)
                    }.accessibilityHidden(true)
                    ForEach(rooms) { room in
                        DraggableRoomTile(room: room, neighbors: rooms.filter { $0.id != room.id }.map(\.footprint),
                                          scale: scale, selected: selectedID == room.id,
                                          select: { selectedID = room.id }, move: { footprint in move(room, to: footprint) })
                    }
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .background(AppTheme.secondarySurface)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .overlay(alignment: .bottomTrailing) {
                    Button("Fit rooms") {
                        let x = rooms.map { $0.footprint.x + $0.footprint.width }.max() ?? 8
                        let z = rooms.map { $0.footprint.z + $0.footprint.depth }.max() ?? 8
                        span = max(8, x + 2, (z + 2) * (geometry.size.width - 32) / max(1, geometry.size.height - 32))
                    }.font(.caption.bold()).padding(10).background(.regularMaterial, in: Capsule()).padding(8)
                }
            }.frame(height: 300)
            HStack {
                Image(systemName: failed ? "exclamationmark.triangle" : "hand.draw")
                Text(message).font(.footnote)
            }.foregroundStyle(failed ? .red : AppTheme.muted).accessibilityElement(children: .combine).accessibilityIdentifier("layout.moveStatus")
            HStack {
                Button("Zoom out", systemImage: "minus.magnifyingglass") { span = min(150, span * 1.3) }
                Spacer()
                if let id = selectedID {
                    Button("Edit selected room", systemImage: "slider.horizontal.3") { onEdit(id) }
                }
                Spacer()
                Button("Zoom in", systemImage: "plus.magnifyingglass") { span = max(4, span / 1.3) }
            }.labelStyle(.iconOnly).buttonStyle(.bordered).tint(AppTheme.ink)
        }
    }

    private func move(_ room: LayoutRoom, to footprint: RoomFootprint) {
        selectedID = room.id
        do {
            try onMove(room.id, footprint)
            message = "\(room.name) moved and saved."
            failed = false
        } catch {
            message = "\(userFacingError(error)) Room returned to its saved position."
            failed = true
        }
    }
}

private struct DraggableRoomTile: View {
    let room: LayoutRoom
    let neighbors: [RoomFootprint]
    let scale: Double
    let selected: Bool
    let select: () -> Void
    let move: (RoomFootprint) -> Void
    @GestureState private var translation = CGSize.zero

    private var candidate: RoomFootprint {
        room.footprint.moved(byX: translation.width / scale, byZ: translation.height / scale, neighbors: neighbors)
    }
    private var dragging: Bool { translation != .zero }
    private var overlaps: Bool { neighbors.contains { candidate.overlaps($0) } }

    private var tile: some View {
        let r = dragging ? candidate : room.footprint
        let color = HomeLayoutPreview.color(room.preset)
        let border: Color = dragging && overlaps ? .red : (selected || dragging ? .black : color)
        return VStack(spacing: 4) {
            Image(systemName: room.preset.symbol).font(.body)
            Text(room.name).font(.caption.weight(.semibold)).lineLimit(2)
        }
        .foregroundStyle(.black).padding(4)
        .frame(width: r.width * scale, height: r.depth * scale)
        .background(color.opacity(dragging ? 0.5 : 0.25))
        .overlay(Rectangle().strokeBorder(border, lineWidth: selected || dragging ? 3 : 1.5))
        .contentShape(Rectangle())
        .offset(x: 16 + r.x * scale, y: 16 + r.z * scale)
    }

    var body: some View {
        tile
        .highPriorityGesture(DragGesture(minimumDistance: 5)
            .updating($translation) { value, state, _ in state = value.translation }
            .onEnded { value in
                move(room.footprint.moved(byX: value.translation.width / scale, byZ: value.translation.height / scale, neighbors: neighbors))
            })
        .onTapGesture(perform: select)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(room.name)
        .accessibilityValue("Position \(room.footprint.x.formatted()) by \(room.footprint.z.formatted()) meters")
        .accessibilityAddTraits(.isButton)
        .accessibilityAction { select() }
        .accessibilityAction(named: "Move right") { nudge(x: 0.25, z: 0) }
        .accessibilityAction(named: "Move left") { nudge(x: -0.25, z: 0) }
        .accessibilityAction(named: "Move down") { nudge(x: 0, z: 0.25) }
        .accessibilityAction(named: "Move up") { nudge(x: 0, z: -0.25) }
        .accessibilityIdentifier("layout.dragRoom.\(room.name)")
    }

    private func nudge(x: Double, z: Double) {
        move(room.footprint.moved(byX: x, byZ: z, neighbors: neighbors))
    }
}
