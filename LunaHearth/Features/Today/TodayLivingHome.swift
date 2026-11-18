import SwiftUI

/// A local, read-only scene. Actions use the existing task, shopping and inventory flows.
struct TodayLivingHome: View {
    let tasks: [HouseholdTask]
    let shopping: [GroceryItem]
    let inventory: [InventoryItem]
    let expanded: Bool
    let enterHome: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var fridgeOpen = false
    @AppStorage(PantryCategoryMemory.storageKey) private var categoryMemory = ""
    private var chilled: [InventoryItem] {
        inventory.filter { VirtualPantryRules.zone(name: $0.name, location: $0.location) == .fridge }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Text("Life at home").font(.title2.bold()).accessibilityAddTraits(.isHeader)
                Spacer()
                Image(systemName: "house").foregroundStyle(TodayTheme.muted).accessibilityHidden(true)
            }
            Text("A little more together.").font(.subheadline).foregroundStyle(TodayTheme.muted)
            Button(action: enterHome) {
                HStack {
                    Image(systemName: "door.left.hand.open").font(.title2)
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Step inside your home").font(.headline)
                        Text("Kitchen, tasks and shopping").font(.caption)
                    }
                    Spacer()
                    Image(systemName: "arrow.right")
                }.padding(18).foregroundStyle(TodayTheme.canvas)
                    .background(TodayTheme.ink, in: RoundedRectangle(cornerRadius: 20))
            }.buttonStyle(.plain).accessibilityIdentifier("today.enterHome")

            (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 14)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))) {
                NavigationLink { PlanningListView(kind: .task) } label: {
                    tile(symbol: "checklist", count: tasks.count, title: "Tasks",
                         detail: tasks.isEmpty ? "Nothing due" : tasks.count == 1 ? "needs attention" : "need attention") {
                        if tasks.isEmpty {
                            Label("All clear", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(TodayTheme.accent)
                        } else {
                            ForEach(tasks.prefix(2)) { task in
                                HStack(spacing: 6) {
                                    Image(systemName: "circle").font(.caption2).foregroundStyle(TodayTheme.accent)
                                    Text(task.title).font(.caption).foregroundStyle(TodayTheme.ink).lineLimit(1)
                                }
                            }
                        }
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("today.living.tasks")
                NavigationLink { ShoppingListView() } label: {
                    tile(symbol: "basket", count: shopping.count, title: "Shopping",
                         detail: shopping.isEmpty ? "All caught up" : "left to buy") {
                        if shopping.isEmpty {
                            Label("List is clear", systemImage: "checkmark.circle.fill").font(.caption.weight(.semibold)).foregroundStyle(TodayTheme.accent)
                        } else {
                            let memory = PantryCategoryMemory.decode(categoryMemory)
                            HStack(spacing: -6) {
                                ForEach(shopping.prefix(4)) { item in
                                    Text(PantryVisualRules.icon(item.name, memory: memory)).font(.system(size: 17))
                                        .frame(width: 32, height: 32)
                                        .background(TodayTheme.hero, in: Circle())
                                        .overlay(Circle().strokeBorder(TodayTheme.surface, lineWidth: 2))
                                }
                                if shopping.count > 4 {
                                    Text("+\(shopping.count - 4)").font(.caption2.weight(.bold)).foregroundStyle(TodayTheme.ink)
                                        .frame(width: 32, height: 32).background(TodayTheme.hero, in: Circle())
                                        .overlay(Circle().strokeBorder(TodayTheme.surface, lineWidth: 2))
                                }
                            }
                        }
                    }
                }.buttonStyle(.plain).accessibilityIdentifier("today.living.shopping")
            }
            VStack(spacing: 0) {
                fridge.frame(height: expanded ? 260 : 145).clipped()
                    .overlay(alignment: .topTrailing) {
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.65)) { fridgeOpen.toggle() }
                        } label: {
                            Label(fridgeOpen ? "Close fridge" : "Open fridge", systemImage: "door.left.hand.open")
                                .font(.subheadline.weight(.semibold)).foregroundStyle(.black)
                                .padding(12).background(.white.opacity(0.95), in: Capsule())
                        }.buttonStyle(.plain)
                            .accessibilityHidden(false)
                            .accessibilityValue(fridgeOpen ? "Open" : "Closed")
                            .accessibilityIdentifier("today.living.fridge")
                            .padding(12)
                    }
                NavigationLink { InventoryView() } label: {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Fridge & pantry").font(.headline)
                            Text(inventory.isEmpty ? "Add what you have at home" : "\(inventory.count) packs at home")
                                .font(.caption).foregroundStyle(TodayTheme.muted)
                        }
                        Spacer()
                        Image(systemName: "arrow.up.right").font(.body.weight(.semibold))
                    }.padding(18).frame(minHeight: 60).contentShape(Rectangle())
                }.buttonStyle(.plain).accessibilityIdentifier("today.living.pantry")
            }.background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                .clipShape(RoundedRectangle(cornerRadius: 22))
        }.accessibilityElement(children: .contain).accessibilityIdentifier("today.livingHome")

    }

    /// A clean summary tile: amber icon chip, large count, label and a small preview.
    private func tile<Preview: View>(symbol: String, count: Int, title: String, detail: String,
                                     @ViewBuilder preview: () -> Preview) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .top) {
                Image(systemName: symbol).font(.body.weight(.semibold)).foregroundStyle(TodayTheme.accent)
                    .frame(width: 40, height: 40).background(TodayTheme.accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                Spacer(minLength: 4)
                Text(count, format: .number).font(.system(.largeTitle, design: .rounded, weight: .bold)).monospacedDigit()
                    .foregroundStyle(TodayTheme.ink).contentTransition(.numericText())
                    .accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(title).font(.headline).foregroundStyle(TodayTheme.ink)
                Text(detail).font(.caption).foregroundStyle(TodayTheme.muted).fixedSize(horizontal: false, vertical: true)
            }
            VStack(alignment: .leading, spacing: 5) { preview() }.frame(minHeight: expanded ? 44 : 32, alignment: .topLeading)
        }
        .padding(16).frame(maxWidth: .infinity, alignment: .leading)
        .background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 22))
        .overlay(RoundedRectangle(cornerRadius: 22).strokeBorder(TodayTheme.ink.opacity(0.06), lineWidth: 1))
        .accessibilityElement(children: .combine)
        .accessibilityLabel("\(title), \(count == 0 ? detail : "\(count) \(detail)")")
    }

    private var fridge: some View {
        GeometryReader { geometry in
            ZStack {
                Color(white: 0.12)
                Image("VirtualFridgeOpen").resizable()
                    .frame(height: geometry.size.height / 0.665)
                    .frame(height: geometry.size.height, alignment: .top).clipped()
                HStack(spacing: 24) {
                    ForEach(chilled.prefix(4)) { item in
                        Text(PantryVisualRules.icon(item.name, memory: PantryCategoryMemory.decode(categoryMemory)))
                            .font(.system(size: expanded ? 44 : 30))
                    }
                }.offset(y: geometry.size.height * 0.10)
                if fridgeOpen { FridgeMistView(reduceMotion: reduceMotion) }
                HStack(spacing: 0) {
                    previewDoor(left: true, size: geometry.size)
                        .rotation3DEffect(.degrees(fridgeOpen ? -105 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                    previewDoor(left: false, size: geometry.size)
                        .rotation3DEffect(.degrees(fridgeOpen ? 105 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                }.opacity(fridgeOpen ? 0 : 1)
            }
        }
    }

    private func previewDoor(left: Bool, size: CGSize) -> some View {
        Image("VirtualFridgeClosed").resizable()
            .frame(width: size.width, height: size.height / 0.665)
            .offset(x: left ? 0 : -size.width / 2)
            .frame(width: size.width / 2, height: size.height, alignment: .topLeading).clipped()
    }
}
