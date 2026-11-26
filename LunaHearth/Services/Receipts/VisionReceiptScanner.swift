import Foundation
import Vision
import ImageIO

actor VisionReceiptScanner: ReceiptScanningService {
    func scan(imageData: Data) async throws -> ReceiptScan {
        let text = try await text(of: try Self.image(imageData), source: .plain) ?? ""
        guard !text.isEmpty else { throw ReceiptImportError.unreadable }
        return ReceiptRules.scan(text: text)
    }

    /// One reading of one page. nil when that reader is not available on this device.
    func text(of image: CGImage, source: ReceiptReadingSource) async throws -> String? {
        try FeatureAccess.require(.receipts)
        try Task.checkCancellation()
        switch source {
        case .layout:
            guard #available(iOS 26.0, *) else { return nil }
            var request = RecognizeDocumentsRequest()
            // Receipts are codes and prices, not prose: do not "correct" them toward words.
            request.textRecognitionOptions.useLanguageCorrection = false
            let documents = try await request.perform(on: image, orientation: nil)
            try Task.checkCancellation()
            return Self.layoutText(documents).text
        case .plain, .corrected:
            let request = VNRecognizeTextRequest()
            request.recognitionLevel = .accurate
            request.usesLanguageCorrection = source == .corrected
            request.automaticallyDetectsLanguage = true
            try VNImageRequestHandler(cgImage: image).perform([request])
            try Task.checkCancellation()
            // Compare baselines at a common x position so tilted prices stay with their SKU.
            let fragments = (request.results ?? []).compactMap { observation -> ReceiptTextFragment? in
                guard let text = observation.topCandidates(1).first?.string else { return nil }
                return ReceiptTextFragment(text: text, x: observation.boundingBox.midX,
                    y: observation.boundingBox.midY, width: observation.boundingBox.width,
                    height: observation.boundingBox.height,
                    slope: (observation.topRight.y - observation.topLeft.y) / max(0.001, observation.topRight.x - observation.topLeft.x))
            }
            return ReceiptTextRows.assemble(fragments)
        }
    }

    static func image(_ data: Data) throws -> CGImage {
        guard data.count <= 20_000_000 else { throw ReceiptImportError.tooLarge }
        guard let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2600
              ] as CFDictionary) else { throw ReceiptImportError.unreadable }
        return image
    }

    /// Table rows become one line each (name, quantity and price together); other text keeps its position.
    @available(iOS 26.0, *)
    static func layoutText(_ documents: [DocumentObservation]) -> (text: String, tables: Int) {
        var fragments: [ReceiptTextFragment] = []
        var tableCount = 0
        for observation in documents {
            var tableRects: [CGRect] = []
            for table in observation.document.tables {
                tableCount += 1
                let tableLines = table.rows.flatMap { $0.flatMap { $0.content.text.lines } }
                if let rect = tableLines.map({ rect($0.boundingBox) }).reduce(nil, { ($0 ?? $1).union($1) }) {
                    tableRects.append(rect)
                }
                for row in table.rows {
                    let cells = row.map { $0.content.text.transcript.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
                    let boxes = row.flatMap { $0.content.text.lines.map { rect($0.boundingBox) } }
                    guard !cells.isEmpty, let box = boxes.reduce(nil, { ($0 ?? $1).union($1) }) else { continue }
                    fragments.append(ReceiptTextFragment(text: cells.joined(separator: " "), x: box.minX, y: box.midY,
                                                         width: box.width, height: boxes.map(\.height).reduce(0, +) / Double(boxes.count), slope: 0))
                }
            }
            for line in observation.document.text.lines {
                let box = rect(line.boundingBox)
                guard !tableRects.contains(where: { $0.contains(CGPoint(x: box.midX, y: box.midY)) }) else { continue }
                fragments.append(ReceiptTextFragment(text: line.transcript, x: box.midX, y: box.midY, width: box.width, height: box.height,
                    slope: (line.topRight.y - line.topLeft.y) / max(0.001, line.topRight.x - line.topLeft.x)))
            }
        }
        return (ReceiptTextRows.assemble(fragments), tableCount)
    }

    @available(iOS 26.0, *)
    private static func rect(_ box: NormalizedRect) -> CGRect {
        CGRect(origin: box.origin, size: CGSize(width: box.width, height: box.height))
    }
}
