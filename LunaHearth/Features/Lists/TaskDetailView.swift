import SwiftUI

struct TaskDetailView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    let task: HouseholdTask
    @State private var editing = false
    @State private var error: String?
    var body: some View {
        Form {
            LabeledContent("For", value: repository.memberName(task.assignedMemberID))
            if let due = task.dueAt { LabeledContent("Due", value: due.formatted(date: .abbreviated, time: task.mealID == nil ? .omitted : .shortened)) }
            Button(task.isCompleted ? "Reopen task" : "Mark completed", systemImage: "checkmark.circle") {
                do { try repository.toggle(task) } catch { self.error = userFacingError(error) }
            }
            Section("Apple apps") {
                Text("Saved in your household. Sharing a note creates a separate copy; it does not enable syncing.").font(.footnote)
                NavigationLink("Share as a note") { NotesSharingView(text: task.title) }
            }
        }.hearthList().navigationTitle(task.title).navigationBarTitleDisplayMode(.inline)
            .toolbar { Button("Edit") { editing = true } }
            .sheet(isPresented: $editing) { QuickAddView(draft: .editing(task)) }
            .saveError($error)
    }
}
