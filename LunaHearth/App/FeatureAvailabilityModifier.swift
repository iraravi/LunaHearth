import SwiftUI

/// Apply only to creation/proposal screens, never to lists of saved records.
private struct FeatureAvailabilityModifier: ViewModifier {
    @Environment(PublicConfigurationStore.self) private var status
    let feature: AppFeature
    func body(content: Content) -> some View {
        if status.configuration?.allows(feature) ?? true { content }
        else {
            ContentUnavailableView(feature.title, systemImage: "pause.circle", description: Text(status.configuration?.message(for: feature) ?? "Temporarily unavailable"))
        }
    }
}
extension View {
    func featureAvailability(_ feature: AppFeature) -> some View { modifier(FeatureAvailabilityModifier(feature: feature)) }
}
