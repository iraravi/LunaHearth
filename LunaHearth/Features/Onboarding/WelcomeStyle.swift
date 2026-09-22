import SwiftUI

/// Quiet editorial styling for the introduction and home setup journey.
enum WelcomeStyle {
    static let canvas = Color("WelcomeCanvas")
    static let ink = Color("WelcomeInk")
    static let muted = Color("WelcomeMuted")
    static let accent = Color("WelcomeAccent")
    static let surface = Color("WelcomeSurface")
    static let heading = Font.system(.largeTitle, design: .serif, weight: .regular)
}

struct WelcomePhotograph: View {
    let name: String
    var height: CGFloat = 240
    var body: some View {
        GeometryReader { geometry in
            Image(name).resizable().scaledToFill()
                .frame(width: geometry.size.width, height: height).clipped()
        }.frame(height: height).clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityHidden(true)
    }
}
