import Foundation

enum AssignmentFocus: String, Sendable {
    case shopping, tasks
    var title: String { self == .shopping ? "Your shopping assignments" : "Your task assignments" }
    var symbol: String { self == .shopping ? "basket" : "checklist" }
}

struct AssignmentNotificationRoute: Equatable, Sendable {
    let focus: AssignmentFocus
    let householdID: UUID
    init?(identifier: String) {
        let parts = identifier.split(separator: ".")
        guard parts.count == 4, parts[1] == "personal", parts[3] == "notification",
              let focus = AssignmentFocus(rawValue: String(parts[0])), let home = UUID(uuidString: String(parts[2])) else { return nil }
        self.focus = focus; householdID = home
    }
}
