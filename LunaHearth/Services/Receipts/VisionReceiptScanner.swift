import Foundation
import Vision
import ImageIO

actor VisionReceiptScanner: ReceiptScanningService {
    func scan(imageData: Data) async throws -> ReceiptScan {
        try FeatureAccess.require(.receipts)
        guard imageData.count <= 20_000_000 else { throw ReceiptImportError.tooLarge }
        try Task.checkCancellation()
        guard let source = CGImageSourceCreateWithData(imageData as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 2600
              ] as CFDictionary) else { throw ReceiptImportError.unreadable }
        let request = VNRecognizeTextRequest()
        request.recognitionLevel = .accurate
        request.usesLanguageCorrection = true
        request.automaticallyDetectsLanguage = true
        try VNImageRequestHandler(cgImage: image).perform([request])
        try Task.checkCancellation()
        let observations = (request.results ?? []).sorted { $0.boundingBox.midY > $1.boundingBox.midY }
        // Vision can split product and price into separate observations. Rejoin on the same baseline.
        var rows: [[VNRecognizedTextObservation]] = []
        for observation in observations {
            if let last = rows.last, let anchor = last.first,
               abs(anchor.boundingBox.midY - observation.boundingBox.midY) < min(anchor.boundingBox.height, observation.boundingBox.height) * 0.5 {
                rows[rows.count - 1].append(observation)
            } else { rows.append([observation]) }
        }
        let text = rows.map { row in
            row.sorted { $0.boundingBox.minX < $1.boundingBox.minX }.compactMap { $0.topCandidates(1).first?.string }.joined(separator: " ")
        }.joined(separator: "\n")
        guard !text.isEmpty else { throw ReceiptImportError.unreadable }
        return ReceiptRules.scan(text: text)
    }
}
