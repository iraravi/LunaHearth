import Foundation
import FoundationModels

actor OnDeviceTodayBriefService: TodayBriefService {
    func summarize(_ facts: TodayBriefFacts) async throws -> TodayBrief {
        let fallback = TodayBrief(text: facts.fallback, usedModel: false)
        guard !ProcessInfo.processInfo.arguments.contains("--ui-testing") else { return fallback }
        if #available(iOS 26.0, *), case .available = SystemLanguageModel.default.availability {
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
                guard !text.isEmpty else { return fallback }
                return TodayBrief(text: String(text.prefix(600)), usedModel: true)
            } catch is CancellationError { throw CancellationError() }
            catch { try Task.checkCancellation(); return fallback }
        }
        return fallback
    }
}
