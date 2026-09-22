import SwiftUI

/// Reads the household's existing shopping-store directory; an expense payee is still free text.
struct ExpenseMerchantField: View {
    @Binding var merchant: String
    var placeholder = "Store or payee"
    var identifier = "expense.merchant"
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var browsing = false
    @FocusState private var focused: Bool
    private var matches: [String] {
        repository.shoppingStoreNames.filter { ShoppingStoreCatalog.matches($0, query: merchant) }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            TextField(placeholder, text: $merchant).focused($focused).accessibilityIdentifier(identifier)
            if let existing = repository.matchingStore(merchant) {
                Label("Shopping store · \(existing.displayName)", systemImage: "checkmark.circle")
                    .font(.caption).foregroundStyle(.secondary).accessibilityIdentifier("expense.storeMatch")
            } else if !matches.isEmpty {
                Text("Your shopping stores").font(.caption).foregroundStyle(.secondary)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(Array(matches.prefix(5)), id: \.self) { name in
                            Button { merchant = name; focused = false } label: {
                                Text(name).font(.subheadline).padding(.horizontal, 12).frame(minHeight: 44)
                                    .background(ExpenseTheme.accent.opacity(0.09), in: Capsule())
                            }.buttonStyle(.borderless).accessibilityIdentifier("expense.storeSuggestion.\(name)")
                        }
                    }
                }
            }
            Button { focused = false; browsing = true } label: {
                Label("Browse shopping stores", systemImage: "storefront")
                    .font(.subheadline).frame(minHeight: 44, alignment: .leading)
            }.buttonStyle(.borderless).accessibilityIdentifier("expense.browseStores")
        }
        .sheet(isPresented: $browsing) { ShoppingStorePicker(store: $merchant) }
    }
}
