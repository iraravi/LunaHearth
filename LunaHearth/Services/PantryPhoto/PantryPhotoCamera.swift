import SwiftUI
import AVFoundation
import ImageIO

struct PantryPhotoCamera: UIViewControllerRepresentable {
    let completed: (Data?) -> Void
    static var isSupported: Bool { UIImagePickerController.isSourceTypeAvailable(.camera) }
    static func authorize() async -> Bool {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized: true
        case .notDetermined: await AVCaptureDevice.requestAccess(for: .video)
        default: false
        }
    }
    func makeCoordinator() -> Coordinator { Coordinator(completed: completed) }
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    func updateUIViewController(_ controller: UIImagePickerController, context: Context) {}
    @MainActor final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let completed: (Data?) -> Void
        init(completed: @escaping (Data?) -> Void) { self.completed = completed }
        func imagePickerControllerDidCancel(_ picker: UIImagePickerController) { completed(nil) }
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]) {
            completed((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.8))
        }
    }
}

@MainActor enum PantryPhotoPreview {
    static func make(_ data: Data) -> UIImage? {
        guard data.count <= 20_000_000, let source = CGImageSourceCreateWithData(data as CFData, nil),
              let image = CGImageSourceCreateThumbnailAtIndex(source, 0, [
                kCGImageSourceCreateThumbnailFromImageAlways: true,
                kCGImageSourceCreateThumbnailWithTransform: true,
                kCGImageSourceThumbnailMaxPixelSize: 900
              ] as CFDictionary) else { return nil }
        return UIImage(cgImage: image)
    }
}
