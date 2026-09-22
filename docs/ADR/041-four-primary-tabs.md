# ADR-041: Four primary tabs

Accepted by the user on September 14, 2026: remove Lists from the root navigation. This supersedes the five-tab layout in AGENTS.md section 9 and DESIGN_SYSTEM.md.

Primary destinations are Today, Calendar, Home and More. Home opens the existing Shopping, Pantry, Meals and Reminders screens, alongside expenses and rooms. Today keeps contextual shortcuts. Home also hosts Quick Add. There is no separate Lists hub in root navigation.

This is presentation-only: no entities, persistence, sharing, permissions or offline behavior change. Existing feature views and accessibility identifiers remain, with Home identifiers replacing hub identifiers in UI tests. No records are deleted.
