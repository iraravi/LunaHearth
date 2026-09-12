# Codex Setup for LunaHearth

## What Codex needs

Codex can work directly from this repository because the root `AGENTS.md` contains durable project instructions. OpenAI's current Codex guidance supports using `AGENTS.md` as project instructions; `/init` can generate one, but this repository already includes a curated version, so do **not** overwrite it with a generic `/init` result.

Official reference: https://help.openai.com/en/articles/11369540

## Required development tools

On the Mac that will build LunaHearth:

- Xcode with the current iOS SDK
- Xcode command-line tools
- XcodeGen (`brew install xcodegen`)
- Codex desktop/CLI/IDE as preferred

There is **no required runtime Swift plugin/package** for the MVP.

## Recommended Codex extension for iOS work

For agent-driven simulator/build/debug workflows, **XcodeBuildMCP is recommended but optional**. OpenAI's current Codex iOS use-case guidance explicitly highlights XcodeBuildMCP for driving iOS Simulator and capturing evidence.

Reference: https://developers.openai.com/codex/use-cases

Do not make the repository depend on an MCP server being installed; `xcodebuild`, `xcrun simctl`, and normal Xcode remain the canonical build path.

## Recommended first Codex prompt

```text
Read AGENTS.md, CODEX_TASKS.md, docs/PRODUCT_SPEC.md,
docs/ARCHITECTURE.md, docs/LLD.md, and all accepted ADRs.

Start with Phase P0 then P1. Do not add any custom backend, login,
third-party analytics, or remote AI. Keep the app local-first and Swift 6
strict-concurrency clean. Generate the Xcode project with XcodeGen, find an
available simulator, build, run tests, and fix all compile errors before
starting product features. Report exact commands and results.
```

## Useful focused prompts

See:
- `.codex/prompts/implement-feature.md`
- `.codex/prompts/review-change.md`
- `.codex/prompts/fix-build.md`

## Suggested working cadence

1. Codex reads `AGENTS.md` and the active task.
2. It makes a small implementation plan.
3. It edits one bounded feature.
4. It builds/tests on macOS.
5. It updates `CODEX_TASKS.md` or docs only when the implementation changes the documented contract.
6. It shows screenshots/simulator evidence for meaningful UI changes when tooling is available.

## Do not grant unnecessary tools

LunaHearth deliberately has no backend. Codex does not need production cloud credentials for normal feature work. CloudKit integration tests should use a dedicated Apple development container/test household, never personal household production data.
