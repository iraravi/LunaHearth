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
    @State private var editing: InventoryItem?
    private var visible: [InventoryItem] {
        items.filter { VirtualPantryRules.zone(name: $0.name, location: $0.location) == zone }
            .sorted { ($0.name, $0.id.uuidString) < ($1.name, $1.id.uuidString) }
    }
    private var hasDoors: Bool { zone == .fridge || zone == .freezer }
    private var contentsVisible: Bool { !hasDoors || opened }
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if hasDoors {
                    Image("VirtualFridgeClosed").resizable().accessibilityHidden(true)
                    Image("VirtualFridgeOpen").resizable()
                        .frame(width: geometry.size.width, height: geometry.size.height / 0.665)
                        .frame(width: geometry.size.width, height: geometry.size.height, alignment: .top)
                        .clipped().opacity(opened ? 1 : 0).accessibilityHidden(true)
                } else { cupboard }
                if contentsVisible {
                    let displayed = Array(visible[VirtualPantryRules.pageRange(page: page, itemCount: visible.count)])
                    ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                        Button { editing = item } label: {
                            Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
                                .font(.system(size: min(100, min(geometry.size.width * 0.14, geometry.size.height * 0.1))))
                                .shadow(color: .black.opacity(0.2), radius: 5, y: 5)
                                .frame(maxWidth: .infinity, maxHeight: .infinity).contentShape(Rectangle())
                        }.buttonStyle(.plain)
                            .frame(width: geometry.size.width * 0.24, height: max(44, geometry.size.height * (hasDoors ? 0.11 : 0.15)))
                            .position(x: geometry.size.width * (0.23 + Double(index % 3) * 0.27),
                                      y: geometry.size.height * ((hasDoors ? 0.15 / 0.665 : 0.23) + Double(index / 3) * (hasDoors ? 0.12 / 0.665 : 0.17)))
                            .accessibilityLabel(item.name)
                            .accessibilityValue(item.quantityText ?? "Amount not set")
                            .accessibilityIdentifier("inventory.item.\(item.name)")
                    }
                }
                if hasDoors {
                    Ellipse().fill(.white.opacity(mist ? 0.5 : 0)).blur(radius: 28)
                        .frame(height: geometry.size.height * 0.15).offset(y: geometry.size.height * 0.2)
                        .allowsHitTesting(false).accessibilityHidden(true)
                    ZStack {
                        HStack(spacing: 0) {
                            door(left: true).rotation3DEffect(.degrees(opened ? -100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                            door(left: false).rotation3DEffect(.degrees(opened ? 100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                        }.frame(height: geometry.size.height * 0.665).contentShape(Rectangle())
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
        .task(id: opened) {
            mist = false
            guard opened, !reduceMotion else { return }
            withAnimation(.easeOut(duration: 0.45)) { mist = true }
            try? await Task.sleep(for: .milliseconds(1000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1)) { mist = false }
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
                ForEach(VirtualPantryZone.allCases) { value in
                    Button(value.title) { zone = value }
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
            Image("VirtualFridgeClosed").resizable()
                .frame(width: geometry.size.width * 2, height: geometry.size.height / 0.665)
                .offset(x: left ? 0 : -geometry.size.width)
                .frame(width: geometry.size.width, height: geometry.size.height, alignment: .topLeading)
                .clipped()
                .overlay {
                    if !left {
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
