import Testing
import UIKit
@testable import LunaHearth

@MainActor
struct ThemeContrastTests {
    @Test func featurePalettesMatchAndTextRemainsReadable() throws {
        for style in [UIUserInterfaceStyle.light, .dark] {
            let traits = UITraitCollection(userInterfaceStyle: style)
            func color(_ name: String) throws -> UIColor {
                try #require(UIColor(named: name)).resolvedColor(with: traits)
            }
            func luminance(_ color: UIColor) -> Double {
                var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                func linear(_ value: CGFloat) -> Double {
                    let value = Double(value)
                    return value <= 0.04045 ? value / 12.92 : pow((value + 0.055) / 1.055, 2.4)
                }
                return 0.2126 * linear(red) + 0.7152 * linear(green) + 0.0722 * linear(blue)
            }
            for prefix in ["Today", "Shopping", "Inventory", "Welcome", "Expense"] {
                for role in ["Canvas", "Surface", "Accent"] {
                    #expect(try color(prefix + role).isEqual(color("Hearth" + role)))
                }
            }
            for foreground in ["HearthInk", "HearthMuted", "HearthAccent"] {
                for background in ["HearthCanvas", "HearthSurface"] {
                    let first = try luminance(color(foreground))
                    let second = try luminance(color(background))
                    let ratio = (max(first, second) + 0.05) / (min(first, second) + 0.05)
                    #expect(ratio >= 4.5, "\(foreground) on \(background), appearance \(style.rawValue): body text and actions need 4.5:1 contrast")
                }
            }
        }
    }
}
