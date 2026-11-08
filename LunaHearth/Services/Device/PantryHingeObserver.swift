import SwiftUI
import UIKit

/// The only adapter referencing the iOS 27.1 hinge API. No permissions or persistence.
struct PantryHingeObserver: UIViewRepresentable {
    let update: @MainActor (PantryHingeState) -> Void
    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        if #available(iOS 27.1, *) {
            view.addInteraction(UIHingeInteraction { _, change in
                let state: PantryHingeState
                if let hinge = change.hinge {
                    switch hinge.status {
                    case .closed: state = .closed
                    case .partiallyOpen: state = .partiallyOpen
                    case .fullyOpen: state = .fullyOpen
                    default: state = .unknown
                    }
                } else { state = .unavailable }
                // Deliver after hierarchy/layout updates, never mutate SwiftUI during rendering.
                Task { @MainActor in update(state) }
            })
        }
        return view
    }
    func updateUIView(_ uiView: UIView, context: Context) {}
}
