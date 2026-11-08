import SwiftUI

struct VirtualPantryView: View {
    let items: [InventoryItem]
    let now: Date
    let open: (InventoryItem) -> Void
    let add: () -> Void
    let scan: () -> Void
    let tools: () -> Void
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var zone: VirtualPantryZone = .fridge
    @State private var selectedID: UUID?
    @State private var page = 0
    @State private var opened = false
    @State private var mist = false
    private var visible: [InventoryItem] {
        items.filter { VirtualPantryRules.zone(name: $0.name, location: $0.location) == zone }
            .sorted { ($0.name, $0.id.uuidString) < ($1.name, $1.id.uuidString) }
    }
    private var selected: InventoryItem? { visible.first { $0.id == selectedID } }
    var body: some View {
        GeometryReader { geometry in
            let wide = geometry.size.width >= 760 && !typeSize.isAccessibilitySize
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    header
                    if wide {
                        HStack(alignment: .top, spacing: 28) {
                            scene(wide: true).frame(width: min(420, max(240, (geometry.size.height - 180) * 2 / 3)))
                            detail.frame(maxWidth: .infinity, alignment: .topLeading)
                        }
                    } else {
                        scene(wide: false).frame(maxWidth: 420).frame(maxWidth: .infinity)
                        detail
                    }
                    Text("A view of your saved groceries. Grouped for browsing; saved locations take priority.")
                        .font(.footnote).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: 1120).frame(maxWidth: .infinity)
            }
        }
        .accessibilityIdentifier("inventory.virtual")
        .task {
            guard !opened else { return }
            if reduceMotion { opened = true; return }
            try? await Task.sleep(for: .milliseconds(180))
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 1.15)) { opened = true }
            withAnimation(.easeOut(duration: 0.45)) { mist = true }
            try? await Task.sleep(for: .milliseconds(1000))
            guard !Task.isCancelled else { return }
            withAnimation(.easeOut(duration: 1)) { mist = false }
        }
        .onChange(of: zone) { _, _ in page = 0; selectedID = nil }
        .onChange(of: visible.map(\.id)) { _, ids in
            page = min(page, VirtualPantryRules.pageCount(itemCount: ids.count) - 1)
            if let selectedID, !ids.contains(selectedID) { self.selectedID = nil }
        }
    }
    private var header: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Your virtual pantry").font(AppTheme.sectionTitle)
                    Text("\(items.count) saved packs · Tap an item to explore")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 8)
                Button(action: tools) { Image(systemName: "slider.horizontal.3").frame(width: 44, height: 44) }
                    .accessibilityLabel("Pantry filters").accessibilityIdentifier("inventory.virtual.filters")
            }
            if typeSize.isAccessibilitySize {
                Picker("Storage area", selection: $zone) {
                    ForEach(VirtualPantryZone.allCases) { value in Text(value.title).tag(value) }
                }.pickerStyle(.menu).frame(minHeight: 44).accessibilityIdentifier("inventory.virtual.storage")
            } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(VirtualPantryZone.allCases) { value in
                        Button { zone = value } label: {
                            Text(value.title).font(.subheadline.weight(.semibold)).padding(.horizontal, 16).frame(minHeight: 44)
                                .foregroundStyle(zone == value ? AppTheme.canvas : AppTheme.ink)
                                .background(zone == value ? AppTheme.ink : AppTheme.surface, in: Capsule())
                        }.buttonStyle(.plain).accessibilityAddTraits(zone == value ? .isSelected : [])
                            .accessibilityIdentifier("inventory.virtual.zone.\(value.rawValue)")
                    }
                }
            }
            }
        }
    }
    private func scene(wide: Bool) -> some View {
        VStack(spacing: 12) {
            if typeSize.isAccessibilitySize {
                // Avoid fixed-size visual labels at accessibility sizes.
                ForEach(visible) { item in
                    Button { selectedID = item.id; open(item) } label: {
                        Label(item.name, systemImage: "shippingbox").frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                    }.accessibilityIdentifier("inventory.item.\(item.name)")
                }
            } else {
                GeometryReader { proxy in
                    ZStack {
                        if zone == .fridge || zone == .freezer {
                            Image("VirtualFridgeInterior").resizable().scaledToFill()
                                .frame(width: proxy.size.width, height: proxy.size.height).clipped().accessibilityHidden(true)
                        } else { cupboard }
                        let displayed = Array(visible[VirtualPantryRules.pageRange(page: page, itemCount: visible.count)])
                        ForEach(Array(displayed.enumerated()), id: \.element.id) { index, item in
                            itemButton(item, wide: wide, iconSize: min(40, proxy.size.width * 0.1))
                                .frame(width: proxy.size.width * 0.25, height: proxy.size.height * 0.16)
                                .position(x: proxy.size.width * (0.23 + Double(index % 3) * 0.27),
                                          y: proxy.size.height * (0.23 + Double(index / 3) * 0.17))
                        }
                        if visible.isEmpty {
                            Text("No saved items here yet").font(.subheadline.weight(.semibold))
                                .foregroundStyle(.black).padding(14).background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 12))
                        }
                        if (zone == .fridge || zone == .freezer), !reduceMotion {
                            Ellipse().fill(.white.opacity(mist ? 0.55 : 0)).blur(radius: 22)
                                .frame(width: proxy.size.width * 0.9, height: proxy.size.height * 0.16)
                                .offset(y: mist ? 80 : 170).allowsHitTesting(false).accessibilityHidden(true)
                        }
                        if !reduceMotion {
                            HStack(spacing: 1) {
                                door(left: true).rotation3DEffect(.degrees(opened ? -100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading, perspective: 0.4)
                                door(left: false).rotation3DEffect(.degrees(opened ? 100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing, perspective: 0.4)
                            }.opacity(opened ? 0 : 1).allowsHitTesting(false).accessibilityHidden(true)
                        }
                    }.clipShape(RoundedRectangle(cornerRadius: 20))
                }.aspectRatio(2.0 / 3.0, contentMode: .fit)
            }
            if visible.count > 9 && !typeSize.isAccessibilitySize {
                HStack {
                    Button { page = max(0, page - 1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }.disabled(page == 0).accessibilityLabel("Previous shelves")
                    Spacer()
                    Text("\(page + 1) of \(VirtualPantryRules.pageCount(itemCount: visible.count))").font(.subheadline.monospacedDigit())
                    Spacer()
                    Button { page += 1 } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                        .disabled(page + 1 >= VirtualPantryRules.pageCount(itemCount: visible.count)).accessibilityLabel("Next shelves")
                }
            }
        }
    }
    private func itemButton(_ item: InventoryItem, wide: Bool, iconSize: CGFloat) -> some View {
        Button {
            selectedID = item.id
            if !wide { open(item) }
        } label: {
            VStack(spacing: 3) {
                Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
                    .font(.system(size: iconSize)).shadow(color: .black.opacity(0.18), radius: 3, y: 3).accessibilityHidden(true)
                Text(item.name).font(.caption2.weight(.semibold)).lineLimit(iconSize < 32 ? 1 : 2).multilineTextAlignment(.center)
                    .foregroundStyle(.black).padding(.horizontal, 5).padding(.vertical, 3)
                    .background(.white.opacity(0.96), in: RoundedRectangle(cornerRadius: 6))
                if InventoryRules.needsDateAttention(item.expiryDay, today: now) {
                    Label("Date", systemImage: "exclamationmark.circle.fill").font(.caption2.bold()).foregroundStyle(.black).padding(3).background(.yellow, in: Capsule())
                } else if item.isLowStock == true {
                    Text("Low").font(.caption2.bold()).foregroundStyle(.black).padding(3).background(.yellow, in: Capsule())
                }
            }.frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(selectedID == item.id ? Color.white.opacity(0.45) : .clear, in: RoundedRectangle(cornerRadius: 12))
        }.buttonStyle(.plain).accessibilityLabel(item.name)
            .accessibilityValue([item.quantityText ?? "Amount not set", item.isLowStock == true ? "Low stock" : ""].filter { !$0.isEmpty }.joined(separator: ", "))
            .accessibilityIdentifier("inventory.item.\(item.name)")
    }
    private func door(left: Bool) -> some View {
        RoundedRectangle(cornerRadius: 10).fill(LinearGradient(colors: [.init(white: 0.78), .init(white: 0.96), .init(white: 0.63)], startPoint: .leading, endPoint: .trailing))
            .overlay(alignment: left ? .trailing : .leading) {
                Capsule().fill(.gray.gradient).frame(width: 7, height: 110).padding(14)
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
    private var detail: some View {
        VStack(alignment: .leading, spacing: 16) {
            if let selected {
                Text(selected.name).font(AppTheme.sectionTitle).fixedSize(horizontal: false, vertical: true)
                Text(selected.quantityText ?? "Amount not set").font(.title3).foregroundStyle(.secondary)
                InventoryStatusBadges(item: selected, today: HouseholdDay(now).key)
                if let location = selected.location { Label(location, systemImage: "mappin") }
                Button("Edit pack", systemImage: "square.and.pencil") { open(selected) }
                    .frame(minHeight: 44).accessibilityIdentifier("inventory.virtual.edit")
                Text("Open pack details to update quantities, restock or mark it used up.").font(.footnote).foregroundStyle(.secondary)
            } else {
                Text(visible.isEmpty ? "Make room for your groceries" : "See what’s at home").font(AppTheme.sectionTitle)
                Text(visible.isEmpty ? "Add a saved item to bring this space to life. Check the other sections for your existing groceries." : "Select a pack to see its amount, dates and details. Each saved pack stays separate.")
                    .font(.body).foregroundStyle(.secondary)
            }
            Divider()
            Button("Add item", systemImage: "plus") { add() }.frame(minHeight: 44).accessibilityIdentifier("inventory.virtual.add")
            Button("Scan receipt", systemImage: "doc.viewfinder") { scan() }.frame(minHeight: 44).accessibilityIdentifier("inventory.virtual.scan")
        }.padding(24).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
    }
}
