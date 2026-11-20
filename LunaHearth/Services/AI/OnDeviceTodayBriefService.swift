import Foundation
import FoundationModels

actor OnDeviceTodayBriefService: TodayBriefService {
    private static let instructions = """
    Write a calm household overview in at most two short sentences using only the supplied counts.
    Counts are independent and may overlap. Never add them into an overall total.
    Shopping counts reflect the selected person's view, or the household when no person is selected.
    Pantry dates are recorded labels, not evidence of food safety. Never recommend eating an item,
    predict freshness, infer missing items, suggest a purchase, or invent plans or names.
    Do not imply all tasks are complete when a count is zero. Omit zero counts where useful.
    """

    func summarize(_ facts: TodayBriefFacts) async throws -> TodayBrief {
        try Task.checkCancellation()
        let fallback = TodayBrief(text: facts.fallback, usedModel: false)
        guard OnDeviceModel.blocked(.aiBriefs) == nil, #available(iOS 26.0, *) else { return fallback }
        do {
            let text = try await OnDeviceModel.text(feature: .aiBriefs, instructions: Self.instructions, input: facts)
            guard !text.isEmpty else { OnDeviceModel.rejected(.aiBriefs); return fallback }
            OnDeviceModel.succeeded(.aiBriefs)
            return TodayBrief(text: String(text.prefix(600)), usedModel: true)
        } catch is OnDeviceModelFailure { return fallback }
    }
}
