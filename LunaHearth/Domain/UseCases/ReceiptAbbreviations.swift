import Foundation

/// Offline expansion of common printed grocery abbreviations ("RSTD" → Roasted, "PIST" → Pistachios).
/// Word-for-word only: unknown words stay as printed (brands such as NICHOLS become Nichols),
/// nothing is invented, and the result is a reviewed suggestion, never an automatic rename.
enum ReceiptAbbreviations {
    /// Trailing single-letter tax or food-stamp flags printed after the name ("PIST F", "MILK N").
    static let trailingFlags: Set<String> = ["F", "T", "N", "X", "O", "S"]

    /// Unambiguous receipt abbreviations. Leave out codes with two plausible meanings (WHT, SR, PPR).
    static let words: [String: String] = [
        // Preparation and qualifiers
        "ORG": "Organic", "ORGNC": "Organic", "RSTD": "Roasted", "RST": "Roasted", "RSTED": "Roasted",
        "SLTD": "Salted", "UNSLTD": "Unsalted", "UNSLT": "Unsalted", "NOSALT": "No-Salt", "LS": "Low Sodium",
        "UNSWT": "Unsweetened", "UNSWTND": "Unsweetened", "SWTND": "Sweetened", "SWT": "Sweet",
        "FRZ": "Frozen", "FRZN": "Frozen", "FRSH": "Fresh", "NAT": "Natural", "NATL": "Natural",
        "SHRD": "Shredded", "SHRDD": "Shredded", "SLCD": "Sliced", "SLC": "Sliced", "DCD": "Diced",
        "CHPD": "Chopped", "GRND": "Ground", "GRD": "Ground", "BNLS": "Boneless", "SKNLS": "Skinless",
        "SMKD": "Smoked", "CKD": "Cooked", "UNCKD": "Uncooked", "WHL": "Whole", "HLF": "Half",
        "LG": "Large", "LRG": "Large", "MED": "Medium", "SM": "Small", "SML": "Small", "XLG": "Extra Large",
        "LF": "Low Fat", "FF": "Fat Free", "RF": "Reduced Fat", "NF": "Nonfat", "LT": "Light", "LITE": "Light",
        "GF": "Gluten Free", "HVY": "Heavy", "SPCY": "Spicy", "MLD": "Mild", "XTRA": "Extra", "VRGN": "Virgin",
        "GRK": "Greek", "ITAL": "Italian", "MEX": "Mexican", "AMER": "American", "CLSC": "Classic", "ORIG": "Original",
        "GRN": "Green", "RD": "Red", "YLW": "Yellow", "YEL": "Yellow", "BLK": "Black", "BRN": "Brown", "WHTE": "White",
        // Dairy and eggs
        "MLK": "Milk", "YOG": "Yogurt", "YGRT": "Yogurt", "YOGRT": "Yogurt", "CHS": "Cheese", "CHSE": "Cheese",
        "CHED": "Cheddar", "CHEDR": "Cheddar", "MOZZ": "Mozzarella", "MOZZRL": "Mozzarella", "PARM": "Parmesan",
        "BTR": "Butter", "BUTR": "Butter", "CRM": "Cream", "CTG": "Cottage", "CRMR": "Creamer",
        // Meat and seafood
        "CHKN": "Chicken", "CHCKN": "Chicken", "CHIC": "Chicken", "BRST": "Breast", "THGH": "Thigh", "THGHS": "Thighs",
        "BF": "Beef", "TKY": "Turkey", "TRKY": "Turkey", "PRK": "Pork", "SSG": "Sausage", "SAUS": "Sausage",
        "SHRMP": "Shrimp", "SLMN": "Salmon", "TLPA": "Tilapia",
        // Produce
        "BAN": "Bananas", "BNNA": "Bananas", "BANANA": "Bananas", "APL": "Apple", "APPL": "Apple", "AVO": "Avocado",
        "AVOC": "Avocado", "STRWB": "Strawberries", "STRAWB": "Strawberries", "BLUEB": "Blueberries", "BLBRY": "Blueberries",
        "RASPB": "Raspberries", "RSPBRY": "Raspberries", "GRPS": "Grapes", "LMN": "Lemon", "LMNS": "Lemons",
        "LETT": "Lettuce", "LTTC": "Lettuce", "SPNCH": "Spinach", "CILN": "Cilantro", "CLNTR": "Cilantro",
        "CUC": "Cucumber", "CUCMBR": "Cucumber", "BROC": "Broccoli", "BRCLI": "Broccoli", "CRT": "Carrots", "CARR": "Carrots",
        "CRRT": "Carrots", "TOM": "Tomatoes", "TOMS": "Tomatoes", "TMTO": "Tomatoes", "POT": "Potatoes", "POTS": "Potatoes",
        "ONI": "Onions", "ONN": "Onions", "ONIN": "Onions", "GRLC": "Garlic", "GNGR": "Ginger", "MSHRM": "Mushrooms",
        "MUSH": "Mushrooms", "PEPR": "Peppers", "PEPRS": "Peppers", "JLPN": "Jalapeño", "VEG": "Vegetables", "VEGS": "Vegetables",
        // Nuts, snacks and pantry
        "PIST": "Pistachios", "PISTA": "Pistachios", "PSTC": "Pistachios", "ALM": "Almonds", "ALMD": "Almonds", "ALMDS": "Almonds",
        "CSHW": "Cashews", "CSHWS": "Cashews", "WLNT": "Walnuts", "WLNTS": "Walnuts", "PCN": "Pecans", "PNT": "Peanut",
        "PNUT": "Peanut", "PNTS": "Peanuts", "NTS": "Nuts", "MXD": "Mixed", "SNK": "Snack", "CHP": "Chips", "CHPS": "Chips",
        "CRKR": "Crackers", "CRKRS": "Crackers", "CKIE": "Cookies", "CKIES": "Cookies", "CHOC": "Chocolate", "CHOCO": "Chocolate",
        "VAN": "Vanilla", "VNLA": "Vanilla", "STRW": "Strawberry", "HNY": "Honey", "MPL": "Maple", "SYR": "Syrup",
        "CRL": "Cereal", "GRNL": "Granola", "PRTN": "Protein", "PWDR": "Powder", "BRD": "Bread", "TORT": "Tortillas",
        "TRTLA": "Tortillas", "FLR": "Flour", "SGR": "Sugar", "RCE": "Rice", "BSMT": "Basmati", "BASM": "Basmati",
        "PSTA": "Pasta", "SPAG": "Spaghetti", "SCE": "Sauce", "MRNR": "Marinara", "SLSA": "Salsa", "BNS": "Beans",
        "OLV": "Olive", "VEGT": "Vegetable", "SSNG": "Seasoning", "SPC": "Spice",
        // Drinks
        "JC": "Juice", "JCE": "Juice", "OJ": "Orange Juice", "WTR": "Water", "SPRKL": "Sparkling", "SPKLG": "Sparkling",
        "SDA": "Soda", "COF": "Coffee", "COFF": "Coffee", "BEV": "Beverage",
        // Packs and sizes
        "PK": "Pack", "CT": "Count", "DZ": "Dozen", "GAL": "Gallon", "QT": "Quart", "PT": "Pint", "BTL": "Bottle",
        "CN": "Can", "BX": "Box", "BG": "Bag",
        // Store brands whose printed code is unambiguous
        "GV": "Great Value", "KS": "Kirkland Signature"
    ]

