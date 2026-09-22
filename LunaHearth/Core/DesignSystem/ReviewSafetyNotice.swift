import SwiftUI

/// Always visible at review points; no acknowledgement is treated as proof of safety.
struct ReviewSafetyNotice: View {
    enum Context { case meal, receipt, photo, pantry }
    let context: Context
    private var title: String {
        switch context {
        case .meal: "Meal ideas, not recipes"
        case .receipt: "Check against the original receipt"
        case .photo: "Photo suggestions can be wrong"
        case .pantry: "Check the actual ingredients"
        }
    }
    private var detail: String {
        switch context {
        case .meal:
            "Ideas and ingredient matches can be wrong. Check product labels and dietary needs. This app does not provide cooking instructions or verify allergens or food safety."
        case .receipt:
            "Scanning and AI can misread names, quantities, prices, dates and currency. Check each selected item and total before saving. A receipt cannot establish allergens, freshness or whether food is safe to eat."
        case .photo:
            "AI and label scanning may miss or misidentify items. Check each name against the actual product before adding it. A photo cannot establish allergens, expiry dates or whether food is safe to eat."
        case .pantry:
            "Suggestions and name matches can be wrong. Check product labels; categories and saved dates do not establish allergens, freshness or food safety."
        }
    }
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: "exclamationmark.triangle").font(.subheadline.weight(.semibold))
            Text(detail).font(.subheadline).fixedSize(horizontal: false, vertical: true)

        }
        .foregroundStyle(.primary)
        .padding(14).frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.primary.opacity(0.05), in: RoundedRectangle(cornerRadius: 14))
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("reviewSafety.\(String(describing: context))")
    }
}
