#if RECEIPT_DEBUG
import SwiftUI
import PhotosUI

/// Internal build only. No repository writes, image storage, telemetry or automatic export.
struct ReceiptDebugView: View {
    @State private var photos: [PhotosPickerItem] = []
    @State private var camera = false
    @State private var session = ReceiptScanSession()
    @State private var report = ""
    @State private var error: String?

    var body: some View {
        List {
            Section("Developer receipt lab") {
                Text("Runs the same OCR and Apple AI pipeline as receipt import. Nothing is added to Expenses or Pantry. Text stays in memory until you clear or leave this screen.")
                Text("Reports can contain private receipt details. Share only after reviewing the text.").font(.footnote).foregroundStyle(.secondary)
                PhotosPicker(selection: $photos, maxSelectionCount: 4, matching: .images) {
                    Label("Choose receipt photos", systemImage: "photo.on.rectangle")
                }.disabled(session.isReading).accessibilityIdentifier("receiptDebug.photos")
                if ReceiptCamera.isSupported {
                    Button("Scan receipt", systemImage: "doc.viewfinder") { camera = true }
                        .disabled(session.isReading).accessibilityIdentifier("receiptDebug.camera")
                }
                if session.isReading {
                    ProgressView("Reading OCR and running on-device AI…")
                    Button("Cancel") { clear() }
                }
                if let error { Text(error).foregroundStyle(.red).accessibilityIdentifier("receiptDebug.error") }
            }
            if !report.isEmpty {
                Section {
                    ShareLink("Share debug text", item: report)
                        .accessibilityIdentifier("receiptDebug.share")
                    Button("Clear report", role: .destructive) { clear() }
                        .accessibilityIdentifier("receiptDebug.clear")
                }
                Section("OCR → AI → validation → final items") {
                    Text(report).font(.system(.caption, design: .monospaced))
                        .textSelection(.enabled).accessibilityIdentifier("receiptDebug.output")
                }
            }
        }
        .navigationTitle("Receipt debug")
        .sheet(isPresented: $camera) {
            ReceiptCamera(completed: { images in
                camera = false
                begin {
                    let encoder = ReceiptCameraEncoder()
                    var pages: [Data] = []
                    for image in images {
                        try Task.checkCancellation()
                        pages.append(try await encoder.encode(image))
                    }
                    return try await run(pages)
                }
            }, failed: { message in camera = false; error = message }, cancelled: { camera = false })
        }
        .onChange(of: photos) { _, selected in
            guard !selected.isEmpty else { return }
            begin {
                var pages: [Data] = []
                for photo in selected {
                    try Task.checkCancellation()
                    guard let data = try await photo.loadTransferable(type: Data.self) else { throw ReceiptImportError.unreadable }
                    pages.append(data)
                }
                return try await run(pages)
            }
        }
        .onDisappear { clear() }
    }

    /// Shipping pipeline first, then the debug-only readers on the same photos for comparison.
    private func run(_ pages: [Data]) async throws -> ReceiptScan {
        let scanner = VisionReceiptScanner()
        var texts: [String] = []
        for page in pages {
            try Task.checkCancellation()
            texts.append(try await scanner.scan(imageData: page).text)
        }
        var scan = try await extract(texts.joined(separator: "\n"))
        report = ReceiptDebugReport.make(scan) + "\n\nEXPERIMENTS RUNNING… (document recognition, then Apple model with image)"
        let lab = ReceiptExperimentService()
        let document = await lab.documentRecognition(pages: pages)
        try Task.checkCancellation()
        let model = await lab.imageModel(pages: pages, ocrText: scan.text)
        try Task.checkCancellation()
        scan.experimentOutput = ReceiptDebugReport.experiments(current: scan, document: document, model: model)
        return scan
    }

    private func extract(_ text: String) async throws -> ReceiptScan {
        // Keep OCR visible if model generation is cancelled or reaches the watchdog.
        var pending = ReceiptScan(text: text, lines: [], extractionMessage: "OCR completed. AI pending; no final items yet.")
        pending.debugOutput = "No structured AI output yet."
        report = ReceiptDebugReport.make(pending)
        return try await OnDeviceReceiptExtractionService().extract(text: text)
    }

    private func begin(_ operation: @escaping @MainActor () async throws -> ReceiptScan) {
        report = ""; error = nil
        session.start(timeout: .seconds(240), operation: operation, completed: { scan in
            report = ReceiptDebugReport.make(scan)
            photos = []
        }, failed: { message in
            error = message; photos = []
            if !report.isEmpty { report += "\n\nSCAN STOPPED\n" + message }
        })
    }
    private func clear() { session.cancel(); report = ""; error = nil; photos = [] }
}

