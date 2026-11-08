import SwiftUI

/// Native switch semantics with a visible state word, independent of monochrome feature tints.
struct HouseholdToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Toggle(isOn: configuration.$isOn) {
            VStack(alignment: .leading, spacing: 3) {
                configuration.label
                Text(configuration.isOn ? "On" : "Off")
                    .font(.caption).foregroundStyle(.secondary).accessibilityHidden(true)
            }
        }.toggleStyle(SwitchToggleStyle(tint: Color("ControlBlue")))
    }
}
