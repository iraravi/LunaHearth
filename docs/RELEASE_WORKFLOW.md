# Nam Illam release workflow

## Version ledger

| Stage | App Store version | Build | Git reference |
| --- | --- | --- | --- |
| Live first release | 1.0 | 70 | v1.0.0 |
| Next major redesign, development only | 2.0.0 | 71 | codex/v2-duo-redesign |

The v1.0.0 tag normalizes the published 1.0 version; it does not rename the App Store version. The owner requested v2 for the next redesign. Smaller compatible enhancements could otherwise use 1.1.0, and urgent v1 fixes should use 1.0.1.

## Branches and immutable releases

- `main` holds the latest accepted release baseline. Develop in `codex/*` branches and merge reviewed pull requests only after validation.
- `codex/release-1.0` starts at v1.0.0 and is reserved for v1 maintenance. Never merge the v2 redesign into this line.
- `codex/v2-duo-redesign` is the next major release development branch. Its existence does not authorize an App Store upload or rollout.
- Annotated `vMAJOR.MINOR.PATCH` tags record public releases. Never move, overwrite or delete a published release tag. Use a new version for corrections.
- Make each reviewable feature/fix a separate commit. Stage explicit paths; never sweep unrelated local archives, website work or personal files into a release.
- These are repository conventions, not a claim that server-side GitHub branch protection is enabled.

## Version source

Edit `MARKETING_VERSION` and `CURRENT_PROJECT_VERSION` in `project.yml`, then run `xcodegen generate`. Commit the generated project together with the YAML. Keep the build number increasing across all branches and uploads: if a v1 hotfix uses 71, allocate 72 or greater to the next v2 upload. Check App Store Connect before allocating each upload number. Do not reuse an uploaded build number.

Keep bundle ID, CloudKit container and local store identity stable so existing users receive an update and retain their records. Read DATA_MODEL.md and CLOUDKIT_SYNC.md before schema or synchronization changes.

## Release gate

1. Review diff, permissions, migration and offline behavior; confirm no secrets or private household data are staged.
2. Run simulator build and unit tests with the public Xcode installation; run affected UI flows on compact iPhone, expansive Duo/iPad, dark mode and accessibility text sizes.
3. Test upgrading from the live version with existing records; verify drafts and selection survive layout changes. Never delete the production store to make an upgrade pass.
4. Record checks, limitations, source commit, version/build, toolchain and screenshots in `docs/release/<version>-build<build>/`.
5. Archive from a clean, committed app source state. Verify archive version, signature and SDK. Keep signing files and archive binaries out of Git.
6. Upload to TestFlight first; verify processing, assignments and tester acceptance. Public App Store submission is a separate deliberate step.
7. After approval, verify public availability and annotate the release commit with its version tag; push the tag without force.

## Hotfixes

Branch `codex/hotfix-<issue>` from the released tag or its maintenance branch. Apply the smallest fix, choose a higher unused build number, test and release as 1.0.1 (then 1.0.2, etc.). Forward-port the fix to v2 using a reviewed cherry-pick or equivalent change. Store migrations may prevent binary rollback, so prefer a validated forward fix.
