
import Testing
@testable import LunaHearth

struct ReceiptLayoutTests {
    @Test(arguments: [-0.08, 0.0, 0.08])
    func tiltedPriceColumnsStayWithTheirOwnProduct(slope: Double) {
        func token(_ text: String, _ x: Double, _ baseline: Double, _ width: Double) -> ReceiptTextFragment {
            ReceiptTextFragment(text: text, x: x, y: baseline + slope * x, width: width, height: 0.018, slope: slope)
        }
        let fragments = [token("Milk", 0.3, 0.8, 0.25), token("3.99", 0.8, 0.8, 0.08),
                         token("Apples", 0.3, 0.77, 0.25), token("2.49", 0.8, 0.77, 0.08)]
        #expect(ReceiptTextRows.assemble(fragments.reversed()) == "Milk 3.99\nApples 2.49")
    }
}
