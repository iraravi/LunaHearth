import SwiftUI

/// Glass belongs to the control layer; record cards and reading surfaces remain opaque.
struct HearthGlassControls<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        if #available(iOS 26, *) {
            GlassEffectContainer(spacing: 8) { content }
        } else {
            content
        }
    }
}

private struct HearthGlassButton: ViewModifier {
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var prominent: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *), !reduceTransparency, contrast != .increased {
            if prominent {
                content.buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else if prominent {
            content.buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

private struct HearthNavigationMaterial: ViewModifier {
    let fallback: Color
    let placement: ToolbarPlacement

    @ViewBuilder func body(content: Content) -> some View {
        if #available(iOS 26, *) {
            // Standard bars supply their own Liquid Glass and accessibility behavior.
            content
        } else {
            content.toolbarBackground(fallback, for: placement)
        }
    }
}

extension View {
    func hearthGlassButton(prominent: Bool = false) -> some View {
        modifier(HearthGlassButton(prominent: prominent))
    }

    func hearthNavigationMaterial(_ fallback: Color, for placement: ToolbarPlacement) -> some View {
        modifier(HearthNavigationMaterial(fallback: fallback, placement: placement))
    }
}
