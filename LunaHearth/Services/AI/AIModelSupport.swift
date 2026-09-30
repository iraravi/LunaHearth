import Foundation
import FoundationModels

/// Device-only troubleshooting. One bounded result per feature, never a request history.
/// UserDefaults is thread-safe; this helper owns no mutable global state.
enum AIRequestDiagnostics {
    static let prefix = "ai.lastResult.v1."
    static func record(_ feature: AppFeature, failure: AIFailureReason?, defaults: UserDefaults = .standard, now: Date = .now) {
        guard feature.isAI, let data = try? JSONEncoder().encode(AIRequestDiagnostic(feature: feature, failure: failure, checkedAt: now)) else { return }
        defaults.set(data, forKey: prefix + feature.rawValue)
    }
    static func latest(defaults: UserDefaults = .standard) -> [AIRequestDiagnostic] {
        AppFeature.allCases.filter(\.isAI).compactMap { feature in
            guard let data = defaults.data(forKey: prefix + feature.rawValue), data.count < 1024,
                  let result = try? JSONDecoder().decode(AIRequestDiagnostic.self, from: data), result.feature == feature else { return nil }
            return result
        }.sorted { $0.checkedAt > $1.checkedAt }
    }
    static func clear(defaults: UserDefaults = .standard) {
        for feature in AppFeature.allCases where feature.isAI { defaults.removeObject(forKey: prefix + feature.rawValue) }
    }
}

enum AIModelSupport {
    static func unavailability(for feature: AppFeature) -> AIFailureReason? {
        guard FeatureAccess.allows(feature) else { return .paused }
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return .testSession }
        if #available(iOS 26.0, *) {
            switch SystemLanguageModel.default.availability {
            case .available: return nil
            case .unavailable(let reason):
                switch reason {
                case .appleIntelligenceNotEnabled: return .disabled
                case .modelNotReady: return .preparing
                case .deviceNotEligible: return .unsupported
                @unknown default: return .unavailable
                }
            }
        }
        return .olderOS
    }

    static func failure(_ error: any Error) -> AIFailureReason {
        // Do not stringify errors: Apple error contexts can contain supplied text.
        if #available(iOS 27.0, *) {
            if let error = error as? LanguageModelError {
                switch error {
                case .contextSizeExceeded: return .contextLimit
                case .unsupportedLanguageOrLocale: return .language
                case .guardrailViolation, .refusal: return .refused
                case .rateLimited: return .busy
                case .timeout: return .timeout
                case .unsupportedGenerationGuide, .unsupportedTranscriptContent: return .invalidResponse
                case .unsupportedCapability: return .unsupported
                @unknown default: return .unavailable
                }
            }
            if error is SystemLanguageModel.Error { return .preparing }
            if error is LanguageModelSession.Error { return .busy }
            if error is GeneratedContent.ParsingError { return .invalidResponse }
        }
        if #available(iOS 26.0, *) {
            if let error = error as? LanguageModelSession.GenerationError {
                switch error {
                case .exceededContextWindowSize: return .contextLimit
                case .assetsUnavailable: return .preparing
                case .unsupportedLanguageOrLocale: return .language
                case .guardrailViolation, .refusal: return .refused
                case .rateLimited, .concurrentRequests: return .busy
                case .decodingFailure, .unsupportedGuide: return .invalidResponse
                @unknown default: return .unavailable
                }
            }
        }
        return .unavailable
    }

    @discardableResult static func recordFailure(_ error: any Error, feature: AppFeature) -> AIFailureReason {
        let reason = failure(error)
        if !(error is CancellationError) && !Task.isCancelled { AIRequestDiagnostics.record(feature, failure: reason) }
        return reason
    }
}
