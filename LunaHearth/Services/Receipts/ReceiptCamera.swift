import SwiftUI
import VisionKit

/// Apple's document scanner owns camera capture and its just-in-time permission UI.
struct ReceiptCamera: UIViewControllerRepresentable {
    let completed: ([UIImage]) -> Void
    let failed: (String) -> Void
    let cancelled: () -> Void
    static var isSupported: Bool { VNDocumentCameraViewController.isSupported }
    func makeCoordinator() -> Coordinator { Coordinator(parent: self) }
    func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
        let controller = VNDocumentCameraViewController()
        controller.delegate = context.coordinator
        return controller
    }
    func updateUIViewController(_ controller: VNDocumentCameraViewController, context: Context) {}
    // VisionKit delivers UI delegate callbacks on the main thread; its legacy protocol lacks isolation annotations.
    @MainActor final class Coordinator: NSObject, @preconcurrency VNDocumentCameraViewControllerDelegate {
        let parent: ReceiptCamera
        init(parent: ReceiptCamera) { self.parent = parent }
        func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) { parent.cancelled() }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFailWithError error: Error) {
            parent.failed("The camera could not scan this receipt. Try choosing a photo instead, or check camera access in Settings.")
        }
        func documentCameraViewController(_ controller: VNDocumentCameraViewController, didFinishWith scan: VNDocumentCameraScan) {
            guard (1...4).contains(scan.pageCount) else {
                parent.failed("Scan up to four pages from one receipt at a time."); return
            }
            // Encoding belongs to the bounded scan session, never this UI callback.
            parent.completed((0..<scan.pageCount).map { scan.imageOfPage(at: $0) })
        }
    }
}

/// Captured UIImages are immutable inputs. Rasterization and JPEG encoding run on this
/// actor, away from the main actor, with bounded output dimensions and no stored photos.
actor ReceiptCameraEncoder {
    func encode(_ image: UIImage) throws -> Data {
        try Task.checkCancellation()
        let longest = max(image.size.width, image.size.height)
        guard longest.isFinite, longest > 0 else { throw ReceiptImportError.unreadable }
        let scale = min(1, 2600 / longest)
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        guard size.width >= 1, size.height >= 1 else { throw ReceiptImportError.unreadable }
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        format.opaque = true
        let data = autoreleasepool {
            UIGraphicsImageRenderer(size: size, format: format).jpegData(withCompressionQuality: 0.9) { context in
                UIColor.white.setFill()
                context.fill(CGRect(origin: .zero, size: size))
                image.draw(in: CGRect(origin: .zero, size: size))
            }
        }
        try Task.checkCancellation()
        guard !data.isEmpty else { throw ReceiptImportError.unreadable }
        guard data.count <= 20_000_000 else { throw ReceiptImportError.tooLarge }
        return data
    }
}
