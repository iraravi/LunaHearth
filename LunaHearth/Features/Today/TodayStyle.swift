import SwiftUI

enum TodayTheme {
    static let canvas = Color("TodayCanvas")
    static let surface = Color("TodaySurface")
    static let ink = Color("TodayInk")
    static let muted = Color("TodayMuted")
    static let accent = Color("TodayAccent")
    static let hero = Color("TodayHero")
    static let brief = Color("TodayBrief")
}

struct TodayCard<Content: View>: View {
    @ViewBuilder var content: Content
    var body: some View {
        VStack(alignment: .leading, spacing: 14) { content }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading).padding(20)
            .background(TodayTheme.surface, in: RoundedRectangle(cornerRadius: 18))
            .hearthCardOutline(TodayTheme.ink)
    }
}

struct TodaySectionHeading: View {
    let title: String
    let symbol: String
    var body: some View {
        Label(title, systemImage: symbol).font(.headline).foregroundStyle(TodayTheme.ink)
    }
}

struct TodayHero: View {
    @Environment(\.dynamicTypeSize) private var typeSize
    let now: Date
    let household: String
    let wide: Bool
    var body: some View {
        HearthEditorialHeader(eyebrow: now.formatted(.dateTime.weekday(.wide).month(.abbreviated).day()),
                              title: "Your day, in focus.", subtitle: household, artwork: "WelcomeResidence")
            .accessibilityIdentifier("today.hero")
    }
}

struct TodayBriefCard: View {
    let facts: TodayBriefFacts
    @State private var brief: TodayBrief?
    @State private var requested = false
    @State private var running = false
    private let service: any TodayBriefService = OnDeviceTodayBriefService()

    var body: some View {
        VStack(alignment: .leading, spacing: 9) {
            HStack {
                Label("Your daily brief", systemImage: "sparkles").font(.subheadline.weight(.semibold))
                Spacer(minLength: 8)
                Button { requested = true } label: {
                    if running { ProgressView().accessibilityLabel("Summarizing") }
                    else { Text("Summarize").font(.caption.weight(.semibold)) }
                }.frame(minWidth: 44, minHeight: 44).buttonStyle(.plain)
                    .foregroundStyle(TodayTheme.accent).disabled(running)
                    .accessibilityIdentifier("today.summarize")
            }
            Text(brief?.text ?? facts.fallback).font(.subheadline).foregroundStyle(TodayTheme.muted)
                .fixedSize(horizontal: false, vertical: true).accessibilityIdentifier("today.briefText")
            if let brief {
                Text(brief.usedModel ? "AI overview may be wrong or incomplete. Check the saved records for details." : "Saved-list summary · On-device AI isn’t available right now.")
                    .font(.caption).foregroundStyle(TodayTheme.muted)
                    .accessibilityIdentifier("today.briefSource")
            }
        }.padding(.horizontal, 18).padding(.vertical, 10)
            .background(TodayTheme.brief, in: RoundedRectangle(cornerRadius: 20))
            .task(id: requested ? facts : nil) {
                guard requested else { return }
                running = true
                defer { running = false; requested = false }
                do {
                    let result = try await service.summarize(facts)
                    try Task.checkCancellation()
                    brief = result
                } catch { if !Task.isCancelled { brief = TodayBrief(text: facts.fallback, usedModel: false) } }
            }
            .onChange(of: facts) { _, _ in brief = nil; requested = false }
    }
}

/// Measures content first, then aligns card backgrounds without clipping Dynamic Type.
struct TodayAlignedCards: Layout {
    var columns: Int
    var spacing: CGFloat = 16
    private func metrics(_ width: CGFloat, _ subviews: Subviews) -> (CGFloat, [CGFloat]) {
        let count = max(1, columns)
        let cardWidth = max(0, (width - CGFloat(count - 1) * spacing) / CGFloat(count))
        var heights: [CGFloat] = []
        for index in subviews.indices {
            let row = index / count
            let height = subviews[index].sizeThatFits(.init(width: cardWidth, height: nil)).height
            if row == heights.count { heights.append(height) }
            else { heights[row] = max(heights[row], height) }
        }
        return (cardWidth, heights)
    }
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 700
        let (_, heights) = metrics(width, subviews)
        return .init(width: width, height: heights.reduce(0, +) + CGFloat(max(0, heights.count - 1)) * spacing)
    }
    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let (width, heights) = metrics(bounds.width, subviews)
        var y = bounds.minY
        for index in subviews.indices {
            let column = index % max(1, columns)
            let row = index / max(1, columns)
            if column == 0 && row > 0 { y += heights[row - 1] + spacing }
            subviews[index].place(at: .init(x: bounds.minX + CGFloat(column) * (width + spacing), y: y), anchor: .topLeading, proposal: .init(width: width, height: heights[row]))
        }
    }
}

struct TodayIllustratedHeading: View {
    let title: String
    let detail: String
    let art: String
    @Environment(\.dynamicTypeSize) private var typeSize
    var body: some View {
        HStack(spacing: 14) {
            VStack(alignment: .leading, spacing: 6) {
                Text(title).font(.title3.bold()).accessibilityAddTraits(.isHeader)
                Text(detail).font(.caption).foregroundStyle(TodayTheme.muted)
            }.frame(maxWidth: .infinity, alignment: .leading)
            if !typeSize.isAccessibilitySize {
                Image(art).resizable().scaledToFill().frame(width: 76, height: 76)
                    .clipped().clipShape(RoundedRectangle(cornerRadius: 16)).allowsHitTesting(false).accessibilityHidden(true)
            }
        }.padding(.bottom, 4)
    }
}
