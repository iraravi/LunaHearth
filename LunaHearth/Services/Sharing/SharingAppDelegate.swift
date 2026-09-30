import CloudKit
import Combine
import UIKit
import UserNotifications

@MainActor final class SharingAppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, ObservableObject {
    @Published var showAppointment = false
    var appointmentID: UUID?
    @Published var showPersonalShopping = false
    @Published var assignmentRoute: AssignmentNotificationRoute?
    @Published var showMealIdeas = false
    @Published var showMealPreparation = false
    var preparationTaskID: UUID?
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification) async -> UNNotificationPresentationOptions {
        (notification.request.identifier.hasPrefix("appointment.") || notification.request.identifier.hasPrefix("meal.prep.") || notification.request.identifier == "meal.planning.daily" || notification.request.identifier.hasPrefix("shopping.personal.") || notification.request.identifier.hasPrefix("tasks.personal.")) ? [.banner, .sound] : []
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse) async {
        if response.notification.request.identifier.hasPrefix("appointment.") { await openAppointment(response.notification.request.identifier); return }
        if response.notification.request.identifier.hasPrefix("meal.prep.") { await openPreparation(response.notification.request.identifier); return }
        if response.notification.request.identifier == "meal.planning.daily" { await openMealIdeas(); return }
        guard let route = AssignmentNotificationRoute(identifier: response.notification.request.identifier) else { return }
        await openPersonalShopping(route)
    }
    private func openAppointment(_ identifier: String) { appointmentID = identifier.split(separator: ".").last.flatMap { UUID(uuidString: String($0)) }; showAppointment = true }
    private func openPreparation(_ identifier: String) { preparationTaskID = identifier.split(separator: ".").last.flatMap { UUID(uuidString: String($0)) }; showMealPreparation = true }
    private func openMealIdeas() { showMealIdeas = true }
    private func openPersonalShopping(_ route: AssignmentNotificationRoute) async {
        assignmentRoute = route
        showPersonalShopping = true
        await refreshShopping?()
    }
    var refreshShopping: (@MainActor () async -> Void)?
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard CKNotification(fromRemoteNotificationDictionary: userInfo)?.subscriptionID == "LHShoppingChanges-v1",
              let refreshShopping else { completionHandler(.noData); return }
        Task { @MainActor in
            await refreshShopping()
            completionHandler(.newData)
        }
    }
    @Published var invitationMetadata: CKShare.Metadata?
    @Published var invitationURL: URL?
    @discardableResult func receiveInvitationURL(_ url: URL) -> Bool {
        guard let validated = HouseholdInvitationLink.url(from: url.absoluteString) else { return false }
        invitationURL = validated
        return true
    }
    @discardableResult func receiveActivity(_ activity: NSUserActivity) -> Bool {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL else { return false }
        return receiveInvitationURL(url)
    }
    func application(_ application: UIApplication, continue userActivity: NSUserActivity,
                     restorationHandler: @escaping ([any UIUserActivityRestoring]?) -> Void) -> Bool {
        receiveActivity(userActivity)
    }

    private var observation: AnyCancellable?
    override init() {
        super.init()
        UNUserNotificationCenter.current().delegate = self
        observation = NotificationCenter.default.publisher(for: SharingSceneDelegate.invitationNotification).sink { [weak self] notification in
            if let metadata = notification.object as? CKShare.Metadata {
                Task { @MainActor in self?.invitationMetadata = metadata }
            } else if let url = notification.object as? URL {
                Task { @MainActor in self?.receiveInvitationURL(url) }
            }
        }
    }
    func application(_ application: UIApplication, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        invitationMetadata = metadata
    }
    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        if let metadata = options.cloudKitShareMetadata { invitationMetadata = metadata }
        else {
            for activity in options.userActivities { if receiveActivity(activity) { break } }
            for context in options.urlContexts { if receiveInvitationURL(context.url) { break } }
        }
        let configuration = (connectingSceneSession.configuration.copy() as? UISceneConfiguration) ?? UISceneConfiguration(name: nil, sessionRole: connectingSceneSession.role)
        configuration.delegateClass = SharingSceneDelegate.self
        return configuration
    }
}

@MainActor final class SharingSceneDelegate: NSObject, UIWindowSceneDelegate {
    static let invitationNotification = Notification.Name("LunaHearth.shareInvitation")
    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        if let metadata = connectionOptions.cloudKitShareMetadata {
            NotificationCenter.default.post(name: Self.invitationNotification, object: metadata)
        } else {
            for activity in connectionOptions.userActivities { forward(activity) }
            for context in connectionOptions.urlContexts { forward(context.url) }
        }
    }
    func scene(_ scene: UIScene, continue userActivity: NSUserActivity) { forward(userActivity) }
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        for context in URLContexts { forward(context.url) }
    }
    private func forward(_ activity: NSUserActivity) {
        guard activity.activityType == NSUserActivityTypeBrowsingWeb, let url = activity.webpageURL else { return }
        forward(url)
    }
    private func forward(_ url: URL) {
        guard let validated = HouseholdInvitationLink.url(from: url.absoluteString) else { return }
        NotificationCenter.default.post(name: Self.invitationNotification, object: validated)
    }
    func windowScene(_ windowScene: UIWindowScene, userDidAcceptCloudKitShareWith metadata: CKShare.Metadata) {
        NotificationCenter.default.post(name: Self.invitationNotification, object: metadata)
    }
}
