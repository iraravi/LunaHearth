# Contributing

Read `AGENTS.md` first.

## Branch/commit guidance

Prefer small feature branches and commits that preserve buildability.

A change that modifies architecture, persistence schema, privacy behavior, CloudKit ownership, minimum OS, or dependencies must update relevant documentation/ADR.

## Before PR

```bash
xcodegen generate
make docs-check
make build
make test
```

If a tool/device is unavailable, report that clearly in the PR rather than claiming success.

## Pull request summary

Include:
- user-visible behavior
- offline behavior
- permissions/data touched
- schema changes
- tests run
- screenshots for UI changes when practical
