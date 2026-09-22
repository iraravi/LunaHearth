import SwiftUI

/// Bundled offline draft. A published policy URL must be confirmed before release.
struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label("Your privacy", systemImage: "hand.raised.fill")
                    .font(AppTheme.displayTitle).accessibilityAddTraits(.isHeader)
                Text("Offline copy · Draft dated September 16, 2026")
                    .font(.subheadline).foregroundStyle(.secondary)
                Text("Preview for testing. Publisher contact details and the published policy are still being finalized. This is not the final release policy.")
                    .font(.subheadline).padding(16).frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
                    .accessibilityIdentifier("privacyPolicy.draft")
                policySection("Your household information", "LunaHearth stores household records on your device. These may include member display names, schedules, reminders, shopping, pantry contents, meal plans, expenses, rooms, belongings and documents that you choose to enter. The app does not require a LunaHearth account.")
                policySection("Optional iCloud", "If you enable iCloud backup or household sharing, data is sent to Apple CloudKit using your Apple account. Shared household records are available to participants you invite through Apple sharing. The owner’s iCloud storage and Apple’s service terms apply. Participants may save or copy information they can access. Removing access does not erase copies already received. Sync requires connectivity and can be delayed.")
                policySection("Photos, receipts and on-device intelligence", "Camera and selected photos are used when you choose a scanning/import feature. Receipt text recognition and optional generative assistance run on the device. Pantry scan photos are transient in the scan workflow; confirmed item details are saved. Imported documents may be retained when you explicitly save them. The app does not send household prompts to a third-party AI service. Review extracted information before saving.")
                policySection("Apple connections and notifications", "Calendar and Reminders access is optional and requested when connecting. Selected information may be read or written to Apple services according to your choices. Device notifications support reminders and household updates. Permissions can be changed in device Settings.")
                policySection("Tracking", "No advertising, attribution, third-party analytics or tracking SDK is included in the audited app. Apple may process service and diagnostic information under its own policies and your device settings.")
                policySection("Your controls", "More > Privacy & data provides data controls and private backup management. Review each deletion confirmation carefully. Live household data, backups, saved files and copies exported to Apple apps can have separate lifecycles; deleting one does not imply every separate copy is erased. Participants may retain previously received information. Keep an export or backup you need before clearing records.")
                policySection("Device backups and external copies", "System device backups may contain app data according to your Apple settings, separately from the app’s optional CloudKit features. Turning off a connection does not itself delete previously saved cloud data or entries in Apple Calendar or Reminders. Manage these copies in the relevant service.")
                policySection("People in your home", "Only enter and share information you are entitled to use. Tell household members what you share and check participant access before adding personal details. Member profiles are household records, not separate authenticated app accounts.")
                policySection("Support and changes", "Publisher support contact and retention practices must be supplied before publishing this draft. If you contact support, avoid sending sensitive household information unless it is necessary. The publisher must confirm the final effective date and how policy changes will be communicated.")
            }.padding(24).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .navigationTitle("Privacy policy").navigationBarTitleDisplayMode(.inline)
        .background(AppTheme.canvas)
        .accessibilityIdentifier("privacyPolicy.screen")
    }
    private func policySection(_ title: String, _ body: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title).font(.headline).accessibilityAddTraits(.isHeader)
            Text(body).font(.body).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
        }.frame(maxWidth: .infinity, alignment: .leading)
    }
}
