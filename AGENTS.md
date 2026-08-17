# FountainScenarioKit — Agent Guide

Scope: generic Swift scenario lifecycle and MIDI 2.0 transport contracts.

Invariants
- The scenario contract is loaded and validated before execution; the kit never invents a scenario from prose.
- Lifecycle is event-driven and idempotent. Timers, polling, UI access, Store access, and credential access do not
  belong in this package.
- The kit owns generic values only. Product operation identities, persistence, fixtures, AX, and visual evidence are
  consumer responsibilities.
- MIDI 2.0 is the typed operation/event transport boundary; a host supplies the negotiated transport.
- The kit cannot self-approve live acceptance. Independent consumer witnesses remain authoritative.
- Public API changes require a semver release. Never consume this repository by path, branch, or raw revision when a
  release exists.

FCIS-KIT and RFC instruction architecture are recorded in `FCIS_COMPLIANCE.md`.
