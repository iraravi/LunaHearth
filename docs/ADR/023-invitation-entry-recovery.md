# ADR 023: Invitation entry and recovery before setup

Status: Implemented; device invitation callback validation pending.

A build 8 recipient reported opening the household invitation into Get Started.
The exact physical callback failure was not observable. Code review identified
missing scene connection and application-delegate acceptance handlers, an
invitation sheet competing with setup presentation, and invitation-registration
errors hidden when no local household existed.

Preserve the connecting scene configuration and route both cold scene connection
metadata and warm acceptance metadata to the existing invitation flow. A pending
invitation is now a root-screen priority after local loading, ahead of onboarding
or an existing home. Joining still requires explicit user action and preserves
any unrelated local household. Invitation errors appear even on an empty device.

Onboarding offers Join an existing home. Users can resolve a pasted direct HTTPS
iCloud share URL through CKContainer metadata lookup, then explicitly join. URL
validation accepts only icloud.com or www.icloud.com /share/ links without embedded
credentials or ports. The returned metadata must match the app's container and
household zone format. URLs and metadata are not logged or saved in preferences.
No arbitrary network fetch, clipboard read, public database, or new backend is
introduced. This is a recovery entry point to the existing opt-in CloudKit
transport. Already joined homes can be found explicitly without creating a home.
It is not an inbox for unopened pending invitations.

Tests cover URL restrictions, visible invalid-invitation state, lookup without
local mutation, joining into an empty local store through a fake shared server,
and invitation precedence over setup plus the manual recovery entry screen.
These checks do not prove Apple's live callback delivery or a real account's
invitation permissions. Production data is never reset for validation.

## Direct-link follow-up (build 10)

The user successfully joined the production shared home using the pasted link,
confirming the fallback path works on the physical recipient. Direct Mail or
Messages handoff still needs verification. The app previously handled CloudKit
metadata and SwiftUI URL opening but omitted web-browsing user activities and
scene URL contexts. Build 10 routes these additional cold/warm entry paths through
the same validated lookup: application continuation, scene continuation, scene
connection activities/URLs, scene openURLContexts, and SwiftUI continuation.
Only validated iCloud share URLs are retained in memory until the view consumes
them. No associated-domain claim, arbitrary URL fetch, or clipboard read was
added. Unit checks cover retained activity delivery, repeated links and rejection
of unrelated activities/URLs. This is defensive callback coverage; only a real
Mail/Messages tap can validate Apple's handoff for these devices.
