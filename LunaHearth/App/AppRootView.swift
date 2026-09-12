import SwiftUI

struct AppRootView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.scenePhase) private var scenePhase
    @State private var startInHome = false
    @State private var loaded = false
    @State private var loadFailed = false

    var body: some View {
        Group {
            if loadFailed {
                ContentUnavailableView {
                    Label("Couldn't open your household", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("Your stored data has not been deleted. Try opening it again.")
                } actions: {
                    Button("Try Again", action: load)
                }
            } else if !loaded {
                ProgressView("Opening your household…")
            } else if repository.household != nil {
                RootTabView(initialTab: startInHome ? .home : .today)
            } else {
                OnboardingView(onCreated: { startInHome = true })
            }
        }
        .task { load() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { load() } }
    }

    private func load() {
        do { try repository.reload(); loaded = true; loadFailed = false }
        catch { loadFailed = true }
    }
}
