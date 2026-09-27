import Foundation

/// Bundled learning content only. Reading a guide never changes household records.
struct HelpStep: Sendable {
    let title: String
    let detail: String
    let symbol: String
}

enum HouseholdHelpTopic: String, CaseIterable, Identifiable, Sendable {
    case connected, today, home, pantry, shopping, receipts, expenses, meals, calendar, family
    var id: String { rawValue }
    var title: String {
        switch self {
        case .connected: "How everything connects"
        case .today: "Your day, at a glance"
        case .home: "Find your way around"
        case .pantry: "Know what you have"
        case .shopping: "From list to pantry"
        case .receipts: "Review a receipt"
        case .expenses: "Understand your spending"
        case .meals: "Plan from your pantry"
        case .calendar: "Make time together"
        case .family: "Share your home"
        }
    }
    var symbol: String {
        switch self {
        case .connected: "point.3.connected.trianglepath.dotted"
        case .today: "sun.max"
        case .home: "house"
        case .pantry: "cabinet"
        case .shopping: "basket"
        case .receipts: "receipt"
        case .expenses: "chart.bar"
        case .meals: "fork.knife"
        case .calendar: "calendar"
        case .family: "person.2"
        }
    }
    var artwork: String {
        switch self {
        case .pantry, .receipts, .expenses: "EditorialPantry"
        case .shopping, .meals, .connected: "WelcomeTable"
        default: "WelcomeResidence"
        }
    }
    var subtitle: String {
        switch self {
        case .connected: "One purchase. A few thoughtful next steps."
        case .today: "Start with what needs your attention."
        case .home: "Your kitchen, plans and belongings, in one place."
        case .pantry: "A record of your food, kept up to date by you."
        case .shopping: "What you need, who is buying, and what comes home."
        case .receipts: "Less typing. You stay in control of what gets saved."
        case .expenses: "See recorded purchases by month and currency."
        case .meals: "Turn recorded ingredients into ideas for your week."
        case .calendar: "Appointments for the people in your home."
        case .family: "Use it on your own, or invite someone you trust."
        }
    }
    var steps: [HelpStep] {
        switch self {
        case .connected:
            [
                HelpStep(title: "Start with a receipt", detail: "In Expenses, scan a receipt and review the store, date, total and item names.", symbol: "doc.viewfinder"),
                HelpStep(title: "Choose what comes home", detail: "Review each pantry update and matching shopping item before saving. Leave gifts or other purchases out of inventory.", symbol: "cabinet"),
                HelpStep(title: "Keep spending together", detail: "With expense recording selected, saving records the purchase in your monthly report.", symbol: "chart.bar"),
                HelpStep(title: "Plan your next meal", detail: "Open Meals for pantry-based ideas. Review a plan and add any missing ingredients to shopping.", symbol: "fork.knife")
            ]
        case .today:
            [
                HelpStep(title: "See what is coming up", detail: "Review appointments, shopping assignments and home alerts from saved household records.", symbol: "sun.max"),
                HelpStep(title: "Open the original item", detail: "Tap a card to review the details or make changes. Summaries are a starting point.", symbol: "arrow.up.forward"),
                HelpStep(title: "Add as you go", detail: "Use + for a new entry. Optional alerts need notification permission on each device.", symbol: "plus.circle")
            ]
        case .home:
            [
                HelpStep(title: "Start in your kitchen", detail: "Pantry is what you have. Shopping is what you need to buy. Meals connects them when you review a plan.", symbol: "cabinet"),
                HelpStep(title: "Keep purchases together", detail: "Open Expenses to add purchases, scan receipts and see monthly totals.", symbol: "receipt"),
                HelpStep(title: "Explore rooms when ready", detail: "Rooms & belongings holds your appliances, items and home care. A floor plan or room scan is optional.", symbol: "door.left.hand.open")
            ]
        case .pantry:
            [
                HelpStep(title: "Choose an easy starting point", detail: "Use Ideas for a kitchen template, scan a receipt or product labels, or add an item yourself. Review suggestions before adding.", symbol: "lightbulb"),
                HelpStep(title: "Add only what you know", detail: "An item name is enough. Amount, unit, storage and pack expiry are optional. Use the actual packaging for dates.", symbol: "square.and.pencil"),
                HelpStep(title: "Keep quantities current", detail: "Open an item to update its amount, mark it low stock or used up. Buying more can update an existing pack after review.", symbol: "arrow.triangle.2.circlepath")
            ]
        case .shopping:
            [
                HelpStep(title: "Add what you need", detail: "Enter a name, then optionally choose an amount, unit, store, buyer and when it is needed.", symbol: "plus.circle"),
                HelpStep(title: "Check for an existing item", detail: "Review matching names before adding another entry. Filters can hide items, so check them if something seems missing.", symbol: "square.on.square"),
                HelpStep(title: "Choose how to finish", detail: "Tap the purchase circle. Review adding or updating inventory, use a separate pack when needed, or finish without adding it to your pantry.", symbol: "checkmark.circle")
            ]
        case .receipts:
            [
                HelpStep(title: "Use a clear photo", detail: "Keep the receipt flat and include its item lines and total. You can also enter an expense manually.", symbol: "camera"),
                HelpStep(title: "Check every suggestion", detail: "Correct abbreviated names, quantities, prices, store and date. Text recognition and optional AI decoding can be wrong.", symbol: "text.magnifyingglass"),
                HelpStep(title: "Review where items go", detail: "Choose inventory additions or existing packs, check shopping matches and set pack dates only when known. Save when the review is complete.", symbol: "checklist")
            ]
        case .expenses:
            [
                HelpStep(title: "Add a purchase", detail: "Scan a receipt or add an expense manually. Review the amount, currency, store and purchase date.", symbol: "receipt"),
                HelpStep(title: "Choose month and currency", detail: "Reports summarize your saved purchases. Different currencies are shown separately, without exchange-rate conversion.", symbol: "calendar"),
                HelpStep(title: "Review the history", detail: "Open a purchase to check its details. These reports reflect what you record, not a connected bank balance.", symbol: "list.bullet.rectangle")
            ]
        case .meals:
            [
                HelpStep(title: "Choose your cooking style", detail: "Pick a cuisine and date, then get ideas based on recorded pantry ingredients. Built-in ideas work without AI.", symbol: "fork.knife"),
                HelpStep(title: "Review and plan", detail: "Check ingredients against what you actually have. Add missing items to shopping; existing matches are shown for review.", symbol: "basket"),
                HelpStep(title: "Make it a habit", detail: "The optional 5 PM reminder invites you to plan tomorrow. It does not generate or save a meal automatically.", symbol: "clock")
            ]
        case .calendar:
            [
                HelpStep(title: "Add an appointment", detail: "Use + to enter the title, date and time, then choose who it belongs to.", symbol: "calendar.badge.plus"),
                HelpStep(title: "Find each person's plans", detail: "Use the people and date controls to focus your view. Check filters if an appointment is missing.", symbol: "person.crop.circle"),
                HelpStep(title: "Choose Apple Calendar separately", detail: "Use the event's Apple Calendar option if you want a copy there. Connecting Apple Calendar is optional and requires permission.", symbol: "calendar.badge.checkmark")
            ]
        case .family:
            [
                HelpStep(title: "Invite through Family", detail: "Use Apple's sharing screen to send an invitation by Messages or Mail. Creating a profile alone does not grant access.", symbol: "person.badge.plus"),
                HelpStep(title: "Accept on the other device", detail: "Open the invitation with the recipient's iCloud account and join the shared home. Avoid creating another home for the same household.", symbol: "envelope.open"),
                HelpStep(title: "Check access and sync", detail: "Manage participants through sharing controls. Both devices need connectivity for changes to sync; updates may take time.", symbol: "icloud")
            ]
        }
    }
    var note: String {
        switch self {
        case .pantry, .meals:
            "Recorded dates and meal ideas do not verify freshness, allergens or food safety. Meal ideas do not include cooking instructions."
        case .family:
            "Sharing is optional. Check people and access before sharing private household information."
        case .receipts, .connected:
            "Nothing is imported by reading this guide. Scanned or generated suggestions need your review."
        default:
            "You can return to this guide anytime from Help & guides in More."
        }
    }
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || ([title, subtitle, note] + steps.flatMap { [$0.title, $0.detail] })
            .contains { $0.localizedStandardContains(query) }
    }
}

