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
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    var prominent: Bool
    var glassInLight: Bool

    @ViewBuilder func body(content: Content) -> some View {
        if colorScheme == .dark {
            content.buttonStyle(HearthOpaqueButtonStyle(prominent: prominent))
        } else if #available(iOS 26, *), glassInLight, !reduceTransparency, contrast != .increased {
            if prominent {
                content.foregroundStyle(AppTheme.canvas).buttonStyle(.glassProminent)
            } else {
                content.buttonStyle(.glass)
            }
        } else if prominent {
            content.foregroundStyle(AppTheme.canvas).buttonStyle(.borderedProminent)
        } else {
            content.buttonStyle(.bordered)
        }
    }
}

/// Opaque dark controls keep their contrast independent of the content behind them.
private struct HearthOpaqueButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.colorSchemeContrast) private var contrast
    let prominent: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .fontWeight(.semibold)
            .foregroundStyle(isEnabled ? (prominent ? AppTheme.canvas : AppTheme.ink) : AppTheme.muted)
            .padding(.horizontal, 12).padding(.vertical, 6)
            .frame(minHeight: 44)
            .background {
                Capsule().fill(prominent && isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(AppTheme.secondarySurface))
            }
            .overlay {
                Capsule().strokeBorder(AppTheme.ink.opacity(contrast == .increased ? 0.65 : 0.30), lineWidth: contrast == .increased ? 2 : 1)
                    .allowsHitTesting(false)
            }
            .overlay {
                if configuration.isPressed && isEnabled {
                    Capsule().fill(AppTheme.ink.opacity(0.12)).allowsHitTesting(false)
                }
            }
            .contentShape(Capsule())
    }
}

/// A round 44-point icon button. System glass and bordered styles pad the label, so a label
/// framed at 44 points grows to about 68 by 58; this keeps the control at the touch target.
private struct HearthIconButtonStyle: ButtonStyle {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.colorSchemeContrast) private var contrast
    @Environment(\.isEnabled) private var isEnabled

    func makeBody(configuration: Configuration) -> some View {
        let label = configuration.label
            .labelStyle(.iconOnly)
            .fontWeight(.semibold)
            .frame(width: 44, height: 44)
            .contentShape(Circle())
            .opacity(configuration.isPressed ? 0.6 : 1)
        if #available(iOS 26, *), colorScheme != .dark, !reduceTransparency, contrast != .increased {
            label.foregroundStyle(isEnabled ? AnyShapeStyle(.tint) : AnyShapeStyle(AppTheme.muted))
                .glassEffect(.regular.interactive(), in: Circle())
        } else {
            label.foregroundStyle(isEnabled ? AppTheme.ink : AppTheme.muted)
                .background(Circle().fill(AppTheme.secondarySurface))
                .overlay {
                    Circle().strokeBorder(AppTheme.ink.opacity(contrast == .increased ? 0.65 : 0.30), lineWidth: contrast == .increased ? 2 : 1)
                        .allowsHitTesting(false)
                }
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
    func hearthGlassButton(prominent: Bool = false, glassInLight: Bool = true) -> some View {
        modifier(HearthGlassButton(prominent: prominent, glassInLight: glassInLight))
    }

    /// Icon-only round button at exactly the 44-point touch target, in glass or the opaque dark style.
    func hearthIconButton() -> some View {
        buttonStyle(HearthIconButtonStyle())
    }

    func hearthNavigationMaterial(_ fallback: Color, for placement: ToolbarPlacement) -> some View {
        modifier(HearthNavigationMaterial(fallback: fallback, placement: placement))
    }
}
