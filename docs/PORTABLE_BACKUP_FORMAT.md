# Portable household backup v1 (`.nlbackup`)

MIME: `application/vnd.neuralluna.household-backup`. Apple UTI: `com.neuralluna.household-backup` (public.data). This is an encrypted interchange snapshot, not a SwiftData database, synchronization protocol, ZIP, or Apple-account-bound file. Android implementation is future work.

## Binary envelope

All offsets are bytes, zero-based. No BOM or line breaks.

| Offset | Length | Meaning |
| --- | --- | --- |
| 0 | 8 | ASCII `NLHBK001` (container version 1) |
| 8 | 16 | Cryptographically random salt |
| 24 | 12 | Cryptographically random AES-GCM nonce |
| 36 | 4 | Unsigned big-endian PBKDF2 iterations: 600000 (`00 09 27 C0`) |
| 40 | variable | AES-256-GCM ciphertext |
| last 16 | 16 | GCM authentication tag |

Derive a 32-byte key with PBKDF2-HMAC-SHA256 using exact UTF-8 password bytes and the salt. Do **not** trim, normalize Unicode, append a NUL, or use a platform keychain key. Authenticate bytes 0–39 as AAD. Reject unknown magic/version, any other work factor, files shorter than 56 bytes or over 96,000,000 bytes before KDF. Never parse/decompress plaintext before tag verification. Password policy for new exports: at least 12 Swift extended grapheme clusters and at most 1,024 UTF-8 bytes; readers need not enforce the creation minimum. Cipher primitives are standards; the file framing is the app's format.

## Encrypted payload

UTF-8 JSON, no compression. Top-level object:

- `formatVersion`: integer 1; reject other versions.
- `household`: existing HouseholdBackup v1 object (`version`, `householdID`, `name`, `savedAt`, `records`).
- `documents`: array of metadata objects: `id`, optional `assetID`, `title`, `kind`, `createdAt`, `modifiedAt`.
- `files`: array of `{owner, recordID, filenameExtension, bytes}`. Owner is `document` or `roomScan`; bytes is standard padded Base64. Extension contains 1–16 ASCII alphanumerics, with no leading dot. Readers must never execute attachments or trust extension as evidence of content type.

UUIDs are canonical hyphenated UUID strings, compared as UUID values (case-insensitive). All Date values, including dates inside record payloads, are fractional seconds since **2001-01-01T00:00:00Z**, following the existing v1 backup codec. Add 978307200 to convert to Unix seconds. Civil-day keys remain `YYYY-MM-DD` strings; do not timezone-shift them. Monetary amounts remain integer minor units plus ISO currency codes, never floating point.

Each record contains `id`, `householdID`, `kind`, `createdAt`, `modifiedAt`, and `payload` (Base64 of UTF-8 JSON). Record field contracts are the Codable value types in `LunaHearth/Data/CloudKit/BackupCodec.swift`. Supported kinds: Household, HouseholdMember, FamilyEvent, HouseholdTask, ShoppingStore, InventoryItem, PurchaseEntry, HouseholdExpense, GroceryItem, MealPlanEntry, HomeFloor, Room, HomeAsset, Warranty, MaintenancePlan, MaintenanceHistory. Unknown kinds must fail, not be silently dropped. Optional legacy fields preserve BackupCodec defaults. The per-entity wrapper and existing inner JSON are intentionally reused so CloudKit records and offline files agree; JSON strings/UUIDs/data must not be replaced by serialized Swift objects.

Document kinds: receipt, warranty, manual, insurance, registration, school, other. Each document has exactly one file. Room-scan files reference a Room record. Duplicate owner/id files and document IDs, missing references, document IDs colliding with other records, invalid dates, unsupported kinds, unsafe extensions and excess sizes fail before mutation. A selected-home snapshot does not include other homes. Sharing access, cloud record metadata, device authorizations, notification registrations, UI preferences and external Apple links are not transferred.

Limits: 10,000 records; 500,000 bytes per decoded record payload; 25,000,000 decoded record-payload bytes total; at most 10,000 documents and 10,000 files; at most 32,000,000 decoded attachment bytes. No local path, password, encryption key or receipt content appears in the unencrypted header. Size and format are observable.

## Interoperability vector

Test-only password: `Tamil தமிழ் backup` (exact Unicode UTF-8). Salt bytes 0..15; nonce bytes 16..27. Plaintext UTF-8: `Portable backup interoperability`. Binary envelope, Base64:

```
TkxIQkswMDEAAQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobAAknwNbdrdA2xmpB3ZiNjM033cdZoe2HT1+4dbTMy/KcMrpYBwI6iK0pisDDY30q4a7V5Q==
```

Independently generated with Python `hashlib.pbkdf2_hmac('sha256', password.encode('utf-8'), salt, 600000, 32)` and `cryptography.hazmat.primitives.ciphers.aead.AESGCM(key).encrypt(nonce, plaintext, header)`. This fixture verifies envelope cryptography, not a valid household JSON graph. Fixed salt/nonce are for this public fixture only; production exports always generate fresh values.

## User flow

More → Privacy & data → Manage backups → Encrypted file backup → password + confirmation → Export → choose Files destination. During setup: Restore a backup → Encrypted file backup → choose file → enter password → Unlock and preview → confirm Restore. Core export/import works offline; choosing a remote Files provider may require that provider's network/storage. There is no password recovery. Keep a copy off the original phone.

### Optional receipt image limitation

Device-local compressed receipt images introduced in November 2026 are sidecars, not DocumentRecord attachments. Version 1 portable exports do not contain these copies. Receipt review discloses this before opting in; the purchase/expense/shopping records remain exportable. Keep originals separately when retention matters.
