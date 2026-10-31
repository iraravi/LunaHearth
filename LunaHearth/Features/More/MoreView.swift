import SwiftUI

struct MoreView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.colorScheme) private var colorScheme

    private var canvas: Color {
        AppTheme.canvas
    }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 820 && !typeSize.isAccessibilitySize
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        hero(wide: wide)
                        if wide {
                            HStack(alignment: .top, spacing: 24) {
                                VStack(spacing: 24) { household; connections }
                                VStack(spacing: 24) { settings }
                            }
                        } else {
                            household
                            connections
                            settings
                        }
                        Label("Your home. Your privacy.", systemImage: "lock")
                            .font(.footnote).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity).padding(.top, 4)
                        Text("Nam Illam · NeuralLuna").font(.caption2).foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }.frame(maxWidth: 1060).padding(.horizontal, wide ? 32 : 20).padding(.vertical, 20)
                        .frame(maxWidth: .infinity)
                }.accessibilityIdentifier("more.content")
            }.background(canvas).foregroundStyle(.primary).tint(.primary)
                .navigationTitle("More").navigationBarTitleDisplayMode(.inline)
        }
    }

    private func hero(wide: Bool) -> some View {
        Group {
            if typeSize.isAccessibilitySize {
                introduction
            } else {
                HStack(spacing: 16) {
                    introduction.frame(maxWidth: .infinity, alignment: .leading)
                    Image("WelcomeResidence").resizable().scaledToFill()
                        .frame(width: wide ? 220 : 84, height: wide ? 120 : 96)
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)
                }
            }
        }.padding(20)
            .background(AppTheme.sage.opacity(colorScheme == .dark ? 0.13 : 0.065), in: RoundedRectangle(cornerRadius: 20))
    }
    private var introduction: some View {
        VStack(alignment: .leading, spacing: 9) {
            Text("YOUR HOUSEHOLD").font(.caption2.weight(.semibold)).tracking(1.5).foregroundStyle(.secondary)
            Text(repository.household?.name ?? "Make yourself at home")
                .font(AppTheme.sectionTitle).fixedSize(horizontal: false, vertical: true)
            Text("People, settings & privacy.")
                .font(.subheadline).foregroundStyle(.secondary).fixedSize(horizontal: false, vertical: true)
        }
    }
    private var household: some View {
        MoreSection(title: "Your home") {
            NavigationLink { HouseholdHelpCenter() } label: {
                MoreDestinationRow(title: "Help & guides", detail: "Quick guides, setup & common questions", symbol: "questionmark.circle", accent: AppTheme.sage)
            }.accessibilityIdentifier("more.help")
            MoreDivider()
            NavigationLink { FamilyView() } label: {
                MoreDestinationRow(title: "Family", detail: "Invite someone · people & access", symbol: "person.2.fill", accent: AppTheme.slate)
            }.accessibilityIdentifier("more.family")
        }
    }
    private var connections: some View {
        MoreSection(title: "Connected to Apple") {
            NavigationLink { ConnectionsView() } label: {
                MoreDestinationRow(title: "Apple connections", detail: "Reminders & Calendar", symbol: "app.connected.to.app.below.fill", accent: AppTheme.slate)
            }.accessibilityIdentifier("more.connections")
        }
    }
    private var settings: some View {
        MoreSection(title: "Settings") {
            NavigationLink { AIStatusView() } label: {
                MoreDestinationRow(title: "AI Status", detail: "On-device model & photo recognition", symbol: "sparkles", accent: AppTheme.slate)
            }.accessibilityIdentifier("more.aiStatus")
            MoreDivider()
            NavigationLink { MorePreferencesView() } label: {
                MoreDestinationRow(title: "Preferences", detail: "Alerts & getting started", symbol: "slider.horizontal.3", accent: AppTheme.plum)
            }.accessibilityIdentifier("more.preferences")
            MoreDivider()
            NavigationLink { MorePrivacyView() } label: {
                MoreDestinationRow(title: "Privacy & data", detail: "iCloud sync, backups & storage", symbol: "hand.raised", accent: AppTheme.sage)
            }.accessibilityIdentifier("more.privacy")
        }
    }

}

