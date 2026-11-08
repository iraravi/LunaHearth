import SwiftUI

/// Neutral native symbols complement the shared sans-serif typography.
/// Labels carry meaning; decoration is excluded from VoiceOver.
struct FeatureIllustration: View {
    let symbol: String
    var size: CGFloat = 56

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.monochrome)
            .font(.system(size: size * 0.42, weight: .medium))
            .foregroundStyle(AppTheme.ink)
            .frame(width: size, height: size)
            .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: size * 0.26, style: .continuous))
            .accessibilityHidden(true)
    }
}
