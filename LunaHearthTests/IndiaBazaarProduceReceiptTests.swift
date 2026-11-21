import Foundation
import Testing
@testable import LunaHearth

/// India Bazaar, Frisco (20 Nov 2026): produce sold by weight, a two-line product name with an
/// item discount, and one bill paid with two Visa cards.
struct IndiaBazaarProduceReceiptTests {
    static let text = """
    INDIA BAZAAR
    The People's Store
    OPEN EVERYDAY
    Monday - Friday: 8:00 AM - 11:00 PM
    INDIA BAZAAR ELDORADO
    14339 Eldorado Pkwy,
    FRISCO, TX 75035
    Customer: Ravi
    Cashier: NAVEEN
    POS Terminal Name: Eldorado POS 2
    ***Sale***
    RAJABOGAM PONNI BOILED RICE
    GRAIN MARKET 20LB (Each) F $18.99
    => Discounts: GM rajabogham ponni b... -$3.00
    KARELA /LB
    1.190 Pound @ $0.99/Pound F $1.18
    Temporary price $0.99, You saved $1.00
    PERSIMMON FRUIT /LB
    1.190 Pound @ $1.49/Pound F $1.77
    CILANTRO EA (Each) F $0.49
    DUDHI /LB
    1.980 Pound @ $0.99/Pound F $1.96
    Temporary price $0.99, You saved $0.50
    WHITE POTATO /LB
    0.630 Pound @ $1.29/Pound F $0.81
    FLAT VALOR /LB
    1.520 Pound @ $1.49/Pound F $2.26
    Temporary price $1.49, You saved $2.00
    OKRA /LB
    2.160 Pound @ $2.99/Pound F $6.46
    SNAKE GOURD /LB
    2.740 Pound @ $1.99/Pound F $5.45
    SUB TOTAL $36.37
    AMOUNT DUE $36.37
    Visa AUTIRIS $5.00
    Visa $31.37
    Visa ************ 7970
    Amount: $5.00
    ID: pi_Ccash65853A2321758D5544E37DF5F60
    Visa ************ 2434
    Amount: $31.37
    AID: A0000000031010
    Customer Copy
    11/20/2026 8:47:12 PM
    Items count: 9
    You saved: $8.22
    Points Balance: 1973.27
    """

    @Test func weighedProduceIsNamedFromTheLineAbove() {
        let lines = ReceiptRules.scan(text: Self.text, sameLinePrices: true).lines
        let read = Dictionary(uniqueKeysWithValues: lines.map { ($0.name, $0.amount) })
        #expect(read == ["RAJABOGAM PONNI BOILED RICE GRAIN MARKET 20LB": "15.99", "KARELA": "1.18", "PERSIMMON FRUIT": "1.77",
                         "CILANTRO": "0.49", "DUDHI": "1.96", "WHITE POTATO": "0.81", "FLAT VALOR": "2.26", "OKRA": "6.46", "SNAKE GOURD": "5.45"])
        #expect(lines.first { $0.name == "OKRA" }?.quantity == "2.16 lb")
        #expect(lines.allSatisfy { !$0.amountNeedsReview })
    }

    @Test func twoCardsThatAddUpToTheTotalAreNotAConflict() {
        #expect(ExpenseRules.receiptTotal(Self.text) == "36.37")
        let lines = ReceiptRules.scan(text: Self.text, sameLinePrices: true).lines
        #expect(ReceiptReconciliation.check(lines: lines, text: Self.text) == .verified)
    }

    @Test func weightRowsMustMultiplyOut() {
        #expect(ReceiptMultilineDetails.weightAmount("1.190 Pound @ $0.99/Pound F $1.18") == 118)
        #expect(ReceiptMultilineDetails.weightAmount("2.740 Pound @ $1.99/Pound F $9.45") == nil)
        #expect(ReceiptMultilineDetails.weightAmount("0.5 kg @ 120.00/kg 60.00") == 6000)
        #expect(ReceiptRules.isNonProductRow("1.190 Pound @ $0.99/Pound F $1.18"))
    }

    @Test func paymentsThatDoNotAddUpStillConflict() {
        let text = "SUB TOTAL $36.37\nAMOUNT DUE $36.37\nAmount: $5.00\nAmount: $30.00"
        #expect(ExpenseRules.receiptTotalEvidence(text) == .conflicting)
    }
}