private struct MoreSection<Content: View>: View {
    let title: String
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title).font(.subheadline.weight(.semibold)).padding(.horizontal, 4)
                .accessibilityAddTraits(.isHeader)
            VStack(spacing: 0) { content }
                .buttonStyle(.plain)
                .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
        }.frame(maxWidth: .infinity, alignment: .topLeading)
    }
}
private struct MoreSymbol: View {
    let symbol: String
    let accent: Color
    var body: some View {
        Image(systemName: symbol).font(.system(size: 21, weight: .medium))
            .foregroundStyle(accent).frame(width: 44, height: 44)
            .background(accent.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
            .accessibilityHidden(true)
    }
}
private struct MoreDestinationRow: View {
    let title: String
    let detail: String
    let symbol: String
    let accent: Color
    var body: some View {
        HStack(spacing: 14) {
            MoreSymbol(symbol: symbol, accent: accent)
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.subheadline.weight(.semibold)).foregroundStyle(.primary)
                Text(detail).font(.caption).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 4)
            Image(systemName: "chevron.right").font(.caption.weight(.semibold)).foregroundStyle(.tertiary).accessibilityHidden(true)
        }.padding(16).frame(maxWidth: .infinity, minHeight: 60, alignment: .leading).contentShape(Rectangle())
            .accessibilityElement(children: .combine)
    }
}
private struct MoreDivider: View {
    var body: some View { Divider().padding(.leading, 74).padding(.trailing, 16) }
}
private struct MorePreferencesView: View {
    @Environment(LocalHouseholdRepository.self) private var repository
    @AppStorage("warranty.horizon") private var horizon = 30
    @State private var showingTour = false
    @State private var confirmReset = false
    @State private var error: String?
    var body: some View {
        SettingsDetailPage(title: "Preferences", subtitle: "Small choices for a calmer home.", symbol: "slider.horizontal.3", accent: AppTheme.plum) {
            SettingsDetailCard(title: "Warranty alerts", symbol: "bell.badge", accent: AppTheme.plum) {
                Text("Show expiring warranties this far ahead.").font(.subheadline).foregroundStyle(.secondary)
                Picker("Remind me before expiry", selection: $horizon) {
                    ForEach([7, 30, 60], id: \.self) { Text("\($0) days").tag($0) }
                }.pickerStyle(.menu).accessibilityIdentifier("more.warrantyHorizon")
                    .frame(minHeight: 44)
            }
            SettingsDetailCard(title: "Getting started", symbol: "sparkles", accent: AppTheme.clay) {
                Text("Explore the ways your household connects.").font(.subheadline).foregroundStyle(.secondary)
                if let homeID = repository.household?.id {
                    NavigationLink { HomeSetupGuideView(householdID: homeID) } label: {
                        Label("Step-by-step setup", systemImage: "checklist").frame(minHeight: 44)
                    }.accessibilityIdentifier("more.setupGuide")
                }
                Button("Take a look around", systemImage: "arrow.up.forward") { showingTour = true }
                    .frame(minHeight: 44).accessibilityIdentifier("more.welcome")
            }
            #if DEBUG
            SettingsDetailCard(title: "Developer tools", symbol: "hammer", accent: .gray) {
                Button("Reset Local Household", role: .destructive) { confirmReset = true }.frame(minHeight: 44)
            }
            #endif
        }.saveError($error)
            .sheet(isPresented: $showingTour) { OnboardingView(isTour: true) }
            .confirmationDialog("Delete all household records on this device? This cannot be undone.", isPresented: $confirmReset, titleVisibility: .visible) {
                #if DEBUG
                Button("Delete Local Household", role: .destructive) {
                    do { try repository.resetLocalData() } catch { self.error = userFacingError(error) }
                }
                #endif
            }
    }
}
private struct MorePrivacyView: View {
    var body: some View {
        SettingsDetailPage(title: "Privacy & data", subtitle: "Your home, stored on your terms.", symbol: "hand.raised.fill", accent: AppTheme.sage) {
            NavigationLink { PrivacyPolicyView() } label: {
                MoreDestinationRow(title: "Privacy policy", detail: "Read the privacy policy", symbol: "doc.text", accent: AppTheme.sage)
            }.accessibilityIdentifier("more.privacyPolicy")
            if let article = HouseholdSupportArticle.all.first(where: { $0.id == "use" }) {
            NavigationLink { HouseholdSupportArticleView(article: article) } label: {
                MoreDestinationRow(title: "Important information", detail: "AI, safety and product limitations", symbol: "doc.text.magnifyingglass", accent: AppTheme.sage)
            }.accessibilityIdentifier("more.responsibleUse")
            }
            SettingsDetailCard(title: "Your home works offline", symbol: "iphone", accent: AppTheme.sage) {
                Text("Your household is saved on this device. No Nam Illam account or tracking is required.")
                    .font(.subheadline).foregroundStyle(.secondary)
            }
            SettingsDetailCard(title: "iCloud sync", symbol: "icloud", accent: AppTheme.slate) {
                Text("Optional sharing uses Apple CloudKit and the owner’s iCloud storage. Participants can access shared records according to their permissions. Sync needs connectivity and may be delayed.")
                    .font(.subheadline).foregroundStyle(.secondary)
                NavigationLink { HouseholdSharingView() } label: {
                    Label("Sync & recovery", systemImage: "arrow.right").frame(minHeight: 44)
                }.accessibilityIdentifier("more.sync")
            }
            SettingsDetailCard(title: "Backups", symbol: "clock.arrow.circlepath", accent: AppTheme.slate) {
                Text("Save a private snapshot to restore later. Backups are separate from live family sync.")
                    .font(.subheadline).foregroundStyle(.secondary)
                NavigationLink { BackupView() } label: {
                    Label("Manage backups", systemImage: "arrow.right").frame(minHeight: 44)
                }.accessibilityIdentifier("more.backup")
            }
            SettingsDetailCard(title: "Data controls", symbol: "externaldrive", accent: AppTheme.clay) {
                Text("Choose which records to clear, then review and confirm your choice. Backups, exports and copies already received by others may remain.")
                    .font(.subheadline).foregroundStyle(.secondary)
                NavigationLink { DangerZoneView() } label: {
                    Label("Clear household data", systemImage: "trash").frame(minHeight: 44)
                }.accessibilityIdentifier("more.dangerZone")
            }
        }
    }
}

