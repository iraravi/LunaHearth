import SwiftUI

/// Presentation-only tools shared by shopping and inventory. No records are changed.
struct GroceryToolsPalette {
    let canvas: Color
    let surface: Color
    let ink: Color
    let muted: Color
    let accent: Color

    static var shopping: Self {
        Self(canvas: ShoppingTheme.canvas, surface: ShoppingTheme.surface,
             ink: ShoppingTheme.ink, muted: ShoppingTheme.muted, accent: ShoppingTheme.accent)
    }
    static var inventory: Self {
        Self(canvas: InventoryTheme.canvas, surface: InventoryTheme.surface,
             ink: InventoryTheme.ink, muted: InventoryTheme.muted, accent: InventoryTheme.accent)
    }
}

struct GroceryToolsSheet<Filters: View, Organization: View>: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.dynamicTypeSize) private var typeSize
    let title: String
    let identifier: String
    let palette: GroceryToolsPalette
    let hasFilters: Bool
    let resetFilters: () -> Void
    let reviewDuplicates: () -> Void
    @ViewBuilder var filters: Filters
    @ViewBuilder var organization: Organization

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 18) {
                    introduction

                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("Show").font(.headline)
                            Spacer()
                            if hasFilters {
                                Button("Reset", action: resetFilters)
                                    .font(.subheadline.weight(.semibold))
                                    .frame(minWidth: 44, minHeight: 44).buttonStyle(.plain)
                                    .foregroundStyle(palette.accent)
                                    .accessibilityLabel("Reset filters")
                                    .accessibilityIdentifier("\(identifier).resetFilters")
                            }
                        }.frame(minHeight: 36).padding(.horizontal, 4)
                        GroceryToolsCard(palette: palette) { filters }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("\(identifier).filterCard")
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("Organize").font(.headline).padding(.horizontal, 4)
                        GroceryToolsCard(palette: palette) { organization }
                            .accessibilityElement(children: .contain)
                            .accessibilityIdentifier("\(identifier).organizationCard")
                        GroceryToolsCard(palette: palette) {
                            Button(action: reviewDuplicates) {
                                HStack(spacing: 12) {
                                    GroceryToolsIcon(symbol: "square.on.square", palette: palette)
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text("Similar items").font(.subheadline.weight(.semibold))
                                        Text("Review possible duplicates").font(.footnote).foregroundStyle(palette.muted)
                                    }.fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 4)
                                    Image(systemName: "chevron.right").font(.caption.weight(.semibold))
                                        .foregroundStyle(palette.muted).accessibilityHidden(true)
                                }.frame(maxWidth: .infinity, minHeight: 54, alignment: .leading)
                                    .padding(.vertical, 4).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityLabel("Review similar items")
                                .accessibilityIdentifier("\(identifier).reviewDuplicates")
                        }
                    }

                    DisclosureGroup {
                        Text("Familiar items use automatic categories. On-device AI can suggest categories for unfamiliar names. Suggestions last while this screen is open; Reset restores automatic categories. Item details stay as you entered them.")
                            .font(.footnote).foregroundStyle(palette.muted)
                            .fixedSize(horizontal: false, vertical: true).padding(.bottom, 8)
                    } label: {
                        Label("About on-device categories", systemImage: "iphone")
                            .font(.footnote.weight(.medium)).frame(minHeight: 44)
                    }.tint(palette.muted).padding(.horizontal, 4)
                        .accessibilityIdentifier("\(identifier).organizationAbout")
                }.frame(maxWidth: 600).padding(.horizontal, 20).padding(.top, 8).padding(.bottom, 24)
                    .frame(maxWidth: .infinity)
            }.background(palette.canvas).foregroundStyle(palette.ink)
                .navigationTitle("Filters & AI").navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button("Done") { dismiss() }.font(.subheadline.weight(.semibold))
                            .accessibilityIdentifier("\(identifier).tools.done")
                    }
                }.tint(palette.accent)
        }.presentationDetents([.large])
    }

    private var introduction: some View {
        HStack(spacing: 4) {
            VStack(alignment: .leading, spacing: 7) {
                Text(title).font(AppTheme.sectionTitle).fixedSize(horizontal: false, vertical: true)
                Text("A clearer view of what you need.").font(.subheadline)
                    .foregroundStyle(palette.muted).fixedSize(horizontal: false, vertical: true)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image("EditorialPantry").resizable().scaledToFit()
                    .frame(width: 144, height: 136).accessibilityHidden(true)
            }
        }.padding(.horizontal, 4).padding(.vertical, typeSize.isAccessibilitySize ? 12 : 0)
    }
}

struct GroceryToolsCard<Content: View>: View {
    let palette: GroceryToolsPalette
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 0) { content }
            .padding(.horizontal, 16).padding(.vertical, 6)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(palette.surface, in: RoundedRectangle(cornerRadius: 20))
            .overlay { RoundedRectangle(cornerRadius: 20).strokeBorder(palette.muted.opacity(0.09)) }
    }
}

struct GroceryToolsIcon: View {
    let symbol: String
    let palette: GroceryToolsPalette
    var body: some View {
        // Decorative tile stays compact while its adjacent text scales independently.
        Image(systemName: symbol).font(.system(size: 17, weight: .medium))
            .foregroundStyle(palette.accent).frame(width: 32, height: 32)
            .background(palette.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 10))
            .accessibilityHidden(true)
    }
}

/// The label and selected value form one tap target, with a stacked large-text fallback.
struct GroceryToolsMenu<Selection: Hashable, Options: View>: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let title: String
    let value: String
    let symbol: String
    let identifier: String
    let palette: GroceryToolsPalette
    @Binding var selection: Selection
    @ViewBuilder var options: Options

    var body: some View {
        Menu {
            Picker(title, selection: $selection) { options }
        } label: {
            HStack(spacing: 12) {
                GroceryToolsIcon(symbol: symbol, palette: palette)
                Group {
                    if typeSize.isAccessibilitySize { stackedLabel }
                    else {
                        ViewThatFits(in: .horizontal) {
                            HStack(spacing: 12) {
                                Text(title).foregroundStyle(palette.ink).fixedSize()
                                Spacer(minLength: 8)
                                selectedValue.fixedSize()
                            }
                            stackedLabel
                        }
                    }
                }.font(.subheadline).frame(maxWidth: .infinity, alignment: .leading)
            }.frame(minHeight: 52).padding(.vertical, 2).contentShape(Rectangle())
        }.buttonStyle(.plain).accessibilityLabel(title).accessibilityValue(value)
            .accessibilityIdentifier(identifier)
    }

    private var selectedValue: some View {
        HStack(spacing: 6) {
            Text(value).fixedSize(horizontal: false, vertical: true)
            Image(systemName: "chevron.down").font(.caption2.weight(.semibold)).accessibilityHidden(true)
        }.foregroundStyle(palette.accent)
    }
    private var stackedLabel: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).foregroundStyle(palette.ink)
            selectedValue
        }.fixedSize(horizontal: false, vertical: true).padding(.vertical, 6)
    }
}
