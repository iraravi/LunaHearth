import SwiftUI

/// V1-inspired native symbols, with restrained category accents on neutral surfaces.
/// Labels carry meaning; decoration is excluded from VoiceOver.
struct FeatureIllustration: View {
    let symbol: String
    var size: CGFloat = 56
    @Environment(\.colorSchemeContrast) private var contrast

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(contrast == .increased ? AppTheme.ink : IllustrationPalette.color(for: symbol))
            .frame(width: size, height: size)
            .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }
}
