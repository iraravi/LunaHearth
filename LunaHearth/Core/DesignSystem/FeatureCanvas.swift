import SwiftUI
import Observation

enum FeatureCanvas: Sendable {
    case standard, pantry, shopping, expenses
    var color: Color {
        switch self {
        case .standard: AppTheme.canvas
        case .pantry: Color("InventoryCanvas")
        case .shopping: Color("ShoppingCanvas")
        case .expenses: Color("ExpenseCanvas")
        }
    }
}
enum FeatureCanvasScope: Hashable, Sendable { case home, lists }
@MainActor @Observable final class FeatureCanvasCoordinator {
    private var visible: [FeatureCanvasScope: [(UUID, FeatureCanvas)]] = [:]
    func color(for scope: FeatureCanvasScope) -> Color { (visible[scope]?.last?.1 ?? .standard).color }
    func show(_ canvas: FeatureCanvas, id: UUID, scope: FeatureCanvasScope) {
        visible[scope, default: []].removeAll { $0.0 == id }
        visible[scope, default: []].append((id, canvas))
    }
    func hide(id: UUID, scope: FeatureCanvasScope) { visible[scope]?.removeAll { $0.0 == id } }
}
private struct FeatureCanvasCoordinatorKey: EnvironmentKey {
    static var defaultValue: FeatureCanvasCoordinator? { nil }
}
private struct FeatureCanvasScopeKey: EnvironmentKey {
    static let defaultValue: FeatureCanvasScope = .home
}
extension EnvironmentValues {
    var featureCanvasCoordinator: FeatureCanvasCoordinator? {
        get { self[FeatureCanvasCoordinatorKey.self] }
        set { self[FeatureCanvasCoordinatorKey.self] = newValue }
    }
    var featureCanvasScope: FeatureCanvasScope {
        get { self[FeatureCanvasScopeKey.self] }
        set { self[FeatureCanvasScopeKey.self] = newValue }
    }
}
private struct FeatureCanvasModifier: ViewModifier {
    let canvas: FeatureCanvas
    @Environment(\.featureCanvasCoordinator) private var coordinator
    @Environment(\.featureCanvasScope) private var scope
    @State private var id = UUID()
    func body(content: Content) -> some View {
        content
            .toolbarBackground(canvas.color, for: .navigationBar)
            .onAppear { coordinator?.show(canvas, id: id, scope: scope) }
            .onDisappear { coordinator?.hide(id: id, scope: scope) }
    }
}
extension View {
    func featureCanvas(_ canvas: FeatureCanvas) -> some View { modifier(FeatureCanvasModifier(canvas: canvas)) }
}
