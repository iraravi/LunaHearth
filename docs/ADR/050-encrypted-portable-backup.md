# ADR 050: Portable, password-encrypted household backups

Status: Implemented for the user's requested offline export/import feature; release validation required before distribution.

## Decision

Add `.nlbackup`, a versioned, platform-neutral file container. Use Apple's CryptoKit AES-256-GCM and CommonCrypto PBKDF2-HMAC-SHA256 (600,000 iterations), fresh secure random salt/nonce, and an authenticated format header. Do not invent a cipher. No new runtime dependency, server, account, telemetry, or network request. The name is independent of the changeable product display name. See `../PORTABLE_BACKUP_FORMAT.md` for the wire contract.

Work is isolated on `codex/encrypted-portable-backup`; already-uploaded build 72 is unchanged. A new signed build and export-compliance review are required to ship this code. No minimum-OS or persistence-schema changes.

## Data and privacy

Exports capture the selected household: all existing BackupCodec record kinds including pantry, purchase history, expenses, schedules, tasks, meals and hidden home/care entities; plus DocumentRecord metadata and document/room-scan bytes. Missing, unsafe or oversized attachments fail the entire export. Original local paths are not transported. Restore generates new file paths and recomputes document hashes. Device-local notifications, external calendar/reminder links, CloudKit ownership/shares/tokens and device preferences are excluded. Restoring does not silently re-share content or recreate Apple Calendar/Reminders entries.

The user supplies a long password twice. Password is not stored in preferences, Keychain, files, logs or server storage. There is no recovery/backdoor; a forgotten password makes the export unusable. Swift strings/copies cannot promise secure memory erasure; temporary KDF buffers are overwritten best-effort. Export contains encrypted bytes only, with a generic default filename. The system Files destination may itself be cloud-backed at the user's choice. No automatic uploading is added. A copy kept only on the same phone does not protect against device loss.

## Restore and failure handling

Decrypt/authenticate before JSON parsing. Bound encrypted input before KDF/decode. Accept only the version's fixed KDF work factor to prevent attacker-selected expensive derivations. Validate record IDs, household graph, metadata, attachment membership, extensions and size limits before installation. Show a preview and require explicit Restore confirmation. Restore into an empty local store only; no merge/overwrite/destructive migration. Files are installed under a fresh UUID folder before a single database save. On validation/save failure, roll back records and delete that new folder only. If the app crashes between staging files and committing, an unreferenced private folder may remain; no existing home or files are removed. Post-save reload errors cannot trigger deletion of committed attachments. File protection applies to restored files.

No plaintext archive is written to disk. Processing is bounded but in memory: 96 MB encrypted file, 32 MB aggregate attachments, existing 10,000-record/25 MB record-payload limits. Oversized homes must not be described as successfully backed up. Larger streaming containers are a future format/version, not a silent partial export. Cloud backups keep their existing semantics and still reject attachments.

## Validation and release gates

Offline tests cover wrong password, Unicode password interoperability using Python-generated AES-GCM/PBKDF2 fixture, fresh random encryption, tampered header/ciphertext/tag, unsupported version/KDF, truncated input, record/attachment restore, preserved IDs, local-only restore, refusal to overwrite an existing home, missing files, duplicate attachments and unsafe paths. Run app build, unit tests and targeted UI tests. Before shipping, perform Files save/reopen/restore on physical devices with airplane mode, low device storage, iCloud full, long/Unicode passwords, attachment-bearing homes and cancellation. An Android client is not implemented or claimed; it must implement the documented schema and pass shared fixtures.

Sources: [Apple AES.GCM](https://developer.apple.com/documentation/cryptokit/aes/gcm), [OWASP password derivation guidance](https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html), [OWASP cryptographic storage guidance](https://cheatsheetseries.owasp.org/cheatsheets/Cryptographic_Storage_Cheat_Sheet.html).
