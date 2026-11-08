import SwiftUI

/// An illustrative home, not a model of the household's actual rooms.
struct InteractiveHomeView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var entrance = HomeEntranceState()
    @State private var path: [Destination] = []
    private enum Destination: String, Hashable, CaseIterable {
        case kitchen, tasks, shopping
        var title: String {
            switch self { case .kitchen: "Kitchen"; case .tasks: "Tasks"; case .shopping: "Shopping" }
        }
        var symbol: String {
            switch self { case .kitchen: "refrigerator"; case .tasks: "checklist"; case .shopping: "basket" }
        }
        var detail: String {
            switch self { case .kitchen: "Fridge & pantry"; case .tasks: "Reminders & chores"; case .shopping: "Your household list" }
        }
    }

    var body: some View {
        NavigationStack(path: $path) {
            GeometryReader { geometry in
                ZStack {
                    Color(white: 0.10)
                    Image("LivingHomeInterior").resizable().scaledToFill()
                        .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        .accessibilityHidden(true)
                    if entrance.isOpen { destinations(size: geometry.size) }
                    ZStack {
                        Image("LivingHomeExterior").resizable().scaledToFill()
                            .frame(width: geometry.size.width, height: geometry.size.height).clipped()
                        // Match the doorway in the square exterior artwork after aspect-fill cropping.
                        let side = max(geometry.size.width, geometry.size.height)
                        ZStack {
                            Image("LivingHomeInterior").resizable().scaledToFill()
                                .frame(width: side * 0.34, height: side * 0.55).clipped()
                            HStack(spacing: 0) {
                                doorLeaf(left: true, side: side)
                                    .rotation3DEffect(.degrees(entrance.isOpen ? -100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                                doorLeaf(left: false, side: side)
                                    .rotation3DEffect(.degrees(entrance.isOpen ? 100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                            }
                        }
                        .frame(width: side * 0.34, height: side * 0.55)
                        .offset(y: -side * 0.011)
                    }
                    .opacity(entrance.isOpen ? 0 : 1).allowsHitTesting(false).accessibilityHidden(true)
                    if !entrance.isOpen && !entrance.followsHinge {
                        Button {
                            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.85)) {
                                entrance.toggleManually()
                            }
                        } label: {
                            Image(systemName: "door.left.hand.open").font(.title2)
                                .foregroundStyle(.black).frame(width: 52, height: 52)
                                .background(.white.opacity(0.95), in: Circle())
                        }.buttonStyle(.plain)
                            .accessibilityLabel("Open door")
                            .accessibilityIdentifier("home.scene.open")
                            .padding(.bottom, 32)
                            .frame(maxHeight: .infinity, alignment: .bottom)
                    }
                }.clipped()
            }
            .ignoresSafeArea()
            .statusBarHidden()
            .toolbar(.hidden, for: .navigationBar)
            .overlay(alignment: .topTrailing) {
                Button { dismiss() } label: {
                    Image(systemName: "xmark").font(.body.weight(.semibold))
                        .foregroundStyle(.black).frame(width: 48, height: 48)
                        .background(.white.opacity(0.95), in: Circle())
                }.buttonStyle(.plain).padding(16)
                    .accessibilityLabel("Dashboard")
                    .accessibilityIdentifier("home.scene.exit")
            }
            .navigationDestination(for: Destination.self) { destination in
                Group {
                    switch destination {
                    case .kitchen: HomeKitchenView()
                    case .tasks: PlanningListView(kind: .task)
                    case .shopping: ShoppingListView()
                    }
                }
                .toolbar(.visible, for: .navigationBar)
                .statusBarHidden(false)
                // Returning home is explicit; posture updates never pop an editor or lose a draft.
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Home view", systemImage: "house") { path.removeAll() }
                            .accessibilityIdentifier("home.scene.return")
                    }
                }
            }

        }
        .background(PantryHingeObserver { state in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.85)) {
                entrance.observe(state)
            }
        })
        .interactiveDismissDisabled()
    }

    @ViewBuilder private func destinations(size: CGSize) -> some View {
        if size.width >= 720 && !typeSize.isAccessibilitySize {
            // Scene anchors correspond to the bundled landscape artwork.
            destination(.tasks).position(x: size.width * 0.17, y: size.height * 0.46)
            destination(.kitchen).position(x: size.width * 0.54, y: size.height * 0.40)
            destination(.shopping).position(x: size.width * 0.82, y: size.height * 0.73)
        } else {
            // Keep every action visible when artwork is cropped in a narrow window.
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Destination.allCases, id: \.self) { destination($0) }
                }.padding(20)
            }.frame(maxHeight: .infinity, alignment: .bottom)
                .defaultScrollAnchor(.bottom)
        }
    }

    private func destination(_ value: Destination) -> some View {
        Button { path.append(value) } label: {
            HStack(spacing: 12) {
                Image(systemName: value.symbol).font(.title2)
                VStack(alignment: .leading, spacing: 3) {
                    Text(value.title).font(.headline)
                    Text(value.detail).font(.caption)
                }
                Image(systemName: "chevron.right").font(.caption.bold())
            }.foregroundStyle(.black).padding(16)
                .background(.white.opacity(0.95), in: RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 12, y: 6)
        }.buttonStyle(.plain).accessibilityIdentifier("home.scene.\(value.rawValue)")
    }

    private func doorLeaf(left: Bool, side: CGFloat) -> some View {
        Image("LivingHomeExteriorDoors").resizable()
            .frame(width: side, height: side)
            .offset(x: -side * (left ? 0.33 : 0.50), y: -side * 0.214)
            .frame(width: side * 0.17, height: side * 0.55, alignment: .topLeading)
            .clipped()
    }

}

/// Keep the virtual kitchen in the home navigation stack rather than stacking full-screen covers.
private struct HomeKitchenView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var hinge: PantryHingeState = .unavailable
    @State private var showsList = false
    var body: some View {
        Group {
            if showsList {
                InventoryView(allowsVirtualView: false)
                    .toolbar {
                        ToolbarItem(placement: .primaryAction) {
                            Button("Virtual kitchen", systemImage: "refrigerator") { showsList = false }
                                .accessibilityIdentifier("home.kitchen.virtual")
                        }
                    }
            } else {
                VirtualPantryView(items: repository.inventory.filter { !$0.isUsedUp },
                                 hingeState: hinge == .unavailable ? .fullyOpen : hinge,
                                 exit: { showsList = true })
                    .navigationTitle("Kitchen")
            }
        }.background(PantryHingeObserver { state in
            if state != .unavailable { hinge = state }
        })
    }
}
