import Foundation
import Testing
@testable import LunaHearth

struct SuggestionSourceTests {
    @Test func onlyModelSuggestionsSayAI() {
        #expect(SuggestionSource.ai.acceptTitle == "Accept AI")
        for source in SuggestionSource.allCases where source != .ai {
            #expect(source.acceptTitle == "Accept")
            #expect(!source.label.contains("AI"))
        }
    }

    @Test func personChoicesOutrankRulesAndRulesOutrankTheModel() {
        let ordered = SuggestionSource.allCases.sorted { $0.priority < $1.priority }
        #expect(ordered == [.memory, .savedItem, .rule, .ai])
    }

    @Test func receiptProposalsMapToOneSource() {
        var proposal = ReceiptNameProposal(id: "1", original: "GV WHL MLK", name: "Great Value whole milk")
        #expect(proposal.source == .rule && proposal.sourceLabel == "Decoded")
        proposal.fromAI = true
        #expect(proposal.source == .ai && proposal.sourceLabel == "AI says")
        proposal.fromSavedItem = true
        #expect(proposal.source == .savedItem)
        proposal.fromCorrection = true
        #expect(proposal.source == .memory && proposal.sourceLabel == "You named it")
    }

    @Test func modelFailuresKeepTheirReason() {
        let failure = OnDeviceModelFailure(reason: .busy)
        #expect(failure.reason.message.contains("busy"))
    }
}
