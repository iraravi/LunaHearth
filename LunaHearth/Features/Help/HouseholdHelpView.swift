import SwiftUI

struct HouseholdHelpView: View {
    let topic: HouseholdHelpTopic
    @Environment(\.dynamicTypeSize) private var typeSize

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if !typeSize.isAccessibilitySize {
                    HearthArtwork(name: topic.artwork, height: 160).accessibilityHidden(true)
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(topic.title).font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                    Text(topic.subtitle).font(.subheadline).foregroundStyle(.secondary)
                }
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(Array(topic.steps.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 14) {
                            Image(systemName: step.symbol).font(.title3)
                                .foregroundStyle(AppTheme.sage).frame(width: 44, height: 44)
                                .background(AppTheme.sage.opacity(0.1), in: RoundedRectangle(cornerRadius: 13))
                                .accessibilityHidden(true)
                            VStack(alignment: .leading, spacing: 7) {
                                Text("\(index + 1). \(step.title)").font(.headline)
                                Text(step.detail).font(.subheadline).foregroundStyle(.secondary)
                            }.fixedSize(horizontal: false, vertical: true)
                        }.padding(18).accessibilityElement(children: .combine)
                        if index < topic.steps.count - 1 { Divider().padding(.horizontal, 18) }
                    }
                }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                if let article = HouseholdSupportArticle.all.first(where: { $0.id == topic.rawValue || (topic == .family && $0.id == "invite") || (topic == .receipts && $0.id == "receipt") }) {
                    NavigationLink { HouseholdSupportArticleView(article: article) } label: {
                        Label("Need help? Troubleshoot this feature", systemImage: "questionmark.circle")
                            .font(.subheadline.weight(.medium)).frame(minHeight: 44)
                    }.accessibilityIdentifier("help.troubleshoot.\(topic.rawValue)")
                }
                Text(topic.note).font(.footnote).foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }.padding(20).frame(maxWidth: 680).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).tint(AppTheme.sage)
            .navigationTitle("Quick guide").navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("help.guide.\(topic.rawValue)")
    }
}

private struct ScreenHelpModifier: ViewModifier {
    let topic: HouseholdHelpTopic
    @State private var showing = false
    func body(content: Content) -> some View {
        content.toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button { showing = true } label: {
                    Image(systemName: "questionmark.circle").frame(minWidth: 44, minHeight: 44)
                }.accessibilityLabel("Help: \(topic.title)")
                    .accessibilityIdentifier("help.open.\(topic.rawValue)")
            }
        }.sheet(isPresented: $showing) {
            NavigationStack {
                HouseholdHelpView(topic: topic)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Done") { showing = false }.accessibilityIdentifier("help.done")
                        }
                    }
            }.presentationDetents([.large])
        }
    }
}

extension View {
    func householdHelp(_ topic: HouseholdHelpTopic) -> some View {
        modifier(ScreenHelpModifier(topic: topic))
    }
}

