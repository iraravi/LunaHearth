import Foundation

/// Sending-app completion is not evidence of recipient delivery or acceptance.
enum InvitationDeliveryStatus: String, Sendable {
    case ready, cancelled, copied, mailQueued, sharingCompleted, failed

    var title: String {
        switch self {
        case .ready: "Invitation ready — not sent yet"
        case .cancelled: "Invitation not sent"
        case .copied: "Link copied — send it to your person"
        case .mailQueued: "Invitation handed to Mail"
        case .sharingCompleted: "Sharing step completed"
        case .failed: "Couldn’t send the invitation"
        }
    }
    var detail: String {
        switch self {
        case .ready: "Send the link through Mail or Messages. Creating a profile does not notify the other person."
        case .cancelled: "The send screen was closed. You can try again using the same invitation."
        case .copied: "Copying does not send a message. Paste the link into Mail or Messages and send it."
        case .mailQueued: "Mail accepted the message for sending. Check Sent or Outbox; delivery and joining are not yet confirmed."
        case .sharingCompleted: "Check the app you chose to make sure the invitation was sent to the right person. Delivery and joining are not yet confirmed."
        case .failed: "Your invitation is still ready. Try Mail, Messages, or another sharing option."
        }
    }
}
