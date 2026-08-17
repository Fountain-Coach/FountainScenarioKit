# FountainScenarioKit

[![Swift 6.1](https://img.shields.io/badge/Swift-6.1-orange.svg)](https://www.swift.org)
[![MIDI 2.0](https://img.shields.io/badge/MIDI-2.0-blue.svg)](https://www.midi.org/midi-2-0)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

FountainScenarioKit is the Fountain Coach org's generic Swift runtime seam for executable, event-driven scenarios.
It validates a tracked scenario projection, emits admitted/running/terminal lifecycle events, enforces idempotent
replay, and carries typed scenario messages over MIDI 2.0 UMP. `FountainScenarioTestKit` supplies deterministic
in-memory lifecycle and transport fixtures.

This is a public, reusable infrastructure package. It is the runtime half of Fountain Coach's
[Scenario-Driven Development](https://book.fountain.coach/scenario-driven-development/) approach: a scenario is a
versioned contract that can be executed, observed, and published with the same typed lifecycle as a production peer.

The kit owns no product vocabulary, UI, Store client, credential, model provider, or fixture corpus. A consumer binds
its operation identity, persistence adapter, actor topology, and independent AX/window witnesses at its boundary.

## Use

```swift
dependencies: [
    .package(url: "https://github.com/Fountain-Coach/FountainScenarioKit.git", from: "0.1.0")
]
```

The package depends only on the released `Fountain-Coach/midi2` package (`0.9.1`). It does not depend on a consumer
checkout or on a host transport implementation.

## Why Scenario-Driven Development

Traditional end-to-end work often leaves the specification in one language, the automation in another, and the proof
in screenshots or timing assumptions. Scenario-Driven Development makes the journey itself a governed artifact:
prerequisites, actors, typed actions, lifecycle events, terminal predicates, and evidence bindings are declared before
implementation. Development, acceptance, and publication therefore share one inspectable identity without making a
test harness the authority for product behavior.

MIDI 2.0 makes this practical as infrastructure rather than ceremony. Its typed, negotiated, event-oriented transport
lets a scenario actor communicate with the same operation boundary used by a software peer. Correlation, lifecycle,
reconnect, and failure can be observed as messages instead of reconstructed from sleeps, polling, or log interpretation.
AX, visual capture, and durable Store read-back remain independent witnesses; MIDI2 does not replace them.

## Boundary

The runtime is behavioral infrastructure, not self-approval. A consumer may use its lifecycle events as Store input,
but only independent behavioral, accessibility, window-ID, telemetry, and provenance evidence can promote a scenario
to live acceptance.

## Related Fountain Coach references

- [The Book of Reframe](https://book.fountain.coach/) — public human reference and scenario-development history;
- [Scenario-Driven Development](https://book.fountain.coach/scenario-driven-development/) — the public explanation;
- [Reframe governance](https://github.com/Fountain-Coach/Reframe-Refactoring) — operational doctrine and boundaries;
- [Fountain Coach FCIS standards](https://github.com/Fountain-Coach/.github/tree/main/docs) — organization standards.
