import Foundation

/// Bundled, searchable guidance. Reading never writes records or requests permissions.
struct HouseholdSupportArticle: Identifiable, Sendable {
    enum Category: String, CaseIterable, Sendable {
        case troubleshooting, legal
        var title: String { self == .troubleshooting ? "Troubleshooting" : "Privacy & responsible use" }
    }
    let id: String
    let category: Category
    let title: String
    let symbol: String
    let steps: [HelpStep]
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || ([title, category.title] + steps.flatMap { [$0.title, $0.detail] }).contains { $0.localizedStandardContains(query) }
    }
    static let all: [Self] = [
        .init(id: "sync", category: .troubleshooting, title: "Changes are missing on another device", symbol: "icloud", steps: [
            HelpStep(title: "Check the home", detail: "Open Family on both devices and confirm that each has joined the same shared home. A profile or a sent invitation alone does not establish sharing.", symbol: "icloud"),
            HelpStep(title: "Check connectivity and status", detail: "Connect both devices to the internet. Open More → Privacy & data → Sync & recovery and read the status or error. Keep the app open while it refreshes.", symbol: "icloud"),
            HelpStep(title: "Check Apple access", detail: "Confirm iCloud is available on each device and that the owner has sufficient iCloud storage. Ask the owner to check that the participant still has access.", symbol: "icloud"),
            HelpStep(title: "Keep your local records", detail: "Do not delete the home, clear data or reinstall to fix a sync problem. Preserve needed records first. If access was removed, use the recovery options shown in the app.", symbol: "icloud")
        ]),
        .init(id: "notifications", category: .troubleshooting, title: "I did not receive an assignment alert", symbol: "bell", steps: [
            HelpStep(title: "Check the saved assignment", detail: "Confirm the item is assigned to the intended member in the shared home. On the receiving device, check the selected personal member and alert preferences.", symbol: "bell"),
            HelpStep(title: "Check device permissions", detail: "In iOS Settings → Notifications → LunaHearth, check notification permission, sounds and delivery settings. Focus and Scheduled Summary can affect alerts.", symbol: "bell"),
            HelpStep(title: "Check the original item", detail: "Open LunaHearth on the receiving device and allow sync to refresh. Confirm the assignment is visible before troubleshooting delivery.", symbol: "bell"),
            HelpStep(title: "Allow for delivery limits", detail: "Background delivery may be delayed or unavailable. Recheck important plans in the app; do not rely on LunaHearth for emergencies or time-critical safety alerts.", symbol: "bell")
        ]),
        .init(id: "receipt", category: .troubleshooting, title: "A receipt has incorrect or abbreviated items", symbol: "receipt", steps: [
            HelpStep(title: "Improve the image", detail: "Use an evenly lit, sharp photo with the receipt flat. Include the store, item lines, date and total. Avoid glare and clipped edges.", symbol: "receipt"),
            HelpStep(title: "Review the draft", detail: "Compare item names, amounts, units, prices, currency, discounts and the total with the original. Correct uncertain names manually; optional AI decoding is a suggestion.", symbol: "receipt"),
            HelpStep(title: "Choose destinations", detail: "Review expense recording, pantry packs and shopping matches before saving. Do not infer expiry or allergens from a receipt.", symbol: "receipt"),
            HelpStep(title: "Avoid importing twice", detail: "If saving seemed interrupted, check Expenses, shopping status and pantry quantity before scanning the receipt again. Keep the original receipt for reference.", symbol: "receipt")
        ]),
        .init(id: "pantry", category: .troubleshooting, title: "My pantry quantity or matching item looks wrong", symbol: "cabinet", steps: [
            HelpStep(title: "Check filters and packs", detail: "Clear pantry filters and search the ingredient. Separate packs may intentionally have different units, storage locations or dates.", symbol: "cabinet"),
            HelpStep(title: "Review the purchase", detail: "When buying more, choose the existing ingredient or pack and check the amount and compatible unit. A separate pack creates a separate record.", symbol: "cabinet"),
            HelpStep(title: "Correct the saved record", detail: "Open the item and adjust the amount or low-stock status to match what is actually at home. The app cannot measure consumption.", symbol: "cabinet"),
            HelpStep(title: "Keep distinct ingredients distinct", detail: "Review similar-item suggestions. Whole and ground spices, varieties, brands and separately dated packs may need to stay separate. Do not merge solely because AI suggests it.", symbol: "cabinet")
        ]),
        .init(id: "ai", category: .troubleshooting, title: "AI is missing, paused or gives an unexpected answer", symbol: "sparkles", steps: [
            HelpStep(title: "Read AI Status", detail: "Open More → AI Status to check device capability and availability. Apple Intelligence must be supported and ready; a standard iPhone 15 does not offer these on-device AI actions.", symbol: "sparkles"),
            HelpStep(title: "Use the available fallback", detail: "Continue with manual entry, supported label reading or built-in ideas. Publisher-paused features may show a message; repeatedly reinstalling will not enable them.", symbol: "sparkles"),
            HelpStep(title: "Make the request specific", detail: "For dish ideas, include the dish name and intended ingredients. Shorten long requests and review all results. AI can omit a main ingredient or misunderstand a name.", symbol: "sparkles"),
            HelpStep(title: "Check the original records", detail: "Existing pantry or shopping matches may be excluded from suggestions. Compare results with actual stock and product labels. AI Status records only a result category and time, not proof that an answer is correct.", symbol: "sparkles")
        ]),
        .init(id: "invite", category: .troubleshooting, title: "An invitation opens setup or will not join", symbol: "person.2", steps: [
            HelpStep(title: "Use Apple sharing", detail: "The owner should use Family sharing and send the invitation through Apple’s sharing screen. Adding a member name alone is not an invitation.", symbol: "person.2"),
            HelpStep(title: "Open on the intended device", detail: "Open the invitation using the recipient’s intended iCloud account. Confirm the address carefully, including dots. Follow the join flow rather than creating a second home for the same household.", symbol: "person.2"),
            HelpStep(title: "Check the invitation", detail: "Ask the owner to check the participant and share status. If Apple reports an invalid or revoked invitation, have the owner send a current invitation using the sharing controls.", symbol: "person.2"),
            HelpStep(title: "Preserve existing data", detail: "If joining still fails, note the exact error and the app version. Do not clear the existing home to troubleshoot. Do not send invitation links or account passwords to support.", symbol: "person.2")
        ]),
        .init(id: "calendar", category: .troubleshooting, title: "An appointment is missing from Apple Calendar", symbol: "calendar", steps: [
            HelpStep(title: "Check the event option", detail: "LunaHearth events do not automatically become Apple Calendar events. Open the event and check its optional Apple Calendar export setting.", symbol: "calendar"),
            HelpStep(title: "Check permission and calendar", detail: "Check calendar permission in device Settings and the writable destination calendar chosen in the app.", symbol: "calendar"),
            HelpStep(title: "Check visibility", detail: "In Apple Calendar, make sure the destination calendar is shown and the date is correct. Read any pending or error status in LunaHearth.", symbol: "calendar"),
            HelpStep(title: "Understand the direction", detail: "LunaHearth → Apple Calendar is an optional export. Do not assume edits made in Apple Calendar update LunaHearth, or that a LunaHearth family share exposes someone’s personal calendars.", symbol: "calendar")
        ]),
        .init(id: "safety", category: .legal, title: "AI, pantry and meal safety", symbol: "hand.raised", steps: [
            HelpStep(title: "Ideas need review", detail: "AI and scanning may produce incorrect, incomplete or unsuitable names, matches, quantities, dates and summaries. Check important details before saving or acting.", symbol: "hand.raised"),
            HelpStep(title: "Food safety is not assessed", detail: "Pantry dates, colours, photographs and meal ideas do not establish freshness, safe storage, safe preparation or absence of allergens. Check actual packaging and authoritative food-safety advice. Do not taste food to test whether it is safe.", symbol: "hand.raised"),
            HelpStep(title: "Meal ideas are not recipes", detail: "LunaHearth provides planning ideas and ingredient lists, not verified cooking instructions or medical, allergy or nutrition advice. Use a trusted recipe and appropriate professional advice for specific dietary needs.", symbol: "hand.raised"),
            HelpStep(title: "Keep important safeguards separate", detail: "Alerts and sync may be delayed. The app is not an emergency, medical or safety-monitoring service. Use appropriate independent reminders for critical obligations.", symbol: "hand.raised")
        ]),
        .init(id: "data", category: .legal, title: "Privacy, sharing and deletion", symbol: "lock.shield", steps: [
            HelpStep(title: "Local records and optional sharing", detail: "Household records are stored locally. Optional CloudKit backup and sharing use Apple services. Invited participants may access shared information according to their permissions.", symbol: "lock.shield"),
            HelpStep(title: "Public settings are separate", detail: "The app reads publisher feature settings and guidance from public CloudKit. These settings requests do not include household content. This does not mean Apple receives no service information.", symbol: "lock.shield"),
            HelpStep(title: "On-device intelligence", detail: "The app’s AI adapters run on device and do not send household prompts to a third-party AI service. Local AI diagnostics retain a feature, result category and timestamp; they can be cleared in AI Status.", symbol: "lock.shield"),
            HelpStep(title: "Deletion has a scope", detail: "Read the confirmation before clearing data. Live shared records, private backups, exported files and Apple app copies have separate lifecycles. Removing a participant cannot erase copies already received. Read the privacy policy for details.", symbol: "lock.shield")
        ]),
        .init(id: "use", category: .legal, title: "Important information about using LunaHearth", symbol: "doc.text", steps: [
            HelpStep(title: "Purpose and limits", detail: "LunaHearth helps organize information you record. It does not inspect your home, measure inventory, verify purchases or guarantee the completeness of household records.", symbol: "doc.text"),
            HelpStep(title: "Spending records", detail: "Expense reports summarize entered purchases and separate currencies. They are not connected bank balances, audited accounts, tax advice or a substitute for original receipts.", symbol: "doc.text"),
            HelpStep(title: "Your choices", detail: "Only enter or share information you are entitled to use. Review recipients, permissions, AI proposals and deletion confirmations. Keep separate copies of records you need.", symbol: "doc.text"),
            HelpStep(title: "Your rights remain", detail: "These explanations describe product limitations; they do not remove mandatory consumer rights or exclude responsibilities that applicable law does not permit a provider to exclude. The applicable App Store licence and privacy policy remain separate documents.", symbol: "doc.text")
        ]),
        .init(id: "support", category: .troubleshooting, title: "What to include when asking for help", symbol: "questionmark.circle", steps: [
            HelpStep(title: "Describe the problem", detail: "Note the app version/build, iOS version, feature, exact error, expected result and steps that reproduce the issue.", symbol: "questionmark.circle"),
            HelpStep(title: "Protect your information", detail: "Crop or redact receipts, addresses, family names and financial details in screenshots. Never send passwords, verification codes, private invitation links or a full household backup.", symbol: "questionmark.circle"),
            HelpStep(title: "Use a confirmed contact", detail: "Use the publisher support contact on the App Store listing. Do not send sensitive records to an unverified email address. This offline guide does not upload diagnostics or send a support request.", symbol: "questionmark.circle")
        ]),
    ]
}
