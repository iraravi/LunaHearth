import SwiftUI

private struct EntryActions: ViewModifier {
    @Environment(CalendarDeliveryCoordinator.self) private var calendarDelivery
    @Environment(LocalHouseholdRepository.self) private var repository
    let draft: EntryDraft
    let includesSwipeActions: Bool
    @State private var showingTask = false
    @State private var editing = false
    @State private var deleting = false
    @State private var error: String?

    private var hasAppleLink: Bool { draft.kind == .event && repository.calendarDeliveryLinks.contains { $0.eventID == draft.recordID } }

    func body(content: Content) -> some View {
        rowContent(content)
            .sheet(isPresented: $showingTask) {
                if let task = repository.tasks.first(where: { $0.id == draft.recordID }) {
                    NavigationStack { TaskDetailView(task: task).toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { showingTask = false } } } }
                }
            }
            .sheet(isPresented: $editing) {
                if draft.kind == .event, let event = repository.events.first(where: { $0.id == draft.recordID }) { AppointmentEditorView(event: event) }
                else { QuickAddView(draft: draft) }
            }
            .confirmationDialog("Delete \(draft.title)?", isPresented: $deleting, titleVisibility: .visible) {
                if hasAppleLink {
                    Button("Delete from both", role: .destructive) { delete(removeApple: true) }
                    Button("Delete here · keep Apple copy", role: .destructive) { delete(removeApple: false) }
                } else { Button("Delete", role: .destructive) { delete(removeApple: false) } }

            } message: { Text(hasAppleLink ? "This removes the household appointment. Apple removal applies only to the copy linked on this device. Other people’s separately exported copies stay. This cannot be undone." : "This removes the item from this household and syncs the deletion when sharing is enabled. This cannot be undone.") }
            .saveError($error)
    }

    private func delete(removeApple: Bool) {
        guard let id = draft.recordID else { return }
        do {
            try repository.deletePlanningEntry(id: id, kind: draft.kind, removeAppleEvent: removeApple)
            Task { await calendarDelivery.run(repository, force: true) }
        } catch { self.error = userFacingError(error) }
    }

    @ViewBuilder
    private func rowContent(_ content: Content) -> some View {
        if includesSwipeActions {
            content.swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if [.event, .task, .grocery, .meal].contains(draft.kind) {
                    Button("Delete", role: .destructive) { deleting = true }
                }
                Button("Edit") { editing = true }.tint(AppTheme.slate)
            }.contextMenu { menuActions }
        } else {
            VStack(alignment: .leading, spacing: 0) {
                content
                HStack {
                    Spacer(minLength: 0)
                    Menu { menuActions } label: {
                        Label("More", systemImage: "ellipsis")
                            .font(.caption.weight(.medium))
                            .frame(minWidth: 44, minHeight: 44)
                    }.buttonStyle(.borderless)
                        .accessibilityLabel("Actions for \(draft.title)")
                        .accessibilityIdentifier("entry.actions.\(draft.title)")
                }
            }
        }
    }

    @ViewBuilder
    private var menuActions: some View {
        Button("Edit", systemImage: "pencil") { editing = true }
        if draft.kind == .task {
            Button("Open task details", systemImage: "list.bullet.rectangle") { showingTask = true }
        }
        ShareLink(item: draft.title + (draft.notes.isEmpty ? "" : "\n\n" + draft.notes)) {
            Label("Share to Notes or another app", systemImage: "square.and.arrow.up")
        }
        if [.event, .task, .grocery, .meal].contains(draft.kind) {
            Button("Delete", systemImage: "trash", role: .destructive) { deleting = true }
        }
    }
}

extension View {
    func entryActions(_ draft: EntryDraft, includesSwipeActions: Bool = true) -> some View {
        modifier(EntryActions(draft: draft, includesSwipeActions: includesSwipeActions))
    }
}
