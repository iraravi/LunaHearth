import SwiftUI

struct ShoppingStoreField: View {
    @Binding var store: String
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Store").font(.subheadline.weight(.semibold))
            TextField("Any store", text: $store).shoppingInputStyle().accessibilityIdentifier("shopping.store")
            ShoppingStoreSuggestions(store: $store)
        }
    }
}

struct ShoppingStorePicker: View {
    @Binding var store: String
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var query = ""
    @State private var region: ShoppingStoreCatalog.Region = .all
    @State private var addingStore = false
    @State private var error: String?
    private var saved: [String] { repository.shoppingStoreNames }
    private var customName: String { ShoppingStoreCatalog.canonicalName(query, saved: saved) }
    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("Country", selection: $region) {
                        ForEach(ShoppingStoreCatalog.Region.allCases) { Text($0.rawValue).tag($0) }
                    }.pickerStyle(.segmented)
                    Text("Popular chains and your own local shops. No location access needed.").font(.caption).foregroundStyle(ShoppingTheme.muted)
                    Button("Any store") { select("") }
                }.listRowBackground(ShoppingTheme.surface)
                let recent = saved.filter { ShoppingStoreCatalog.matches($0, query: query) }
                if !recent.isEmpty {
                    Section("Your stores") { ForEach(recent, id: \.self) { name in storeRow(name) } }
                        .listRowBackground(ShoppingTheme.surface)
                }
                let suggestions = ShoppingStoreCatalog.suggestions(query: query, region: region, excluding: saved)
                if !suggestions.isEmpty {
                    Section("Popular stores") {
                        ForEach(suggestions) { item in storeRow(item.name, detail: item.region.rawValue) }
                    }.listRowBackground(ShoppingTheme.surface)
                }
                if !query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && !saved.contains(customName) && !suggestions.contains(where: { $0.name == customName }) {
                    Section {
                        Button { addingStore = true } label: { Label("Add “\(customName)”", systemImage: "plus.circle") }
                            .disabled(customName.count > 200).accessibilityIdentifier("shopping.useStore")
                        Text("For a specific branch, add its area—for example, Walmart Plano.").font(.caption).foregroundStyle(ShoppingTheme.muted)
                    }.listRowBackground(ShoppingTheme.surface)
                }
            }.scrollContentBackground(.hidden).background(ShoppingTheme.canvas)
                .searchable(text: $query, prompt: "Store or local shop")
                .navigationTitle("Choose a store").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .tint(ShoppingTheme.accent)
                .saveError($error)
                .sheet(isPresented: $addingStore) {
                    ShoppingStoreEditor(initialName: customName) { value in store = value; dismiss() }
                }
        }
    }
    private func storeRow(_ name: String, detail: String? = nil) -> some View {
        Button { select(name) } label: {
            HStack(spacing: 12) {
                Image(systemName: "storefront").foregroundStyle(ShoppingTheme.accent)
                Text(name).foregroundStyle(ShoppingTheme.ink)
                Spacer()
                if ShoppingStoreCatalog.canonicalName(store, saved: saved) == name { Image(systemName: "checkmark") }
                else if let detail { Text(detail).font(.caption).foregroundStyle(ShoppingTheme.muted) }
            }.frame(minHeight: 36)
        }
    }
    private func select(_ name: String) {
        if name.isEmpty { store = ""; dismiss(); return }
        do {
            if let existing = repository.stores.first(where: { $0.displayName == name }) { store = existing.displayName }
            else { store = try repository.addStore(name: name).displayName }
            dismiss()
        } catch { self.error = userFacingError(error) }
    }
}

struct ShoppingStoreBrowseButton: View {
    @Binding var store: String
    @State private var browsing = false
    var body: some View {
        Button { browsing = true } label: {
            Label("Browse stores", systemImage: "magnifyingglass").font(.subheadline.weight(.semibold)).frame(minHeight: 44)
        }.accessibilityIdentifier("shopping.browseStores")
            .sheet(isPresented: $browsing) { ShoppingStorePicker(store: $store) }
    }
}

struct ShoppingStoreEditor: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var name: String
    @State private var branch = ""
    @State private var error: String?
    let onSave: (String) -> Void
    init(initialName: String, onSave: @escaping (String) -> Void) {
        _name = State(initialValue: initialName); self.onSave = onSave
    }
    private var existing: ShoppingStore? { repository.matchingStore(name, branch: branch) }
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Label("A store for your home", systemImage: "storefront.fill").font(AppTheme.sectionTitle)
                    Text("Save it once. Choose it for any shopping item.").foregroundStyle(ShoppingTheme.muted)
                    ShoppingFormCard {
                        Text("Store name").font(.subheadline.bold())
                        TextField("e.g. Anand Stores", text: $name).shoppingInputStyle().accessibilityIdentifier("shopping.storeName")
                        Text("Branch or area · optional").font(.subheadline.bold())
                        TextField("e.g. Adyar", text: $branch).shoppingInputStyle().accessibilityIdentifier("shopping.storeBranch")
                    }
                    if let existing {
                        Label("This store already exists: \(existing.displayName). Use it instead of creating a duplicate.", systemImage: "checkmark.circle.fill")
                            .font(.subheadline).foregroundStyle(ShoppingTheme.accent).accessibilityIdentifier("shopping.duplicateStore")
                    }
                    Label("Private to your home", systemImage: "lock.shield")
                    Text("Saved on this device. When home sync is enabled, shared through your home’s private iCloud space.").font(.footnote).foregroundStyle(ShoppingTheme.muted)
                }.padding(20)
            }.background(ShoppingTheme.canvas)
                .navigationTitle("Add store").navigationBarTitleDisplayMode(.inline)
                .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } } }
                .safeAreaInset(edge: .bottom) {
                    ShoppingBottomAction(title: existing == nil ? "Save store" : "Use existing", detail: "Available even when your shopping list is empty", disabled: name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, identifier: "shopping.saveStore") {
                        do { let value = try repository.addStore(name: name, branch: branch); onSave(value.displayName); dismiss() }
                        catch { self.error = userFacingError(error) }
                    }
                }.saveError($error)
        }
    }
}
