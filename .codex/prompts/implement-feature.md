# Codex prompt: implement a LunaHearth feature

Read `AGENTS.md`, `CODEX_TASKS.md`, and the relevant docs/ADRs first.

Implement the requested feature using these constraints:
- local/offline path first
- Apple frameworks first
- no new backend/account/analytics/remote AI
- Swift 6 strict concurrency
- domain protocol boundary for Apple services
- tests for deterministic business logic
- just-in-time permissions
- adaptive compact/expansive SwiftUI

Before editing, identify:
1. affected entities
2. privacy/permission impact
3. offline behavior
4. sync impact
5. test plan

After editing:
- run build/tests when on macOS/Xcode
- update docs/ADR if architecture/schema/privacy changed
- report exactly what was tested
