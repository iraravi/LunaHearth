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
                        .scaleEffect(entrance.isOpen ? 1 : 1.08)
                        .accessibilityHidden(true)
                    if entrance.isOpen { destinations(size: geometry.size) }
                    HStack(spacing: 0) {
                        frontDoor(left: true)
                            .rotation3DEffect(.degrees(entrance.isOpen ? -100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .leading)
                        frontDoor(left: false)
                            .rotation3DEffect(.degrees(entrance.isOpen ? 100 : 0), axis: (x: 0, y: 1, z: 0), anchor: .trailing)
                    }.opacity(entrance.isOpen ? 0 : 1).allowsHitTesting(false).accessibilityHidden(true)
                    if !entrance.isOpen {
                        VStack(spacing: 14) {
                            Text("Welcome home").font(.largeTitle.bold())
                            if entrance.followsHinge {
                                Text("Unfold to step inside").font(.headline)
                            } else {
                                Button("Open door", systemImage: "door.left.hand.open") {
                                    withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.9)) { entrance.toggleManually() }
                                }.buttonStyle(.borderedProminent).tint(.white).foregroundStyle(.black)
                                    .accessibilityIdentifier("home.scene.open")
                            }
                        }.foregroundStyle(.white).padding(24)
                            .background(.black.opacity(0.55), in: RoundedRectangle(cornerRadius: 24))
                            .padding(24)
                    }
                }.clipped()
            }
            .navigationTitle("Your home").navigationBarTitleDisplayMode(.inline)
            .navigationDestination(for: Destination.self) { destination in
                Group {
                    switch destination {
                    case .kitchen: HomeKitchenView()
                    case .tasks: PlanningListView(kind: .task)
                    case .shopping: ShoppingListView()
                    }
                }
                // Returning home is explicit; posture updates never pop an editor or lose a draft.
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button("Home view", systemImage: "house") { path.removeAll() }
                            .accessibilityIdentifier("home.scene.return")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Dashboard", systemImage: "list.bullet") { dismiss() }
                        .accessibilityIdentifier("home.scene.exit")
                }
            }
        }
        .background(PantryHingeObserver { state in
            withAnimation(reduceMotion ? nil : .easeInOut(duration: 0.9)) { entrance.observe(state) }
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

    private func frontDoor(left: Bool) -> some View {
        GeometryReader { geometry in
            ZStack {
                LinearGradient(colors: [Color(white: left ? 0.22 : 0.18), Color(white: 0.08)], startPoint: .topLeading, endPoint: .bottomTrailing)
                RoundedRectangle(cornerRadius: 8).stroke(.white.opacity(0.1), lineWidth: 2).padding(18)
                RoundedRectangle(cornerRadius: 5)
                    .fill(LinearGradient(colors: [.white.opacity(0.16), .black.opacity(0.8)], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: geometry.size.width * 0.48, height: geometry.size.height * 0.29)
                    .overlay { RoundedRectangle(cornerRadius: 5).stroke(.white.opacity(0.25), lineWidth: 2) }
                    .offset(y: -geometry.size.height * 0.22)
                Capsule().fill(LinearGradient(colors: [.gray, .white, .gray], startPoint: .leading, endPoint: .trailing))
                    .frame(width: 9, height: 92)
                    .position(x: geometry.size.width * (left ? 0.84 : 0.16), y: geometry.size.height * 0.57)
            }.overlay(alignment: left ? .trailing : .leading) { Color.black.frame(width: 2) }
        }
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
