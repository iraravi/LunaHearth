# Codex prompt: fix build/test

Do not weaken Swift 6 strict concurrency or delete tests to make the build green.

1. Generate project using XcodeGen.
2. Discover a valid simulator.
3. Run build and capture first actionable compiler error.
4. Fix root cause with minimal architecture disruption.
5. Run tests.
6. If an Apple SDK API changed, update capability/availability handling and docs.
7. Report command output summary truthfully.
