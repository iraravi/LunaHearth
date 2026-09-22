import Foundation

struct AppointmentLink: Identifiable {
    let id = UUID()
    let title: String
    let date: Date
    let member: String
    let create: Bool
    static func url(title: String = "", date: Date = .now, member: String = "", create: Bool) throws -> URL {
        var parts = URLComponents(); parts.scheme = "lunahearth"; parts.host = "calendar"
        parts.queryItems = [URLQueryItem(name: "title", value: String(title.prefix(200))), URLQueryItem(name: "date", value: String(date.timeIntervalSince1970)), URLQueryItem(name: "member", value: String(member.prefix(100))), URLQueryItem(name: "create", value: create ? "1" : "0")]
        guard let url = parts.url else { throw AppointmentError.invalid }; return url
    }
    init?(url: URL) {
        guard url.scheme == "lunahearth", url.host == "calendar", url.absoluteString.count < 4096,
              let parts = URLComponents(url: url, resolvingAgainstBaseURL: false) else { return nil }
        let items = parts.queryItems ?? []
        func value(_ key: String) -> String? { items.first { $0.name == key }?.value }
        guard let raw = value("date"), let seconds = Double(raw), seconds.isFinite, (-2208988800...7258118400).contains(seconds) else { return nil }
        title = String((value("title") ?? "").prefix(200)); member = String((value("member") ?? "").prefix(100)); date = Date(timeIntervalSince1970: seconds); create = value("create") == "1"
    }
}
