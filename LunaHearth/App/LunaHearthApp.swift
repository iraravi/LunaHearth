import SwiftUI
import SwiftData

@main
struct LunaHearthApp: App {
    @UIApplicationDelegateAdaptor(SharingAppDelegate.self) private var sharingDelegate
    @State private var sharing: HouseholdSharingController
    private let appContainer: ModelContainer
    private let storeNeedsRecovery: Bool
    @State private var repository: LocalHouseholdRepository
    @State private var connections: AppleConnections
    @State private var calendarDelivery: CalendarDeliveryCoordinator
    @State private var appointmentAlerts: AppointmentAlertCoordinator
    @State private var personal: PersonalShopping
    @State private var reminderDelivery: ReminderDeliveryCoordinator

    init() {
        do {
            #if DEBUG
            let isUITest = ProcessInfo.processInfo.arguments.contains("--ui-testing")
            if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-reset-walkthrough") {
                UserDefaults.standard.set(false, forKey: "welcome.walkthrough.v1.reviewed")
            }
            #else
            let isUITest = false
            #endif
            let container: ModelContainer
            do {
                #if DEBUG
                if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-store-failure") { throw CocoaError(.fileReadCorruptFile) }
                #endif
                container = try LocalStoreConfiguration.makeContainer(inMemory: isUITest)
                storeNeedsRecovery = false
            } catch {
                // A transient storage/migration failure must not become a reset or fresh onboarding.
                // This temporary container is never exposed to household UI or synchronization.
                container = try LocalStoreConfiguration.makeContainer(inMemory: true)
                storeNeedsRecovery = true
            }
            appContainer = container
            let repository = LocalHouseholdRepository(container: container)
            #if DEBUG
            if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-named-invite") {
                try repository.createHousehold(name: "Our Home", owner: "Ravi", members: [])
                if let home = repository.household?.id {
                    try repository.configureSharing(SyncDestination(householdID: home, zoneName: "LHHousehold-\(home.uuidString)", ownerName: "owner", accountID: "ui-owner", isOwner: true))
                }
            }
            if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-pantry") { try UITestPantryFixture.seed(repository) }
            #endif
            _repository = State(initialValue: repository)
            let preferences = isUITest ? UserDefaults(suiteName: "UITest.AppleConnections.\(UUID().uuidString)") ?? .standard : .standard
            let calendarDelivery: CalendarDeliveryCoordinator
            #if DEBUG
            calendarDelivery = isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-calendar-delivery") ? CalendarDeliveryCoordinator(service: UITestCalendarDelivery()) : CalendarDeliveryCoordinator()
            #else
            calendarDelivery = CalendarDeliveryCoordinator()
            #endif
            _calendarDelivery = State(initialValue: calendarDelivery)
            let appointmentAlerts = AppointmentAlertCoordinator(defaults: preferences)
            _appointmentAlerts = State(initialValue: appointmentAlerts)
            let personal = PersonalShopping(defaults: preferences)
            _personal = State(initialValue: personal)
            let sharing = HouseholdSharingController(service: CloudKitHouseholdService())
            #if DEBUG
            if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-invitation") {
                sharing.invitation = HouseholdInvitation(id: UUID(), title: "Kira Home")
            }
            #endif
            _sharing = State(initialValue: sharing)
            let appleService: any ApplePlanningService & ReminderDeliveryService
            #if DEBUG
            if isUITest && ProcessInfo.processInfo.arguments.contains("--ui-testing-reminder-sync") {
                appleService = UITestPlanningService()
            } else { appleService = CalendarIntegrationService() }
            #else
            appleService = CalendarIntegrationService()
            #endif
            _connections = State(initialValue: AppleConnections(service: appleService, defaults: preferences))
            _reminderDelivery = State(initialValue: ReminderDeliveryCoordinator(service: appleService))
            // Install before launch callbacks: a background push must not depend on a visible view task.
            let unavailable = storeNeedsRecovery
            sharingDelegate.refreshShopping = {
                guard !unavailable else { return }
                do { try repository.reload() } catch { return }
                await sharing.sync(repository, force: true)
                await personal.refresh(repository)
                await appointmentAlerts.refresh(repository)
                await calendarDelivery.run(repository)
            }
        } catch {
            fatalError("Unable to initialize the local store.")
        }
    }

    var body: some Scene {
        WindowGroup {
            if storeNeedsRecovery {
                ContentUnavailableView {
                    Label("Your home needs a moment", systemImage: "externaldrive.badge.exclamationmark")
                } description: {
                    Text("LunaHearth couldn’t open its saved data. Nothing has been erased or replaced. Unlock your device, check that storage is available, then close and reopen the app. If this continues, keep the app installed to preserve its data.")
                }
                .accessibilityIdentifier("storage.recovery")
                .background(Color(.systemBackground))
            } else {
            AppRootView().environment(calendarDelivery).environment(appointmentAlerts).environment(repository).environment(connections).environment(reminderDelivery).environment(sharing).environment(personal).tint(AppTheme.accent)
                .sheet(isPresented: Binding(get: { sharingDelegate.showAppointment }, set: { sharingDelegate.showAppointment = $0 })) {
                    NavigationStack {
                        Group {
                            if let event = repository.events.first(where: { $0.id == sharingDelegate.appointmentID }) { EventDetailView(event: event) }
                            else { ContentUnavailableView("Appointment unavailable", systemImage: "calendar", description: Text("Open the household that owns this appointment, or refresh its calendar.")) }
                        }.toolbar { Button("Done") { sharingDelegate.showAppointment = false } }
                    }.environment(repository).environment(connections).environment(appointmentAlerts)
                }
                .sheet(isPresented: Binding(get: { sharingDelegate.showMealPreparation }, set: { sharingDelegate.showMealPreparation = $0 })) {
                    NavigationStack {
                        Group {
                            if let task = repository.tasks.first(where: { $0.id == sharingDelegate.preparationTaskID }), let meal = repository.meals.first(where: { $0.id == task.mealID }) { MealCookingView(meal: meal) }
                            else { PlanningListView(kind: .meal) }
                        }.toolbar { Button("Done") { sharingDelegate.showMealPreparation = false } }
                    }.environment(repository).environment(connections).environment(reminderDelivery).environment(sharing)
                }
                .sheet(isPresented: Binding(get: { sharingDelegate.showMealIdeas }, set: { sharingDelegate.showMealIdeas = $0 })) {
                    NavigationStack { MealIdeasView().toolbar { Button("Done") { sharingDelegate.showMealIdeas = false } } }.environment(repository).environment(connections).environment(reminderDelivery).environment(sharing)
                }
                .sheet(isPresented: Binding(get: { sharingDelegate.showPersonalShopping }, set: { sharingDelegate.showPersonalShopping = $0 })) {
                    NavigationStack {
                        PersonalShoppingView().toolbar {
                            ToolbarItem(placement: .confirmationAction) { Button("Done") { sharingDelegate.showPersonalShopping = false } }
                        }
                    }.environment(repository).environment(personal).environment(sharing)
                        .environment(connections).environment(reminderDelivery)
                }
                .onContinueUserActivity(NSUserActivityTypeBrowsingWeb) { activity in
                    sharingDelegate.receiveActivity(activity)
                }
                .task(id: sharingDelegate.invitationURL) {
                    guard let url = sharingDelegate.invitationURL else { return }
                    await sharing.lookupInvitation(url.absoluteString)
                    if sharingDelegate.invitationURL == url { sharingDelegate.invitationURL = nil }
                }
                .task(id: sharingDelegate.invitationMetadata?.share.recordID) {
                    guard let metadata = sharingDelegate.invitationMetadata,
                          let service = sharing.service as? CloudKitHouseholdService else { return }
                    do { sharing.invitation = try await service.register(metadata) }
                    catch { sharing.invitationError = HouseholdSharingFailure(error).message }
                    sharingDelegate.invitationMetadata = nil
                }
                .environment(calendarDelivery).environment(appointmentAlerts)
                #if DEBUG
                .modifier(UITestAppearance())
                #endif
            }
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
