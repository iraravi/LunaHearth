import SwiftUI
import SwiftData

@main
struct LunaHearthApp: App {
    private let appContainer: ModelContainer
    @State private var repository: LocalHouseholdRepository

    init() {
        do {
            #if DEBUG
            let isUITest = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            #else
            let isUITest = false
            #endif
            let container = try LocalStoreConfiguration.makeContainer(inMemory: isUITest)
            appContainer = container
            _repository = State(initialValue: LocalHouseholdRepository(container: container))
        } catch {
            fatalError("Unable to initialize the local store.")
        }
    }

    var body: some Scene {
        WindowGroup {
            AppRootView().environment(repository).tint(AppTheme.accent)
                #if DEBUG
                .modifier(UITestAppearance())
                #endif
        }
        .modelContainer(appContainer)
    }
}

#if DEBUG
/// Test-only presentation overrides never change device or production preferences.
struct UITestAppearance: ViewModifier {
    func body(content: Content) -> some View {
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") {
            content
                .preferredColorScheme(ProcessInfo.processInfo.arguments.contains("--dark") ? .dark : .light)
                .dynamicTypeSize(ProcessInfo.processInfo.arguments.contains("--large-text") ? .accessibility3 : .large)
        } else {
            content
        }
    }
}
#endif
