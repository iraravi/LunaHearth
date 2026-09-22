#if DEBUG
import UIKit

/// Synthetic label image for UI automation; never real household content.
@MainActor enum PantryPhotoTestFixture {
    static func data() -> Data? {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 900, height: 500), format: format).image { context in
            UIColor.systemTeal.withAlphaComponent(0.12).setFill()
            context.fill(CGRect(x: 0, y: 0, width: 900, height: 500))
            for (index, name) in ["RICE", "MILK"].enumerated() {
                let box = CGRect(x: 65 + index * 420, y: 55, width: 340, height: 370)
                UIColor.white.setFill(); UIBezierPath(roundedRect: box, cornerRadius: 24).fill()
                (name as NSString).draw(at: CGPoint(x: box.minX + 42, y: 210), withAttributes: [.font: UIFont.systemFont(ofSize: 56, weight: .bold), .foregroundColor: UIColor.black])
            }
        }.pngData()
    }
}
#endif
