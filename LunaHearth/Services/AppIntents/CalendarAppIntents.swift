import AppIntents
import Foundation

struct DraftAppointmentIntent: AppIntent {
    static let title: LocalizedStringResource = "Plan an appointment"
    static let description = IntentDescription("Open a household appointment draft to review before saving.")
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Appointment name") var name: String
    @Parameter(title: "Starts") var date: Date
    @Parameter(title: "Person’s name", default: "") var member: String
    static var parameterSummary: some ParameterSummary { Summary("Plan \(\.$name) on \(\.$date)") }
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(try AppointmentLink.url(title: name, date: date, member: member, create: true)))
    }
}
struct ShowFamilyCalendarIntent: AppIntent {
    static let title: LocalizedStringResource = "Show family calendar"
    static let openAppWhenRun = true
    static let authenticationPolicy: IntentAuthenticationPolicy = .requiresAuthentication
    @Parameter(title: "Day") var date: Date?
    func perform() async throws -> some IntentResult & OpensIntent {
        .result(opensIntent: OpenURLIntent(try AppointmentLink.url(date: date ?? .now, create: false)))
    }
}
struct HouseholdCalendarShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(intent: DraftAppointmentIntent(), phrases: ["Plan an appointment in \(.applicationName)"], shortTitle: "Plan appointment", systemImageName: "calendar.badge.plus")
        AppShortcut(intent: ShowFamilyCalendarIntent(), phrases: ["Show my family calendar in \(.applicationName)"], shortTitle: "Family calendar", systemImageName: "calendar")
    }
}