/// Shared visual treatment for More's secondary screens; no persistence or permission behavior.
struct SettingsDetailPage<Content: View>: View {
    let title: String
    let subtitle: String
    let symbol: String
    let accent: Color
    @ViewBuilder var content: Content
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var textSize
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if !textSize.isAccessibilitySize {
                    HStack(alignment: .top, spacing: 16) {
                    Image(systemName: symbol).font(.title).foregroundStyle(accent)
                        .frame(width: 56, height: 56).background(accent.opacity(0.12), in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityHidden(true)
                    Text(subtitle).font(.title3.weight(.semibold)).fixedSize(horizontal: false, vertical: true)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }.padding(20).background(accent.opacity(0.07), in: RoundedRectangle(cornerRadius: 18))
                }
                content
            }.padding(20).frame(maxWidth: 760).frame(maxWidth: .infinity)
        }
        .background(AppTheme.canvas)
        .tint(accent).foregroundStyle(.primary)
        .navigationTitle(title).navigationBarTitleDisplayMode(.inline)
    }
}

struct SettingsDetailCard<Content: View>: View {
    let title: String
    let symbol: String
    let accent: Color
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 10) {
                Image(systemName: symbol).foregroundStyle(accent).accessibilityHidden(true)
                Text(title).foregroundStyle(.primary)
            }.font(.headline).accessibilityElement(children: .combine).accessibilityAddTraits(.isHeader)
            content
        }.frame(maxWidth: .infinity, alignment: .leading).padding(20)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
    }
}
