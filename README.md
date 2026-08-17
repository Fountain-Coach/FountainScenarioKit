# FountainScenarioKit

FountainScenarioKit is the Fountain Coach org's generic Swift runtime seam for executable, event-driven scenarios.
It validates a tracked scenario projection, emits admitted/running/terminal lifecycle events, enforces idempotent
replay, and carries typed scenario messages over MIDI 2.0 UMP. `FountainScenarioTestKit` supplies deterministic
in-memory lifecycle and transport fixtures.

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

## Boundary

The runtime is behavioral infrastructure, not self-approval. A consumer may use its lifecycle events as Store input,
but only independent behavioral, accessibility, window-ID, telemetry, and provenance evidence can promote a scenario
to live acceptance.
