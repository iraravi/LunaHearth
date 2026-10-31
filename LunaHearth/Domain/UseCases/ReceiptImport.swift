import Foundation
import CryptoKit

protocol ReceiptScanningService: Sendable {
    func scan(imageData: Data) async throws -> ReceiptScan
}

struct ReceiptScan: Sendable {
    let text: String
    let lines: [ReceiptLine]
}

struct ReceiptLine: Identifiable, Sendable {
    let id: String
    var name: String
    var quantity: String = ""
    var amount: String = ""
    var expiryDay: String?
    var included = true
    var addToInventory = true
    var groceryID: UUID?
    var inventoryID: UUID?
    /// Review-only selection; a match links evidence without repeating any stock action.
    var existingPurchaseID: UUID?
    var confirmedNewPurchase = false
}

enum ReceiptImportError: LocalizedError {
    case unreadable, tooLarge, noSelection, changedMatch, duplicateLine, reviewPurchase, alreadyExpensed
    var errorDescription: String? {
        switch self {
        case .reviewPurchase: "A recent purchase matches this item. Choose the recorded purchase or confirm this is a new purchase before saving."
        case .alreadyExpensed: "This purchase already has a receipt or expense. Open Purchase history to review it, or confirm a genuinely new purchase. Nothing was added."
        case .unreadable: "No readable receipt items were found. Try a sharper photo with the whole receipt visible."
        case .tooLarge: "Choose a receipt photo smaller than 20 MB."
        case .noSelection: "Select at least one item to add."
        case .duplicateLine: "Two selected rows name the same ingredient. Keep one row and confirm its quantity before adding."
        case .changedMatch: "A selected shopping or inventory item changed. Review its match again before saving."
        }
    }
}

/// Conservative receipt text parsing. Only priced product lines are proposed; every name is editable.
/// Totals/payment details are not household items, and a monetary amount is never a stock quantity.
enum ReceiptRules {
    static func scan(text: String) -> ReceiptScan {
        let bounded = String(text.prefix(40_000))
        let normalized = bounded.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let fingerprint = hash(normalized)
        var lines: [ReceiptLine] = []
        for (index, raw) in bounded.components(separatedBy: .newlines).enumerated() {
            let line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            guard line.count <= 250, !line.isEmpty else { continue }
            let excluded = #"(?i)\b(subtotal|sub total|total|net amount|net payable|amount due|amount payable|tax|gst|cgst|sgst|igst|vat|cash|change|tender|balance|payment|visa|mastercard|debit|credit|savings|discount|coupon|refund|return|rounding|round off|loyalty|member|phone|tel|receipt|invoice|transaction|cashier|register|terminal)\b"#
            guard line.range(of: excluded, options: .regularExpression) == nil,
                  let price = line.range(of: #"(?i)(?:\s+|(?=[₹$€£]))[-−]?\s*(?:(?:₹|\$|€|£|INR\b|Rs\.?)\s*[-−]?\s*\d[\d,]*(?:\.\d{2})?|\d[\d,]*[.,]\d{2})\s*[A-Za-z]?$"#, options: .regularExpression) else { continue }
            // Refunds and discounts are never treated as newly purchased stock.
            guard !String(line[price]).contains("-"), !String(line[price]).contains("−") else { continue }
            var name = String(line[..<price.lowerBound]).trimmingCharacters(in: .whitespaces)
            var quantity = ""
            if let prefix = name.range(of: #"^\d{1,3}\s*[xX×]\s+"#, options: .regularExpression) {
                let count = name[prefix].prefix(while: \.isNumber)
                quantity = "\(count) pieces"
                name.removeSubrange(prefix)
            }
            name = name.replacingOccurrences(of: #"^\d{4,}\s+"#, with: "", options: .regularExpression)
            guard name.rangeOfCharacter(from: .letters) != nil, (2...200).contains(name.count) else { continue }
            lines.append(ReceiptLine(id: hash("\(fingerprint)|\(index)"), name: name, quantity: quantity))
            if lines.count == 150 { break }
        }
        // A product printed on multiple receipt lines is one review row. Only explicit piece
        // counts can be combined; unknown counts stay unknown instead of becoming a false total.
        var grouped: [ReceiptLine] = []
        for line in lines {
            if let index = grouped.firstIndex(where: { IngredientMatching.same($0.name, line.name) }) {
                if let a = Int(grouped[index].quantity.split(separator: " ").first ?? ""),
                   let b = Int(line.quantity.split(separator: " ").first ?? "") {
                    grouped[index].quantity = "\(a + b) pieces"
                } else { grouped[index].quantity = "" }
            } else { grouped.append(line) }
        }
        return ReceiptScan(text: bounded, lines: grouped)
    }
    static func hash(_ text: String) -> String {
        SHA256.hash(data: Data(text.utf8)).map { String(format: "%02x", $0) }.joined()
    }
    static func groceryID(home: UUID, key: String) -> UUID {
        var b = Array(SHA256.hash(data: Data("LunaHearth.receipt.v1|\(home)|\(key)".utf8)).prefix(16))
        b[6] = (b[6] & 0x0f) | 0x80; b[8] = (b[8] & 0x3f) | 0x80
        return UUID(uuid: (b[0],b[1],b[2],b[3],b[4],b[5],b[6],b[7],b[8],b[9],b[10],b[11],b[12],b[13],b[14],b[15]))
    }
}

/// Bulk review never reselects excluded, imported or already-linked purchases.
enum ReceiptInventorySelection {
    static func setAll(_ enabled: Bool, lines: inout [ReceiptLine], unavailableIDs: Set<String>) {
        for index in lines.indices where lines[index].included && lines[index].existingPurchaseID == nil && !unavailableIDs.contains(lines[index].id) {
            lines[index].addToInventory = enabled
        }
    }
}
