import SwiftUI

enum AppTheme {
    static let canvas = Color("HearthCanvas")
    static let surface = Color("HearthSurface")
    static let ink = Color("HearthInk")
    static let muted = Color("HearthMuted")
    static let accent = Color("HearthAccent")
    static let secondarySurface = Color("HearthSecondary")
    static let cardCornerRadius: CGFloat = 18
    static let sectionSpacing: CGFloat = 16
    static let contentPadding: CGFloat = 20
    static let displayTitle = Font.system(.largeTitle, design: .serif, weight: .regular)
    static let sectionTitle = Font.system(.title2, design: .serif, weight: .regular)
    static let sage = Color("IllustrationGreen")
    static let clay = Color("IllustrationOrange")
    static let slate = Color("IllustrationBlue")
    static let plum = Color("IllustrationPurple")
    static let rose = Color("IllustrationCoral")
    static let ochre = Color("HearthOchre")
}

/// Decorative category accents; navigation and primary actions stay black and white.
private enum IllustrationPalette {
    static func color(for symbol: String) -> Color {
        let name: String
        switch symbol {
        case let value where value.contains("calendar") || value.contains("clock") || value.contains("drop"):
            name = "IllustrationBlue"
        case let value where value.contains("check") || value.contains("leaf") || value.contains("shield"):
            name = "IllustrationGreen"
        case let value where value.contains("basket") || value.contains("cart") || value.contains("carrot"):
            name = "IllustrationOrange"
        case let value where value.contains("fork") || value.contains("book") || value.contains("doc"):
            name = "IllustrationPurple"
        default:
            name = "IllustrationCoral"
        }
        return Color(name)
    }
}

struct HearthIcon: View {
    let symbol: String
    var body: some View {
        Image(systemName: symbol)
            .font(.title3.weight(.semibold))
            .foregroundStyle(IllustrationPalette.color(for: symbol))
            .frame(width: 46, height: 46)
            .background(IllustrationPalette.color(for: symbol).opacity(0.12), in: RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}

struct HearthArtwork: View {
    let name: String
    var height: CGFloat = 140
    var body: some View {
        GeometryReader { geometry in
            Image(name).resizable().scaledToFill()
                .frame(width: geometry.size.width, height: height).clipped()
        }
        .frame(height: height)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .accessibilityHidden(true)
    }
}

struct ScreenIntro: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var art: String?
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(eyebrow).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.muted)
            Text(title).font(.system(.largeTitle, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
                .fixedSize(horizontal: false, vertical: true)
            Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.muted)
                .fixedSize(horizontal: false, vertical: true)
            if let art { HearthArtwork(name: art).padding(.top, 4) }
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct DashboardCard<Content: View>: View {
    let title: String
    var symbol: String
    var detail: String?
    @ViewBuilder var content: Content

    init(_ title: String, symbol: String = "house", detail: String? = nil, @ViewBuilder content: () -> Content) {
        self.title = title
        self.symbol = symbol
        self.detail = detail
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 18) {
            HStack(spacing: 12) {
                HearthIcon(symbol: symbol)
                VStack(alignment: .leading, spacing: 3) {
                    Text(title).font(.headline).foregroundStyle(AppTheme.ink)
                    if let detail { Text(detail).font(.caption).foregroundStyle(AppTheme.muted) }
                }
                Spacer(minLength: 0)
            }
            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(AppTheme.contentPadding)
        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: AppTheme.cardCornerRadius))
        .hearthCardOutline(AppTheme.ink, radius: AppTheme.cardCornerRadius)
    }
}

struct GentleEmptyState: View {
    let title: String
    let message: String
    let symbol: String
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: symbol).font(.title3).foregroundStyle(AppTheme.accent).accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.subheadline.weight(.medium)).foregroundStyle(AppTheme.ink)
                Text(message).font(.subheadline).foregroundStyle(AppTheme.muted)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }.padding(.vertical, 6)
    }
}

struct SectionLink: View {
    let title: String
    var body: some View {
        HStack {
            Text(title).font(.subheadline.weight(.semibold))
            Spacer()
            Image(systemName: "arrow.right").font(.caption.weight(.semibold))
        }.foregroundStyle(AppTheme.accent).frame(minHeight: 44)
    }
}

struct SummaryMetric: View {
    let count: Int
    let title: String
    let symbol: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: symbol).font(.subheadline.weight(.semibold)).foregroundStyle(IllustrationPalette.color(for: symbol)).accessibilityHidden(true)
            Text(count, format: .number).font(.system(.title2, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
            Text(title).font(.caption).foregroundStyle(AppTheme.muted)
        }.frame(maxWidth: .infinity, alignment: .leading).padding(16)
            .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 16))
            .accessibilityElement(children: .combine)
    }
}

private struct HearthListStyle: ViewModifier {
    var canvas: Color = AppTheme.canvas
    func body(content: Content) -> some View {
        content.scrollContentBackground(.hidden)
            .background(canvas)
            .listRowSeparatorTint(AppTheme.ink.opacity(0.12))
            .tint(AppTheme.accent)
    }
}

extension View {
    func hearthList(canvas: Color = AppTheme.canvas) -> some View { modifier(HearthListStyle(canvas: canvas)) }
}

extension AssetCategory {
    var symbol: String {
        switch self {
        case .appliance: "refrigerator"
        case .electronics: "tv"
        case .furniture: "sofa"
        case .hvac: "fan"
        case .plumbing: "drop"
        case .vehicle: "car"
        case .tool: "hammer"
        case .safety: "checkmark.shield"
        case .other: "shippingbox"
        }
    }
}

/// Visible boundaries strengthen with the system's Increase Contrast setting.
private struct HearthCardOutline: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.colorSchemeContrast) private var contrast
    let color: Color
    let radius: CGFloat
    func body(content: Content) -> some View {
        content.overlay {
            RoundedRectangle(cornerRadius: radius)
                .strokeBorder(color.opacity(contrast == .increased ? 0.6 : (colorScheme == .dark ? 0.30 : 0.12)), lineWidth: contrast == .increased ? 2 : 1)
                .allowsHitTesting(false).accessibilityHidden(true)
        }
    }
}

extension View {
    func hearthCardOutline(_ color: Color, radius: CGFloat = 18) -> some View {
        modifier(HearthCardOutline(color: color, radius: radius))
    }
}

/// Shared editorial hierarchy; imagery yields to large accessibility text.
struct HearthEditorialHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    var artwork: String?
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 10) {
                    Text(eyebrow.uppercased()).font(.caption2.weight(.medium)).tracking(1.8)
                        .foregroundStyle(AppTheme.muted)
                    Text(title).font(AppTheme.displayTitle).foregroundStyle(AppTheme.ink)
                        .fixedSize(horizontal: false, vertical: true).accessibilityAddTraits(.isHeader)
                    Text(subtitle).font(.subheadline).foregroundStyle(AppTheme.muted)
                        .fixedSize(horizontal: false, vertical: true)
                }.frame(maxWidth: .infinity, alignment: .leading)
                if let artwork, !textSize.isAccessibilitySize {
                    Image(artwork).resizable().scaledToFill()
                        .frame(width: sizeClass == .regular ? 220 : 112, height: 144)
                        .clipped().clipShape(RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
                }
            }
            Divider().overlay(AppTheme.ink.opacity(0.05))
        }.padding(.vertical, 4)
    }
}
