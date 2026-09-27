import XCTest
@testable import LunaHearth

/// Synthetic local data only. Establish baselines on the same device/configuration;
/// simulator measurements are not a prediction of physical battery consumption.
final class GroceryPerformanceTests: XCTestCase {
    func testSearchThousandIngredients() {
        let names = (0..<1_000).map { ["Organic cumin seeds", "Rice flour", "Jeera", "Milk", "Cumin powder"][$0 % 5] }
        let options = XCTMeasureOptions()
        options.iterationCount = 5
        measure(metrics: [XCTClockMetric(), XCTCPUMetric(), XCTMemoryMetric()], options: options) {
            let matches = names.filter { IngredientMatching.matchesSearch($0, query: "cumin") }
            XCTAssertEqual(matches.count, 600)
        }
    }
}
