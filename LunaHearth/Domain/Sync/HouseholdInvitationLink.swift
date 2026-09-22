import Foundation

/// Only Apple's direct share URLs may be resolved. Never fetch arbitrary pasted URLs.
enum HouseholdInvitationLink {
    static func url(from text: String) -> URL? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count <= 4096, let url = URL(string: trimmed),
              url.scheme?.lowercased() == "https", let host = url.host?.lowercased(),
              ["www.icloud.com", "icloud.com"].contains(host),
              url.user == nil, url.password == nil, url.port == nil,
              url.path.hasPrefix("/share/"), url.path.count > "/share/".count else { return nil }
        return url
    }
}

protocol HouseholdInvitationLookupService: Sendable {
    func invitation(for url: URL) async throws -> HouseholdInvitation
}
