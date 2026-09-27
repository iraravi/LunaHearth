import SwiftUI
import Charts
import UniformTypeIdentifiers

enum ExpenseTheme {
    static let canvas = Color("ExpenseCanvas"), surface = Color("ExpenseSurface"), accent = Color("ExpenseAccent")
}

struct ExpensesView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var month = ExpenseRules.month(.now)
    @State private var currency = ExpenseRules.defaultCurrency
    @State private var adding = false
    @State private var scanning = false
    @State private var editing: HouseholdExpense?
    @State private var exporting = false
    @State private var search = ""
    @State private var category: ExpenseCategory?
    @State private var error: String?
    private var report: ExpenseMonthSummary { ExpenseRules.summary(repository.expenseReportItems, month: month, currency: currency) }
    private var history: [ExpenseReportItem] {
        report.items.filter { (category == nil || $0.category == category) && (search.isEmpty || $0.merchant.localizedStandardContains(search) || $0.notes.localizedStandardContains(search)) }
    }
    private var trend: [ExpenseMonthSummary] {
        (-5...0).map { ExpenseRules.summary(repository.expenseReportItems, month: ExpenseRules.offset(month, by: $0), currency: currency) }
    }
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                monthControls
                overview
                if typeSize.isAccessibilitySize {
                    VStack(spacing: 16) { trendCard; categoriesCard }
                } else {
                ViewThatFits(in: .horizontal) {
                    HStack(alignment: .top, spacing: 16) {
                        trendCard.frame(minWidth: 360)
                        categoriesCard.frame(minWidth: 300)
                    }
                    VStack(spacing: 16) { trendCard; categoriesCard }
                }
                }
                purchaseHistory
            }.padding(20).frame(maxWidth: 1100).frame(maxWidth: .infinity)
        }
        .background(ExpenseTheme.canvas).tint(ExpenseTheme.accent).featureCanvas(.expenses)
        .householdHelp(.expenses)
        .navigationTitle("Expenses").navigationBarTitleDisplayMode(.inline)
        .searchable(text: $search, prompt: "Find a purchase")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Scan receipt", systemImage: "doc.viewfinder") { scanning = true }.accessibilityIdentifier("expenses.scan")
            }
            ToolbarItem(placement: .primaryAction) {
                Button("Add expense", systemImage: "plus") { adding = true }.accessibilityIdentifier("expenses.add")
            }
        }
        .sheet(isPresented: $adding) { ExpenseEditor(currency: currency, onSave: showSavedExpense) }
        .sheet(item: $editing) { ExpenseEditor(item: $0, onSave: showSavedExpense) }
        .sheet(isPresented: $scanning) { if let home = repository.household?.id { ReceiptImportView(householdID: home, startsWithExpense: true, onExpenseSaved: showSavedExpense) } }
        .fileExporter(isPresented: $exporting, document: ExpenseReportDocument(text: ExpenseRules.csv(report)), contentType: .commaSeparatedText,
                      defaultFilename: "Expenses-\(month)-\(currency)") { result in
            if case .failure(let failure) = result { error = userFacingError(failure) }
        }
        .saveError($error)
    }
    private func showSavedExpense(_ savedMonth: String, _ savedCurrency: String) {
        month = savedMonth; currency = savedCurrency; category = nil; search = ""
    }
    private var monthControls: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Button { month = ExpenseRules.offset(month, by: -1) } label: { Image(systemName: "chevron.left").frame(width: 44, height: 44) }
                    .accessibilityLabel("Previous month").accessibilityIdentifier("expenses.previousMonth")
                Text(ExpenseRules.monthLabel(month)).font(.title3.bold()).frame(maxWidth: .infinity)
                    .accessibilityIdentifier("expenses.month")
                Button { month = ExpenseRules.offset(month, by: 1) } label: { Image(systemName: "chevron.right").frame(width: 44, height: 44) }
                    .accessibilityLabel("Next month").accessibilityIdentifier("expenses.nextMonth")
            }
            HStack {
                Button("This month") { month = ExpenseRules.month(.now) }.font(.subheadline).frame(minHeight: 44)
                Spacer()
                Picker("Currency", selection: $currency) { ForEach(ExpenseRules.currencies, id: \.self) { Text($0).tag($0) } }
                    .accessibilityIdentifier("expenses.currency")
            }
        }
    }
    private var overview: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(month == ExpenseRules.month(.now) ? "Spent this month" : "Spent in \(ExpenseRules.monthLabel(month))")
                        .font(.subheadline.weight(.medium))
                    Text(ExpenseRules.money(report.spent, currency: currency)).font(.largeTitle.weight(.semibold)).monospacedDigit()
                        .contentTransition(.numericText()).accessibilityIdentifier("expenses.total")
                    Text("\(report.items.filter { !$0.isRefund }.count) \(report.items.filter { !$0.isRefund }.count == 1 ? "purchase" : "purchases") · \(currency)")
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer(minLength: 12)
                Image(systemName: "chart.bar.xaxis").font(.system(size: 38, weight: .light))
                    .foregroundStyle(ExpenseTheme.accent).accessibilityHidden(true)
            }
            if report.refunded > 0 {
                Divider()
                LabeledContent("Refunds", value: ExpenseRules.money(report.refunded, currency: currency))
                LabeledContent("Net spending", value: ExpenseRules.money(report.net, currency: currency)).fontWeight(.semibold)
            }
            Text("Recorded purchases only. Each currency has its own report.").font(.caption).foregroundStyle(.secondary)
        }.padding(22).frame(maxWidth: .infinity, alignment: .leading)
            .background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Six-month spending").font(.headline)
            Chart(trend, id: \.month) { entry in
                BarMark(x: .value("Month", ExpenseRules.shortMonthLabel(entry.month)), y: .value("Spent", entry.spent))
                    .foregroundStyle(ExpenseTheme.accent.opacity(entry.month == month ? 1 : 0.35)).cornerRadius(5)
                    .accessibilityLabel(ExpenseRules.monthLabel(entry.month))
                    .accessibilityValue(ExpenseRules.money(entry.spent, currency: currency))
            }
            .chartYAxis(.hidden).frame(height: 145)
            let previous = ExpenseRules.summary(repository.expenseReportItems, month: ExpenseRules.offset(month, by: -1), currency: currency)
            Text("Previous month: \(ExpenseRules.money(previous.spent, currency: currency))")
                .font(.caption).foregroundStyle(.secondary)
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
    private var categoriesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Where it went").font(.headline)
            let categories = ExpenseCategory.allCases.filter { report.spending(in: $0) > 0 }
            if categories.isEmpty { Text("Your categories will appear after your first expense.").font(.subheadline).foregroundStyle(.secondary) }
            ForEach(categories.sorted { report.spending(in: $0) > report.spending(in: $1) }) { item in
                VStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline) {
                        Label(item.rawValue, systemImage: item.symbol).font(.subheadline)
                        Spacer(minLength: 8)
                        Text(ExpenseRules.money(report.spending(in: item), currency: currency)).font(.subheadline.weight(.semibold))
                    }
                    ProgressView(value: Double(report.spending(in: item)), total: Double(max(report.spent, 1)))
                        .accessibilityLabel("\(item.rawValue) share of spending")
                }
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
    private var purchaseHistory: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Purchases & refunds").font(.headline)
                Spacer()
                Button("Export report", systemImage: "square.and.arrow.up") { exporting = true }
                    .labelStyle(.iconOnly).frame(minWidth: 44, minHeight: 44).disabled(report.items.isEmpty)
                    .accessibilityIdentifier("expenses.export")
            }
            Picker("Category", selection: $category) {
                Text("All categories").tag(nil as ExpenseCategory?)
                ForEach(ExpenseCategory.allCases) { Text($0.rawValue).tag(Optional($0)) }
            }.accessibilityIdentifier("expenses.filter")
            if history.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text(report.items.isEmpty ? "Start with a receipt or an expense." : "No matching purchases.").font(.headline)
                    Text(report.items.isEmpty ? "Record groceries, bills and home purchases here. Scan a grocery receipt to update shopping and inventory too." : "Try a different category or search.")
                        .font(.subheadline).foregroundStyle(.secondary)
                }.padding(20).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            }
            ForEach(history, id: \.id) { entry in
                Button {
                    editing = repository.expenses.first { $0.id == entry.id }
                } label: {
                    HStack(alignment: .top, spacing: 14) {
                        Image(systemName: entry.category.symbol).font(.title3).foregroundStyle(ExpenseTheme.accent)
                            .frame(width: 40, height: 40).background(ExpenseTheme.accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 12)).accessibilityHidden(true)
                        VStack(alignment: .leading, spacing: 5) {
                            Text(entry.merchant).font(.headline)
                            Text("\(entry.day) · \(entry.category.rawValue)").font(.caption).foregroundStyle(.secondary)
                            if typeSize.isAccessibilitySize {
                                Text((entry.isRefund ? "−" : "") + ExpenseRules.money(entry.amount, currency: currency)).font(.headline)
                            }
                            if entry.isRefund { Text("Refund").font(.caption.weight(.semibold)).foregroundStyle(ExpenseTheme.accent) }
                        }
                        if !typeSize.isAccessibilitySize { Spacer(minLength: 8) }
                        if !typeSize.isAccessibilitySize {
                        Text((entry.isRefund ? "−" : "") + ExpenseRules.money(entry.amount, currency: currency)).font(.subheadline.weight(.semibold))
                            .multilineTextAlignment(.trailing)
                        }
                    }.padding(16).frame(maxWidth: .infinity, alignment: .leading).background(ExpenseTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                }.buttonStyle(.plain).accessibilityIdentifier("expenses.item.\(entry.merchant)")
            }
            Text("Export includes the whole selected month and currency, including refunds.").font(.caption).foregroundStyle(.secondary)
        }
    }
}

struct ExpenseReportDocument: FileDocument {
    static var readableContentTypes: [UTType] { [.commaSeparatedText] }
    var text: String
    init(text: String) { self.text = text }
    init(configuration: ReadConfiguration) throws { text = String(decoding: configuration.file.regularFileContents ?? Data(), as: UTF8.self) }
    func fileWrapper(configuration: WriteConfiguration) throws -> FileWrapper { FileWrapper(regularFileWithContents: Data(text.utf8)) }
}
