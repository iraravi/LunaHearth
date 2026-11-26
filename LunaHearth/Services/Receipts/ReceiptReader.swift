import Foundation
import CoreGraphics

/// The one path from receipt photos to review lines.
///
/// 1. Read every page with the layout-aware reader (iOS 26+), then plain OCR with spelling
///    correction off, then the old spelling-corrected OCR, stopping at the first reading whose
///    items add up to the receipt's own printed totals.
/// 2. If none adds up, keep the closest reading (`ReceiptReadingChoice`) and, where the device's
///    Apple model can read images, ask it for a proposal that is used only when it adds up and
///    every amount is backed by printed numbers (`ReceiptModelReadingCheck`).
/// Everything runs on the device; the review screen still needs the person's confirmation.
actor ReceiptReader {
    private let scanner = VisionReceiptScanner()
    /// Plain OCR per page, kept so the layout fallback and the plain pass read each page once.
    private var plainPages: [Int: String] = [:]

    private func plain(_ index: Int, _ image: CGImage) async throws -> String {
        if let cached = plainPages[index] { return cached }
        let text = try await scanner.text(of: image, source: .plain) ?? ""
        plainPages[index] = text
        return text
    }

    func read(pages: [Data]) async throws -> ReceiptScan {
        try FeatureAccess.require(.receipts)
        guard !pages.isEmpty else { throw ReceiptImportError.unreadable }
        let images = try pages.map { try VisionReceiptScanner.image($0) }
        plainPages = [:]

        var readings: [ReceiptReading] = []
        var notes: [String] = []
        for source in ReceiptReadingSource.allCases {
            try Task.checkCancellation()
            var texts: [String] = []
            var available = true
            for index in images.indices {
                switch source {
                case .plain:
                    texts.append(try await plain(index, images[index]))
                case .corrected:
                    texts.append(try await scanner.text(of: images[index], source: .corrected) ?? "")
                case .layout:
                    do {
                        guard let text = try await scanner.text(of: images[index], source: .layout) else { available = false; break }
                        // A page the layout reader could not read falls back to plain OCR for that page.
                        texts.append(text.isEmpty ? try await plain(index, images[index]) : text)
                    } catch is CancellationError {
                        throw CancellationError()
                    } catch {
                        texts.append(try await plain(index, images[index]))
                        notes.append("Layout reader failed on page \(index + 1); plain OCR used for it.")
                    }
                }
                if !available { break }
            }
            guard available else { notes.append("Layout reader not available on this iOS version."); continue }
            let reading = ReceiptReading(source: source, text: texts.joined(separator: "\n"))
            readings.append(reading)
            if ReceiptReadingChoice.score(reading.text).verified { break }
        }
        guard let chosen = ReceiptReadingChoice.best(readings) else { throw ReceiptImportError.unreadable }

        var scan = try await OnDeviceReceiptExtractionService().extract(text: chosen.reading.text)
        let verified = ReceiptReconciliation.check(lines: scan.lines, text: scan.text) == .verified
        #if RECEIPT_DEBUG
        scan.debugOutput = "READERS: " + readings.map { "\($0.source.label) \(ReceiptReadingChoice.score($0.text).verified ? "adds up" : "doesn't add up")" }
            .joined(separator: "; ") + ". Used: \(chosen.reading.source.label).\n" + notes.map { $0 + "\n" }.joined() + scan.debugOutput
        #endif
        if verified || ProcessInfo.processInfo.arguments.contains("--ui-testing") { return scan }

        // Last resort: the on-device model reads the first page; OCR's printed totals decide.
        guard images.count == 1 else { return scan }
        switch try await OnDeviceReceiptImageReader().read(images[0]) {
        case .read(let proposals):
            let lines = ReceiptImageProposalRules.lines(proposals, text: scan.text)
            if ReceiptModelReadingCheck.accepts(lines, text: scan.text, evidence: readings.map(\.text)) {
                scan.lines = lines
                scan.extractionMessage = "On-device AI read these items from the photo, and they add up to the totals printed on the receipt. Check them before saving."
                OnDeviceModel.succeeded(.aiReceiptNames)
                #if RECEIPT_DEBUG
                scan.debugOutput += "\nAI PHOTO READING accepted: \(lines.count) items add up and every amount is backed by printed numbers."
                #endif
            } else {
                OnDeviceModel.rejected(.aiReceiptNames)
                #if RECEIPT_DEBUG
                scan.debugOutput += "\nAI PHOTO READING rejected: \(proposals.count) items didn't add up or used amounts not printed on the receipt."
                #endif
            }
        case .unavailable(let reason):
            #if RECEIPT_DEBUG
            scan.debugOutput += "\nAI PHOTO READING skipped: \(reason)."
            #else
            _ = reason
            #endif
        case .failed(let reason):
            #if RECEIPT_DEBUG
            scan.debugOutput += "\nAI PHOTO READING failed: \(reason)."
            #else
            _ = reason
            #endif
        }
        return scan
    }
}
