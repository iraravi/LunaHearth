import SwiftUI

/// Type or paste one note — "Costco Saturday, milk, 2 kg rice, call plumber tomorrow, $45 gas yesterday" —
/// and review the shopping items, tasks, events and expenses it becomes. Nothing is saved until Add.
struct QuickCaptureView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PublicConfigurationStore.self) private var publicStatus
    @Environment(\.aiAvailability) private var aiAvailability
    @Environment(\.dismiss) private var dismiss
    @State private var text: String
    @State private var items: [QuickCaptureItem] = []
    @State private var sorting = false
    @State private var status: String?
    @State private var saving = false
    @State private var error: String?
    @FocusState private var typing: Bool
    private let service: any QuickCaptureService = OnDeviceQuickCaptureService()
    private let onAdded: () -> Void

    init(text: String = "", onAdded: @escaping () -> Void = {}) {
        _text = State(initialValue: String(text.prefix(QuickCaptureRules.maxTextLength))); self.onAdded = onAdded
    }

    private var included: [QuickCaptureItem] { items.filter(\.included) }
    private var canSortWithAI: Bool {
        aiAvailability.showsAIActions && (publicStatus.configuration?.allows(.aiQuickAdd) ?? true)
            && text.contains(where: \.isLetter)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Milk, eggs, call plumber tomorrow, $45 gas yesterday", text: $text, axis: .vertical)
                        .lineLimit(3...8).focused($typing).accessibilityIdentifier("capture.text")
                } header: {
                    Text("Type it the way you’d say it")
                } footer: {
                    Text("Separate things with commas or new lines. Nothing is saved until you tap Add.")
                }
                if canSortWithAI {
                    Section {
                        Button { typing = false; sorting = true } label: {
                            Label(sorting ? "Sorting on your device…" : "Sort with AI", systemImage: "sparkles")
                        }.disabled(sorting).accessibilityIdentifier("capture.sortAI")
                    } footer: { if let status { Text(status).accessibilityIdentifier("capture.status") } }
                } else if let status {
                    Section { Text(status).font(.footnote).accessibilityIdentifier("capture.status") }
                }
                if !items.isEmpty {
                    Section("Review \(items.count == 1 ? "1 item" : "\(items.count) items")") {
                        ForEach($items) { $item in CaptureRow(item: $item) }
                    }
                }
            }
            .hearthList()
            .disabled(saving)
            .navigationTitle("Add several")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() }.disabled(saving) }
                ToolbarItem(placement: .confirmationAction) {
                    Button(included.isEmpty ? "Add" : "Add \(included.count)") { save() }.bold()
                        .disabled(included.isEmpty || saving || sorting).accessibilityIdentifier("capture.add")
                }
                ToolbarItemGroup(placement: .keyboard) { Spacer(); Button("Done") { typing = false } }
            }
            .onAppear { reread(); if text.isEmpty { typing = true } }
            .onChange(of: text) { _, _ in reread() }
            .task(id: sorting) {
                guard sorting else { return }
                defer { sorting = false }
                let note = text
                do {
                    let result = try await service.sort(note, now: .now, savedStores: repository.shoppingStoreNames)
                    guard note == text else { return }
                    items = annotated(result.items); status = result.message
                } catch { if !Task.isCancelled { status = "AI couldn’t finish. The offline reading is still here." } }
            }
            .saveError($error)
        }
    }

    /// Offline reading on every change; AI results are replaced as soon as the note is edited.
    private func reread() {
        status = nil
        items = annotated(QuickCaptureRules.parse(text, savedStores: repository.shoppingStoreNames))
    }

    /// Shopping already on the list starts unchecked instead of creating a duplicate.
    private func annotated(_ parsed: [QuickCaptureItem]) -> [QuickCaptureItem] {
        let pending = repository.groceries.filter { !$0.isCompleted }
        return parsed.map { item in
            var item = item
            if item.kind == .shopping, pending.contains(where: { IngredientMatching.same($0.name, item.title) }) {
                item.included = false; item.note = "Already on your list"
            }
            return item
        }
    }

    private func save() {
        saving = true
        defer { saving = false }
        let currency = Self.householdCurrency(repository.expenses)
        var failed: [QuickCaptureItem] = [], firstError: String?
        for item in included {
            do {
                if let draft = item.expenseDraft(defaultCurrency: currency) { try repository.saveExpense(draft) }
                else if let draft = item.entryDraft() { try repository.add(draft) }
            } catch {
                failed.append(item); firstError = firstError ?? userFacingError(error)
            }
        }
        guard let firstError else { onAdded(); dismiss(); return }
        // Keep only what didn't save so nothing is added twice on retry.
        let failedIDs = Set(failed.map(\.id))
        items = items.filter { failedIDs.contains($0.id) }
        error = "\(failed.count == 1 ? "1 item" : "\(failed.count) items") couldn’t be added. \(firstError)"
    }

    /// Expenses default to the currency this household uses most.
    static func householdCurrency(_ expenses: [HouseholdExpense]) -> String {
        let counts = Dictionary(grouping: expenses.map(\.currencyCode), by: { $0 }).mapValues(\.count)
        return counts.max { $0.value < $1.value }?.key ?? ExpenseRules.defaultCurrency
    }
}

