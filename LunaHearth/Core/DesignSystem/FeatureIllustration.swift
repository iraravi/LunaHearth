import SwiftUI

/// Original-color bundled artwork; never tinted or inverted by a feature theme.
/// Text beside the image supplies the accessible action name.
struct FeatureIllustration: View {
    let symbol: String
    var size: CGFloat = 56
    private var asset: String? {
        switch symbol {
        case "cabinet", "cabinet.fill": "FeaturePantryV1"
        case "basket", "basket.fill", "cart", "cart.fill", "bag", "bag.fill": "FeatureShoppingV1"
        case "checklist", "checkmark.circle", "bell", "list.bullet": "FeatureRemindersV1"
        case "receipt", "doc.viewfinder": "FeatureReceiptsV1"
        case "fork.knife": "FeatureMealsV1"
        case "chart.bar.xaxis", "chart.bar", "creditcard": "FeatureExpensesV1"
        default: nil
        }
    }
    var body: some View {
        Group {
            if let asset {
                Image(asset).renderingMode(.original).resizable().scaledToFit()
            } else {
                Image(systemName: symbol).symbolRenderingMode(.multicolor)
                    .font(.system(size: size * 0.5, weight: .medium)).foregroundStyle(.blue)
            }
        }.frame(width: size, height: size).accessibilityHidden(true)
    }
}
