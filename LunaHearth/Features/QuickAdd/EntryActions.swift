import SwiftUI

private struct EntryActions: ViewModifier {
    @Environment(LocalHouseholdRepository.self) private var repository
    let draft: EntryDraft
    @State private var editing = false
    @State private var deleting = false
    @State private var error: String?

    func body(content: Content) -> some View {
        content
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                if [.event, .task, .grocery, .meal].contains(draft.kind) {
                    Button("Delete", role: .destructive) { deleting = true }
                }
                Button("Edit") { editing = true }.tint(.blue)
            }
            .contextMenu {
                Button("Edit", systemImage: "pencil") { editing = true }
                if [.event, .task, .grocery, .meal].contains(draft.kind) {
                    Button("Delete", systemImage: "trash", role: .destructive) { deleting = true }
                }
            }
            .sheet(isPresented: $editing) { QuickAddView(draft: draft) }
            .confirmationDialog("Delete \(draft.title)?", isPresented: $deleting, titleVisibility: .visible) {
                Button("Delete", role: .destructive) {
                    guard let id = draft.recordID else { return }
                    do { try repository.deletePlanningEntry(id: id, kind: draft.kind) }
                    catch { self.error = userFacingError(error) }
                }
            } message: { Text("This removes the item from this device and cannot be undone.") }
            .saveError($error)
    }
}

extension View {
    func entryActions(_ draft: EntryDraft) -> some View { modifier(EntryActions(draft: draft)) }
}
