import SwiftUI

/// Offline learning only. No household records or services are changed by this tour.
struct HowItWorksView: View {
    let hasHome: Bool
    var replay = false
    let onFinish: () -> Void
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var page = 0
    @AccessibilityFocusState private var titleFocused: Bool

    private var chapter: WelcomeChapter { WelcomeChapter.allCases[page] }
    var body: some View {
        NavigationStack {
            GeometryReader { geometry in
                let wide = geometry.size.width >= 800 && !textSize.isAccessibilitySize
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: wide ? 32 : 22) {
                            Color.clear.frame(height: 0).id("tour.top").accessibilityHidden(true)
                            if !textSize.isAccessibilitySize {
                                Text("A MORE CONSIDERED EVERYDAY")
                                    .font(.caption2.weight(.medium)).tracking(2.4)
                                    .foregroundStyle(WelcomeStyle.muted)
                            }
                            if wide {
                                HStack(alignment: .center, spacing: 44) {
                                    WelcomePhotograph(name: chapter.art, height: 430)
                                        .frame(maxWidth: .infinity)
                                    story.frame(maxWidth: .infinity)
                                }
                            } else {
                                if !textSize.isAccessibilitySize {
                                    WelcomePhotograph(name: chapter.art, height: geometry.size.height < 660 ? 170 : 210)
                                }
                                story
                            }
                            chapterNavigation
                            Text("A guide only. Nothing is added until you choose to save it.")
                                .font(.caption).foregroundStyle(WelcomeStyle.muted)
                        }.padding(.horizontal, wide ? 36 : 24).padding(.top, 18).padding(.bottom, 20)
                            .frame(maxWidth: 1080).frame(maxWidth: .infinity)
                    }.onChange(of: page) { _, _ in proxy.scrollTo("tour.top", anchor: .top) }
                }
            }
            .background(WelcomeStyle.canvas)
            .foregroundStyle(WelcomeStyle.ink)
            .navigationTitle("Nam Illam")
            .navigationBarTitleDisplayMode(.inline)
            .hearthNavigationMaterial(WelcomeStyle.canvas, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(replay ? "Close" : "Skip", action: onFinish)
                        .accessibilityLabel(replay ? "Close guide" : "Skip tour")
                        .frame(minHeight: 44).accessibilityIdentifier("tour.skip")
                }
            }
            .safeAreaInset(edge: .bottom) { controls }
        }.tint(WelcomeStyle.ink)
    }

    private var story: some View {
        VStack(alignment: .leading, spacing: 18) {
            Text(chapter.shortTitle.uppercased()).font(.caption.weight(.medium)).tracking(2)
                .foregroundStyle(WelcomeStyle.accent)
            Text(chapter.title).font(textSize.isAccessibilitySize ? .system(.title2, design: .serif) : WelcomeStyle.heading).fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader).accessibilityFocused($titleFocused)
                .accessibilityIdentifier("tour.title")
            Text(chapter.detail).font(.body).foregroundStyle(WelcomeStyle.muted)
                .lineSpacing(3).fixedSize(horizontal: false, vertical: true)
            if page > 0 {
                HStack(alignment: .top, spacing: 12) {
                    Image(systemName: chapter.symbol).font(.body.weight(.light))
                        .foregroundStyle(WelcomeStyle.accent).frame(width: 22).accessibilityHidden(true)
                    Text(chapter.action).font(.subheadline.weight(.medium)).fixedSize(horizontal: false, vertical: true)
                }.padding(.vertical, 4)
            }
            Divider().overlay(WelcomeStyle.muted.opacity(0.12))
            Text(chapter.note).font(.footnote).foregroundStyle(WelcomeStyle.muted)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var chapterNavigation: some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 24) {
                    ForEach(Array(WelcomeChapter.allCases.enumerated()), id: \.element) { index, item in
                        Button { go(to: index) } label: {
                            VStack(alignment: .leading, spacing: 9) {
                                Text(item.shortTitle).font(.subheadline.weight(page == index ? .semibold : .regular))
                                Rectangle().fill(page == index ? WelcomeStyle.accent : .clear).frame(height: 2)
                                    .animation(reduceMotion ? nil : .easeInOut(duration: 0.2), value: page)
                            }.foregroundStyle(page == index ? WelcomeStyle.ink : WelcomeStyle.muted)
                                .frame(minHeight: 44).contentShape(Rectangle())
                        }.buttonStyle(.plain).id(index)
                            .accessibilityLabel("Learn about \(item.shortTitle)")
                            .accessibilityAddTraits(page == index ? .isSelected : [])
                            .accessibilityIdentifier("tour.chapter.\(item.rawValue)")
                    }
                }
            }.onChange(of: page) { _, value in proxy.scrollTo(value, anchor: .center) }
        }
    }

    private var controls: some View {
        VStack(spacing: 0) {
            Divider()
            Group {
                if textSize.isAccessibilitySize {
                    VStack(spacing: 8) {
                        HStack { backAndProgress; Spacer(minLength: 0) }
                        nextButton
                    }
                } else {
                    HStack(spacing: 16) {
                        backAndProgress
                        Spacer(minLength: 8)
                        nextButton
                    }
                }
            }.padding(.horizontal, 24).padding(.vertical, 10).frame(maxWidth: 1080).frame(maxWidth: .infinity)
        }.background(WelcomeStyle.canvas)
    }
    @ViewBuilder private var backAndProgress: some View {
        if page > 0 {
            Button { go(to: page - 1) } label: {
                Image(systemName: "arrow.left").frame(width: 44, height: 44)
            }.accessibilityLabel("Previous chapter").accessibilityIdentifier("tour.back")
        }
        Text(String(format: "%02d / %02d", page + 1, WelcomeChapter.allCases.count))
            .font(.caption.monospacedDigit()).foregroundStyle(WelcomeStyle.muted)
            .accessibilityLabel("Step \(page + 1) of \(WelcomeChapter.allCases.count)")
    }
    private var nextButton: some View {
        Button {
            if page == WelcomeChapter.allCases.count - 1 { onFinish() } else { go(to: page + 1) }
        } label: {
            HStack(spacing: 12) {
                Text(page == 4 ? (replay ? "Done" : hasHome ? "Go to my home" : "Set up my home") : "Continue")
                    .fixedSize(horizontal: false, vertical: true)
                Image(systemName: "arrow.right").accessibilityHidden(true)
            }.font(.subheadline.weight(.medium)).padding(.horizontal, 18).padding(.vertical, 12)
                .frame(maxWidth: textSize.isAccessibilitySize ? .infinity : nil, minHeight: 44)
                .foregroundStyle(WelcomeStyle.canvas)
                .background(WelcomeStyle.ink, in: Capsule())
        }.buttonStyle(.plain).accessibilityIdentifier("tour.next")
    }
    private func go(to index: Int) {
        page = index
        titleFocused = true
    }
}

