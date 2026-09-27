import Foundation
import Testing
@testable import LunaHearth

@Suite struct PublicAppConfigurationTests {
    let now = Date(timeIntervalSince1970: 1_800_000_000)
    func config(_ features: [String: FeatureSetting] = [:], revision: Int = 1) -> PublicAppConfiguration {
        PublicAppConfiguration(revision: revision, expiresAt: now.addingTimeInterval(86_400), features: features)
    }
    @Test func masterOnlyAffectsAI() {
        let value = config(["ai": .init(enabled: false, message: "AI maintenance")])
        #expect(!value.allows(.aiMeals, at: now))
        #expect(!value.allows(.aiPhoto, at: now))
        #expect(value.allows(.receipts, at: now))
        #expect(value.allows(.shoppingToPantry, at: now))
        #expect(value.message(for: .aiMeals, at: now) == "AI maintenance")
    }
    @Test func independentFlagsAndExpiry() {
        let value = config(["receiptExpenses": .init(enabled: false)])
        #expect(!value.allows(.receiptExpenses, at: now))
        #expect(value.allows(.receiptPantry, at: now))
        #expect(value.allows(.receiptExpenses, at: now.addingTimeInterval(86_401)))
        #expect(throws: ConfigurationError.self) { try value.validated(at: now.addingTimeInterval(86_401)) }
    }
    @Test func rejectsUnknownSchemaAndOversizedContent() {
        var value = config()
        value.schemaVersion = 2
        #expect(throws: ConfigurationError.self) { try value.validated(at: now) }
        value.schemaVersion = 1
        value.helpText = String(repeating: "x", count: 4_001)
        #expect(throws: ConfigurationError.self) { try value.validated(at: now) }
    }
    @Test func unknownKeysCannotDisableExistingFeatures() throws {
        let value = try config(["futureFeature": .init(enabled: false)]).validated(at: now)
        #expect(AppFeature.allCases.allSatisfy { value.allows($0, at: now) })
    }
    @MainActor @Test func refreshPersistsAndThrottles() async throws {
        let name = "configuration-tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let service = ConfigurationFixture(value: config(["receipts": .init(enabled: false)]))
        let store = PublicConfigurationStore(service: service, defaults: defaults)
        await store.refresh(now: now)
        #expect(store.configuration?.revision == 1)
        #expect(FeatureAccess.cached(defaults: defaults, now: now)?.allows(.receipts, at: now) == false)
        await store.refresh(now: now.addingTimeInterval(1))
        #expect(await service.calls == 1)
    }
    @MainActor @Test func failureAndRollbackPreserveLastValidConfiguration() async throws {
        let name = "configuration-tests-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: name))
        defer { defaults.removePersistentDomain(forName: name) }
        let service = ConfigurationFixture(value: config(revision: 4))
        let store = PublicConfigurationStore(service: service, defaults: defaults)
        await store.refresh(now: now)
        await service.set(config(revision: 3))
        await store.refresh(now: now.addingTimeInterval(901))
        #expect(store.configuration?.revision == 4)
        #expect(store.issue != nil)
        defaults.set(Data("invalid".utf8), forKey: FeatureAccess.cacheKey)
        #expect(FeatureAccess.cached(defaults: defaults, now: now) == nil)
    }
}
private actor ConfigurationFixture: PublicConfigurationFetching {
    var value: PublicAppConfiguration
    var calls = 0
    init(value: PublicAppConfiguration) { self.value = value }
    func set(_ value: PublicAppConfiguration) { self.value = value }
    func fetch() async throws -> PublicAppConfiguration { calls += 1; return value }
}
