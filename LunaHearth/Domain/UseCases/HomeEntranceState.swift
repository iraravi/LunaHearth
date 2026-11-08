/// Presentation only. Door changes never modify household records or navigation drafts.
struct HomeEntranceState: Equatable {
    private(set) var isOpen = false
    private(set) var followsHinge = false

    mutating func observe(_ state: PantryHingeState) {
        guard let open = state.interiorVisible else { return }
        followsHinge = true
        isOpen = open
    }

    mutating func toggleManually() {
        guard !followsHinge else { return }
        isOpen.toggle()
    }
}
