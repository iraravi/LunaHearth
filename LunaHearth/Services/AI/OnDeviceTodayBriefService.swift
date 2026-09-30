import Foundation
import FoundationModels

actor OnDeviceTodayBriefService: TodayBriefService {
    func summarize(_ facts: TodayBriefFacts) async throws -> TodayBrief {
        try Task.checkCancellation()
        let fallback = TodayBrief(text: facts.fallback, usedModel: false)
        if let reason = AIModelSupport.unavailability(for: .aiBriefs) {
            AIRequestDiagnostics.record(.aiBriefs, failure: reason)
            return fallback
        }
        if #available(iOS 26.0, *) {
            do {
                let session = LanguageModelSession(instructions: """
                Write a calm household overview in at most two short sentences using only the supplied counts.
                Counts are independent and may overlap. Never add them into an overall total.
                Shopping counts reflect the selected person's view, or the household when no person is selected.
                Pantry dates are recorded labels, not evidence of food safety. Never recommend eating an item,
                predict freshness, infer missing items, suggest a purchase, or invent plans or names.
                Do not imply all tasks are complete when a count is zero. Omit zero counts where useful.
                """)
                let data = try JSONEncoder().encode(facts)
                let result = try await session.respond(to: String(decoding: data, as: UTF8.self))
                try Task.checkCancellation()
                let text = result.content.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !text.isEmpty else { AIRequestDiagnostics.record(.aiBriefs, failure: .invalidResponse); return fallback }
                AIRequestDiagnostics.record(.aiBriefs, failure: nil)
                return TodayBrief(text: String(text.prefix(600)), usedModel: true)
            } catch is CancellationError { throw CancellationError() }
            catch { try Task.checkCancellation(); AIModelSupport.recordFailure(error, feature: .aiBriefs); return fallback }
        }
        return fallback
    }
}
