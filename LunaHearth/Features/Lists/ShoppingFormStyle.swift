import SwiftUI

struct ShoppingFormCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 18) { content }
            .padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(ShoppingTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}

extension View {
    func shoppingInputStyle() -> some View {
        self.font(.body).padding(14).frame(minHeight: 52)
            .background(ShoppingTheme.canvas, in: RoundedRectangle(cornerRadius: 14))
            .overlay { RoundedRectangle(cornerRadius: 14).strokeBorder(ShoppingTheme.muted.opacity(0.25)) }
    }
}

struct ShoppingBottomAction: View {
    let title: String
    let detail: String
    let disabled: Bool
    let identifier: String
    let action: () -> Void
    var body: some View {
        HStack(spacing: 16) {
            Text(detail).font(.caption).foregroundStyle(ShoppingTheme.muted)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button(action: action) {
                Text(title).font(.subheadline.weight(.semibold))
                    .padding(.horizontal, 18).frame(minWidth: 80, minHeight: 44)
            }.hearthGlassButton(prominent: true)
                .tint(ShoppingTheme.accent).disabled(disabled).accessibilityIdentifier(identifier)
                .fixedSize(horizontal: false, vertical: true)
        }.padding(.horizontal, 20).padding(.vertical, 10).frame(maxWidth: 640).frame(maxWidth: .infinity).background(.regularMaterial)
    }
}

struct ShoppingTimingPicker: View {
    @Binding var neededLater: Bool
    @Binding var date: Date
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("When do you need it?").font(.subheadline.weight(.semibold))
            Picker("When do you need it?", selection: $neededLater) {
                Text("Now").tag(false)
                Text("Later").tag(true)
            }.pickerStyle(.segmented).accessibilityIdentifier("shopping.when")
            if neededLater {
                DatePicker("Shopping date", selection: $date, displayedComponents: .date)
                    .accessibilityIdentifier("shopping.plannedDate")
                Text("Planned for this date. No reminder notification is created.").font(.caption).foregroundStyle(.secondary)
            } else { Text("Include it in your next shop.").font(.caption).foregroundStyle(.secondary) }
        }
    }
}

/// Shopping uses botanical surfaces with readable adaptive contrast.
enum ShoppingTheme {
    static let canvas = Color("ShoppingCanvas")
    static let surface = Color("ShoppingSurface")
    static let ink = Color("ShoppingInk")
    static let muted = Color("ShoppingMuted")
    static let accent = Color("ShoppingAccent")
    static let hero = Color("ShoppingHero")
    static let heroInk = AppTheme.ink
}
