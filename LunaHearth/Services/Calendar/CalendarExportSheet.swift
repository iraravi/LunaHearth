import EventKit
import EventKitUI
import SwiftUI

/// Apple provides a reviewed event editor without requiring event-store read access.
struct CalendarExportSheet: UIViewControllerRepresentable {
    let draft: CalendarExportDraft
    @Environment(\.dismiss) private var dismiss
    func makeCoordinator() -> Coordinator { Coordinator { dismiss() } }
    func makeUIViewController(context: Context) -> EKEventEditViewController {
        let store = EKEventStore()
        let event = EKEvent(eventStore: store)
        event.title = draft.title; event.startDate = draft.start; event.endDate = draft.end; event.notes = draft.notes
        let editor = EKEventEditViewController()
        editor.eventStore = store; editor.event = event; editor.editViewDelegate = context.coordinator
        return editor
    }
    func updateUIViewController(_ controller: EKEventEditViewController, context: Context) {}
    // EventKitUI invokes its legacy delegate from the presented UI on the main thread.
    @MainActor final class Coordinator: NSObject, @preconcurrency EKEventEditViewDelegate {
        let dismiss: () -> Void
        init(dismiss: @escaping () -> Void) { self.dismiss = dismiss }
        func eventEditViewController(_ controller: EKEventEditViewController, didCompleteWith action: EKEventEditViewAction) { dismiss() }
    }
}
