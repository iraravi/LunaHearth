import UIKit

/// A synthetic document, rendered locally for the same Vision scan path as a photo.
@MainActor enum DemoReceiptImage {
    static func make() -> UIImage {
        let format = UIGraphicsImageRendererFormat(); format.scale = 1
        return UIGraphicsImageRenderer(size: CGSize(width: 1100, height: 1200), format: format).image { context in
            UIColor.white.setFill(); context.fill(CGRect(x: 0, y: 0, width: 1100, height: 1200))
            let paragraph = NSMutableParagraphStyle(); paragraph.lineSpacing = 24
            (ConnectedDemo.receipt as NSString).draw(in: CGRect(x: 55, y: 90, width: 990, height: 1000), withAttributes: [
                .font: UIFont.monospacedSystemFont(ofSize: 30, weight: .medium), .foregroundColor: UIColor.black, .paragraphStyle: paragraph
            ])
        }
    }
}
