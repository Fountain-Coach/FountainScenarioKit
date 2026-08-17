# FountainScenarioKit Plan

## Goal

Provide one independently released, generic Swift/MIDI2 scenario seam for Fountain Coach consumers.

## Current release

- v0.1.0: initial scenario contract, lifecycle runtime, MIDI2 envelope codec, transport boundary, and test fixtures.
- Consumer: Reframe, via semver after the release is published.

## Acceptance

- [x] Clean package resolves from its manifest and lockfile.
- [x] Package tests prove codec round-trip, contract validation, lifecycle ordering, persistence-before-yield,
  idempotent replay, and transport adaptation.
- [x] No UI, Store, model, credential, or consumer-domain import exists.
- [x] Release tag and GitHub release are cut only from the tested commit.
- [ ] Consumer live acceptance remains owned by the consuming application.
