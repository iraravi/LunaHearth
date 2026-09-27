import SwiftUI

/// Shared presentation for shopping items and inventory packs. Counts follow the
/// screen's other filters, while category selection remains independently resettable.
struct GroceryCategoryFilters: View {
    let categories: [PantryCategory]
    @Binding var selection: PantryCategory?
    let accent: Color
    let surface: Color
    let ink: Color
    let identifier: String

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                chip(nil, count: categories.count)
                ForEach(PantryCategory.allCases) { category in
                    let count = categories.filter { $0 == category }.count
                    if count > 0 || selection == category { chip(category, count: count) }
                }
            }
        }
    }

    private func chip(_ category: PantryCategory?, count: Int) -> some View {
        Button { selection = category } label: {
            Text("\(category.map { "\($0.icon) \($0.title)" } ?? "All") · \(count)")
                .font(.subheadline.weight(.medium)).padding(.horizontal, 14).padding(.vertical, 12)
                .foregroundStyle(selection == category ? surface : ink)
                .background(selection == category ? accent : surface, in: Capsule())
        }.buttonStyle(.plain).accessibilityAddTraits(selection == category ? .isSelected : [])
            .accessibilityLabel("\(category?.title ?? "All categories"), \(count) items")
            .accessibilityIdentifier("\(identifier).category.\(category?.rawValue ?? "all")")
    }
}

struct GroceryAIOrganizationControls: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let hasUnfamiliarItems: Bool
    let hasHints: Bool
    let organizing: Bool
    let status: String?
    let palette: GroceryToolsPalette
    let identifier: String
    let organize: () -> Void
    let reset: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if typeSize.isAccessibilitySize {
                VStack(alignment: .leading, spacing: 4) { heading; organizeButton }
            } else {
                ViewThatFits(in: .horizontal) {
                    HStack(spacing: 12) { heading; Spacer(minLength: 0); organizeButton.fixedSize() }
                    VStack(alignment: .leading, spacing: 4) { heading; organizeButton }
                }
            }
            if let status, !organizing {
                Text(status).font(.footnote).foregroundStyle(palette.muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier("\(identifier).organizationStatus")
            }
            if hasHints || organizing {
                Button("Reset AI categories", systemImage: "arrow.counterclockwise", action: reset)
                    .font(.footnote.weight(.medium)).foregroundStyle(palette.accent)
                    .frame(minHeight: 44).buttonStyle(.plain)
                    .accessibilityIdentifier("\(identifier).resetAICategories")
            }
        }.padding(.vertical, 8).frame(maxWidth: .infinity, alignment: .leading)
    }

    private var heading: some View {
        HStack(spacing: 12) {
            GroceryToolsIcon(symbol: hasHints || hasUnfamiliarItems ? "sparkles" : "checkmark.circle", palette: palette)
            VStack(alignment: .leading, spacing: 3) {
                Text("Categories").font(.subheadline.weight(.semibold))
                Text(organizing ? "Organizing on this device…" : (hasHints ? "AI suggestions applied" : (hasUnfamiliarItems ? "Some items need a category" : "Automatic categories ready")))
                    .font(.footnote).foregroundStyle(palette.muted)
            }.fixedSize(horizontal: false, vertical: true)
        }.accessibilityElement(children: .combine)
    }

    private var organizeButton: some View {
        Button(action: organize) {
            HStack(spacing: 6) {
                if organizing { ProgressView().controlSize(.small).tint(palette.accent) }
                Text(organizing ? "Working…" : (hasHints ? "Refresh" : (hasUnfamiliarItems ? "Organize" : "Check")))
                    .font(.subheadline.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
            }.foregroundStyle(palette.accent)
                .padding(.horizontal, 12).padding(.vertical, 7)
                .background(palette.accent.opacity(0.10), in: RoundedRectangle(cornerRadius: 10))
                .frame(minWidth: 44, minHeight: 44)
                .contentShape(Rectangle())
        }.buttonStyle(.plain).disabled(organizing)
            .accessibilityLabel(hasUnfamiliarItems ? "Organize categories with AI" : "Check categories")
            .accessibilityIdentifier("\(identifier).organizeAI")
    }
}

/// One action layout keeps shopping and at-home inventory in step.
struct GroceryShelfActions: View {
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(\.dynamicTypeSize) private var typeSize
    let identifier: String
    let filterCount: Int
    @Binding var shelves: Bool
    let tools: () -> Void
    let ideas: () -> Void

    var body: some View {
        ScrollView(.horizontal, showsIndicators: typeSize.isAccessibilitySize) {
            HearthGlassControls {
                HStack(spacing: 8) { actions.fixedSize() }
                    .padding(.vertical, 4)
            }
        }.accessibilityLabel("List tools").font(.subheadline)
    }

    private var actions: some View {
        Group {
            Button(action: tools) {
                Label(filterCount == 0 ? aiAvailability.filterTitle : "\(aiAvailability.filterTitle) (\(filterCount))", systemImage: "slider.horizontal.3")
            }.accessibilityIdentifier("\(identifier).tools")
            Button(action: ideas) { Label("Ideas", systemImage: "sparkles") }
                .accessibilityIdentifier(identifier == "shopping" ? "shopping.ai.open" : "inventory.ideas")
            Button { shelves.toggle() } label: {
                Label(shelves ? "List" : "Shelves", systemImage: shelves ? "list.bullet" : "square.grid.2x2")
            }.accessibilityIdentifier("\(identifier).changeView")
        }.labelStyle(.titleAndIcon).fixedSize(horizontal: false, vertical: true)
            .frame(minHeight: 44)
            .hearthGlassButton()
    }
}

/// Shared editorial header: artwork fills one side instead of becoming a thumbnail.
struct GroceryShelfHeader: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.horizontalSizeClass) private var sizeClass
    let title: String
    let summary: String
    let artwork: String
    let background: Color
    let ink: Color
    let muted: Color
    var summaryIdentifier = ""

    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
                if !typeSize.isAccessibilitySize {
                    Text(title).font(AppTheme.sectionTitle).foregroundStyle(ink)
                        .fixedSize(horizontal: false, vertical: true)
                }
                Text(summary).font(.subheadline).foregroundStyle(muted)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityIdentifier(summaryIdentifier)
            }.padding(16).frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image(artwork).resizable().scaledToFill()
                    .frame(width: sizeClass == .regular ? 220 : 136, height: 124)
                    .clipped()
                    .accessibilityHidden(true)
            }
        }.background(background).clipShape(RoundedRectangle(cornerRadius: 18)).hearthCardOutline(ink)
    }
}
