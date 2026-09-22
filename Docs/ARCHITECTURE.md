# Baloot Hub Architecture

## Current State

Baloot Hub is currently a native iOS codebase. Phase 1 verification found no Flutter or Dart project files, no `pubspec.yaml`, no Dart sources, and no Flutter registrant or runtime references.

The application is split into two main layers:

- `BalootHub/`: the iOS app target, built with SwiftUI and SwiftData.
- `Packages/BalootEngine/`: a local Swift package that owns Baloot rules, deterministic state transitions, scoring, bidding, projects, replayable actions, AI agents, training analysis, and sandbox logic.

This separation keeps game rules out of SwiftUI views and makes the engine testable with `swift test`.

## App Target Structure

- `App/`: app entry point, tab routing, and navigation state.
- `Core/DesignSystem/`: shared colors, spacing, typography, animation constants, and reusable UI components.
- `Core/Persistence/`: SwiftData container setup, fallback behavior, and catalog seeding.
- `Core/Utilities/`: logging and cancellable task helpers.
- `Domain/Models/`: SwiftData models for settings, score sessions, tournaments, academy progress, scoring quiz attempts, what-to-play attempts, and catalog entities.
- `Domain/Repositories/`: persistence access helpers.
- `Domain/Services/`: app-level business services that remain UI-independent where possible.
- `Features/`: SwiftUI feature areas such as game play, scorekeeper, academy, challenges, sandbox, catalog, settings, and history.

## Engine Package Structure

- `Cards/`: suits, ranks, playing cards, and deck construction.
- `Rules/`: game modes and configurable Baloot rules.
- `Bidding/`: bids, bidding state, bidding policy, and hand evaluation.
- `Scoring/`: score calculation, multipliers, projects, and project detection.
- `State/`: replayable game state, phases, tricks, and actions.
- `Validation/`: turn and legal move validation.
- `AI/`: agent protocol, profiles, simple/smart/expert agents.
- `Training/`: what-to-play scenarios, hand analysis, round analysis, and sandbox helpers.

## Determinism Requirements

The engine must remain deterministic:

- Use explicit ordinals or stable raw values for seeds and sorting.
- Do not use Swift `hashValue` for seeded behavior, replay, AI, or persistence identity.
- Record user-visible game decisions as actions/events so replay can rebuild the same state.
- Keep heavy analysis and AI search off the main thread.

## Persistence

SwiftData is the local persistence layer. The app stores user data on-device only:

- Score sessions and rounds.
- User settings and house rules.
- What-to-play attempts and progress.
- Academy progress.
- Scoring quiz attempts.
- Offline tournaments.
- Project declaration statistics.

The container falls back to an in-memory store if the persistent store cannot open, preserving the on-disk data for a later recovery update.

## Commerce State

The current source includes StoreKit 2 subscription handling and a Baloot Plus purchase view. Product
availability, metadata, review screenshots, and submission status are external App Store Connect state
and must be verified there before release. Keep the app usable if product loading or purchase verification
fails, and test purchase, restore, renewal, and cancellation in Sandbox.

## Current Compliance Notes

- No Flutter/Dart runtime dependency was found.
- No custom Info.plist file is present; Info.plist values are generated from Xcode build settings.
- No entitlements file was found in the repository during Phase 1 inspection.
- No privacy permissions such as camera, microphone, location, contacts, or photos were found.
- Xcode currently targets iPhone and iPad (`TARGETED_DEVICE_FAMILY = 1,2`). This setting confirms target configuration, not complete visual or functional QA for every iPad layout.
