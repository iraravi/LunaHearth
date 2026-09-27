# Functional, performance and energy audit — September 22, 2026

## Scope

Build 60 source checkpoint, plus local audit fixes. No production household data, schemas, permissions, CloudKit ownership or test accounts changed. Tests use synthetic stores/integration doubles. No TestFlight upload or physical install is part of this audit.

## Findings and fixes

1. Foreground activation performed a forced service refresh and immediately entered an identical refresh before its first 20-second wait. The periodic loop now waits first. Cancellation stops it before the next refresh; regression tests cover both waiting order and interrupted initial wait.
2. Setup with no home previously kept the periodic refresh alive, including notification-center queries. Active/home guards now prevent that work until a home exists.
3. Ingredient search constructed its alias lookup data and normalized the same item repeatedly per keystroke. Alias search metadata is now immutable and reused; specific ingredient form matching remains unchanged.

## Performance measurement

Optimized Swift command-line comparison on this Mac, synthetic 1,000-item search with six passes each, same query and 600 results per pass:
- Before: 40.7–45.0 ms per pass.
- After: 31.7–32.5 ms per pass.
- This is a local microbenchmark, not physical iPhone UI latency or battery measurement. Initial concurrent-build runs varied substantially, so do not interpret the difference as a guaranteed device improvement.

A repeatable XCTest measures the 1,000-item search using wall-clock, CPU and memory metrics. A UI performance test measures application launch with a synthetic household. Record resulting measurements below after execution. There is no historical performance baseline yet; passing correctness assertions alone does not establish a performance budget.

## Battery verification boundary

Ravi's iPad and iPhone were unavailable to devicectl during this audit, so no physical Power Profiler run or battery-drain result is claimed. Simulator timing/memory cannot establish battery life.

Static checks: scene task cancellation limits the refresh loop to foreground; foreground fallback still polls every 20 seconds, with sync failure backoff. Notification scheduling already compares existing appointment triggers before replacing them. Receipt/photo scanners downsample images (2,600/1,800 pixels respectively; preview 900). Full snapshot/merge work during foreground sync and active on-device AI remain candidates for physical profiling with realistic household sizes.

When a device is connected/unlocked: record idle, scrolling/search, receipt scan, AI suggestion and shared-home sync in Instruments Power Profiler and Time Profiler. Use the same dataset, brightness, network and thermal conditions for before/after comparisons. Check backgrounding/locking stops periodic work, monitor peak memory and repeated scans, and compare Low Power Mode. A short battery percentage observation is not a reliable energy benchmark.

## Repeatable commands

- Functional release gate: `DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer bash scripts/release-check.sh`
- Search metrics: select `LunaHearthTests/GroceryPerformanceTests/testSearchThousandIngredients` in Xcode Test navigator or xcodebuild `-only-testing`.
- Launch metrics: select `LunaHearthUITests/VisualFlowTests/testLaunchPerformance`.
- Refresh cancellation regression: `LunaHearthTests/ForegroundRefreshLoopTests`.

Keep comparisons on the same hardware, runtime and build configuration with other test/build activity stopped. Record a baseline before enforcing a regression threshold. Test accounts/real household content are not required.

## Completed results

- Initial build-60 gate: 240 unit tests passed; eight iPhone end-to-end tests passed.
- After audit fixes: 242 Swift Testing tests across 45 suites passed, including two refresh-loop regressions. Eight iPad end-to-end tests passed with the updated source.
- Search XCTest: five measured iterations, 1,000 ingredients, 600 matches each. Debug iPhone simulator mean wall time 43 ms; mean CPU time 79 ms; test-process peak physical memory approximately 34.2 MB. Memory delta was near zero but variable; this is not a leak test or whole-app memory budget.
- Launch XCTest: three measured iterations of the Debug app with synthetic fixture data, mean 3.029 s (3.158, 2.945, 2.985 s). This deserves a Release/physical-device startup profile before making speed claims. No historical baseline or enforced regression threshold exists yet.
- Both performance tests passed. Staged/source whitespace checks passed.
- Physical devices remained unavailable at the end; battery/energy, thermal behavior, leaks under repeated camera/AI use, real push delivery and multi-device CloudKit remain unverified by this audit.

End-to-end scenarios: linked receipt without double restocking (normal and large text), measured shopping restock, monthly expense report, optional Apple Calendar delivery using a fake service, Siri draft deep link, large-text family week and storage-open failure recovery. These do not certify real EventKit/iCloud/APNs/Siri voice operation.

Evidence: /tmp/LunaHearthAudit-20260922/iPhone.xcresult and iPad.xcresult; /tmp/luna-audit-final-units.log; /tmp/luna-audit-performance.log; /tmp/luna-search-before-results.txt and /tmp/luna-search-after-results.txt. Tests and instrumentation are saved as pending local changes, not uploaded to TestFlight. Build 60 on TestFlight does not contain these fixes yet.
