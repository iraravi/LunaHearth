import Foundation

/// Fixed troubleshooting categories only. Never contains prompts, responses or error descriptions.
enum AIFailureReason: String, Codable, Sendable, CaseIterable {
    case paused, disabled, preparing, unsupported, olderOS, contextLimit, language, refused, busy, timeout, invalidResponse, unavailable, testSession
    var message: String {
        switch self {
        case .paused: "This AI feature is temporarily paused by the app publisher."
        case .disabled: "Apple Intelligence is off. Check Apple Intelligence in Settings."
        case .preparing: "Apple’s on-device model is still preparing or its files are unavailable. Try again later."
        case .unsupported: "This device does not support the requested on-device AI capability."
        case .olderOS: "This AI feature needs a newer version of iOS."
        case .contextLimit: "The request exceeded the model’s context limit. Try a shorter request or fewer items."
        case .language: "The model does not support the language or locale used by this request."
        case .refused: "Apple’s model declined this request. It did not produce a usable result."
        case .busy: "The model is busy or temporarily rate-limited. Try again later."
        case .timeout: "The on-device request timed out. Try again later."
        case .invalidResponse: "The model response could not be validated. Review manually or try again."
        case .unavailable: "The on-device request could not finish. The underlying cause was not identified."
        case .testSession: "Model generation is disabled in this automated test session."
        }
    }
}

struct AIRequestDiagnostic: Codable, Sendable, Identifiable {
    let feature: AppFeature
    let failure: AIFailureReason?
    let checkedAt: Date
    var id: String { feature.rawValue }
}

/// Character bounds supplement, but do not claim to replace, the model's token limit.
enum AIInputRules {
    static func names(_ names: [String], limit: Int, characterBudget: Int) -> [String] {
        var result: [String] = [], seen: Set<String> = []
        var remaining = max(0, characterBudget)
        for value in names {
            let clean = value.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !clean.isEmpty, clean.count <= 200,
                  !clean.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains),
                  seen.insert(IngredientMatching.key(clean)).inserted else { continue }
            guard result.count < limit else { break }
            guard clean.count <= remaining else { continue }
            result.append(clean); remaining -= clean.count
        }
        return result
    }
    static func batches(count: Int, size: Int) -> [Range<Int>] {
        guard count > 0, size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map { $0..<min($0 + size, count) }
    }
    static func label(_ value: String, maximum: Int) -> Bool {
        !value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && value.count <= maximum
            && !value.unicodeScalars.contains(where: CharacterSet.controlCharacters.contains)
            && !value.contains("://")
    }
}
