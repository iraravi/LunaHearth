import Foundation
import Testing
@testable import LunaHearth

/// India Bazaar, Frisco (Nov 2026): mirrored show-through "SEBO-" printed above the header.
struct IndiaBazaarReceiptTests {
    static let text = """
    SEBO-
    13 INDIA BAZAA
    The People's Store
    OPEN EVERYDAY
    Monday - Friday: 8:00 AM - 11:00 PM
    Saturday - Sunday: 7:00 AM - 11:00 PM
    JOAE INDIA BAZAAR ELDORADO
    14339 Eldorado Pkwy,
    FRISCO, TX 75035
    (972) 312-0114
    Customer: Ravi
    Cashier: NAVEEN
    POS Terminal Name: Eldorado POS 1
    ***Sale***
    BOMBAY MIXTURE IDHAYAM 340G
    2 Each @ $2.99/Each F $5.98
    SUB TOTAL $5.98
    AMOUNT DUE $5.98
    Visa $5.98
    Visa ************ 2434
    Amount: $5.98
    Customer Copy
    11/13/2026 8:48:50 PM
    0001683521
    Items count: 1
    Points Balance: 1936.9
    with original receipt within 14 days from the date of Return or exchange of unopened items can be made
    Uvisit www.IndiaBazaarDFW.com/return. In
    """

    @Test func storeNameComesFromTheHeaderNotShowThrough() {
        #expect(ReceiptPurchaseDetails.merchant(Self.text) == "India Bazaar")
    }

    @Test func dateTotalAndItemAreRead() throws {
        #expect(ReceiptPurchaseDetails.day(Self.text) == "2026-11-13")
        #expect(ExpenseRules.receiptTotal(Self.text) == "5.98")
        let scan = ReceiptRules.scan(text: Self.text)
        let line = try #require(scan.lines.first)
        #expect(scan.lines.count == 1)
        #expect(line.name.contains("BOMBAY MIXTURE"))
        #expect(line.amount == "5.98")
    }

    @Test func junkRowsAreNotStoreNames() {
        for junk in ["SEBO-", "13", "OPEN EVERYDAY", "Monday - Friday: 8:00 AM - 11:00 PM", "Customer Copy"] {
            #expect(!ReceiptPurchaseDetails.plausibleStoreRow(junk), "\(junk)")
        }
        #expect(ReceiptPurchaseDetails.merchant("TEST MARKET\nMilk 4.00\nTOTAL 4.00") == "TEST MARKET")
    }
}
