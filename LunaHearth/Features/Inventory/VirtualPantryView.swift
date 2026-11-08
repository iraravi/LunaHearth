import SwiftUI

/// Immersive visual presentation only; the normal pantry remains the editing workspace.
struct VirtualPantryView: View {
    let items: [InventoryItem]
    let hingeState: PantryHingeState
    let exit: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zone: VirtualPantryZone = .fridge
    @State private var page = 0
    @State private var opened = false
    @State private var mist = false
    @State private var itemsRevealed = false
    @State private var editing: InventoryItem?
    private var visible: [InventoryItem] {
        items.filter { VirtualPantryRules.zone(name: $0.name, location: $0.location) == zone }
            .sorted { ($0.name, $0.id.uuidString) < ($1.name, $1.id.uuidString) }
    }
    private var coldStorage: Bool { zone == .fridge || zone == .freezer }
    private var hasDoors: Bool { zone != .other }
    private var contentsVisible: Bool { (!hasDoors || opened) && itemsRevealed }
    private struct RevealKey: Hashable { let opened: Bool; let zone: String; let reduceMotion: Bool }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if coldStorage {
                    Image("VirtualFridgeClosed").resizable().accessibilityHidden(true)
                    Image("VirtualFridgeOpen").resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height / 0.665)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                        .clipped().opacity(opened ? 1 : 0).accessibilityHidden(true)
                } else if zone == .cupboard {
                    Image("VirtualCupboardClosed").resizable().accessibilityHidden(true)
                    Image("VirtualCupboardOpen").resizable().opacity(opened ? 1 : 0).accessibilityHidden(true)
                } else { cupboard }
                if contentsVisible {
                    let displayed = Array(visible[VirtualPantryRules.pageRange(page: page, itemCount: visible.count)])
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                        let iconSize = min(100, min(geometry.size.width * 0.14, geometry.size.height * 0.13))
                        let itemHeight = max(44, iconSize + 12)
                        Button { editing = item } label: {
                            ZStack(alignment: .bottom) {
                                Ellipse().fill(.black.opacity(0.24))
                                    .frame(width: iconSize * 0.68, height: 5).blur(radius: 2)
                                Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
                                    .font(.system(size: iconSize)).offset(y: iconSize * 0.08)
                            }
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                            .contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .frame(width: geometry.size.width * 0.24, height: itemHeight)
                            .position(x: geometry.size.width * (0.25 + Double(index % 3) * 0.25),
                                      y: geometry.size.height * VirtualPantryRules.shelfSurface(row: index / 3, zone: zone) - itemHeight / 2)
                            .accessibilityLabel(item.name)
                            .accessibilityValue(item.quantityText ?? "Amount not set")
                            .accessibilityIdentifier("inventory.item.\(item.name)")
                    }
                }
                if hasDoors {
                    if coldStorage && !reduceMotion {
                        ZStack {
                            ForEach(0..<3) { layer in
                                Ellipse().fill(Color(red: 0.87, green: 0.94, blue: 1).opacity(mist ? 0.6 : 0))
                                    .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.28)
                                    .blur(radius: 25)
                                    .offset(x: Double(layer - 1) * geometry.size.width * 0.16,
                                            y: geometry.size.height * (mist ? 0.12 : 0.34) + Double(layer) * 24)
                            }
                        }.allowsHitTesting(false).accessibilityHidden(true)
                    }
                    ZStack {
                        HStack(spacing: 0) {
                            door(left: true).rotation3DEffect(.degrees(opened ? -100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                            door(left: false).rotation3DEffect(.degrees(opened ? 100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                        }.frame(height: geometry.size.height * (coldStorage ? 0.665 : 1)).contentShape(Rectangle())
                    }.frame(maxHeight: .infinity, alignment: .top).opacity(opened ? 0 : 1)
                        .allowsHitTesting(false).accessibilityHidden(true)

                }
            }.clipped()
        }
        .ignoresSafeArea()
        .overlay(alignment: .bottom) { controls.padding(16) }
        .statusBarHidden()
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("inventory.virtual")
        .sheet(item: $editing) { InventoryEditor(item: $0) }
        .onChange(of: hingeState, initial: true) { _, state in
            guard let showInterior = state.interiorVisible else { return }
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.85)) { opened = showInterior }
        }
        .task(id: RevealKey(opened: opened, zone: zone.rawValue, reduceMotion: reduceMotion)) {
            mist = false
            itemsRevealed = false
            guard opened || !hasDoors else { return }
            guard VirtualPantryRules.showsColdMist(zone: zone, reduceMotion: reduceMotion) else {
                itemsRevealed = true
                return
            }
            withAnimation(.easeOut(duration: 0.3)) { mist = true }
            try? await Task.sleep(for: .milliseconds(550))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.4)) { itemsRevealed = true }
            withAnimation(.easeOut(duration: 1.2)) { mist = false }
        }
        .onChange(of: zone) { _, _ in page = 0; opened = hingeState.interiorVisible ?? opened; mist = false }
        .onChange(of: visible.map(\.id)) { _, ids in
            page = min(page, VirtualPantryRules.pageCount(itemCount: ids.count) - 1)
        }
    }
    private var controls: some View {
        HStack(spacing: 12) {
            Button(action: exit) { controlIcon("list.bullet") }
                .accessibilityLabel("List view").accessibilityIdentifier("inventory.viewMode")
            Menu {
                Button("Fridge") { zone = .fridge }
                Button("Pantry") { zone = .cupboard }
                Section("Other storage") {
                    Button("Freezer") { zone = .freezer }
                    Button("Other") { zone = .other }
                }
            } label: { controlIcon("cabinet") }
                .accessibilityLabel("Storage area").accessibilityIdentifier("inventory.virtual.storage")
            if contentsVisible && visible.count > 9 {
                Button { page = max(0, page - 1) } label: { controlIcon("chevron.left") }
                    .disabled(page == 0).accessibilityLabel("Previous shelves")
                Button { page += 1 } label: { controlIcon("chevron.right") }
                    .disabled(page + 1 >= VirtualPantryRules.pageCount(itemCount: visible.count))
                    .accessibilityLabel("Next shelves")
            }
        }.buttonStyle(.plain)
    }
    private func controlIcon(_ symbol: String) -> some View {
        Image(systemName: symbol).font(.body.weight(.semibold)).foregroundStyle(.black)
            .frame(width: 48, height: 48).background(.white.opacity(0.95), in: Circle())
    }
    private func door(left: Bool) -> some View {
        GeometryReader { geometry in
            Image(coldStorage ? "VirtualFridgeClosed" : "VirtualCupboardClosed").resizable()
                .frame(width: geometry.size.width * 2, height: geometry.size.height / (coldStorage ? 0.665 : 1))
                .offset(x: left ? 0 : -geometry.size.width)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
                .overlay {
                    if !left && coldStorage {
                        VStack(spacing: 16) {
                            ForEach(Array(visible.prefix(3))) { item in
                                Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
                                    .font(.system(size: min(36, geometry.size.width * 0.12)))
                            }
                        }.opacity(0.38).accessibilityHidden(true)
                    }
                }
        }
    }
    private var cupboard: some View {
        GeometryReader { proxy in
            ZStack {
                LinearGradient(colors: [Color(white: 0.25), Color(white: 0.12)], startPoint: .top, endPoint: .bottom)
                ForEach(0..<3) { index in
                    RoundedRectangle(cornerRadius: 3).fill(Color(white: 0.6).gradient)
                        .frame(height: 7).shadow(color: .black.opacity(0.35), radius: 8, y: 8)
                        .position(x: proxy.size.width / 2, y: proxy.size.height * (0.31 + Double(index) * 0.17))
                }
            }
        }.accessibilityHidden(true)
    }
}
