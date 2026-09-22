import SwiftUI
import VisionKit

/// Apple's document scanner owns camera capture and its just-in-time permission UI.
struct ReceiptCamera: UIViewControllerRepresentable {
    let completed: ([Data]) -> Void
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
            let data = (0..<scan.pageCount).compactMap { scan.imageOfPage(at: $0).jpegData(compressionQuality: 0.8) }
            guard data.count == scan.pageCount else { parent.failed("A page could not be read. Please scan it again."); return }
            parent.completed(data)
        }
    }
}
