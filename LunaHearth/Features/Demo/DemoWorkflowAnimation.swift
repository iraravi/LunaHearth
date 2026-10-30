import SwiftUI

/// A presentation-only story. Never reads or changes household data.
struct DemoWorkflowAnimation: View {
    @Environment(\.accessibilityReduceMotion) private var systemReduceMotion
    private var reduceMotion: Bool { HearthMotion.reduced(systemReduceMotion) }
    @Environment(\.dynamicTypeSize) private var typeSize
    @Environment(\.scenePhase) private var scenePhase
    @State private var running = true
    @State private var scene = 0
    @State private var visible = false
    private let chapters = ["Receipt", "Spending", "Shopping", "Pantry", "Tomorrow"]
    private let titles = ["One receipt. A little less to do.", "A clear picture of your spending.", "Your list catches up with you.", "A place for everything you bought.", "Tomorrow starts with what’s here."]
    private let captions = [
        "Read the receipt and review the items.",
        "The receipt splits into an expense and purchased items.",
        "Bought items leave shopping; ingredients reach the pantry.",
        "Pack dates stay with the food you store.",
        "Your pantry becomes the starting point for tomorrow’s meals."
    ]
    private var playing: Bool { running && !reduceMotion && scenePhase == .active }
    private var artwork: String { scene == 4 ? "WelcomeTable" : scene == 3 ? "EditorialPantry" : "ShoppingShelvesFresh" }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Label("THE CONNECTED HOME", systemImage: "circle.hexagongrid")
                    .font(.caption.weight(.semibold)).tracking(1)
                Spacer()
                Text("0\(scene + 1) / 05").font(.caption.monospacedDigit())
            }.foregroundStyle(AppTheme.sage)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(chapters.indices, id: \.self) { index in
                        Button { running = false; changeScene(index) } label: {
                            Text(chapters[index]).font(.subheadline.weight(scene == index ? .semibold : .regular))
                                .padding(.horizontal, 14).frame(minHeight: 44)
                                .background(scene == index ? AppTheme.sage.opacity(0.14) : Color.clear, in: Capsule())
                        }.buttonStyle(.plain)
                            .accessibilityAddTraits(scene == index ? .isSelected : [])
                            .accessibilityLabel("Scene \(index + 1): \(chapters[index])")
                            .accessibilityIdentifier("demo.scene.\(index)")
                    }
                }
            }
            if !typeSize.isAccessibilitySize {
                GeometryReader { proxy in
                    ZStack(alignment: .bottomLeading) {
                        Image(artwork).resizable().scaledToFill()
                            .frame(width: proxy.size.width, height: 330).clipped()
                            .overlay(Color.black.opacity(0.12))
                            .id(artwork).transition(.opacity)
                        // Legible, opaque sample records over editorial photography.
                        sceneCard
                            .padding(18)
                            .frame(maxWidth: 330, alignment: .leading)
                            .offset(y: visible ? 0 : 24)
                            .opacity(visible ? 1 : 0)
                            .id(scene)
                            .transition(.asymmetric(insertion: .opacity.combined(with: .move(edge: .bottom)), removal: .opacity))
                    }.frame(width: proxy.size.width, height: 330)
                        .clipShape(RoundedRectangle(cornerRadius: 26))
                }.frame(height: 330).accessibilityHidden(true)
            }
            VStack(alignment: .leading, spacing: 10) {
                Text(titles[scene]).font(AppTheme.sectionTitle).accessibilityAddTraits(.isHeader)
                Text(captions[scene]).font(.body).foregroundStyle(.secondary)
                    .accessibilityIdentifier("demo.animationCaption")
                Text(scene == 0 ? "You check names, amounts and matches before anything is saved." : scene == 4 ? "Example ideas, not recipes. Ingredients and dietary needs still need your review." : "Illustrative sample · changes happen only after your review.")
                    .font(.footnote).foregroundStyle(.secondary)
            }.fixedSize(horizontal: false, vertical: true)
            HStack(spacing: 6) {
                ForEach(chapters.indices, id: \.self) { index in
                    Capsule().fill(index <= scene ? AppTheme.sage : AppTheme.sage.opacity(0.15)).frame(height: 3)
                }
            }.accessibilityHidden(true)
            HearthGlassControls {
                HStack(spacing: 12) {
                    Button(playing ? "Pause" : "Play", systemImage: playing ? "pause.fill" : "play.fill") {
                        running.toggle()
                    }.disabled(reduceMotion).frame(minHeight: 44).hearthGlassButton()
                        .accessibilityIdentifier("demo.play")
                    Button("Next scene", systemImage: "arrow.right") {
                        running = false; changeScene((scene + 1) % chapters.count)
                    }.frame(minHeight: 44).hearthGlassButton()
                        .accessibilityIdentifier("demo.next")
                }.font(.subheadline)
            }
            Text(reduceMotion ? "Reduce Motion is on. Choose a chapter or Next scene to explore." : "A gentle 25-second tour · pause or choose any chapter.")
                .font(.caption).foregroundStyle(.secondary)
        }
        .task(id: playing) {
            guard playing else { return }
            visible = true
            while !Task.isCancelled {
                do { try await Task.sleep(for: .seconds(5)) } catch { return }
                guard !Task.isCancelled else { return }
                changeScene((scene + 1) % chapters.count)
            }
        }
        .onAppear { visible = true }
        .onChange(of: scenePhase) { _, value in if value != .active { running = false } }
        .onChange(of: reduceMotion) { _, value in if value { running = false } }
        .onDisappear { running = false }
    }

    private func changeScene(_ next: Int) {
        withAnimation(reduceMotion ? nil : .smooth(duration: 0.8)) { scene = next; visible = true }
    }

    private var sceneCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(scene == 4 ? "TOMORROW · A SAMPLE IDEA" : "LUNA DEMO MARKET", systemImage: scene == 4 ? "sun.horizon" : "receipt")
                .font(.system(size: 10, weight: .semibold)).tracking(1).foregroundStyle(AppTheme.sage)
            switch scene {
            case 0:
                Text("The little details,\nready to review.").font(.system(size: 23, weight: .medium, design: .serif))
                sampleRow("Rice", value: "$5.00", symbol: "checkmark.circle")
                sampleRow("Curd", value: "$3.00", symbol: "checkmark.circle")
                Divider()
                Text("5 items · USD 16.00").font(.system(size: 13, weight: .semibold))
            case 1:
                Text("$16.00").font(.system(size: 42, weight: .medium, design: .serif))
                Text("One reviewed purchase").font(.system(size: 14)).foregroundStyle(.secondary)
                HStack(alignment: .bottom, spacing: 9) {
                    ForEach([28.0, 45, 35, 62, 48].indices, id: \.self) { i in
                        RoundedRectangle(cornerRadius: 5).fill(AppTheme.sage.opacity(i == 4 ? 0.9 : 0.22))
                            .frame(width: 28, height: [28.0, 45, 35, 62, 48][i])
                    }
                }.frame(height: 65)
                Text("Illustrative spending chart").font(.system(size: 10)).foregroundStyle(.secondary)
            case 2:
                Text("Five fewer things\nto remember.").font(.system(size: 23, weight: .medium, design: .serif))
                ForEach(["Rice", "Curd", "Carrots"], id: \.self) { name in
                    sampleRow(name, value: "Bought", symbol: "checkmark.circle.fill")
                }
            case 3:
                Text("Welcome to\nyour pantry.").font(.system(size: 23, weight: .medium, design: .serif))
                sampleRow("Curd", value: "Stock updated", symbol: "cabinet")
                sampleRow("Pack dates", value: "You choose", symbol: "calendar")
                Text("Review amounts, units and existing packs.").font(.system(size: 12)).foregroundStyle(.secondary)
            default:
                Text("Curd rice").font(.system(size: 29, weight: .medium, design: .serif))
                Text("A starting point from your pantry").font(.system(size: 13)).foregroundStyle(.secondary)
                sampleRow("Rice + curd", value: "At home", symbol: "checkmark.circle")
                Text("5 PM · time to plan tomorrow").font(.system(size: 12, weight: .medium))
            }
        }.padding(20).frame(maxWidth: .infinity, alignment: .leading)
            .background(AppTheme.surface, in: RoundedRectangle(cornerRadius: 20))
            .shadow(color: .black.opacity(0.12), radius: 18, y: 8)
    }
    private func sampleRow(_ title: String, value: String, symbol: String) -> some View {
        HStack {
            Image(systemName: symbol).foregroundStyle(AppTheme.sage)
            Text(title)
            Spacer(minLength: 4)
            Text(value).foregroundStyle(.secondary)
        }.font(.system(size: 12))
    }
}
