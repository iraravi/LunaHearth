import SwiftUI

struct AppRootView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(PersonalShopping.self) private var personal
    @Environment(HouseholdSharingController.self) private var sharing
    @Environment(ReminderDeliveryCoordinator.self) private var reminderDelivery
    @Environment(AppleConnections.self) private var connections
    @Environment(\.scenePhase) private var scenePhase
    @State private var reminderPurpose: ReminderPurpose = .reminders
    @State private var showReminders = false
    @State private var linkedTask: HouseholdTask?
    @State private var linkUnavailable = false
    @State private var startInHome = false
    @State private var showCloudStatus = false
    @Environment(CalendarDeliveryCoordinator.self) private var calendarDelivery
    @Environment(AppointmentAlertCoordinator.self) private var appointmentAlerts
    @State private var appointmentLink: AppointmentLink?
    @AppStorage("welcome.walkthrough.v1.reviewed") private var walkthroughReviewed = false
    @State private var aiAvailability: AIAvailability = .unavailable
    @State private var publicStatus = PublicConfigurationStore()
    @State private var loaded = false
    @State private var loadFailed = false

    var body: some View {
        @Bindable var sharing = sharing
        VStack(spacing: 0) {
            cloudStatusBanner
            if let config = publicStatus.configuration, config.expiresAt > .now,
               let notice = config.announcement, !notice.isEmpty {
                Label(notice, systemImage: "info.circle")
                    .font(.footnote).padding(10).frame(maxWidth: .infinity, alignment: .leading)
                    .background(.regularMaterial).accessibilityIdentifier("appStatus.notice")
            }
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
                } else if let invitation = sharing.invitation {
                    HouseholdInvitationView(invitation: invitation)
                } else if sharing.lookingUpInvitation {
                    ProgressView("Opening invitation…")
                } else if shouldShowWalkthrough {
                    HowItWorksView(hasHome: repository.household != nil) {
                        walkthroughReviewed = true
                        startInHome = true
                    }
                } else if repository.household != nil {
                    RootTabView(initialTab: startInHome ? .home : .today)
                } else {
                    OnboardingView(onCreated: { startInHome = true })
                }
            }
        }
        .background(AppTheme.canvas).tint(AppTheme.accent)
        .scrollContentBackground(.hidden)
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            aiAvailability = AppleAIStatusService().status().availability
            #if DEBUG
            // Presentation fixture only; AI services retain their real capability checks.
            let arguments = ProcessInfo.processInfo.arguments
            if arguments.contains("--ui-testing") {
                if arguments.contains("--ui-testing-ai-ready") { aiAvailability = .ready }
                if arguments.contains("--ui-testing-ai-unavailable") { aiAvailability = .unsupportedDevice }
            }
            #endif
        }
        .task(id: scenePhase) {
            guard scenePhase == .active else { return }
            #if DEBUG
            if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return }
            #endif
            await publicStatus.refresh()
        }
        .task { load() }
        .task(id: "\(scenePhase == .active)-\(repository.household?.id.uuidString ?? "none")") {
            guard scenePhase == .active, repository.household != nil else { return }
            await personal.preparePush(repository, service: sharing.service)
            await refreshHouseholdServices(force: true)
            await ForegroundRefreshLoop.run {
                await refreshHouseholdServices()
            }
        }
        .task(id: repository.writeRevision) {
            guard scenePhase == .active, repository.household != nil else { return }
            do { try await Task.sleep(for: .seconds(1)) } catch { return }
            await refreshHouseholdServices()
        }
        .alert("Couldn’t open invitation", isPresented: Binding(get: { sharing.invitationError != nil }, set: { if !$0 { sharing.invitationError = nil } })) {
            Button("OK") { sharing.invitationError = nil }
        } message: { Text(sharing.invitationError ?? "Try opening the invitation again.") }
        .sheet(isPresented: $showCloudStatus) {
            NavigationStack { HouseholdSharingView().toolbar { Button("Done") { showCloudStatus = false } } }
        }
        .sheet(item: $appointmentLink) { link in AppointmentLinkView(link: link) }
        .onOpenURL { url in
            if url.scheme == "lunahearth", url.host == "appointment", url.pathComponents.count == 3,
               let homeID = UUID(uuidString: url.pathComponents[1]), let eventID = UUID(uuidString: url.pathComponents[2]) {
                load()
                if homeID == repository.household?.id, let event = repository.events.first(where: { $0.id == eventID }),
                   let calendarURL = try? AppointmentLink.url(date: event.startAt, create: false) { appointmentLink = AppointmentLink(url: calendarURL) }
                else { linkUnavailable = true }
                return
            }
            if let link = AppointmentLink(url: url) { load(); appointmentLink = link; return }
            if HouseholdInvitationLink.url(from: url.absoluteString) != nil {
                Task { await sharing.lookupInvitation(url.absoluteString) }; return
            }
            if url.scheme == "lunahearth", let host = url.host, let purpose = ReminderPurpose(rawValue: host) { reminderPurpose = purpose; showReminders = true; return }
            guard let id = HouseholdLink.taskID(url) else { return }
            load()
            linkedTask = repository.tasks.first { $0.id == id }
            linkUnavailable = linkedTask == nil
        }
        .sheet(isPresented: $showReminders) { NavigationStack { ConnectedRemindersView(purpose: reminderPurpose) } }
        .sheet(item: $linkedTask) { task in
            NavigationStack {
                TaskDetailView(task: task)
                    .toolbar { ToolbarItem(placement: .cancellationAction) { Button("Done") { linkedTask = nil } } }
            }
        }
        .alert("Task unavailable", isPresented: $linkUnavailable) {
            Button("OK", role: .cancel) {}
        } message: { Text("This task isn't in the household stored on this device.") }
        .onChange(of: scenePhase) { _, phase in if phase == .active { load(); connections.foreground() } }
        .environment(publicStatus)
        .environment(\.aiAvailability, (publicStatus.configuration?.allows(.ai) ?? true) ? aiAvailability : .unavailable)
    }

    @ViewBuilder private var cloudStatusBanner: some View {
        if repository.syncConfiguration != nil && (repository.syncConfiguration?.recovery == true || repository.syncConfiguration?.readOnly == true || sharing.message != nil || sharing.pendingCount > 0) {
            Button { showCloudStatus = true } label: {
                Label(repository.syncConfiguration?.recovery == true ? "Shared home in recovery · Local data preserved" : repository.syncConfiguration?.readOnly == true ? "Read-only shared home" : sharing.message != nil ? "iCloud needs attention · Changes saved here" : "\(sharing.pendingCount) changes waiting to sync", systemImage: "icloud")
                    .font(.caption).frame(maxWidth: .infinity).padding(8)
            }.buttonStyle(.plain).background(.regularMaterial).accessibilityIdentifier("sharing.banner")
        }
    }

    private var shouldShowWalkthrough: Bool {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") && !ProcessInfo.processInfo.arguments.contains("--ui-testing-walkthrough") { return false }
        #endif
        return !walkthroughReviewed
    }

    private func refreshHouseholdServices(force: Bool = false) async {
        guard !Task.isCancelled, scenePhase == .active, let home = repository.household?.id else { return }
        await sharing.sync(repository, force: force)
        guard !Task.isCancelled, repository.household?.id == home else { return }
        await personal.refresh(repository)
        await appointmentAlerts.refresh(repository)
        await calendarDelivery.run(repository)
        await MealPrepReminder().reconcile(householdID: home, tasks: repository.tasks.filter { $0.mealID != nil }.map {
            MealPrepReminderInput(id: $0.id, due: $0.dueAt, completed: $0.isCompleted)
        })
    }

    private func load() {
        do { try repository.reload(); try repository.retireAutomaticReminderDelivery(); loaded = true; loadFailed = false }
        catch { loadFailed = true }
    }
}
