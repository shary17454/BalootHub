# Flutter to Native iOS Migration Audit

## Scope

This audit records Phase 1 findings for the requested Flutter-to-native iOS readiness work.

Repository inspected:

`/Users/shrybnhshymbnmrzwqbnhwyd/Developer/Projects/BalootHub`

## Flutter/Dart Evidence

No Flutter or Dart implementation was found in the current repository.

Checks performed:

- Searched for `pubspec.yaml`, `pubspec.lock`, `.flutter-plugins`, `.flutter-plugins-dependencies`, Dart files, Flutter iOS folders, and common Flutter metadata.
- Searched source text for `Flutter`, `Dart`, `GeneratedPluginRegistrant`, `FLUTTER`, and `flutter`.

Result: no matching Flutter/Dart files or runtime references were found.

## Native Implementation Evidence

The repository is already implemented as a native iOS project:

- `BalootHub.xcodeproj`
- SwiftUI app entry point in `BalootHub/App/BalootHubApp.swift`
- SwiftData models and persistence in `BalootHub/Domain/Models` and `BalootHub/Core/Persistence`
- Native Swift local package in `Packages/BalootEngine`
- XCTest app tests in `BalootHubTests`
- Swift package tests in `Packages/BalootEngine/Tests`

## Feature Areas Present

The current native codebase includes:

- Baloot game table.
- Full bidding-oriented engine types.
- Sun/Hokum game mode handling.
- Project detection and project statistics.
- Multipliers and rare-case references.
- What-to-play trainer with analysis, replay hooks, and share card support.
- Hand analysis.
- Baloot academy.
- Scoring quiz.
- Scorekeeper.
- Player statistics.
- Offline tournaments.
- Achievements.
- Daily and weekly challenges.
- Baloot sandbox.
- Encyclopedia and rare-case library.

These features still need requirement-by-requirement verification before they can be declared fully complete against the full product specification.

## Phase 1 Risks Found

- README and App Store privacy draft still described IAP as active even after the App Review fix disabled IAP for the current build.
- README claimed the app was iPhone-only, while the long-term production specification requires iPhone and iPad support. The current Xcode setting confirms iPhone-only support, so iPad must remain an explicit future production task.
- Exact test-count statements in README were stale because the repository now contains many more tests than the older documented count.
- There is no dedicated architecture or migration audit document prior to this Phase 1 pass.

## Phase 1 Actions Taken

- Added `Docs/ARCHITECTURE.md`.
- Added this migration audit.
- Updated public-facing project documentation to match the current IAP review-safe behavior.
- Avoided claiming iPad support or full production readiness before verification.

## Next Phase Gate

Before moving into broader implementation phases, the next safe engineering steps are:

1. Run the full app and engine test suites.
2. Generate or archive a Release build with a new build number for App Review.
3. Decide whether the current submission should remain free with IAP disabled or re-enable IAP only after the App Store Connect product is submitted for review.
4. Audit iPad support separately before changing `TARGETED_DEVICE_FAMILY`.
