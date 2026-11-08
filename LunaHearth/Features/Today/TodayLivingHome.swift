import SwiftUI

/// A local, read-only scene. Actions use the existing task, shopping and inventory flows.
struct TodayLivingHome: View {
    let tasks: [HouseholdTask]
    let shopping: [GroceryItem]
    let inventory: [InventoryItem]
    let expanded: Bool
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var fridgeOpen = false
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
            (typeSize.isAccessibilitySize ? AnyLayout(VStackLayout(spacing: 14)) : AnyLayout(HStackLayout(alignment: .top, spacing: 14))) {
                NavigationLink { PlanningListView(kind: .task) } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        noticeboard.frame(height: expanded ? 120 : 80)
                        tileLabel("Tasks", detail: tasks.isEmpty ? "Nothing due" : "\(tasks.count) need attention")
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 22))
                }.buttonStyle(.plain).accessibilityIdentifier("today.living.tasks")
                NavigationLink { ShoppingListView() } label: {
                    VStack(alignment: .leading, spacing: 12) {
                        groceryBag.frame(height: expanded ? 120 : 80)
                        tileLabel("Shopping", detail: shopping.isEmpty ? "All caught up" : "\(shopping.count) left to buy")
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
                        .background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 22))
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

    private func tileLabel(_ title: String, detail: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.headline)
            Text(detail).font(.caption).foregroundStyle(TodayTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var noticeboard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 14).fill(Color(red: 0.25, green: 0.30, blue: 0.36).gradient)
            VStack(spacing: 7) {
                ForEach(0..<3) { index in
                    HStack(spacing: 7) {
                        Image(systemName: tasks.isEmpty ? "checkmark.circle.fill" : "circle")
                            .foregroundStyle(Color(red: 0.83, green: 0.68, blue: 0.46))
                        Capsule().fill(.white.opacity(index < tasks.count ? 0.8 : 0.22)).frame(height: 4)
                    }
                }
            }.font(.system(size: 12)).padding(16)
        }.frame(width: expanded ? 160 : 120, height: expanded ? 100 : 68).rotationEffect(.degrees(-3)).padding(.horizontal, 8)
            .shadow(color: .black.opacity(0.14), radius: 5, y: 5)
            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : tasks.count)
            .accessibilityHidden(true)
    }

    private var groceryBag: some View {
        ZStack(alignment: .bottom) {
            RoundedRectangle(cornerRadius: 12).stroke(Color(red: 0.50, green: 0.39, blue: 0.27), lineWidth: 5)
                .frame(width: 35, height: 55).offset(y: -28)
            HStack(spacing: -5) {
                ForEach(Array(shopping.prefix(3).enumerated()), id: \.element.id) { index, item in
                    Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
                        .font(.system(size: expanded ? 35 : 25)).rotationEffect(.degrees(Double(index - 1) * 12))
                }
            }.offset(y: -32)
            RoundedRectangle(cornerRadius: 10).fill(Color(red: 0.73, green: 0.58, blue: 0.40).gradient)
                .frame(width: expanded ? 95 : 72, height: expanded ? 66 : 48)
                .overlay { Image(systemName: "basket").font(.title3).foregroundStyle(.white.opacity(0.8)) }
        }.frame(maxWidth: .infinity).padding(.bottom, 4)
            .shadow(color: .black.opacity(0.14), radius: 5, y: 5)
            .symbolEffect(.bounce, options: .nonRepeating, value: reduceMotion ? 0 : shopping.count)
            .accessibilityHidden(true)
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
                        Text(PantryVisualRules.icon(item.name, category: PantryVisualRules.category(item.name)))
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
