import Foundation
import Testing
@testable import LunaHearth

/// The math reader decides what each row is by making the receipt's own numbers agree.
struct ReceiptSolverTests {
    private func solve(_ text: String) -> ReceiptSolver.Outcome { ReceiptSolver.solve(text: text) }
    private func read(_ outcome: ReceiptSolver.Outcome) -> [String: String] {
        Dictionary(uniqueKeysWithValues: outcome.lines.map { ($0.name, $0.amount) })
    }

    @Test func weighedProduceTwoLineNamesAndDiscounts() {
        let outcome = solve(IndiaBazaarProduceReceiptTests.text)
        #expect(outcome.status == .unique && outcome.cost == 0)
        #expect(read(outcome) == ["RAJABOGAM PONNI BOILED RICE GRAIN MARKET 20LB": "15.99", "KARELA": "1.18", "PERSIMMON FRUIT": "1.77",
                                  "CILANTRO": "0.49", "DUDHI": "1.96", "WHITE POTATO": "0.81", "FLAT VALOR": "2.26", "OKRA": "6.46", "SNAKE GOURD": "5.45"])
        #expect(outcome.lines.first { $0.name == "OKRA" }?.quantity == "2.16 lb")
    }

    @Test func pricesOnTheirOwnRowsTakeTheNameAbove() {
        let outcome = solve("""
        FRESH MART
        Customer: Sam
        ORGANIC MILK
        $4.99
        BREAD WHITE
        $2.50
        SUBTOTAL $7.49
        TOTAL $7.49
        """)
        #expect(outcome.status == .unique)
        #expect(read(outcome) == ["ORGANIC MILK": "4.99", "BREAD WHITE": "2.50"])
    }

    @Test func kilogramsInRupees() {
        let outcome = solve("""
        SRI BALAJI STORES
        ONION
        0.5 kg @ 40.00/kg 20.00
        TOMATO
        1.25 kg @ 32.00/kg 40.00
        Coriander 10.00
        GRAND TOTAL ₹70.00
        """)
        #expect(outcome.status == .unique)
        #expect(read(outcome) == ["ONION": "20.00", "TOMATO": "40.00", "Coriander": "10.00"])
        #expect(outcome.lines.first { $0.name == "TOMATO" }?.quantity == "1.25 kg")
    }

    @Test func aBreakdownRowIsNotASecondItem() {
        let outcome = solve("BANANAS 2.98\n2 @ 1.49 2.98\nMILK 3.49\nSUBTOTAL 6.47\nTOTAL 6.47")
        #expect(outcome.status == .unique)
        #expect(read(outcome) == ["BANANAS": "2.98", "MILK": "3.49"])
    }

    @Test func savingsUnderAnItemAreSubtractedOnlyWhenTheTotalsSaySo() {
        let charged = solve("CHEESE 5.99\nCARD SAVINGS 1.00-\nEGGS 3.00\nSUBTOTAL 7.99\nTOTAL 7.99")
        #expect(read(charged) == ["CHEESE": "4.99", "EGGS": "3.00"])
        let note = solve("CHEESE 4.99\nRegular price $5.99 You saved $1.00\nEGGS 3.00\nSUBTOTAL 7.99\nTOTAL 7.99")
        #expect(read(note) == ["CHEESE": "4.99", "EGGS": "3.00"])
    }

    @Test func twoEquallyGoodReadingsProposeNothing() {
        let outcome = solve("APPLES 2.00\nPEARS 2.00\nSUBTOTAL 2.00\nTOTAL 2.00")
        #expect(outcome.status == .ambiguous && outcome.lines.isEmpty)
    }

    @Test func numbersThatNeverAddUpProposeNothing() {
        let outcome = solve("APPLES 2.00\nPEARS 3.00\nSUBTOTAL 9.00\nTOTAL 9.00")
        #expect(outcome.status == .noSolution && outcome.lines.isEmpty)
        #expect(solve("APPLES 2.00\nPEARS 3.00").status == .notApplicable)
    }

    @Test func aStrayPricedRowIsLeftOutWhenOnlyThatAddsUp() {
        let outcome = solve("STORE 42 2.00\nAPPLES 2.00\nPEARS 3.00\nSUBTOTAL 5.00\nTAX 0.40\nTOTAL 5.40")
        // Leaving out either 2.00 row adds up: two readings, so nothing is proposed.
        #expect(outcome.status == .ambiguous)
        let clear = solve("REWARDS ID 7781 9.99\nAPPLES 2.00\nPEARS 3.00\nSUBTOTAL 5.00\nTAX 0.40\nTOTAL 5.40")
        #expect(clear.status == .unique && read(clear) == ["APPLES": "2.00", "PEARS": "3.00"])
    }

    @Test func printedItemCountIsRead() {
        #expect(ReceiptSolver.printedItemCount("Items count: 9\nfoo") == 9)
        #expect(ReceiptSolver.printedItemCount("# ITEMS SOLD 12") == 12)
        #expect(ReceiptSolver.printedItemCount("no count here") == nil)
    }
}
