import SwiftUI

struct InventoryShelf: View {
    let items: [InventoryItem]
    let hints: [String: PantryCategory]
    let now: Date
    let open: (InventoryItem) -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    static func category(_ item: InventoryItem, hints: [String: PantryCategory]) -> PantryCategory {
        let known = PantryVisualRules.category(item.name)
        return known == .other ? hints[item.name] ?? .other : known
    }
    var body: some View {
        ForEach(PantryCategory.allCases) { category in
            let group = items.filter { Self.category($0, hints: hints) == category }
            if !group.isEmpty {
                Section {
                    LazyVGrid(columns: textSize.isAccessibilitySize ? [GridItem(.flexible(), alignment: .top)] : [GridItem(.adaptive(minimum: 155), spacing: 12, alignment: .top)], alignment: .leading, spacing: 12) {
                        ForEach(group) { item in
                            Button { open(item) } label: {
                                VStack(alignment: .leading, spacing: 10) {
                                    HStack {
                                        Text(PantryVisualRules.icon(item.name, category: category)).font(.system(size: 32)).accessibilityHidden(true)
                                        Spacer(minLength: 0)
                                        if item.isUsedUp { Image(systemName: "checkmark.circle").accessibilityHidden(true) }
                                    }.padding(12).frame(maxWidth: .infinity)
                                        .background(tint(category).opacity(0.07), in: RoundedRectangle(cornerRadius: 16))
                                    Text(item.name).font(.headline).foregroundStyle(InventoryTheme.ink).fixedSize(horizontal: false, vertical: true)
                                    Text(item.quantityText?.isEmpty == false ? item.quantityText ?? "" : "Amount not set").font(.subheadline).foregroundStyle(InventoryTheme.muted)
                                    InventoryStatusBadges(item: item, today: HouseholdDay(now).key)
                                    if let location = item.location { Label(location, systemImage: "cabinet").font(.caption).foregroundStyle(InventoryTheme.muted) }
                                    if hints[item.name] != nil { Label("AI category", systemImage: "sparkles").font(.caption2).foregroundStyle(InventoryTheme.muted) }
                                    Spacer(minLength: 0)
                                }.padding(12).frame(maxWidth: .infinity, minHeight: 215, alignment: .topLeading)
                                    .background(InventoryTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                                    .hearthCardOutline(InventoryTheme.accent)
                                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(InventoryStatusBadges.attentionColor(item, today: HouseholdDay(now).key).opacity(0.5), lineWidth: 1.5))
                                    .contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("inventory.item.\(item.name)")
                        }
                    }.listRowInsets(EdgeInsets(top: 4, leading: 0, bottom: 12, trailing: 0)).listRowSeparator(.hidden).listRowBackground(Color.clear)
                } header: {
                    HStack { Text("\(category.icon)  \(category.title)"); Spacer(); Text(group.count == 1 ? "1 pack" : "\(group.count) packs") }
                        .font(.subheadline.bold()).textCase(nil).foregroundStyle(InventoryTheme.ink)
                }
            }
        }
    }
    private func tint(_ category: PantryCategory) -> Color {
        switch category {
        case .grains: AppTheme.ochre
        case .pulses: AppTheme.clay
        case .spices: AppTheme.rose
        case .produce: AppTheme.sage
        case .chilled: AppTheme.slate
        case .essentials: AppTheme.plum
        case .other: .gray
        }
    }
}
