# Nam Illam 3.0 — plan

Theme: **one clean, smarter household app on iPhone, iPad and Apple Watch.**
All intelligence stays on device (Apple Foundation Models + Vision), per AGENTS.md: no network AI, no new backend, and every feature still works without Apple Intelligence.

## 1. One AI layer, one look (foundation)

Today each screen has its own AI service (receipt names, pantry categories, shopping brief, Today brief…). 3.0 makes them one system:

- **`HouseholdIntelligence`**: one service with typed requests (parse, categorize, summarize, suggest), one availability check, one "AI allowed" setting and shared rate limits. Existing services move behind it.
- **One suggestion pattern everywhere**: the receipt "On bill / AI says / Accept / Keep" design becomes a shared `AISuggestion` component. AI never changes saved data silently; you accept or keep.
- **Rules first, AI second**: deterministic rules answer when they can (fast, offline, testable). AI fills the gaps. Device-local learning (like receipt corrections) remembers your choices.

## 2. Smarter screens

| Screen | 3.0 intelligence |
|---|---|
| **Quick Add** (everywhere) | Type or say one sentence: "Costco Saturday, milk, eggs, change upstairs filter, $45 gas yesterday" → separate shopping items, task, event and expense, shown for review |
| **Shopping** | Quantities and units understood ("2 dozen eggs"); items grouped by store aisle; Buy again predicts when you'll run out from purchase history; duplicates merged; meal plan and low pantry feed the list |
| **Tasks** | Due date, repeat and person read from text ("every Sunday, Ravi"); big tasks split into steps on request; Today ranks what matters (overdue, due soon, quick wins) |
| **Expenses** | Category picked automatically from merchant and items; month summary in plain words ("Groceries up 18% vs October, mostly Costco"); possible duplicate charges flagged; natural entry ("spent 45 at Shell yesterday") |
| **Today** | One short brief joining all of the above: what's due, what to buy, what's spent |
| **Siri and Shortcuts** | App Intents: add shopping item, add task, add expense, what's on my list. These also power the Watch. |

## 3. Apple Watch app (new)

Companion app (needs the iPhone app), watchOS 11+.

- **Shopping list**: check items off in the store, grouped by aisle; large tap targets.
- **Today's tasks**: see and complete.
- **Add by voice**: dictate "milk and bread" → parsed into items (parsing happens on the iPhone).
- **Watch face and Smart Stack widgets**: items left to buy, next task.
- **Notifications with actions**: mark done, snooze.

**Sync:** WatchConnectivity between the phone and the watch. The phone sends a small snapshot (open shopping items, today's tasks); the watch sends back actions (checked, completed, added). The phone stays the source of truth. No CloudKit or schema change; works offline and catches up when the devices reconnect.

## 4. Release

- Unit tests for every rule and parser; UI tests for the suggestion flow and watch actions.
- Version **3.0**, TestFlight builds to the debug group first.
- App Store: new screenshots (iPhone, iPad, Duo, Watch), description and What's New.
- Before submitting: answer the new **age rating questions** (due Jan 15, 2027).

## Order of work

1. Shared AI layer + suggestion component (moves existing AI, no visible change except consistency)
2. Quick Add for everything + Siri intents
3. Shopping, Tasks, Expenses intelligence (one TestFlight build each)
4. Watch app target, sync, widgets
5. Polish, screenshots, 3.0 submission

## Status (2026-11-24)

- Steps 1–3 shipped in TestFlight builds 94–96.
- Step 4 done in build 97: Watch app, sync, widgets, meal prep notification actions. See `docs/WATCH_APP.md`. Not yet tried on a real watch.
- Step 5: 3.0 App Store text drafted in `docs/release/nam-illam-app-store/en-US-3.0.json`; screenshots in `docs/release/nam-illam-app-store/screenshots-3.0/`. Checklist in `docs/release/nam-illam-app-store/SUBMISSION-3.0.md`.