struct HouseholdHelpCenter: View {
    @Environment(PublicConfigurationStore.self) private var publishedContent
    @Environment(LocalHouseholdRepository.self) private var repository
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var search = ""
    @State private var walkthrough = false
    private var topics: [HouseholdHelpTopic] { HouseholdHelpTopic.allCases.filter { $0.matches(search) } }
    private var articles: [HouseholdSupportArticle] { HouseholdSupportArticle.all.filter { $0.matches(search) } }
    private var answers: [HouseholdHelpAnswer] { HouseholdHelpAnswer.all.filter { $0.matches(search) } }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                if search.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    HearthEditorialHeader(eyebrow: "A LITTLE GUIDANCE", title: "Make yourself at home.",
                                          subtitle: "Short guides, whenever you need them.", artwork: "WelcomeResidence")
                    VStack(alignment: .leading, spacing: 12) {
                        if let home = repository.household?.id {
                            NavigationLink { HomeSetupGuideView(householdID: home) } label: {
                                Label("Your setup checklist", systemImage: "checklist").frame(minHeight: 44)
                            }.accessibilityIdentifier("help.setup")
                        }
                        Button("Replay the introduction", systemImage: "play.rectangle") { walkthrough = true }
                            .frame(minHeight: 44).accessibilityIdentifier("help.replay")
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                }
                if let config = publishedContent.configuration, config.expiresAt > .now,
                   let guidance = config.helpText, !guidance.isEmpty,
                   search.isEmpty || guidance.localizedCaseInsensitiveContains(search) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Latest guidance").font(.headline).accessibilityAddTraits(.isHeader)
                        Text(guidance).font(.body).fixedSize(horizontal: false, vertical: true)
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                        .accessibilityIdentifier("help.publishedGuidance")
                }
                if !topics.isEmpty {
                    Text("Explore a guide").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                    LazyVGrid(columns: typeSize.isAccessibilitySize ? [GridItem(.flexible())] : [GridItem(.adaptive(minimum: 280), spacing: 14)], spacing: 14) {
                        ForEach(topics) { topic in
                            NavigationLink { HouseholdHelpView(topic: topic) } label: {
                                HStack(alignment: .top, spacing: 12) {
                                    Image(systemName: topic.symbol).font(.title3).foregroundStyle(AppTheme.sage)
                                        .frame(width: 28).accessibilityHidden(true)
                                    VStack(alignment: .leading, spacing: 6) {
                                        Text(topic.title).font(.headline)
                                        Text(topic.subtitle).font(.subheadline).foregroundStyle(.secondary)
                                    }.fixedSize(horizontal: false, vertical: true)
                                    Spacer(minLength: 0)
                                    Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
                                }.padding(18).frame(maxWidth: .infinity, minHeight: 100, maxHeight: .infinity, alignment: .topLeading)
                                    .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18)).contentShape(Rectangle())
                            }.buttonStyle(.plain).accessibilityIdentifier("help.topic.\(topic.rawValue)")
                        }
                    }
                }
                ForEach(HouseholdSupportArticle.Category.allCases, id: \.rawValue) { category in
                    let matches = articles.filter { $0.category == category }
                    if !matches.isEmpty {
                        Text(category.title).font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                        VStack(spacing: 0) {
                            ForEach(matches) { article in
                                NavigationLink { HouseholdSupportArticleView(article: article) } label: {
                                    HStack(spacing: 12) {
                                        Image(systemName: article.symbol).foregroundStyle(AppTheme.sage).accessibilityHidden(true)
                                        Text(article.title).font(.body).multilineTextAlignment(.leading)
                                        Spacer(minLength: 8)
                                        Image(systemName: "chevron.right").font(.caption).accessibilityHidden(true)
                                    }.frame(minHeight: 44).padding(16).contentShape(Rectangle())
                                }.buttonStyle(.plain).accessibilityIdentifier("help.article.\(article.id)")
                                if article.id != matches.last?.id { Divider().padding(.horizontal, 16) }
                            }
                        }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                    }
                }
                if !answers.isEmpty {
                    Text("Common questions").font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                    VStack(spacing: 0) {
                        ForEach(answers) { answer in
                            DisclosureGroup {
                                Text(answer.answer).font(.subheadline).foregroundStyle(.secondary)
                                    .fixedSize(horizontal: false, vertical: true).padding(.vertical, 12)
                            } label: {
                                Text(answer.question).font(.subheadline.weight(.medium))
                                    .frame(minHeight: 44, alignment: .leading)
                            }.padding(.horizontal, 18).padding(.vertical, 6)
                                .accessibilityIdentifier("help.answer.\(answer.id)")
                        }
                    }.background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
                }
                if topics.isEmpty && answers.isEmpty && articles.isEmpty {
                    ContentUnavailableView.search(text: search)
                    Button("Show all guides") { search = "" }.frame(minHeight: 44)
                }
            }.padding(20).frame(maxWidth: 940).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).tint(AppTheme.sage)
            .navigationTitle("Help & guides").navigationBarTitleDisplayMode(.inline)
            .searchable(text: $search, placement: .navigationBarDrawer(displayMode: .always), prompt: "Search guides and questions")
            .sheet(isPresented: $walkthrough) {
                HowItWorksView(hasHome: repository.household != nil, replay: true) { walkthrough = false }
            }
    }
}


struct HouseholdSupportArticleView: View {
    let article: HouseholdSupportArticle
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                Label(article.category.title, systemImage: article.symbol).font(.subheadline).foregroundStyle(AppTheme.sage)
                Text(article.title).font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                ForEach(Array(article.steps.enumerated()), id: \.offset) { index, step in
                    VStack(alignment: .leading, spacing: 8) {
                        Text("\(index + 1). \(step.title)").font(.headline).accessibilityAddTraits(.isHeader)
                        Text(step.detail).font(.body).textSelection(.enabled).fixedSize(horizontal: false, vertical: true)
                    }.padding(18).frame(maxWidth: .infinity, alignment: .leading)
                        .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 18))
                }
                if article.category == .legal {
                    NavigationLink("Read the privacy policy") { PrivacyPolicyView() }.frame(minHeight: 44)
                    if let url = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                        Link("Apple standard app licence (opens website)", destination: url).frame(minHeight: 44)
                    }
                }
                Text("Offline guide · Updated September 30, 2026").font(.footnote).foregroundStyle(.secondary)
            }.padding(20).frame(maxWidth: 720).frame(maxWidth: .infinity)
        }.background(AppTheme.canvas).tint(AppTheme.sage)
            .navigationTitle(article.category.title).navigationBarTitleDisplayMode(.inline)
            .accessibilityIdentifier("help.articleDetail.\(article.id)")
    }
}
