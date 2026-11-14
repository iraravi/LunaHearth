import Foundation
import CryptoKit

protocol ReceiptScanningService: Sendable {
    func scan(imageData: Data) async throws -> ReceiptScan
}

struct ReceiptScan: Sendable {
    let text: String
    var lines: [ReceiptLine]
    var extractionMessage: String? = nil
    #if RECEIPT_DEBUG
    var debugOutput: String = "AI was not invoked."
    /// Internal receipt lab comparison of alternative readers; empty outside the debug screen.
    var experimentOutput: String = ""
    #endif
    var previewImages: [Data] = []
    var previewIncomplete = false
}

struct ReceiptLine: Identifiable, Sendable {
    let id: String
    var name: String
    var quantity: String = ""
    var amount: String = ""
    var amountNeedsReview = false
    var expiryDay: String?
    var included = true
    var addToInventory = true
    var groceryID: UUID?
    var inventoryID: UUID?
    var reviewedShoppingMatch: ReceiptShoppingApproval?
    /// Review-only selection; a match links evidence without repeating any stock action.
    var existingPurchaseID: UUID?
    var confirmedNewPurchase = false
    /// Explicit review choice; never merge into an existing pack when true.
    var keepSeparatePack = false
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
    /// - Parameter sameLinePrices: keep the price printed on a product's own row as a proposed
    ///   line amount. Production scans enable it because `ReceiptReconciliation` hides any item
    ///   list whose amounts do not reproduce the printed subtotal/total.
    static func scan(text: String, sameLinePrices: Bool = false) -> ReceiptScan {
        let bounded = String(text.prefix(40_000))
        let normalized = bounded.lowercased().split(whereSeparator: \.isWhitespace).joined(separator: " ")
        let fingerprint = hash(normalized)
        var lines: [ReceiptLine] = []
        let sourceRows = ItemCodeReceiptDetails.productSection(bounded).components(separatedBy: .newlines)
        let flags = taxFlags(bounded)
        for (index, raw) in sourceRows.enumerated() {
            var line = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            // Layout-aware OCR can print a product's price on its own row. Join a bare price only
            // to an unpriced row directly above; the joined row still passes every exclusion below.
            if index > 0, line.range(of: #"^[₹$€£]\s*\d[\d,]*\.\d{2}\s*[A-Za-z]?$"#, options: .regularExpression) != nil {
                let previous = sourceRows[index - 1].trimmingCharacters(in: .whitespacesAndNewlines)
                guard previous.contains(where: \.isLetter),
                      previous.range(of: #"\d[.,]\d{2}(?!\d)"#, options: .regularExpression) == nil else { continue }
                line = previous + " " + line
            }
            guard line.count <= 250, !line.isEmpty, !isNonProductRow(line) else { continue }
            guard line.range(of: excludedRow, options: .regularExpression) == nil,
                  let price = line.range(of: pricePattern, options: .regularExpression) else { continue }
            // Refunds and discounts are never treated as newly purchased stock.
            guard !String(line[price]).contains("-"), !String(line[price]).contains("−") else { continue }
            var name = String(line[..<price.lowerBound]).trimmingCharacters(in: .whitespaces)
            var quantity = ""
            if let prefix = name.range(of: #"^\d{1,3}\s*[xX×]\s+"#, options: .regularExpression) {
                let count = name[prefix].prefix(while: \.isNumber)
                quantity = "\(count) pieces"
                name.removeSubrange(prefix)
            }
            name = name.replacingOccurrences(of: #"^(?:[EA]\s+)?\d{4,}\s+"#, with: "", options: .regularExpression)
            // A tax marker such as "T" is stripped only when the receipt prints its legend ("T = TX TAX").
            if !flags.isEmpty {
                name = name.replacingOccurrences(of: #"\s+(?:"# + flags.sorted().joined(separator: "|") + ")$", with: "", options: .regularExpression)
            }
            guard name.rangeOfCharacter(from: .letters) != nil, (2...200).contains(name.count) else { continue }
            var amount = ""
            if sameLinePrices {
                let printed = String(line[price]).replacingOccurrences(of: #"\s*[A-Za-z]$"#, with: "", options: .regularExpression)
                amount = ExpenseRules.normalizedReceiptAmount(printed) ?? ""
                // "NAME QTY [UNIT] RATE AMOUNT" columns: keep the name and quantity only when
                // quantity × rate reproduces the printed line amount.
                if let columns = ReceiptColumns.split(name: name, lineAmount: amount) {
                    name = columns.name
                    quantity = columns.quantity
                }
            }
            lines.append(ReceiptLine(id: hash("\(fingerprint)|\(index)"), name: name, quantity: quantity,
                                     amount: amount, amountNeedsReview: sameLinePrices && amount.isEmpty))
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
                // Money for repeated rows is additive; an unreadable part makes the whole unknown.
                if sameLinePrices {
                    if let a = try? ExpenseRules.minorUnits(grouped[index].amount), let b = try? ExpenseRules.minorUnits(line.amount),
                       !grouped[index].amountNeedsReview, !line.amountNeedsReview {
                        grouped[index].amount = ExpenseRules.amountText(a + b)
                    } else { grouped[index].amount = ""; grouped[index].amountNeedsReview = true }
                }
            } else { grouped.append(line) }
        }
        ReceiptMultilineDetails.apply(text: bounded, lines: &grouped)
        ReceiptTableDetails.apply(text: bounded, lines: &grouped)
        ItemCodeReceiptDetails.apply(text: bounded, lines: &grouped)
        return ReceiptScan(text: bounded, lines: grouped)
    }
    /// Summary, payment and identifier rows in any supported language; never products.
    /// Short words that are also common brand words (moms, ust, mva) are only matched as labels.
    static let excludedRow: String = {
        let english = ["amount", "approved", "cash", "change", "tender", "balance", "payment", "visa", "mastercard", "debit", "credit",
                       "refund", "return", "rounding", "round off", "loyalty", "member", "phone", "tel", "receipt", "invoice",
                       "transaction", "cashier", "register", "terminal", "upi", "paytm", "gpay", "phonepe"]
        let other = ["karte", "rückgeld", "wechselgeld", "espèces", "especes", "carte", "rendu", "efectivo", "tarjeta",
                     "cambio", "contanti", "kontant", "beleg", "ticket", "factura", "facture", "fattura"]
        let ambiguous: Set<String> = ["moms", "ust", "mva"]
        let words = ReceiptVocabulary.subtotal + ReceiptVocabulary.strongTotal + ReceiptVocabulary.total
            + ReceiptVocabulary.tax.filter { !ambiguous.contains($0) } + ReceiptVocabulary.discount + english + other
        return #"(?i)(?<![\p{L}])(?:"# + ReceiptVocabulary.alternation(words) + #")(?![\p{L}])"#
    }()
    /// A trailing line amount, with an optional currency marker on either side and tax letter.
    static let pricePattern = #"(?i)(?:\s+|(?=[₹$€£]))[-−]?\s*(?:"# + ExpenseRules.currencyPattern
        + #"\s*[-−]?\s*\d[\d,.]*(?:[.,]\d{2})?|\d[\d,.]*[.,]\d{2})(?:\s*(?:€|EUR|zł|kr))?\s*[A-Za-z]?$"#

    /// Structural receipt fields are not inventory, even when OCR puts a price beside them.
    /// Keep these rules anchored: a product may legitimately contain words such as "service".
    /// Do not stop at subtotal/payment rows: mixed layouts can place real items after them.
    static func isNonProductRow(_ line: String) -> Bool {
        let patterns = [
            #"(?i)^\s*\d+\s+Each\s*@"#,
            // A payment-method word alone with the amount paid ("Bar 10,00", "EC 7,26", "CB 12,00").
            // Words such as "bar" are only payments in this exact shape, never inside product names.
            #"(?i)^\W*(?:bar|ec|ec[\s-]?karte|girocard|cb|carte\s+bancaire|espèces|efectivo|contanti|kontant|cash|card|upi)\s*[:=]?\s*(?:[₹$€£]|EUR|Rs\.?)?\s*\d[\d.,]*\s*(?:€|EUR)?$"#,
            // Count × unit price calculation rows in any currency ("2 @ 2.99 5.98", "2 x 1,29 2,58").
            #"(?i)^\s*\d{1,3}\s*(?:each|ea|pcs?|nos?|st|stk)?\s*(?:@|×|x)\s*(?:[₹$€£]|Rs\.?)?\s*\d+[.,]\d{2}"#,
            #"(?i)^\s*Temporary\s+price\b"#,
            // Reference prices and promotion notes annotate the item above, whose printed
            // amount is already net ("Regular Price $12.99", "25% off Circle").
            #"(?i)^\W*(?:regular|reg\.?|orig(?:inal)?|list)\s+price\b"#,
            #"(?i)^\W*\d{1,3}(?:\.\d+)?\s*%\s*off\b"#,
            // Store-card percentage discounts are receipt-level adjustments ("Circle Card 5% $0.33 -").
            #"(?i)\bcard\s+\d{1,2}(?:\.\d+)?\s*%"#,
            // Card authorization and receipt identifiers, often followed by a currency amount.
            #"(?i)^\W*(?:aid|appr|auth(?:orization)?(?:\s+code)?|approval(?:\s+code)?|resp(?:onse)?|ref(?:erence)?(?:\s+(?:no|number))?|rrn|stan|batch|seq|trace|acct|account|card(?:\s+(?:no|number|ending))?|entry\s+mode|merchant\s+id|terminal\s+id)\s*(?:[:#=]|\b\s+\d)"#,
            #"(?i)^\W*(?:approved|declined|contactless|chip\s+(?:read|sale)|eftpos|eft|ebt|snap|amex|american\s+express|discover|upi|paid|cashback|cash\s+back)\b"#,
            // Charges and summaries belong to expense review, not stock selection.
            #"(?i)^\W*(?:service\s+charge|delivery\s+(?:fee|charge)|shipping(?:\s+(?:fee|charge))?|handling(?:\s+fee)?|convenience\s+fee|bag\s+fee|bottle\s+deposit|gratuity|tip|rounding\s+adjustment|you\s+saved|items?\s+(?:sold|count)|no\.?\s+of\s+items|number\s+of\s+items)\s*(?:[:#=]|\b\s+[₹$€£\d])"#,
            // Contact details, promotions and unit-price calculations are not products.
            #"(?i)(?:https?://|www\.|\b[^\s@]+@[^\s@]+\.[a-z]{2,}\b)"#,
            #"(?i)^\W*(?:thank\s+you|thanks\s+for|please\s+(?:come|visit|retain|keep)|visit\s+us|survey|rewards?\s+(?:points|balance)|points\s+(?:earned|balance)|save\s+(?:up\s+to\s+)?[₹$€£\d])\b"#,
            #"(?i)^\s*\d+(?:[.,]\d+)?\s*(?:kg|g|lb|lbs|oz|l|ml)\s*(?:@|x|×|at)\s*"#
        ]
        return patterns.contains { line.range(of: $0, options: .regularExpression) != nil }
    }

    /// Tax markers declared by a printed legend such as "T = TX TAX 8.25000 on $29.39 $2.42".
    static func taxFlags(_ text: String) -> Set<String> {
        let pattern = #"(?im)^\s*([A-Z]{1,2})\s*=\s*(?:[A-Z]+\s+){0,2}(?:sales\s+)?(?:tax|gst|vat|hst|pst)\b"#
        guard let regex = try? NSRegularExpression(pattern: pattern) else { return [] }
        return Set(regex.matches(in: text, range: NSRange(text.startIndex..., in: text)).compactMap { match in
            Range(match.range(at: 1), in: text).map { String(text[$0]).uppercased() }
        })
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
