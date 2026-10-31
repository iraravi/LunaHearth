import MessageUI
import SwiftUI
import UIKit

enum InvitationSendMethod: String, Identifiable {
    case mail, share
    var id: String { rawValue }
    @MainActor static var preferred: Self { MFMailComposeViewController.canSendMail() ? .mail : .share }
}

/// Only presents Apple's composer. The user reviews the recipient and presses Send.
struct InvitationSendSheet: UIViewControllerRepresentable {
    let method: InvitationSendMethod
    let recipient: String
    let homeName: String
    let url: URL
    let onResult: @MainActor (InvitationDeliveryStatus) -> Void

    func makeCoordinator() -> Coordinator { Coordinator(onResult: onResult) }
    func makeUIViewController(context: Context) -> UIViewController {
        if method == .mail, MFMailComposeViewController.canSendMail() {
            let controller = MFMailComposeViewController()
            controller.setToRecipients([recipient])
            controller.setSubject("Join \(homeName) in Nam Illam")
            controller.setMessageBody("You’re invited to join \(homeName) in Nam Illam. Open this invitation on the device signed into your invited iCloud account:\n\n\(url.absoluteString)", isHTML: false)
            controller.mailComposeDelegate = context.coordinator
            return controller
        }
        let controller = UIActivityViewController(activityItems: ["Join \(homeName) in Nam Illam.", url], applicationActivities: nil)
        controller.view.accessibilityIdentifier = "sharing.sendSheet"
        if let popover = controller.popoverPresentationController {
            popover.sourceView = controller.view
            popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.midY, width: 1, height: 1)
            popover.permittedArrowDirections = []
        }
        controller.completionWithItemsHandler = { activity, completed, _, error in
            let result: InvitationDeliveryStatus
            if error != nil { result = .failed }
            else if !completed { result = .cancelled }
            else if activity == .copyToPasteboard { result = .copied }
            else { result = .sharingCompleted }
            Task { @MainActor in onResult(result) }
        }
        return controller
    }
    func updateUIViewController(_ controller: UIViewController, context: Context) {}

    @MainActor final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let onResult: @MainActor (InvitationDeliveryStatus) -> Void
        init(onResult: @escaping @MainActor (InvitationDeliveryStatus) -> Void) { self.onResult = onResult }
        nonisolated func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
            let status: InvitationDeliveryStatus
            if error != nil { status = .failed }
            else {
                switch result {
                case .sent: status = .mailQueued
                case .cancelled, .saved: status = .cancelled
                case .failed: status = .failed
                @unknown default: status = .failed
                }
            }
            Task { @MainActor [weak self] in self?.onResult(status) }
        }
    }
}
