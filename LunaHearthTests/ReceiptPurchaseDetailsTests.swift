import Foundation
import Testing
@testable import LunaHearth

struct ReceiptPurchaseDetailsTests {
    @Test func damagedTotalCannotOverridePaymentEvidence() {
        #expect(ExpenseRules.receiptTotal("SUBTOTAL 723.19\nTAX 47.44\nTOTAL 170.63\nAMOUNT: $770.63") == "770.63")
        #expect(ExpenseRules.receiptTotal("TOTAL 770.63\nAMOUNT: $770.63") == "770.63")
        #expect(ExpenseRules.receiptTotal("GRAND TOTAL 170.63\nAMOUNT: $770.63") == nil)
    }
    @Test func merchantDoesNotUseGenericWholesaleHeader() {
        #expect(ReceiptPurchaseDetails.merchant("WHOLESALE\nCelina TX 75009\nCostco Visa 770.63") == "Costco")
        #expect(ReceiptPurchaseDetails.merchant("WHOLESALE\nMilk 4.00") == nil)
        #expect(ReceiptPurchaseDetails.merchant("FRESH MARKET\nMilk 4.00") == "FRESH MARKET")
    }
    @Test func printedDateUsesReceiptAddressNotDeviceLocaleOrToday() {
        #expect(ReceiptPurchaseDetails.day("Celina, TX 75009\n11/08/2026 13:04") == "2026-11-08")
        #expect(ReceiptPurchaseDetails.day("11/08/2026") == nil)
        #expect(ReceiptPurchaseDetails.day("2026-11-08") == "2026-11-08")
        #expect(ReceiptPurchaseDetails.day("TOTAL 770.63") == nil)
        #expect(ReceiptPurchaseDetails.day("Celina, TX 75009\n11/08/2026\n11/09/2026") == nil)
        #expect(ReceiptPurchaseDetails.day("Celina, TX 75009\n02/30/2026") == nil)
    }
}
