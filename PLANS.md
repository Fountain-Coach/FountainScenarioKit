# FountainScenarioKit Plan

## Goal

Provide one independently released, generic Swift/MIDI2 scenario seam for Fountain Coach consumers.

## Planned release — v0.2.0 semantic pipeline contract (2026-08-19)

- Add the product-neutral semantic pipeline stage identities, immutable source reference, receipt dependencies,
  per-operation lane provenance, framework/model revision, idempotency, and ordering validation.
- Keep Reframe views, Store, credentials, providers, and live acceptance outside the kit.
- Release only after package tests and a clean semver commit pass; Reframe consumes the tag, not a path or revision.

Release evidence: 11 tests pass, the generic-seam and dependency-boundary falsification checks pass, and the
consumer migration is intentionally a separate change after the upstream tag is published.

## Current release

- v0.1.1: initial scenario contract, lifecycle runtime, MIDI2 envelope codec, transport boundary, and test fixtures.
- Consumer: Reframe, via semver after the release is published.

## Acceptance

- [x] Clean package resolves from its manifest and lockfile.
- [x] Package tests prove codec round-trip, contract validation, lifecycle ordering, persistence-before-yield,
  idempotent replay, and transport adaptation.
- [x] No UI, Store, model, credential, or consumer-domain import exists.
- [x] Release tag and GitHub release are cut only from the tested commit.
- [ ] Consumer live acceptance remains owned by the consuming application.