private enum WelcomeChapter: String, CaseIterable {
    case overview, receipt, shopping, pantry, meals
    var title: String {
        switch self {
        case .overview: "Welcome to a calmer home."
        case .receipt: "Every purchase,\nin its place."
        case .shopping: "A thoughtful list.\nAn easier shop."
        case .pantry: "A clear view of\nwhat’s at home."
        case .meals: "Turn what you have\ninto tomorrow’s plan."
        }
    }
    var detail: String {
        switch self {
        case .overview: "Your plans, purchases and pantry, quietly connected. Start with one small thing. Build the rest at your pace."
        case .receipt: "Scan a receipt. Review the items and total, then choose what goes into your pantry. Match purchases with your shopping list before saving."
        case .shopping: "Add what you need. When it’s bought, review the pantry update—or simply finish the purchase without adding stock."
        case .pantry: "Begin with a kitchen photo, a starter list or one item. Review what to add, then keep quantities and label dates up to date."
        case .meals: "Find ideas from your pantry, choose a style and save a plan. Send missing ingredients to your shopping list."
        }
    }
    var action: String {
        switch self {
        case .overview: "Begin at Home"
        case .receipt: "Home → Expenses → Scan receipt"
        case .shopping: "Home → Shopping"
        case .pantry: "Home → Groceries at home"
        case .meals: "Home → Meals · Optional 5 PM planning reminder"
        }
    }
    var note: String {
        switch self {
        case .overview: "Private by default. Works offline. iCloud sharing is your choice."
        case .receipt: "Scanning and AI can make mistakes. Check names, amounts and totals."
        case .shopping: "Amounts, stores and buyers are optional. You choose what updates your pantry."
        case .pantry: "Recorded dates are reminders. The app cannot verify food safety."
        case .meals: "Ideas, not recipes. Review ingredients and dietary needs. On-device AI is optional."
        }
    }
    var shortTitle: String { switch self { case .overview: "Welcome"; case .receipt: "Receipts"; case .shopping: "Shopping"; case .pantry: "Pantry"; case .meals: "Meals" } }
    var art: String { self == .overview ? "WelcomeResidence" : "WelcomeTable" }
    var symbol: String { switch self { case .overview: "house"; case .receipt: "receipt"; case .shopping: "basket"; case .pantry: "cabinet"; case .meals: "fork.knife" } }
}