struct HouseholdHelpAnswer: Identifiable, Sendable {
    let id: String
    let question: String
    let answer: String
    func matches(_ query: String) -> Bool {
        let query = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return query.isEmpty || question.localizedStandardContains(query) || answer.localizedStandardContains(query)
    }
    static let all: [Self] = [
        .init(id: "sync", question: "Why is something missing on another device?", answer: "Check that both devices joined the same home and have internet access. In More → Privacy & data → Sync & recovery, review the sync status. Keep your local records while resolving a sync issue."),
        .init(id: "quantity", question: "Does inventory update itself?", answer: "Receipts and shopping purchases can update inventory after your review. The app cannot see what you consume. Update amounts or mark items used up as needed."),
        .init(id: "duplicates", question: "What if an item is already in my pantry?", answer: "Review the existing match when completing shopping or importing a receipt. Check the amount and unit before updating it. Choose a separate pack only when you want a separate record."),
        .init(id: "ai", question: "Where are the AI buttons?", answer: "AI-only controls appear when Apple's on-device model is available. Check More → AI Status. Manual entry, label reading and built-in ideas remain available without AI."),
        .init(id: "privacy", question: "Can I use the app without sharing?", answer: "Yes. Household records work locally. iCloud sharing is optional. Help and setup progress stay on this device and do not turn on services or request permissions."),
        .init(id: "receipt", question: "Can a receipt get a name or total wrong?", answer: "Yes. Check every suggested name, amount and total against the receipt and packaging. Optional AI decoding also needs review. You can correct the entries before saving.")
    ]
}
