import Foundation

/// Receipt label words by meaning, across the languages and countries the app serves.
/// Countries differ in words, not in logic: add a language by adding words here, never by
/// adding a store- or country-specific parser. All matching is case-insensitive.
enum ReceiptVocabulary {
    /// Pre-tax merchandise subtotal.
    static let subtotal = [
        "sub total", "subtotal", "sub-total", "item total", "items total",
        "zwischensumme", "sous-total", "sous total", "subtotale", "subtotaal"
    ]
    /// Amount actually charged. Strong labels win over a bare "total".
    static let strongTotal = [
        "grand total", "net total", "net amount", "net amt", "net payable", "amount due", "amount payable",
        "total payable", "total due", "balance due", "bill total", "bill amount", "total amount payable",
        "total ttc", "net à payer", "net a payer", "à payer", "a payer",
        "gesamtbetrag", "zu zahlen", "importe total", "total a pagar", "totale complessivo",
        "te betalen"
    ]
    static let total = ["total amount", "total amt", "total", "summe", "gesamt", "montant", "totale", "importe", "totaal", "att betala"]
    /// Tax labels (also matched after a short region prefix such as "TEXAS TAX").
    static let tax = [
        "tax", "sales tax", "gst", "cgst", "sgst", "igst", "utgst", "cess", "vat", "hst", "pst", "qst",
        "mwst", "ust", "tva", "iva", "btw", "moms", "mva"
    ]
    /// Item-level deductions.
    static let discount = [
        "discount", "savings", "you saved", "instant savings", "coupon", "promo", "promotion", "offer",
        "rabatt", "nachlass", "remise", "réduction", "reduction", "descuento", "sconto", "korting"
    ]

    /// A regex alternation for one meaning, longest phrases first, words separated by flexible spaces.
    static func alternation(_ words: [String]) -> String {
        words.sorted { $0.count > $1.count }
            .map { NSRegularExpression.escapedPattern(for: $0).replacingOccurrences(of: "\\ ", with: #"\s+"#).replacingOccurrences(of: " ", with: #"\s+"#) }
            .joined(separator: "|")
    }

    /// Row-start label pattern: optional decoration, the label, then an optional separator.
    static func label(_ words: [String]) -> String {
        #"(?i)^\W*(?:"# + alternation(words) + #")(?![\p{L}])\s*[:=\-]?\s*"#
    }

    static func contains(_ words: [String], in row: String) -> Bool {
        // Plural forms count too ("Discounts:", "Coupons").
        row.range(of: #"(?i)(?<![\p{L}])(?:"# + alternation(words) + #")(?:e?s)?(?![\p{L}])"#, options: .regularExpression) != nil
    }
}
