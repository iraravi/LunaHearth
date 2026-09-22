import SwiftUI

/// Saved household stores are visible before typing; matching names fill the field on selection.
struct ShoppingStoreSuggestions: View {
    @Binding var store: String
    @Environment(LocalHouseholdRepository.self) private var repository
    @State private var error: String?
    private var isSearching: Bool { !store.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
    private var saved: [String] { repository.shoppingStoreNames.filter { ShoppingStoreCatalog.matches($0, query: store) } }
    private var suggested: [String] {
        ShoppingStoreCatalog.suggestions(query: store, region: .all, excluding: repository.shoppingStoreNames).map(\.name)
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            if let existing = repository.matchingStore(store) {
                Label("Saved store · \(existing.displayName)", systemImage: "checkmark.circle.fill")
                    .font(.caption).foregroundStyle(ShoppingTheme.accent).accessibilityIdentifier("shopping.storeMatch")
            } else {
                if !saved.isEmpty {
                    choices(saved, title: "Your saved stores · \(repository.shoppingStoreNames.count)", saved: true)
                } else if !isSearching && repository.shoppingStoreNames.isEmpty {
                    Text("No saved stores yet. Choose one below or type your local shop.")
                        .font(.caption).foregroundStyle(ShoppingTheme.muted)
                }
                if !suggested.isEmpty {
                    choices(Array(suggested.prefix(isSearching ? 5 : 6)), title: isSearching ? "Suggestions · tap to fill" : "Popular stores · US & India", saved: false)
                } else if saved.isEmpty && isSearching {
                    Text("New store · saved to your home when you add this item.")
                        .font(.caption).foregroundStyle(ShoppingTheme.muted)
                }
            }
            ShoppingStoreBrowseButton(store: $store)
            Text("\(ShoppingStoreCatalog.stores.count) bundled suggestions + your saved stores. Works offline.")
                .font(.caption2).foregroundStyle(ShoppingTheme.muted)
        }.saveError($error)
    }
    @ViewBuilder private func choices(_ names: [String], title: String, saved: Bool) -> some View {
        Text(title).font(.caption.weight(.semibold)).foregroundStyle(ShoppingTheme.muted)
            .accessibilityIdentifier(saved ? "shopping.savedStoresHeading" : "shopping.suggestedStoresHeading")
        if isSearching {
            ForEach(Array(names.prefix(5)), id: \.self) { name in
                Button { select(name) } label: {
                    HStack {
                        Image(systemName: saved ? "checkmark.circle" : "storefront")
                        Text(name).multilineTextAlignment(.leading)
                        Spacer(minLength: 8)
                        Image(systemName: "arrow.up.left").font(.caption)
                    }.font(.subheadline).frame(minHeight: 44).contentShape(Rectangle())
                }.buttonStyle(.plain).foregroundStyle(ShoppingTheme.accent)
                    .accessibilityIdentifier("shopping.storeSuggestion.\(name)")
            }
        } else {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(names, id: \.self) { name in
                        Button { select(name) } label: {
                            Text(name).font(.subheadline.weight(.medium)).padding(.horizontal, 14)
                                .frame(minHeight: 44).background(ShoppingTheme.canvas, in: Capsule())
                        }.buttonStyle(.plain).foregroundStyle(ShoppingTheme.accent)
                            .accessibilityIdentifier("shopping.storeSuggestion.\(name)")
                    }
                }
            }
        }
    }
    private func select(_ name: String) {
        do { store = try repository.addStore(name: name).displayName }
        catch { self.error = userFacingError(error) }
    }
}
