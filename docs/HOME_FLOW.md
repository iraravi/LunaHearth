# Home setup and everyday use

The native app now follows this path:

1. **Get Started → Set up your home.** Name the household, optionally choose a first room and add local family profiles. **Create my home** stays visible at the bottom, including at accessibility text sizes. Setup works offline and saves the home, people and first room together, then opens Home directly.
2. **Home → Add a room.** Rooms can exist immediately without a floor or scan. Add a floor when useful, or choose an existing floor when adding a room.
3. **Open a room → Add an item to that room.** The form names the destination and keeps the item type fixed. Add item details now or edit later. Home also offers a direct Add an item action.
4. **Open an item → Warranty or Maintenance.** Coverage, repeating care, completion history and replacement groceries stay linked to the item even if it moves rooms.
5. **Home → Arrange rooms in 2D / 3D.** Create measured layouts, drag rooms in 2D, and drag the 3D view to rotate and tilt. Layout changes save locally; invalid overlapping moves return to the saved position.

## Optional private cloud storage

**More → iCloud backup → Back up to iCloud** asks before sending household data to Apple. This saves a manual snapshot and replaces the previous backup in that Apple Account. Later edits require another backup.

On a new installation, **Restore from iCloud → Find my iCloud backup** downloads and validates the backup. Review its home name, date and record count, then tap **Restore this home**. Existing local homes cannot be overwritten by restore.

See [CloudKit setup](CLOUDKIT_SETUP.md) for signing and real-device checks. Private backup is implemented; automatic sync and live family sharing are future work. Document/room-scan files are not backed up in this version.

## Review assets

[Native screen walkthrough](visual-review/home-flow.html) contains simulator screenshots, not interactive app controls. Use the native simulator app to exercise the complete flow. The older browser layout demo is an independent sample and does not save into the native household store.
