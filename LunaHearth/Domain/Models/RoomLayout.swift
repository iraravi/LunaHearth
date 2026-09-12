import Foundation

struct RoomFootprint: Equatable, Sendable {
    var x: Double = 0
    var z: Double = 0
    var width: Double = 4
    var depth: Double = 4
    var height: Double = 2.7
    var area: Double { width * depth }

    func validate() throws {
        guard [x, z, width, depth, height].allSatisfy(\.isFinite),
              (0...100).contains(x), (0...100).contains(z),
              (1...30).contains(width), (1...30).contains(depth),
              (2...6).contains(height) else { throw LayoutError.invalidDimensions }
    }

    func overlaps(_ other: Self) -> Bool {
        // Touching edges are adjacent rooms, not overlaps.
        x < other.x + other.width - 0.001 && x + width > other.x + 0.001 &&
        z < other.z + other.depth - 0.001 && z + depth > other.z + 0.001
    }

    static func nextPlacement(among rooms: [Self], width: Double, depth: Double) -> Self {
        let columns = Set([0.0] + rooms.map { $0.x + $0.width }).filter { (0...100).contains($0) }.sorted()
        let rows = Set([0.0] + rooms.map { $0.z + $0.depth }).filter { (0...100).contains($0) }.sorted()
        for row in rows {
            for column in columns {
                let candidate = Self(x: column, z: row, width: width, depth: depth)
                if !rooms.contains(where: { candidate.overlaps($0) }) { return candidate }
            }
        }
        return Self(width: width, depth: depth)
    }
}

enum LayoutError: LocalizedError {
    case invalidDimensions, overlap, missingRoom
    var errorDescription: String? {
        switch self {
        case .invalidDimensions: "Use room widths and lengths from 1–30 m, heights from 2–6 m, and positions from 0–100 m."
        case .overlap: "These rooms overlap. Adjust the position or size, then save again."
        case .missingRoom: "This room or floor is no longer available. Reopen the layout and try again."
        }
    }
}

enum RoomPreset: String, CaseIterable, Identifiable, Sendable {
    case living = "Living room", bedroom = "Bedroom", kitchen = "Kitchen", bathroom = "Bathroom", office = "Office", other = "Other"
    var id: String { rawValue }
    var symbol: String {
        switch self {
        case .living: "sofa.fill"
        case .bedroom: "bed.double.fill"
        case .kitchen: "refrigerator.fill"
        case .bathroom: "bathtub.fill"
        case .office: "desktopcomputer"
        case .other: "door.left.hand.open"
        }
    }
    var size: (Double, Double) {
        switch self {
        case .living: (5, 4)
        case .bedroom: (4, 3.5)
        case .kitchen: (3.5, 3)
        case .bathroom: (2.5, 2)
        case .office: (3, 3)
        case .other: (4, 4)
        }
    }
}

struct LayoutRoom: Identifiable {
    let id: UUID
    let name: String
    let preset: RoomPreset
    let footprint: RoomFootprint
}

extension Room {
    var footprint: RoomFootprint? {
        guard let layoutX, let layoutZ, let layoutWidth, let layoutDepth, let layoutHeight else { return nil }
        return RoomFootprint(x: layoutX, z: layoutZ, width: layoutWidth, depth: layoutDepth, height: layoutHeight)
    }
    var layoutRoom: LayoutRoom? {
        footprint.map { LayoutRoom(id: id, name: name, preset: RoomPreset(rawValue: layoutPreset ?? "") ?? .other, footprint: $0) }
    }
}

extension RoomFootprint {
    func moved(byX dx: Double, byZ dz: Double, neighbors: [Self]) -> Self {
        var result = self
        result.x = min(100, max(0, ((x + dx) * 4).rounded() / 4))
        result.z = min(100, max(0, ((z + dz) * 4).rounded() / 4))
        // Prefer exact shared edges when close to the quarter-meter grid.
        let xs = neighbors.flatMap { [$0.x, $0.x + $0.width, $0.x - width, $0.x + $0.width - width] }
        let zs = neighbors.flatMap { [$0.z, $0.z + $0.depth, $0.z - depth, $0.z + $0.depth - depth] }
        if let edge = xs.filter({ (0...100).contains($0) && abs($0 - result.x) <= 0.2 }).min(by: { abs($0 - result.x) < abs($1 - result.x) }) { result.x = edge }
        if let edge = zs.filter({ (0...100).contains($0) && abs($0 - result.z) <= 0.2 }).min(by: { abs($0 - result.z) < abs($1 - result.z) }) { result.z = edge }
        return result
    }
}

struct LayoutCamera: Equatable, Sendable {
    var azimuth: Double = 35
    var elevation: Double = 35

    func rotated(horizontal: Double, vertical: Double) -> Self {
        let angle = (azimuth + horizontal).truncatingRemainder(dividingBy: 360)
        return Self(azimuth: angle < 0 ? angle + 360 : angle,
                    elevation: min(75, max(15, elevation + vertical)))
    }
}
