import SwiftUI

struct PurchaseFeedback: Identifiable, Equatable {
    let id = UUID()
    let name: String
    let detail: String
}

private struct PurchaseFeedbackModifier: ViewModifier {
    @Binding var feedback: PurchaseFeedback?
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { HearthMotion.reduced(systemReduceMotion) }
    @Environment(LocalHouseholdRepository.self) private var repository
    func body(content: Content) -> some View {
        content.safeAreaInset(edge: .bottom) {
            if let feedback {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: "checkmark.circle.fill").font(.title2).foregroundStyle(ShoppingTheme.accent)
                        .symbolEffect(.bounce, value: feedback.id).symbolEffectsRemoved(reduceMotion).accessibilityHidden(true)
                    VStack(alignment: .leading, spacing: 3) {
                        Text("Bought · \(feedback.name)").font(.subheadline.weight(.semibold))
                        Text(feedback.detail).font(.footnote).foregroundStyle(.secondary)
                    }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
                    Button { self.feedback = nil } label: { Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44) }
                        .accessibilityLabel("Dismiss purchase confirmation")
                }.padding(12).frame(maxWidth: 620)
                    .background(ShoppingTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                    .overlay(RoundedRectangle(cornerRadius: 20).stroke(ShoppingTheme.accent.opacity(0.25)))
                    .padding(.horizontal).padding(.bottom, 8)
                    .accessibilityIdentifier("shopping.purchaseConfirmation")
                    .transition(reduceMotion ? .identity : .move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(reduceMotion ? nil : .smooth(duration: 0.25), value: feedback?.id)
        .onChange(of: repository.household?.id) { _, _ in feedback = nil }
    }
}
extension View {
    func purchaseFeedback(_ feedback: Binding<PurchaseFeedback?>) -> some View { modifier(PurchaseFeedbackModifier(feedback: feedback)) }
}

struct AssignmentArrivalBanner: View {
    let focus: AssignmentFocus
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { HearthMotion.reduced(systemReduceMotion) }
    @State private var appeared = false
    var body: some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(focus.title).font(.headline)
                Text("Your current saved list is below. Updates appear as your home syncs.").font(.subheadline).foregroundStyle(.secondary)
            }
        } icon: {
            Image(systemName: focus.symbol).foregroundStyle(ShoppingTheme.accent)
                .symbolEffect(.bounce, value: appeared).symbolEffectsRemoved(reduceMotion).accessibilityHidden(true)
        }
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(ShoppingTheme.accent.opacity(0.09), in: RoundedRectangle(cornerRadius: 16))
        .accessibilityElement(children: .combine).accessibilityIdentifier("assignment.arrival.\(focus.rawValue)")
        .onAppear { appeared = true }
    }
}

/// Production always follows accessibility settings; UI fixtures can exercise the static path.
enum HearthMotion {
    static func reduced(_ system: Bool) -> Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"), ProcessInfo.processInfo.arguments.contains("--reduce-motion") { return true }
        #endif
        return system
    }
}
