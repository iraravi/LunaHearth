# ADR-002: No custom login/account for Apple-only MVP

**Status:** Accepted

## Decision

LunaHearth MVP has no NeuralLuna user account, email/password login, OAuth, or Sign in with Apple. Local mode requires no account. Optional collaboration uses iCloud/CloudKit sharing.

## Consequences

Positive:
- lower privacy/security footprint
- immediate onboarding
- no credential backend

Tradeoff:
- Android/web cross-platform identity is deferred and would require a future architecture decision.
