import Foundation
import Testing
@testable import LunaHearth

/// Layout patterns shared by many US and Indian chains, reconstructed from public descriptions
/// (not copied receipts). Store details are fictional. Each test names a pattern, not a store:
/// the parser has no per-store rules, so a pattern that passes here works for every store using it.
/// Replace or extend with real receipts as they arrive.
struct ReceiptLayoutPatternTests {
    private func verified(_ text: String) -> ReceiptScan {
        ReceiptRules.scan(text: text, sameLinePrices: true)
    }
    private func amounts(_ scan: ReceiptScan) -> [String: String] {
        Dictionary(scan.lines.map { ($0.name, $0.amount) }, uniquingKeysWith: { a, _ in a })
    }

    // MARK: US patterns

    /// Item code before the name, tax letter after the price, quantity line, loyalty savings line.
    static let usHomeImprovement = """
    THE HOME DEPOT
    123 MAIN ST, DALLAS, TX 75201
    (214) 555-0100
    012345678901 CLAW HAMMER 16OZ 14.98 T
    078742012345 WOOD SCREWS 100PK
    4 @ 2.49 9.96 T
    045242012345 PAINT TRAY 6.98 T
    PRO XTRA SAVINGS -1.00
    SUBTOTAL 30.92
    SALES TAX 8.25% 2.55
    TOTAL $33.47
    VISA USD$ 33.47
    11/19/2026 10:42 AM
    """

    @Test func homeImprovementLayoutListsItemsWithNetPrices() throws {
        let scan = verified(Self.usHomeImprovement)
        let byName = amounts(scan)
        #expect(scan.lines.count == 3, "\(scan.lines.map(\.name))")
        #expect(byName.keys.contains { $0.contains("CLAW HAMMER") })
        #expect(byName.first { $0.key.contains("WOOD SCREWS") }?.value == "9.96")
        #expect(byName.first { $0.key.contains("PAINT TRAY") }?.value == "5.98")
        #expect(byName.keys.allSatisfy { !$0.hasSuffix(" T") && !$0.hasPrefix("0") }, "codes and tax letters stay out of names")
        #expect(ReceiptReconciliation.check(lines: scan.lines, text: Self.usHomeImprovement) == .verified)
        #expect(ReceiptPurchaseDetails.merchant(Self.usHomeImprovement) == "The Home Depot")
        #expect(ReceiptPurchaseDetails.day(Self.usHomeImprovement) == "2026-11-19")
    }

    /// Product code first, tax letters N/T after prices, loyalty percentage discount line.
    static let usGeneralMerchandise = """
    TARGET
    SOUTHLAKE - 555-555-0123
    GROCERY
    212020034 MILK 1GAL N $3.79
    071010056 BANANAS N $1.29
    HOME
    084090112 DISH SOAP T $4.99
    Target Circle 5% -$0.25
    SUBTOTAL $9.82
    T = TX TAX 8.25000 on $4.74 $0.39
    TOTAL $10.21
    """

    @Test func generalMerchandiseLayoutKeepsTaxLettersAndCodesOutOfNames() {
        let scan = verified(Self.usGeneralMerchandise)
        let names = scan.lines.map(\.name)
        #expect(scan.lines.count == 3, "\(names)")
        #expect(names.contains { $0.contains("MILK") } && names.contains { $0.contains("BANANAS") } && names.contains { $0.contains("DISH SOAP") })
        #expect(!names.contains { $0.contains("GROCERY") || $0.contains("HOME") && !$0.contains("SOAP") })
        #expect(ReceiptPurchaseDetails.merchant(Self.usGeneralMerchandise) == "Target")
    }

    // MARK: Indian patterns

    /// GST supermarket bill: MRP / Rate / Amount columns, CGST and SGST rows, round off, net amount.
    static let indiaGSTSupermarket = """
    Avenue Supermarts Ltd
    D MART, KONDAPUR, HYDERABAD 500084
    GSTIN: 36AAAAA0000A1Z5
    TAX INVOICE
    Bill No: 1234   Date: 19/11/2026
    Item              Qty   MRP     Rate    Amount
    TOOR DAL 1KG       1    180.00  165.00  165.00
    AMUL BUTTER 500G   2    285.00  275.00  550.00
    SUGAR 1KG          1     55.00   50.00   50.00
    Total Qty: 4                    Gross Amt 765.00
    CGST 2.50%    on 214.29   5.36
    SGST 2.50%    on 214.29   5.36
    Round Off      0.00
    Net Amt       765.00
    You Saved Rs. 70.00
    """

    @Test func gstSupermarketBillReadsSellingPriceColumnAndSkipsTaxRows() {
        let scan = verified(Self.indiaGSTSupermarket)
        let byName = amounts(scan)
        #expect(scan.lines.count == 3, "\(scan.lines.map { "\($0.name)=\($0.amount)" })")
        #expect(byName.first { $0.key.contains("TOOR DAL") }?.value == "165.00")
        #expect(byName.first { $0.key.contains("AMUL BUTTER") }?.value == "550.00")
        #expect(!byName.keys.contains { $0.contains("CGST") || $0.contains("SGST") || $0.contains("Round") || $0.contains("Net Amt") })
        #expect(ReceiptPurchaseDetails.merchant(Self.indiaGSTSupermarket) == "DMart")
        #expect(ReceiptPurchaseDetails.day(Self.indiaGSTSupermarket) == "2026-11-19")
        #expect(ExpenseRules.receiptTotal(Self.indiaGSTSupermarket) == "765.00")
    }

    /// Small Indian shop bill with ₹ amounts and "Rs." labels.
    static let indiaRupeeBill = """
    RATNADEEP SUPERMARKET
    MADHAPUR, HYDERABAD
    Date: 19-11-2026
    TOMATO 1KG  ₹40.00
    ONION 2KG   ₹70.00
    CURD 400G   ₹45.00
    Total Items: 3
    Total  ₹155.00
    Paid by UPI Rs. 155.00
    """

    @Test func rupeeBillListsItemsAndIgnoresPaymentRows() {
        let scan = verified(Self.indiaRupeeBill)
        #expect(scan.lines.count == 3, "\(scan.lines.map(\.name))")
        #expect(!scan.lines.contains { $0.name.contains("UPI") || $0.name.contains("Total") })
        #expect(ReceiptPurchaseDetails.merchant(Self.indiaRupeeBill) == "Ratnadeep")
    }

    // MARK: Store names (data, not parsing)

    @Test func printedChainSpellingsResolveToOneName() {
        let cases: [(String, String)] = [
            ("LOWE'S HOME CENTERS, LLC\n1500 OAK ST", "Lowe’s"),
            ("Walmart Supercenter\nST# 01234", "Walmart"),
            ("COSTCO WHOLESALE\n#1234 FRISCO", "Costco"),
            ("Reliance Smart Bazaar\nGSTIN 36AAAAA0000A1Z5", "SMART Bazaar"),
            ("CVS pharmacy\n123 ELM ST", "CVS Pharmacy")
        ]
        for (text, expected) in cases {
            #expect(ReceiptPurchaseDetails.merchant(text + "\nMILK 3.00\nTOTAL 3.00") == expected, "\(text)")
        }
    }
}
