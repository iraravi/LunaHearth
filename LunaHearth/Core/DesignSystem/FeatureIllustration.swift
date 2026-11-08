import SwiftUI

/// Native decorative symbols; adjacent text supplies the accessible action name.
struct FeatureIllustration: View {
    let symbol: String
    var size: CGFloat = 56
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        Image(systemName: symbol)
            .symbolRenderingMode(.hierarchical)
            .font(.system(size: size * 0.43, weight: .semibold))
            .foregroundStyle(colorScheme == .dark ? Color.orange : Color(red: 0.76, green: 0.15, blue: 0.1))
            .frame(width: size, height: size)
            .background {
                RoundedRectangle(cornerRadius: size * 0.28)
                    .fill(LinearGradient(colors: [Color.red.opacity(0.16), Color.orange.opacity(0.09)], startPoint: .topLeading, endPoint: .bottomTrailing))
            }
            .accessibilityHidden(true)
    }
}
