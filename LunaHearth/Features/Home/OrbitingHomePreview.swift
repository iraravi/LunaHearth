import SwiftUI

struct OrbitingHomePreview: View {
    let rooms: [LayoutRoom]
    @Binding var angle: Double
    @Binding var elevation: Double
    var selectedID: UUID?
    @GestureState private var translation = CGSize.zero

    private var camera: LayoutCamera {
        LayoutCamera(azimuth: angle, elevation: elevation)
            .rotated(horizontal: translation.width * 0.7, vertical: -translation.height * 0.3)
    }

    var body: some View {
        HomeLayoutPreview(rooms: rooms, is3D: true, angle: camera.azimuth,
                          elevation: camera.elevation, selectedID: selectedID)
            .contentShape(Rectangle())
            .highPriorityGesture(DragGesture(minimumDistance: 5)
                .updating($translation) { gesture, state, _ in state = gesture.translation }
                .onEnded { gesture in
                    let result = LayoutCamera(azimuth: angle, elevation: elevation)
                        .rotated(horizontal: gesture.translation.width * 0.7, vertical: -gesture.translation.height * 0.3)
                    angle = result.azimuth
                    elevation = result.elevation
                })
            .accessibilityElement(children: .ignore)
            .accessibilityLabel("3D home, drag to rotate")
            .accessibilityValue("Angle \(Int(camera.azimuth)) degrees, tilt \(Int(camera.elevation)) degrees")
            .accessibilityAdjustableAction { direction in rotate(horizontal: direction == .increment ? 15 : -15, vertical: 0) }
            .accessibilityAction(named: "Tilt up") { rotate(horizontal: 0, vertical: 10) }
            .accessibilityAction(named: "Tilt down") { rotate(horizontal: 0, vertical: -10) }
            .accessibilityIdentifier("layout.orbit")
    }

    private func rotate(horizontal: Double, vertical: Double) {
        let result = LayoutCamera(azimuth: angle, elevation: elevation).rotated(horizontal: horizontal, vertical: vertical)
        angle = result.azimuth
        elevation = result.elevation
    }
}
