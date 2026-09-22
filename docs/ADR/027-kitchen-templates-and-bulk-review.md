# ADR 027: Kitchen templates and bulk pantry review

Status: Accepted for requested implementation, 2026-09-13.

## Behavior
Pantry Ideas offers bundled South Indian, North Indian, American basics and Everyday basics kitchen checklists. The regional checklists contain more than 100 names; Everyday is a smaller 60-item option. These are ready-made templates, never claims of owned stock or live AI-generated results. Optional on-device generation can propose up to 100 names for the selected style and request; unsupported devices use the templates with explicit fallback feedback.

Selection begins empty. Search, Select all shown, category selection and individual toggles let the user assemble a draft. Review shows selected names and allows removal. Only the final Add confirmation writes InventoryItem records. Existing active ingredient aliases are excluded both during selection and immediately before commit. Quantities, stores and expiry remain unset. A single local transaction saves the batch; the existing private/shared CloudKit adapter synchronizes confirmed records.

The deterministic validator now inspects up to 300 input names and retains up to 150 reviewed distinct names, replacing the old 24-item limit in both presentation and repository insertion. Templates and generated proposals pass through the same validation. Strong regional aliases include rajma/kidney beans; whole mung beans remain distinct from split moong dal. No existing duplicates are automatically removed.

## Privacy and architecture
No schema, permissions, sharing roles or new backend changes. Built-in templates work entirely offline. Model context remains limited to style, 300 request characters and 50 bounded existing names; no Apple identity, household member names or cloud AI requests. Generation never saves data.

The iPad canvas update is presentation state only. A per-tab coordinator tracks visible pantry/shopping destinations and gives the Home sidebar and root background their matching named asset color. Dismissed destinations remove their color contribution; asset dark variants and native Dynamic Type remain in use.

## Validation
Unit tests cover 100+ item counts, uniqueness, atomic full-size insertion, replay deduplication and optional metadata remaining unset. UI tests cover selecting all, reviewing, excluding a name and confirming a batch. iPad screenshots verify peach pantry, green shopping and return navigation. Live Foundation Models generation remains a device capability check.
