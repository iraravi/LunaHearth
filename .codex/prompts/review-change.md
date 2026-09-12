# Codex prompt: review a LunaHearth change

Review against `AGENTS.md` with priority order:
1. data loss / migration
2. privacy or unexpected network transmission
3. CloudKit ownership/sync conflicts
4. Swift concurrency correctness
5. offline behavior
6. permission timing
7. business logic/date correctness
8. accessibility/adaptive UI
9. tests/docs

Reject convenience dependencies or login/backend additions lacking an ADR.
