import SwiftUI

struct AIStatusView: View {
    @Environment(\.scenePhase) private var scenePhase
    @State private var snapshot: AIStatusSnapshot?
    private let service: any AIStatusProviding = AppleAIStatusService()

    var body: some View {
        SettingsDetailPage(title: "AI Status", subtitle: "Know what’s running on your device.", symbol: "sparkles", accent: AppTheme.slate) {
            if let snapshot {
                SettingsDetailCard(title: "Apple Intelligence", symbol: "brain", accent: AppTheme.slate) {
                    Label(snapshot.availability.title, systemImage: snapshot.availability == .ready ? "checkmark.circle.fill" : "info.circle")
                        .font(.headline).accessibilityIdentifier("aiStatus.availability")
                    Text(snapshot.availability.guidance).font(.subheadline).foregroundStyle(.secondary)
                    Button("Refresh status", systemImage: "arrow.clockwise") { refresh() }
                        .frame(minHeight: 44).accessibilityIdentifier("aiStatus.refresh")
                    Text("Checked \(snapshot.checkedAt.formatted(date: .omitted, time: .shortened))").font(.caption).foregroundStyle(.secondary)
                }
                SettingsDetailCard(title: "Your device & model", symbol: "cpu", accent: AppTheme.plum) {
                    detail("Device", snapshot.device)
                    detail("Software", snapshot.system)
                    detail("Model family", "Apple on-device Foundation Model")
                    detail("Exact model revision", "Not exposed by Apple’s public API")
                    Text("Apple updates the model with software releases. A newer iPhone does not by itself identify a different model revision.")
                        .font(.footnote).foregroundStyle(.secondary)
                    DisclosureGroup("Technical details") {
                        detail("Hardware identifier", snapshot.hardware)
                        detail("App model selection", "SystemLanguageModel.default")
                        Text("The hardware identifier is Apple’s internal device code, not the retail iPhone generation.").font(.caption).foregroundStyle(.secondary)
                    }.font(.subheadline)
                }
                SettingsDetailCard(title: "Pantry photos & receipts", symbol: "camera.viewfinder", accent: AppTheme.sage) {
                    Label(snapshot.pantryMode, systemImage: snapshot.imageAIReady ? "sparkles" : "text.viewfinder")
                        .font(.headline).accessibilityIdentifier("aiStatus.pantryMode")
                    Text(snapshot.imageAIReady
                        ? "Kitchen photos can use on-device image AI. If it fails, the scan falls back to readable product labels. Every suggestion needs review."
                        : "Kitchen photos use readable product labels. Full photo AI needs iOS 27, available Apple Intelligence and image-input support. You can always add missed items manually.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("Receipts use Apple Vision to read text. AI name decoding is optional when the text model is available.")
                        .font(.subheadline).foregroundStyle(.secondary)
                    Text("This shows current capability, not the result of your last scan. Each scan tells you which method it used.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
                SettingsDetailCard(title: "Review AI results", symbol: "exclamationmark.triangle", accent: AppTheme.clay) {
                    Text("On-device processing does not guarantee accuracy. AI can misidentify products, miss details or suggest unsuitable ingredients. Review results before saving or acting on them. LunaHearth does not verify food safety or allergens.").font(.subheadline)
                }
                SettingsDetailCard(title: "Private by design", symbol: "lock.shield", accent: AppTheme.sage) {
                    Text("LunaHearth uses on-device AI. Cloud AI and Private Cloud Compute are not used.").font(.subheadline)
                    Text("Checking status does not send photos or household data, run a model prompt, or enable Apple Intelligence. Your optional iCloud household sync is separate.")
                        .font(.footnote).foregroundStyle(.secondary)
                }
            } else { ProgressView("Checking this device…") }
        }
        .task { refresh() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { refresh() } }
    }
    private func refresh() { snapshot = service.status() }
    private func detail(_ title: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.subheadline.weight(.medium)).textSelection(.enabled)
        }.frame(maxWidth: .infinity, alignment: .leading).accessibilityElement(children: .combine)
    }
}
