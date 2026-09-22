import Foundation

enum HomeSetupStep: String, CaseIterable, Identifiable, Sendable {
    case pantry, shopping, receipts, meals, planning, sharing
    var id: String { rawValue }
}

struct HomeSetupProgress: Equatable, Sendable {
    let completed: Set<HomeSetupStep>
    let skipped: Set<HomeSetupStep>
    init(savedCompleted: String, savedSkipped: String, observed: Set<HomeSetupStep>) {
        completed = Self.decode(savedCompleted).union(observed)
        skipped = Self.decode(savedSkipped).subtracting(completed)
    }
    var reviewedCount: Int { 1 + completed.union(skipped).count }
    var totalCount: Int { 1 + HomeSetupStep.allCases.count }
    var isFinished: Bool { reviewedCount == totalCount }
    var next: HomeSetupStep? { HomeSetupStep.allCases.first { !completed.contains($0) && !skipped.contains($0) } }
    static func decode(_ value: String) -> Set<HomeSetupStep> {
        Set(value.split(separator: ",").compactMap { HomeSetupStep(rawValue: String($0)) })
    }
    static func encode(_ steps: Set<HomeSetupStep>) -> String {
        HomeSetupStep.allCases.filter(steps.contains).map(\.rawValue).joined(separator: ",")
    }
    static func storageKey(householdID: UUID, field: String) -> String {
        "homeSetup.v1.\(householdID.uuidString).\(field)"
    }
}
