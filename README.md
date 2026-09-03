# wherewasi

# Where Was I?

A privacy-first, local-only reading tracker built with Flutter.

## Status

🚧 Early development — foundational scaffold only, no features built yet.

## Concept

A single-purpose app focused entirely on reading: tracking what you're
reading, picking up where you left off, and reflecting on reading habits
over time. No cloud sync, no accounts, no unrelated feature bloat — just
reading.

This app is a deliberate split from an earlier multi-tracker project
(FlowState). Reading and fitness were the two use cases that felt strong
enough to justify standalone apps; this repo covers reading only. A
separate fitness app is planned later.

## Tech Stack

- **Framework:** Flutter (targeting Flutter 3.44 / Dart 3.12 — verify
  current versions before assuming these are still latest)
- **Platforms:** macOS, Windows, Linux, iOS, Android
- **Storage:** Local-only (no cloud sync).
- **Package ID:** `com.mady.wherewasi`

## Design Philosophy

- **Privacy-first, local-only.** No accounts, no cloud, no tracking.
- **Single-purpose.** This app does one thing — reading — and does not
  try to become a general lifestyle tracker.
- **Finish over explore.** Scope discipline matters; features get added
  deliberately, not speculatively.

## License

TBD

