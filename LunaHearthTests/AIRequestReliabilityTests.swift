import Foundation
import FoundationModels
import Testing
@testable import LunaHearth

struct AIRequestReliabilityTests {
    @Test func classifiesLegacyModelErrorsWithoutExposingContext() {
        if #available(iOS 26.0, *) {
            let context = LanguageModelSession.GenerationError.Context(debugDescription: "PRIVATE synthetic prompt contents")
            let cases: [(LanguageModelSession.GenerationError, AIFailureReason)] = [
                (.exceededContextWindowSize(context), .contextLimit), (.assetsUnavailable(context), .preparing),
                (.unsupportedLanguageOrLocale(context), .language), (.guardrailViolation(context), .refused),
                (.rateLimited(context), .busy), (.concurrentRequests(context), .busy),
                (.decodingFailure(context), .invalidResponse), (.unsupportedGuide(context), .invalidResponse)
            ]
            for (error, expected) in cases {
                let result = AIModelSupport.failure(error)
                #expect(result == expected)
                #expect(!result.message.contains("PRIVATE"))
            }
        }
    }
    @Test func classifiesCurrentModelErrors() {
        if #available(iOS 27.0, *) {
            #expect(AIModelSupport.failure(LanguageModelError.contextSizeExceeded(.init(contextSize: 10, tokenCount: 11, debugDescription: "private"))) == .contextLimit)
            #expect(AIModelSupport.failure(LanguageModelError.rateLimited(.init(resetDate: nil, debugDescription: "private"))) == .busy)
            #expect(AIModelSupport.failure(SystemLanguageModel.Error.assetsUnavailable(.init(debugDescription: "private"))) == .preparing)
            #expect(AIModelSupport.failure(LanguageModelSession.Error.concurrentRequests) == .busy)
        }
        #expect(AIModelSupport.failure(NSError(domain: "private user text", code: 1)) == .unavailable)
    }
    @Test func diagnosticsStoreOnlyLastResultAndCanBeCleared() throws {
        let suite = "ai-diagnostics-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        let now = Date(timeIntervalSince1970: 100)
        AIRequestDiagnostics.record(.aiShopping, failure: .contextLimit, defaults: defaults, now: now)
        AIRequestDiagnostics.record(.aiMeals, failure: .language, defaults: defaults, now: now.addingTimeInterval(1))
        AIRequestDiagnostics.record(.aiShopping, failure: nil, defaults: defaults, now: now.addingTimeInterval(2))
        AIRequestDiagnostics.record(.receipts, failure: .unavailable, defaults: defaults)
        let results = AIRequestDiagnostics.latest(defaults: defaults)
        #expect(results.count == 2)
        #expect(results.first?.feature == .aiShopping)
        #expect(results.first?.failure == nil)
        let encoded = try #require(defaults.data(forKey: AIRequestDiagnostics.prefix + AppFeature.aiMeals.rawValue))
        let fields = try #require(JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        #expect(Set(fields.keys) == ["feature", "failure", "checkedAt"])
        AIRequestDiagnostics.clear(defaults: defaults)
        #expect(AIRequestDiagnostics.latest(defaults: defaults).isEmpty)
    }
    @Test func corruptedDiagnosticsAreIgnored() throws {
        let suite = "ai-diagnostics-test-\(UUID())"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(Data(repeating: 0, count: 1024), forKey: AIRequestDiagnostics.prefix + "aiShopping")
        #expect(AIRequestDiagnostics.latest(defaults: defaults).isEmpty)
    }
    @Test func inputBudgetDeduplicatesWithoutChangingIngredientIdentity() {
        let result = AIInputRules.names([" Rice ", "rice", "Cumin", "Jeera", "Cumin powder", "Chicken"], limit: 80, characterBudget: 100)
        #expect(result == ["Rice", "Cumin", "Cumin powder", "Chicken"])
        #expect(AIInputRules.names(["Chicken", "Rice"], limit: 2, characterBudget: 4) == ["Rice"])
        #expect(AIInputRules.names(["Rice", "Eggs"], limit: 1, characterBudget: 100) == ["Rice"])
        #expect(AIInputRules.names(["Rice"], limit: 0, characterBudget: 100).isEmpty)
    }
    @Test func batchIndexesStayWithinOriginalInput() {
        for count in [0, 1, 12, 13, 40, 60] {
            let batches = AIInputRules.batches(count: count, size: 12)
            #expect(batches.flatMap(Array.init) == Array(0..<count))
            for batch in batches {
                let values = IngredientComparison.validated([-1, 0, batch.count - 1, batch.count, 999], count: batch.count).map { batch.lowerBound + $0 }
                #expect(values.allSatisfy(batch.contains))
            }
        }
        #expect(AIInputRules.batches(count: 10, size: 0).isEmpty)
    }
    @Test func malformedLabelsDoNotReachSuggestions() {
        let invalid = [" ", "Chicken\nLentils", "https://example.invalid", "Rice\u{0000}"]
        #expect(ShoppingSuggestionRules.reviewed(invalid.map { .init(name: $0) }, excluding: []).isEmpty)
        #expect(PantrySuggestionRules.reviewed(invalid, existing: []).isEmpty)
        #expect(PantryPhotoRules.names(invalid).isEmpty)
        for label in invalid {
            #expect(MealSuggestionRules.generatedIdea(id: "x", name: "Meal", ingredients: [label], minutes: 20) == nil)
        }
    }
    @Test func mealValidationNormalizesAndKeepsDistinctForms() throws {
        let meal = try #require(MealSuggestionRules.generatedIdea(id: "x", name: " Rice bowl ", ingredients: [" Rice ", "rice", "Jeera", "Cumin", "Cumin powder"], minutes: 20))
        #expect(meal.name == "Rice bowl")
        #expect(meal.ingredients == ["Rice", "Jeera", "Cumin powder"])
        #expect(meal.steps.isEmpty)
    }
    @Test func cancellationPreventsFallbackFromBecomingAResult() async {
        let task = Task {
            // Cancellation is observed even on an unsupported simulator, before the fallback branch.
            while !Task.isCancelled { await Task.yield() }
            return try await OnDeviceShoppingSuggestionService().suggest(.init(prompt: "Chicken briyani", recentItems: ["Lentils"], pendingItems: []))
        }
        task.cancel()
        do { _ = try await task.value; Issue.record("Cancelled generation returned suggestions") }
        catch { #expect(error is CancellationError) }
    }
}
