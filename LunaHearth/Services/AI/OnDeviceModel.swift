import Foundation
import FoundationModels

/// Why a model request produced nothing usable. Already recorded in `AIRequestDiagnostics`.
struct OnDeviceModelFailure: Error, Sendable {
    let reason: AIFailureReason
}

/// The one path from a feature to Apple's on-device model. Every AI feature uses it, so all of them
/// share the same permission check (`FeatureAccess`), availability check, cancellation handling,
/// error mapping and device-only diagnostics. Features keep only what is theirs: instructions,
/// the typed output, validation of that output, and a rule-based fallback.
///
/// Input is always encoded as JSON data and described to the model as untrusted, never as instructions.
enum OnDeviceModel {
    /// nil when the model can run for this feature; otherwise the reason, already recorded.
    static func blocked(_ feature: AppFeature) -> AIFailureReason? {
        guard let reason = AIModelSupport.unavailability(for: feature) else { return nil }
        AIRequestDiagnostics.record(feature, failure: reason)
        return reason
    }

    /// Record that the feature produced a validated result.
    static func succeeded(_ feature: AppFeature) { AIRequestDiagnostics.record(feature, failure: nil) }

    /// Record that the model answered but its output failed validation.
    static func rejected(_ feature: AppFeature) { AIRequestDiagnostics.record(feature, failure: .invalidResponse) }

    /// Structured generation. Throws `CancellationError` when cancelled, or `OnDeviceModelFailure`.
    @available(iOS 26.0, *)
    static func generate<Output: Generable & Sendable>(_ type: Output.Type, feature: AppFeature,
                                                       instructions: String, input: some Encodable) async throws -> Output {
        let prompt = try json(input)
        return try await run(feature) {
            try await LanguageModelSession(instructions: instructions).respond(to: prompt, generating: Output.self).content
        }
    }

    /// Short free text, trimmed. Throws `CancellationError` when cancelled, or `OnDeviceModelFailure`.
    @available(iOS 26.0, *)
    static func text(feature: AppFeature, instructions: String, input: some Encodable) async throws -> String {
        let prompt = try json(input)
        return try await run(feature) {
            try await LanguageModelSession(instructions: instructions).respond(to: prompt).content
                .trimmingCharacters(in: .whitespacesAndNewlines)
        }
    }

    static func json(_ value: some Encodable) throws -> String {
        String(decoding: try JSONEncoder().encode(value), as: UTF8.self)
    }

    private static func run<T: Sendable>(_ feature: AppFeature, _ body: () async throws -> T) async throws -> T {
        try Task.checkCancellation()
        do {
            let value = try await body()
            try Task.checkCancellation()
            return value
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw OnDeviceModelFailure(reason: AIModelSupport.recordFailure(error, feature: feature))
        }
    }
}
