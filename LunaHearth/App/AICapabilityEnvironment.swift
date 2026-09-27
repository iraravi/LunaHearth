import SwiftUI

private struct AIAvailabilityKey: EnvironmentKey {
    static let defaultValue: AIAvailability = .unavailable
}

extension EnvironmentValues {
    var aiAvailability: AIAvailability {
        get { self[AIAvailabilityKey.self] }
        set { self[AIAvailabilityKey.self] = newValue }
    }
}