enum ReceiptDebugReport {
    static func make(_ scan: ReceiptScan) -> String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "?"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "?"
        let rows = scan.text.components(separatedBy: .newlines).enumerated().map { "[\($0.offset)] \($0.element)" }.joined(separator: "\n")
        let items = scan.lines.enumerated().map { index, line in
            "\(index + 1). \(line.name) | amount=\(line.amount.isEmpty ? "unknown" : line.amount) | quantity=\(line.quantity) | amountNeedsReview=\(line.amountNeedsReview || line.amount.isEmpty)\(line.correctedFrom.map { " | correctedFrom=\($0)" } ?? "")"
        }.joined(separator: "\n")
        return """
        INTERNAL RECEIPT DEBUG · \(version) (\(build))
        \(ProcessInfo.processInfo.operatingSystemVersionString)
        No records saved. Review all values.

        PIPELINE STATUS
        \(scan.extractionMessage ?? "Standard scan; no AI status returned.")

        NUMBERED OCR TEXT (zero-based rows)
        \(rows)

        \(scan.debugOutput)

        PURCHASE SUGGESTIONS
        Store: \(ReceiptPurchaseDetails.merchant(scan.text) ?? "needs review")
        Date: \(ReceiptPurchaseDetails.day(scan.text) ?? "needs review")
        Total: \(ExpenseRules.receiptTotal(scan.text) ?? "needs review")

        ITEMIZATION CHECK (public builds list items only when verified)
        \(itemizationSummary(scan))

        MAIN SCREEN PREVIEW
        \(mainScreenSummary(scan))

        RAW ITEM CANDIDATES (\(scan.lines.count)) — diagnostic only, not necessarily listed
        \(items)
        \(scan.experimentOutput)
        """
    }
    static func experiments(current: ReceiptScan, document: ReceiptExperimentService.Outcome, model: ReceiptExperimentService.Outcome) -> String {
        func result(_ lines: [ReceiptLine], text: String) -> String {
            switch ReceiptReconciliation.check(lines: lines, text: text) {
            case .verified: "LISTED (items match printed totals)"
            case .unverified(let gap): "HIDDEN (\(gap))"
            }
        }
        func items(_ lines: [ReceiptLine], printedIn text: String? = nil) -> String {
            lines.enumerated().map { index, line in
                let printed = text.map { ReceiptImageProposalRules.isPrinted(line.amount, in: $0) ? " | printed" : " | not printed (net or invented)" } ?? ""
                return "  \(index + 1). \(line.name) | \(line.amount.isEmpty ? "unknown" : line.amount)\(printed)"
            }.joined(separator: "\n")
        }
        func section(_ title: String, _ outcome: ReceiptExperimentService.Outcome, checkText: String, printedIn: String? = nil) -> String {
            guard outcome.available, outcome.seconds > 0 || !outcome.lines.isEmpty else { return "\(title)\n  Not run: \(outcome.note)" }
            return """
            \(title) · \(String(format: "%.1f", outcome.seconds)) s
              \(outcome.note)
              Result: \(result(outcome.lines, text: checkText)) · \(outcome.lines.count) items · sum \(ExpenseRules.amountText(outcome.lines.compactMap { try? ExpenseRules.minorUnits($0.amount) }.reduce(0, +)))
            \(items(outcome.lines, printedIn: printedIn))
            """
        }
        let documentText = document.text.isEmpty ? "" : "\n  Document text (numbered):\n" + document.text.components(separatedBy: .newlines).enumerated().map { "  [\($0.offset)] \($0.element)" }.joined(separator: "\n")
        return """

        ===== EXPERIMENTS (debug only, nothing saved) =====
        Each reader's items are checked against the printed subtotal/tax/total.
        The main screen uses A. Readers B and C are diagnostic comparisons only.

        A. CURRENT PIPELINE
          Result: \(result(current.lines, text: current.text)) · \(current.lines.count) items

        \(section("B. VISION DOCUMENT RECOGNITION (option 2)", document, checkText: document.text.isEmpty ? current.text : document.text))\(documentText)

        \(section("C. APPLE MODEL READING THE IMAGE (option 1)", model, checkText: current.text, printedIn: current.text))
          Totals for C come from OCR text, never from the model.

        \(mathReader(current.text))
        """
    }
    /// D: the math reader on its own, so every scan shows whether one reading of the rows adds up.
    static func mathReader(_ text: String) -> String {
        let outcome = ReceiptSolver.solve(text: text)
        let rows = outcome.lines.enumerated().map { "  \($0.offset + 1). \($0.element.name) | \($0.element.amount)\($0.element.quantity.isEmpty ? "" : " | \($0.element.quantity)")" }
        return (["D. MATH READER (used when A does not add up)", "  Status: \(outcome.status) · \(outcome.note)"] + rows).joined(separator: "\n")
    }
    static func totalEvidenceSummary(_ text: String) -> String {
        switch ExpenseRules.receiptTotalEvidence(text) {
        case .absent: "absent — enter total manually"
        case .unreadable: "unreadable — compare with receipt"
        case .conflicting: "conflicting — manual review required"
        case .value(let amount): "readable proposal: \(amount)"
        }
    }

    static func mainScreenSummary(_ scan: ReceiptScan) -> String {
        let result = ReceiptReconciliation.check(lines: scan.lines, text: scan.text)
        let count = result == .verified ? scan.lines.count : 0
        return """
        Visible scanned items: \(count)
        \(result == .verified ? "Items can be reviewed before saving." : "Expense-only fallback; scanned items are hidden. Add items manually if needed.")
        Store, date, currency and total require user review before saving an expense.
        Main screen can keep the receipt image with explicit opt-in, even without items.
        This debug screen saves no expense, products or receipt image.
        """
    }

    static func itemizationSummary(_ scan: ReceiptScan) -> String {
        let printed = ReceiptReconciliation.totals(scan.text)
        func money(_ value: Int?) -> String { value.map(ExpenseRules.amountText) ?? "unreadable" }
        let sum = scan.lines.compactMap { try? ExpenseRules.minorUnits($0.amount) }.reduce(0, +)
        return """
        Result: \(ReceiptReconciliation.check(lines: scan.lines, text: scan.text))
        Total evidence: \(totalEvidenceSummary(scan.text))
        Conflicting printed amounts: \(printed.hasConflictingAmounts ? "yes" : "no")
        Items sum (readable amounts only): \(ExpenseRules.amountText(sum))
        Subtotal: \(money(printed.subtotal)) · Tax: \(money(printed.tax))\(printed.taxLabelSeen ? "" : " (no tax label)")\(printed.discounts > 0 ? " · Receipt discounts: −\(ExpenseRules.amountText(printed.discounts))" : "") · Total: \(money(printed.total))
        """
    }
}
#endif
