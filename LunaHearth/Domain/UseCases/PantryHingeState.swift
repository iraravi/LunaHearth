/// Physical hinge observations only; geometry and device names never infer capability.
enum PantryHingeState: Equatable, Sendable {
    case unavailable, unknown, closed, partiallyOpen, fullyOpen
    var supportsVirtualPantry: Bool { self != .unavailable }
    var interiorVisible: Bool? {
        switch self {
        case .closed: false
        case .partiallyOpen, .fullyOpen: true
        case .unavailable, .unknown: nil
        }
    }
}
