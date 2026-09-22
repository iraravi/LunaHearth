import SwiftUI

struct InventoryStatusBadges: View {
    let item: InventoryItem
    let today: String
    static let danger = Color("InventoryDanger"), caution = Color("InventoryCaution")
    static func attentionColor(_ item: InventoryItem, today: String) -> Color {
        guard !item.isUsedUp else { return .clear }
        switch InventoryRules.expiryState(item.expiryDay, today: today) {
        case .past: return danger
        case .today, .soon: return caution
        default: return item.isLowStock == true ? caution : .clear
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            if item.isUsedUp { Label("Used up", systemImage: "checkmark.circle").font(.caption).foregroundStyle(InventoryTheme.muted) }
            else {
                switch InventoryRules.expiryState(item.expiryDay, today: today) {
                case .past: badge("Past expiry", symbol: "exclamationmark.triangle.fill", color: Self.danger)
                case .today: badge("Expires today", symbol: "clock.badge.exclamationmark", color: Self.caution)
                case .soon: badge("Expires soon", symbol: "clock", color: Self.caution)
                default: EmptyView()
                }
                Text(InventoryRules.expiryLabel(item.expiryDay, today: today)).font(.caption).foregroundStyle(InventoryTheme.muted)
                if item.isLowStock == true { badge("Low stock", symbol: "shippingbox", color: Self.caution) }
            }
        }
    }
    private func badge(_ text: String, symbol: String, color: Color) -> some View {
        Label(text, systemImage: symbol).font(.caption.weight(.semibold)).foregroundStyle(color)
            .padding(.horizontal, 8).padding(.vertical, 5).background(color.opacity(0.10), in: RoundedRectangle(cornerRadius: 8))
    }
}

struct InventoryAttentionSummary: View {
    let items: [InventoryItem]
    let select: (String) -> Void
    var body: some View {
        let today = HouseholdDay(.now).key
        let dated = items.filter { [.past, .today, .soon].contains(InventoryRules.expiryState($0.expiryDay, today: today)) }.count
        let low = items.filter { $0.isLowStock == true }.count
        if dated > 0 || low > 0 {
            Divider()
            ViewThatFits(in: .horizontal) {
                HStack(spacing: 12) { datesButton(dated); lowButton(low) }
                VStack(alignment: .leading, spacing: 10) { datesButton(dated); lowButton(low) }
            }.padding(.vertical, 4)
        }
    }
    @ViewBuilder private func datesButton(_ count: Int) -> some View {
        if count > 0 {
            Button { select("dates") } label: { Label("\(count) dates to check", systemImage: "exclamationmark.triangle") }
                .font(.footnote.weight(.medium)).foregroundStyle(InventoryStatusBadges.danger)
                .frame(minHeight: 44).buttonStyle(.plain).accessibilityIdentifier("inventory.attentionDates")
        }
    }
    @ViewBuilder private func lowButton(_ count: Int) -> some View {
        if count > 0 {
            Button { select("low") } label: { Label("\(count) running low", systemImage: "shippingbox") }
                .font(.footnote.weight(.medium)).foregroundStyle(InventoryStatusBadges.caution)
                .frame(minHeight: 44).buttonStyle(.plain).accessibilityIdentifier("inventory.attentionLow")
        }
    }
}
