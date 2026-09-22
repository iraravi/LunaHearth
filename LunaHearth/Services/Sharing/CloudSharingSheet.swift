import CloudKit
import SwiftUI
import UIKit

struct CloudSharingSheet: View {
    let ticket: HouseholdShareTicket
    let service: CloudKitHouseholdService
    var onError: (Error) -> Void
    var onChanged: () -> Void
    @Environment(\.dismiss) private var dismiss
    @State private var presentation: Presentation?
    @State private var failed = false
    private struct Presentation { let share: CKShare; let container: CKContainer }
    var body: some View {
        Group {
            if let presentation {
                SharingControllerRepresentable(share: presentation.share, container: presentation.container, onError: onError, onChanged: onChanged)
            } else {
                VStack(spacing: 20) {
                    if failed { Text("Could not open iCloud sharing. Your home is still saved.") }
                    else { ProgressView("Opening Apple sharing…") }
                    Button("Close") { dismiss() }
                }.padding()
            }
        }.task {
            do {
                let (share, container) = try await service.presentation(for: ticket)
                presentation = Presentation(share: share, container: container)
            } catch { failed = true; onError(error) }
        }
    }
}

private struct SharingControllerRepresentable: UIViewControllerRepresentable {
    let share: CKShare
    let container: CKContainer
    let onError: (Error) -> Void
    let onChanged: () -> Void
    func makeCoordinator() -> Coordinator { Coordinator(onError: onError, onChanged: onChanged) }
    func makeUIViewController(context: Context) -> UICloudSharingController {
        let controller = UICloudSharingController(share: share, container: container)
        controller.delegate = context.coordinator
        controller.availablePermissions = [.allowPrivate, .allowReadWrite, .allowReadOnly]
        return controller
    }
    func updateUIViewController(_ controller: UICloudSharingController, context: Context) {}
    final class Coordinator: NSObject, UICloudSharingControllerDelegate {
        let onError: (Error) -> Void
        let onChanged: () -> Void
        init(onError: @escaping (Error) -> Void, onChanged: @escaping () -> Void) { self.onError = onError; self.onChanged = onChanged }
        func itemTitle(for csc: UICloudSharingController) -> String? { "LunaHearth household" }
        func cloudSharingController(_ csc: UICloudSharingController, failedToSaveShareWithError error: Error) { onError(error) }
        func cloudSharingControllerDidSaveShare(_ csc: UICloudSharingController) { onChanged() }
        func cloudSharingControllerDidStopSharing(_ csc: UICloudSharingController) { onChanged() }
    }
}
