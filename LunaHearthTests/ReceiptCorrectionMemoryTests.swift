import Foundation
import Testing
@testable import LunaHearth

struct ReceiptCorrectionMemoryTests {
    @Test func storeFingerprintsComeFromPhoneWebsiteAndAddress() {
        let keys = ReceiptCorrectionMemory.storeKeys(IndiaBazaarReceiptTests.text)
        #expect(keys.contains("tel:9723120114"))
        #expect(keys.contains("web:indiabazaardfw"))
        #expect(keys.contains { $0.hasPrefix("addr:14339 eldorado") })
        #expect(!keys.contains { $0.contains("2434") }) // masked card numbers are never a fingerprint
    }

    @Test func savedStoreIsRememberedForTheNextReceiptFromThatStore() {
        let learned = ReceiptCorrectionMemory.learn(text: IndiaBazaarReceiptTests.text, savedStore: "India Bazaar Eldorado", renamed: [], state: .init())
        // A later receipt with different show-through junk and items, same store details.
        let next = "XQ7 ~\nINDIA BAZAAR ELDORADO\n14339 Eldorado Pkwy,\n(972) 312-0114\nTOOR DAL 4LB 7.99\nTOTAL 7.99"
        #expect(ReceiptCorrectionMemory.rememberedStore(next, state: learned) == "India Bazaar Eldorado")
        #expect(ReceiptCorrectionMemory.rememberedStore("OTHER SHOP\n(469) 555-0100\nMILK 3.00\nTOTAL 3.00", state: learned) == nil)
    }

    @Test func renamedItemsAreSuggestedNextTimeButUnchangedOnesAreNot() {
        var state = ReceiptCorrectionMemory.learn(text: "", savedStore: "",
            renamed: [("BOMBAY MIXTURE IDHAYAM 340G", "Bombay mixture"), ("MILK", "milk"), ("X", "")], state: .init())
        #expect(ReceiptCorrectionMemory.rememberedName("Bombay Mixture Idhayam 340g", state: state) == "Bombay mixture")
        #expect(ReceiptCorrectionMemory.rememberedName("MILK", state: state) == nil)
        #expect(state.stores.isEmpty)
        state = ReceiptCorrectionMemory.decode(ReceiptCorrectionMemory.encode(state))
        #expect(state.items.count == 1)
        #expect(ReceiptCorrectionMemory.decode("not json") == .init())
    }

    @Test func suggestionSaysItCameFromYou() {
        var proposal = ReceiptNameProposal(id: "a", original: "PIST F", name: "Pistachios")
        proposal.fromCorrection = true
        #expect(proposal.sourceLabel == "You named it")
    }
}
