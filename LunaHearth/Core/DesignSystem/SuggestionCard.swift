import SwiftUI

/// The one review card for every suggestion in the app: what the person (or the bill) wrote,
/// what is suggested and where it came from, then Accept or Keep. Nothing changes until Accept.
///
///     On bill   NICHOLS RSTD PIST F
///     AI says   Nichols roasted pistachios
///     [ Accept AI ]  [ Keep bill ]
struct SuggestionCard: View {
    /// Label for the original value, e.g. "On bill", "You typed".
    let originalLabel: String
    let original: String
    let suggestion: String
    let source: SuggestionSource
    /// Overrides `source.label` where a screen has a more precise word (receipts say "Decoded").
    var sourceLabel: String?
    /// A short caution under the values, e.g. "Confirm it is the same product."
    var note: String?
    var keepTitle = "Keep"
    /// Prefix for UI-test identifiers: "<id>.accept" and "<id>.keep".
    let accessibilityID: String
    let accept: () -> Void
    let keep: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Grid(alignment: .leadingFirstTextBaseline, horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    Text(originalLabel).font(.caption).foregroundStyle(.secondary)
                    Text(original).font(.caption.monospaced()).foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                GridRow {
                    Label(sourceLabel ?? source.label, systemImage: source == .ai ? "sparkles" : "checkmark.seal")
                        .labelStyle(SuggestionSourceLabelStyle())
                        .font(.caption).foregroundStyle(.secondary)
                    Text(suggestion).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            if let note {
                Text(note).font(.caption2).foregroundStyle(.secondary)
            }
            HStack(spacing: 10) {
                Button(action: accept) {
                    Text(source.acceptTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .accessibilityIdentifier("\(accessibilityID).accept")
                Button(action: keep) {
                    Text(keepTitle).frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .accessibilityIdentifier("\(accessibilityID).keep")
            }
            .controlSize(.regular).font(.subheadline.weight(.semibold))
            .frame(minHeight: 44)
        }
        .accessibilityElement(children: .contain)
    }
}

/// Text first so the column stays aligned; the symbol is a quiet hint of the source.
private struct SuggestionSourceLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 3) {
            configuration.title
            configuration.icon.imageScale(.small)
        }
    }
}