private struct CaptureRow: View {
    @Binding var item: QuickCaptureItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Button { item.included.toggle() } label: {
                Image(systemName: item.included ? "checkmark.circle.fill" : "circle")
                    .font(.title3).foregroundStyle(item.included ? AppTheme.accent : .secondary)
            }
            .buttonStyle(.plain).frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel(item.included ? "Included" : "Not included")
            .accessibilityIdentifier("capture.include")
            VStack(alignment: .leading, spacing: 4) {
                TextField("Name", text: $item.title).font(.body.weight(.semibold))
                    .accessibilityIdentifier("capture.title")
                if !item.detail.isEmpty { Text(item.detail).font(.caption).foregroundStyle(.secondary) }
                if let note = item.note { Text(note).font(.caption).foregroundStyle(.secondary) }
                if item.source == .ai {
                    Label(item.source.label, systemImage: "sparkles").font(.caption2).foregroundStyle(.secondary)
                } else if item.original.caseInsensitiveCompare(item.title) != .orderedSame {
                    Text("From “\(item.original)”").font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                }
            }
            Spacer(minLength: 4)
            Menu {
                ForEach(QuickCaptureKind.allCases) { kind in
                    Button { change(to: kind) } label: { Label(kind.title, systemImage: kind.symbol) }
                        .disabled(kind == .expense && item.amount.isEmpty)
                }
            } label: {
                Label(item.kind.title, systemImage: item.kind.symbol).font(.caption.weight(.semibold))
                    .padding(.horizontal, 10).padding(.vertical, 6)
                    .background(.quaternary, in: Capsule())
            }
            .accessibilityLabel("Type: \(item.kind.title)")
            .accessibilityIdentifier("capture.kind")
        }
        .opacity(item.included ? 1 : 0.6)
    }

    private func change(to kind: QuickCaptureKind) {
        item.kind = kind
        if kind == .event && item.date == nil { item.date = Calendar.current.startOfDay(for: .now) }
    }
}

/// `lunahearth://capture?text=…` opens the review screen with a note from Siri or Shortcuts.
struct CaptureLink: Identifiable {
    let id = UUID()
    let text: String

    static func url(text: String) -> URL? {
        var parts = URLComponents(); parts.scheme = "lunahearth"; parts.host = "capture"
        parts.queryItems = [URLQueryItem(name: "text", value: String(text.prefix(QuickCaptureRules.maxTextLength)))]
        return parts.url
    }

    init?(url: URL) {
        guard url.scheme == "lunahearth", url.host == "capture", url.absoluteString.count < 8192,
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        text = String((parts.queryItems?.first { $0.name == "text" }?.value ?? "").prefix(QuickCaptureRules.maxTextLength))
    }
}
