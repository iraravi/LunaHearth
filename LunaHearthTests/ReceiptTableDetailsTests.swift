import Testing
@testable import LunaHearth

struct ReceiptTableDetailsTests {
    @Test func damagedTableRetainsNamesWithoutInventingMissingTotals() {
        let scan = ReceiptRules.scan(text: """
        India Metro Hypermarket
        Weight/pc Unit Price Total Price
        FS Leaves¿Mint Pc-SM17543
        $0.99/0
        IS Swad Rst Chana With Halt 1402-5821809
        $3.49/0
        IS Deccan Jeera Samba Rice 101b-518369
        10 $17.99/0 $17.99
        FS Okra-1b-SM18556
        $1,99/0
        Fs Squash-Snake Gourd 1b-5M20927
        $2.99/0 $5.14
        1. 72 rela Inậian Bittermelon 1b-SM15903ś
        1.33 0 $1.29/0 $1.72
        $0.94
        0s Squash Opo- Indian: 15-5420925
        $2.69
        ES Cilantro -DC-SM1281 79/0
        $0.33/0 $0.99
        1.48 0 FS Beans-Green 1b-SM1943 $1.29/0 $1.91
        Subtotal $41.84
        GRAND TOTAL $41.84
        Amount saved $4.60
        """)
        #expect(scan.lines.count == 9)
        #expect(scan.lines.map(\.amount) == ["", "", "17.99", "", "5.14", "1.72", "2.69", "0.99", "1.91"])
        #expect(scan.lines.allSatisfy { $0.amountNeedsReview })
        #expect(scan.lines.last?.name == "Beans-Green 1b")
        #expect(!scan.lines.contains { $0.amount == "0.94" || $0.amount == "4.60" })
    }

    @Test func unitPriceCannotReplaceLineTotalOrCrossProducts() {
        let scan = ReceiptRules.scan(text: """
        Weight/pc Unit Price Total Price
        FS Okra-lb-SM18556
        $1.99/0
        FS Rice-SM12345
        $17.99/0 $17.99
        SUBTOTAL $20.48
        """)
        #expect(scan.lines.count == 2)
        #expect(scan.lines[0].amount.isEmpty)
        #expect(scan.lines[1].amount == "17.99")
    }
}
