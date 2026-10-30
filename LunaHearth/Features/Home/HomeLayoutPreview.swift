import SwiftUI

/// A lightweight orthographic 3D cutaway built from the saved room dimensions.
/// No downloaded models or sensor access is required.
struct HomeLayoutPreview: View {
    let rooms: [LayoutRoom]
    var is3D = true
    var angle: Double = 35
    var elevation: Double = 35
    var selectedID: UUID?
    @ScaledMetric(relativeTo: .caption) private var labelSize = 11.0

    static func color(_ preset: RoomPreset) -> Color {
        switch preset {
        case .living: Color("IllustrationBlue")
        case .bedroom: Color("IllustrationPurple")
        case .kitchen: Color("IllustrationGreen")
        case .bathroom: Color.cyan
        case .office: Color("IllustrationCoral")
        case .other: Color("IllustrationOrange")
        }
    }

    var body: some View {
        Canvas { context, size in
            let rooms = rooms.filter { (try? $0.footprint.validate()) != nil }
            guard !rooms.isEmpty else { return }
            let radians = is3D ? angle * .pi / 180 : 0
            func project(_ x: Double, _ z: Double, _ y: Double = 0) -> CGPoint {
                CGPoint(x: x * cos(radians) - z * sin(radians),
                        y: (x * sin(radians) + z * cos(radians)) * (is3D ? sin(elevation * .pi / 180) : 1) - y * (is3D ? cos(elevation * .pi / 180) : 0))
            }
            let vertices = rooms.flatMap { room -> [CGPoint] in
                let r = room.footprint
                return [project(r.x, r.z), project(r.x + r.width, r.z),
                        project(r.x, r.z + r.depth), project(r.x + r.width, r.z + r.depth),
                        project(r.x, r.z, r.height), project(r.x + r.width, r.z, r.height),
                        project(r.x, r.z + r.depth, r.height), project(r.x + r.width, r.z + r.depth, r.height)]
            }
            let minX = vertices.map(\.x).min() ?? 0
            let maxX = vertices.map(\.x).max() ?? 1
            let minY = vertices.map(\.y).min() ?? 0
            let maxY = vertices.map(\.y).max() ?? 1
            let scale = min((size.width - 44) / max(maxX - minX, 1), (size.height - 44) / max(maxY - minY, 1))
            func point(_ x: Double, _ z: Double, _ y: Double = 0) -> CGPoint {
                let p = project(x, z, y)
                return CGPoint(x: (p.x - (minX + maxX) / 2) * scale + size.width / 2,
                               y: (p.y - (minY + maxY) / 2) * scale + size.height / 2)
            }
            func polygon(_ points: [CGPoint], fill: Color, stroke: Color = .white) {
                let path = Path { p in
                    guard let first = points.first else { return }
                    p.move(to: first)
                    for point in points.dropFirst() { p.addLine(to: point) }
                    p.closeSubpath()
                }
                context.fill(path, with: .color(fill))
                context.stroke(path, with: .color(stroke), lineWidth: 1.5)
            }
            let sorted = rooms.sorted {
                let a = $0.footprint, b = $1.footprint
                return (a.x + a.width / 2) * sin(radians) + (a.z + a.depth / 2) * cos(radians)
                    < (b.x + b.width / 2) * sin(radians) + (b.z + b.depth / 2) * cos(radians)
            }
            for room in sorted {
                let r = room.footprint, color = Self.color(room.preset)
                let x = r.x, z = r.z, w = r.width, d = r.depth, h = r.height
                polygon([point(x,z), point(x+w,z), point(x+w,z+d), point(x,z+d)],
                        fill: color.opacity(0.22), stroke: room.id == selectedID ? color : color.opacity(0.6))
                if is3D {
                    let backZ = cos(radians) >= 0 ? z : z+d
                    let backX = sin(radians) >= 0 ? x : x+w
                    polygon([point(x,backZ), point(x+w,backZ), point(x+w,backZ,h), point(x,backZ,h)], fill: color.opacity(0.45))
                    polygon([point(backX,z), point(backX,z+d), point(backX,z+d,h), point(backX,z,h)], fill: color.opacity(0.65))
                    // A subtle plinth makes the cutaway read as a solid miniature.
                    polygon([point(x,z+d), point(x+w,z+d), point(x+w,z+d,-0.12), point(x,z+d,-0.12)], fill: color.opacity(0.75))
                }
                let labelPoint = point(x+w/2, z+d/2)
                context.draw(Text(room.name).font(.system(size: labelSize, weight: .semibold)).foregroundColor(AppTheme.ink), at: labelPoint)
            }
        }
        .background(AppTheme.secondarySurface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityLabel(is3D ? "3D room layout" : "2D floor plan")
        .accessibilityValue("\(rooms.count) rooms. Room names and dimensions are listed below.")
    }
}
