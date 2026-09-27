import Foundation
import Observation

/// Read-only policy access for service entry points, including non-UI callers.
/// UserDefaults is thread-safe; no household store or shared mutable singleton.
enum FeatureAccess {
    static let cacheKey = "public.configuration.v1"
    static func cached(defaults: UserDefaults = .standard, now: Date = .now) -> PublicAppConfiguration? {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing"),
           ProcessInfo.processInfo.arguments.contains("--ui-testing-public-settings") {
            return PublicAppConfiguration(revision: 1, expiresAt: now.addingTimeInterval(86_400), features: [
                "ai": .init(enabled: false, message: "AI is temporarily paused."),
                "receipts": .init(enabled: false, message: "Receipt scanning is temporarily paused. Manual entry is available.")
            ], announcement: "App status test notice", helpText: "Your saved household records remain available.")
        }
        #endif
        guard let data = defaults.data(forKey: cacheKey), data.count <= 32_768,
              let value = try? JSONDecoder().decode(PublicAppConfiguration.self, from: data),
              (try? value.validated(at: now)) != nil else { return nil }
        return value
    }
    static func allows(_ feature: AppFeature) -> Bool { cached()?.allows(feature) ?? true }
    static func require(_ feature: AppFeature) throws {
        if let policy = cached(), !policy.allows(feature) {
            throw ConfigurationError.paused(policy.message(for: feature))
        }
    }
}

@MainActor @Observable final class PublicConfigurationStore {
    private(set) var configuration: PublicAppConfiguration?
    private(set) var lastChecked: Date?
    private(set) var isRefreshing = false
    private(set) var issue: String?
    private let service: any PublicConfigurationFetching
    private let defaults: UserDefaults
    private var lastAttempt: Date?

    init(service: any PublicConfigurationFetching = CloudKitPublicConfigurationService(), defaults: UserDefaults = .standard) {
        self.service = service
        self.defaults = defaults
        configuration = FeatureAccess.cached(defaults: defaults)
        lastChecked = defaults.object(forKey: "public.configuration.checked") as? Date
        lastAttempt = defaults.object(forKey: "public.configuration.attempt") as? Date
    }
    func refresh(now: Date = .now) async {
        #if DEBUG
        if ProcessInfo.processInfo.arguments.contains("--ui-testing") { return }
        #endif
        // Manual refresh also observes the minimum interval; avoid quota/retry storms.
        guard !isRefreshing, lastAttempt.map({ now.timeIntervalSince($0) >= 900 }) ?? true else { return }
        lastAttempt = now
        defaults.set(now, forKey: "public.configuration.attempt")
        isRefreshing = true
        defer { isRefreshing = false }
        do {
            let value = try await service.fetch().validated(at: now)
            try Task.checkCancellation()
            if let previous = configuration, value.revision < previous.revision { throw ConfigurationError.invalid }
            let data = try JSONEncoder().encode(value)
            guard data.count <= 32_768 else { throw ConfigurationError.invalid }
            defaults.set(data, forKey: FeatureAccess.cacheKey)
            defaults.set(now, forKey: "public.configuration.checked")
            configuration = value
            lastChecked = now
            issue = nil
        } catch is CancellationError {
            lastAttempt = nil
            defaults.removeObject(forKey: "public.configuration.attempt")
        } catch {
            issue = "Couldn’t refresh app status. Saved settings or app defaults are in use."
        }
    }
}
