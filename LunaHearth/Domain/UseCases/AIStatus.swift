import Foundation

enum AIAvailability: String, Sendable, CaseIterable {
    case ready, disabled, preparing, unsupportedDevice, olderOS, unavailable
    var showsAIActions: Bool { self == .ready }
    var filterTitle: String { showsAIActions ? "Filters & AI" : "Filters" }

    var title: String {
        switch self {
        case .ready: "Ready on this device"
        case .disabled: "Apple Intelligence is off"
        case .preparing: "Model is still preparing"
        case .unsupportedDevice: "Device not eligible"
        case .olderOS: "Requires iOS 26 or later"
        case .unavailable: "Currently unavailable"
        }
    }
    var guidance: String {
        switch self {
        case .ready: "On-device text AI is available. Individual requests can still use a fallback if generation fails."
        case .disabled: "Check Settings → Apple Intelligence & Siri, then return here to refresh."
        case .preparing: "Apple has not finished preparing the model. Check Apple Intelligence in Settings and try again later."
        case .unsupportedDevice: "Apple reports that this device cannot run its on-device language model. Manual entry and label reading still work."
        case .olderOS: "LunaHearth’s text AI needs iOS 26 or later on an eligible device. Manual features remain available."
        case .unavailable: "Apple could not report a usable model. You can keep using the app without AI."
        }
    }
}
struct AIStatusSnapshot: Sendable {
    let device: String
    let hardware: String
    let system: String
    let availability: AIAvailability
    let supportsImageInput: Bool
    let checkedAt: Date
    var imageAIReady: Bool { availability == .ready && supportsImageInput }
    var pantryMode: String { imageAIReady ? "Photo AI available" : "Product-label reading" }
}
@MainActor protocol AIStatusProviding {
    func status() -> AIStatusSnapshot
}
