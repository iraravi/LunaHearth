import Foundation
import Testing
@testable import LunaHearth

struct RoomGeometryTests {
    @Test func cameraWrapsThrough360AndClampsTilt() {
        #expect(LayoutCamera(azimuth: 350).rotated(horizontal: 30, vertical: 0).azimuth == 20)
        #expect(LayoutCamera(azimuth: 10).rotated(horizontal: -30, vertical: 0).azimuth == 340)
        #expect(LayoutCamera().rotated(horizontal: 720, vertical: 200).elevation == 75)
        #expect(LayoutCamera().rotated(horizontal: 0, vertical: -200).elevation == 15)
    }

    @Test func draggingSnapsAndClampsWithoutResizing() {
        let room = RoomFootprint(x: 5, z: 2, width: 3, depth: 4)
        let moved = room.moved(byX: -100, byZ: 0.37, neighbors: [])
        #expect(moved.x == 0)
        #expect(moved.z == 2.25)
        #expect(moved.width == room.width && moved.depth == room.depth)
        let edge = room.moved(byX: 0.1, byZ: 0, neighbors: [RoomFootprint(width: 5.1)])
        #expect(edge.x == 5.1)
    }

    @Test func edgesMayTouchButInteriorsCannotOverlap() {
        let room = RoomFootprint(width: 4, depth: 3)
        #expect(!room.overlaps(RoomFootprint(x: 4, width: 2, depth: 3)))
        #expect(room.overlaps(RoomFootprint(x: 3.5, width: 2, depth: 3)))
        #expect(!room.overlaps(RoomFootprint(z: 3, width: 4, depth: 2)))
        #expect(room.area == 12)
    }
    @Test func rejectsInvalidAndNonfiniteGeometry() {
        for room in [RoomFootprint(x: -1), RoomFootprint(width: 0), RoomFootprint(depth: .nan), RoomFootprint(height: .infinity)] {
            #expect(throws: LayoutError.self) { try room.validate() }
        }
    }
    @Test func automaticPlacementFindsOpenSpace() throws {
        let first = RoomFootprint(width: 5.25, depth: 4)
        let next = RoomFootprint.nextPlacement(among: [first], width: 3, depth: 3)
        try next.validate()
        #expect(!next.overlaps(first))
        #expect(next.x == 5.25)
        #expect(next.z == 0)
    }
}

@MainActor struct RoomLayoutPersistenceTests {
    @Test func savesGeometryAndPreservesExistingRoomAndAssetLinks() throws {
        let container = try LocalStoreConfiguration.makeContainer(inMemory: true)
        let repo = LocalHouseholdRepository(container: container)
        try repo.createHousehold(name: "Home", owner: "", members: [])
        try repo.add(EntryDraft(kind: .room, title: "Existing room"))
        let room = try #require(repo.rooms.first)
        #expect(room.footprint == nil)
        try repo.add(EntryDraft(kind: .asset, title: "Sofa", parentID: room.id))
        try repo.saveRoomLayout(id: room.id, name: "Living room", floorID: nil, preset: .living,
                                footprint: RoomFootprint(width: 5, depth: 4))
        let reloaded = LocalHouseholdRepository(container: container)
        try reloaded.reload()
        #expect(reloaded.rooms.count == 1)
        #expect(reloaded.rooms.first?.footprint?.area == 20)
        #expect(reloaded.assets.first?.roomID == room.id)
        #expect(reloaded.rooms.first?.layoutPreset == RoomPreset.living.rawValue)
    }
    @Test func rejectsOverlapAndForeignFloorWithoutPartialWrites() throws {
        let repo = LocalHouseholdRepository(container: try LocalStoreConfiguration.makeContainer(inMemory: true))
        try repo.createHousehold(name: "Home", owner: "", members: [])
        try repo.saveRoomLayout(id: nil, name: "Living room", floorID: nil, preset: .living, footprint: RoomFootprint())
        #expect(throws: LayoutError.self) {
            try repo.saveRoomLayout(id: nil, name: "Overlap", floorID: nil, preset: .bedroom, footprint: RoomFootprint())
        }
        #expect(throws: LayoutError.self) {
            try repo.saveRoomLayout(id: nil, name: "Foreign", floorID: UUID(), preset: .bedroom, footprint: RoomFootprint(x: 4))
        }
        #expect(repo.rooms.count == 1)
        try repo.add(EntryDraft(kind: .floor, title: "Upstairs"))
        let floor = try #require(repo.floors.first)
        try repo.saveRoomLayout(id: nil, name: "Bedroom", floorID: floor.id, preset: .bedroom, footprint: RoomFootprint())
        #expect(repo.rooms.count == 2)
    }
}