    /// Plain words that only need readable case; they never count as a decoded abbreviation.
    private static let smallWords = ["NO": "No", "AND": "and", "OF": "of", "WITH": "with", "IN": "in", "FOR": "for"]

    private static let sizeUnits: Set<String> = ["OZ", "FZ", "LB", "LBS", "CT", "PK", "GAL", "ML", "L", "G", "KG", "QT", "PT"]

    /// Returns a readable name, or nil when nothing on the label is a known abbreviation.
    static func expand(_ label: String) -> String? {
        var tokens = label.split(whereSeparator: \.isWhitespace).map(String.init)
        // A short leading line number ("1 NICHOLS ...") is not part of the name.
        if tokens.count >= 2, tokens[0].count <= 3, tokens[0].allSatisfy(\.isNumber), tokens[1].contains(where: \.isLetter) {
            tokens.removeFirst()
        }
        if tokens.count >= 3, let last = tokens.last, trailingFlags.contains(last.uppercased()), last.count == 1 {
            tokens.removeLast()
        }
        guard !tokens.isEmpty else { return nil }
        var expandedWords = 0
        let output = tokens.map { token -> String in
            // Hyphenated parts are expanded separately ("NO-SALT", "CHKN-BRST").
            let parts = token.split(separator: "-", omittingEmptySubsequences: false).map { part -> String in
                let word = String(part)
                // Printed abbreviations are all caps; a typed "Instant Pot" must not become Potatoes.
                if word == word.uppercased(), let expansion = words[word.uppercased()] { expandedWords += 1; return expansion }
                return readable(word)
            }
            return parts.joined(separator: "-")
        }.joined(separator: " ")
        // Only suggest when a real abbreviation was decoded; tidying case alone is not a decode.
        guard expandedWords > 0 else { return nil }
        return output
    }

    /// Unknown words stay as printed, only easier to read: NICHOLS → Nichols, 12OZ → 12 oz.
    private static func readable(_ word: String) -> String {
        if let match = word.wholeMatch(of: /(?i)(\d+(?:\.\d+)?)([A-Z]+)/), sizeUnits.contains(String(match.2).uppercased()) {
            return "\(match.1) \(match.2.lowercased())"
        }
        if let small = smallWords[word.uppercased()] { return small }
        // Short all-caps words are usually brands or codes (HEB, BBQ); keep them as printed.
        guard word.count >= 4, word.allSatisfy(\.isLetter), word == word.uppercased() else { return word }
        return word.prefix(1).uppercased() + word.dropFirst().lowercased()
    }
}
