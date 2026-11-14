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
        // Compare baselines at a common x position so tilted prices stay with their SKU.
        let fragments = (request.results ?? []).compactMap { observation -> ReceiptTextFragment? in
            guard let text = observation.topCandidates(1).first?.string else { return nil }
            return ReceiptTextFragment(text: text, x: observation.boundingBox.midX,
                y: observation.boundingBox.midY, width: observation.boundingBox.width,
                height: observation.boundingBox.height,
                slope: (observation.topRight.y - observation.topLeft.y) / max(0.001, observation.topRight.x - observation.topLeft.x))
        }
        let text = ReceiptTextRows.assemble(fragments)
        guard !text.isEmpty else { throw ReceiptImportError.unreadable }
        return ReceiptRules.scan(text: text)
    }
}
