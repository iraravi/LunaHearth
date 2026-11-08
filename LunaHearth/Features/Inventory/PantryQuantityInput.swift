import SwiftUI

struct PantryQuantityInput: View {
    @Binding var amount: String
    @Binding var unit: PantryUnit?
    @Binding var custom: String
    @FocusState.Binding var focused: Bool
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Picker("Unit", selection: $unit) {
                Text("Unmeasured").tag(nil as PantryUnit?)
                ForEach(PantryUnit.allCases) { Text($0.label).tag(Optional($0)) }
            }.accessibilityIdentifier("inventory.amountUnit")
            if unit != nil {
                LabeledContent("Amount remaining") { TextField("Not set", text: $amount).keyboardType(.decimalPad).focused($focused).multilineTextAlignment(.trailing).accessibilityLabel("Amount remaining").accessibilityIdentifier("inventory.measuredAmount") }
                Text("Optional. Leave blank if unknown; enter 0 only for an empty pack. Use a decimal such as 1.5.").font(.footnote).foregroundStyle(.secondary)
            } else {
                TextField("Amount · e.g. half a bag", text: $custom).focused($focused).accessibilityIdentifier("inventory.quantity")
            }
        }
    }
}
