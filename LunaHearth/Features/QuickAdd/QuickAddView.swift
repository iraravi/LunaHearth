import SwiftUI

struct QuickAddView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dismiss) private var dismiss
    @State private var draft: EntryDraft
    @State private var error: String?
    private enum Field: Hashable { case title, quantity, manufacturer, model, serial, shopping, notes }
    @FocusState private var focusedField: Field?
    private let fixedKind: Bool

    init(kind: EntryKind = .task, parentID: UUID? = nil, date: Date = .now, fixedKind: Bool = false) {
        self.fixedKind = fixedKind
        _draft = State(initialValue: EntryDraft(kind: kind, date: date, endDate: date.addingTimeInterval(3600), parentID: parentID))
    }

    init(draft: EntryDraft) { _draft = State(initialValue: draft); fixedKind = true }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack(spacing: 14) {
                        HearthIcon(symbol: draft.kind.symbol)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(draft.recordID == nil ? (fixedKind ? "Add \(draft.kind.rawValue.lowercased())." : "Add to your household.") : "Edit the details.")
                                .font(.system(.title2, design: .default, weight: .bold)).foregroundStyle(AppTheme.ink)
                            Text("\(draft.kind.rawValue) · Saved on this device")
                                .font(.caption).foregroundStyle(AppTheme.muted)
                        }
                    }.padding(.vertical, 6)
                }.listRowBackground(Color.clear)
                Section {
                    if !fixedKind { Picker("Add", selection: $draft.kind) {
                        ForEach(EntryKind.allCases) { kind in Label(kind.rawValue, systemImage: kind.symbol).tag(kind) }
                    }.accessibilityIdentifier("quickAdd.kind").disabled(draft.recordID != nil) }
                    TextField(draft.kind == .warranty ? "Provider / warranty name" : "Name or title", text: $draft.title)
                        .accessibilityIdentifier("quickAdd.title").focused($focusedField, equals: .title)
                }
                details
            }
            .hearthList()
            .scrollDismissesKeyboard(.interactively)
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(draft.recordID == nil ? (fixedKind ? "Add \(draft.kind.rawValue)" : "Quick Add") : "Edit \(draft.kind.rawValue)")
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Done") { focusedField = nil }.accessibilityIdentifier("quickAdd.keyboardDone")
                }
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }.bold().accessibilityIdentifier("quickAdd.save")
                        .disabled(draft.title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .onChange(of: draft.kind) { _, _ in draft.parentID = nil; draft.memberID = nil }
            .saveError($error)
        }
    }

    @ViewBuilder private var details: some View {
        if draft.kind == .event {
            Section("When") {
                DatePicker("Starts", selection: $draft.date)
                DatePicker("Ends", selection: $draft.endDate)
            }
        }
        if [.task, .warranty, .maintenance].contains(draft.kind) {
            Section {
                Toggle(draft.kind == .warranty ? "Expiration date" : "Due date", isOn: $draft.hasDate)
                if draft.hasDate { DatePicker("Date", selection: $draft.date, displayedComponents: .date) }
            }
        }
        if draft.kind == .task || draft.kind == .event {
            Section {
                Picker("Assigned to", selection: $draft.memberID) {
                    Text("Family").tag(nil as UUID?)
                    ForEach(repository.members) { Text($0.displayName).tag(Optional($0.id)) }
                }
            }
        }
        if draft.kind == .grocery {
            Section { TextField("Quantity (e.g. 2 cartons)", text: $draft.quantity).focused($focusedField, equals: .quantity) }
        }
        if draft.kind == .meal {
            Section {
                DatePicker("Day", selection: $draft.date, displayedComponents: .date)
                Picker("Meal", selection: $draft.mealType) {
                    ForEach(["Breakfast", "Lunch", "Dinner", "Snack"], id: \.self) { Text($0) }
                }
            }
        }
        if draft.kind == .room {
            Section {
                Picker("Floor", selection: $draft.parentID) {
                    Text("No floor").tag(nil as UUID?)
                    ForEach(repository.floors) { Text($0.name).tag(Optional($0.id)) }
                }
            }
        }
        if draft.kind == .asset {
            Section("Home item") {
                if let room = repository.rooms.first(where: { $0.id == draft.parentID }) {
                    Label("This item will be added to \(room.name)", systemImage: "door.left.hand.open")
                        .font(.subheadline).accessibilityIdentifier("item.roomContext")
                }
                Picker("Room", selection: $draft.parentID) {
                    Text("Unassigned").tag(nil as UUID?)
                    ForEach(repository.rooms) { Text($0.name).tag(Optional($0.id)) }
                }
                Picker("Category", selection: $draft.category) {
                    ForEach(AssetCategory.allCases, id: \.self) { Text($0.rawValue.capitalized).tag($0) }
                }
                TextField("Manufacturer", text: $draft.manufacturer).focused($focusedField, equals: .manufacturer)
                TextField("Model", text: $draft.modelNumber).focused($focusedField, equals: .model)
                TextField("Serial number", text: $draft.serialNumber).focused($focusedField, equals: .serial).textInputAutocapitalization(.never)
            }
        }
        if draft.kind == .warranty || draft.kind == .maintenance {
            Section {
                Picker("Home item", selection: $draft.parentID) {
                    Text("Select an item").tag(nil as UUID?)
                    ForEach(repository.assets) { Text($0.name).tag(Optional($0.id)) }
                }
                if repository.assets.isEmpty { Text("Choose Home Item above to add your first item, then add its warranty or maintenance.").foregroundStyle(.secondary) }
            }
        }
        if draft.kind == .maintenance {
            Section {
                Toggle("Repeat after completion", isOn: $draft.repeats)
                if draft.repeats { Stepper("Every \(draft.intervalDays) days", value: $draft.intervalDays, in: 1...3650) }
                TextField("Replacement shopping item (optional)", text: $draft.shoppingItem).focused($focusedField, equals: .shopping)
            } footer: { Text("Shopping items are added only when you tap Add replacement to groceries.") }
        }
        if [.event, .meal, .asset, .warranty].contains(draft.kind) {
            Section("Notes") { TextField("Optional notes", text: $draft.notes, axis: .vertical).focused($focusedField, equals: .notes).lineLimit(3...8) }
        }
    }

    private func save() {
        do { try repository.add(draft); dismiss() }
        catch { self.error = userFacingError(error) }
    }
}

func userFacingError(_ error: Error) -> String {
    (error as? HouseholdValidation)?.errorDescription ?? (error as? LayoutError)?.errorDescription ?? "Couldn't save this change. Your previously saved data is still available. Please try again."
}

private struct SaveErrorModifier: ViewModifier {
    @Binding var message: String?
    func body(content: Content) -> some View {
        content.alert("Couldn't save", isPresented: Binding(get: { message != nil }, set: { if !$0 { message = nil } })) {
            Button("OK", role: .cancel) { message = nil }
        } message: { Text(message ?? "Please try again.") }
    }
}

extension View {
    func saveError(_ message: Binding<String?>) -> some View { modifier(SaveErrorModifier(message: message)) }
}
