# FCIS Compliance — FountainScenarioKit

Assessed at the `v0.1.1` release against the Fountain Coach org standards published in `Fountain-Coach/.github`.

## Binding

### RFC 0001 — Orthogonal Instruction Architecture

`AGENTS.md` carries law, `PLANS.md` carries intent and gates, and the package has no MCP or workflow configuration.

### FCIS-KIT — Owned Kits, Factoring and Release

| Rule | Evidence |
| --- | --- |
| KIT-01 | This declaration and the Reframe consumer declaration name the kit and semver mode. |
| KIT-02 | The only dependency is the org-owned `midi2` package; no new third-party capability is introduced. |
| KIT-03 | The seam is generic: operation identity, persistence, actor, fixture, and UI decisions are supplied by consumers. |
| KIT-04 | The package is released as immutable semver `v0.1.0`; consumers use `from: "0.1.0"`. |
| KIT-05 | No revision pins. |
| KIT-06 | No path or external checkout dependencies. |
| KIT-07 | The release is an annotated tag and GitHub release from a passing package suite. |
| KIT-08 | The kit is released upstream before Reframe consumes it. |
| KIT-09 | Consumer migration is a single-purpose dependency bump/removal of the in-repo copy. |
| KIT-10 | Reframe records the release tag and migration commit in its plan. |
| KIT-11 | The kit suite proves its own lifecycle, codec, contract, persistence, and transport seam. |
| KIT-12 | No public API is removed in `v0.1.0`. |
| KIT-13 | No user interface or rendered output is shipped by this package. |

### FCIS Publication and Source Policy

This repository is public by an explicit visibility decision on 2026-08-17. The public scope is limited to the
generic package contract, tests, governance-facing documentation, and release provenance. It contains no Reframe
runtime source, private Store records, credentials, deployment details, manuscript material, or consumer fixtures.
The public Book and governance links are intentional; they do not expose the private Reframe implementation.

## Not binding

- FCIS-AX: no UI target; AX is required at the Reframe consumer surface.
- FCIS-VRT: no rendered output.
- FCIS-AIC-Preflight: no model, prompt, or intelligence invocation.
- Publication/source policy: the repository contains no private Store records, manuscript material, credentials, or
  consumer fixtures.

## Falsification

```sh
rg -n 'import (SwiftUI|AppKit|UIKit|FoundationModels|CoreML)' Sources/   # must be empty
rg -n '\.package\(.*path:' Package.swift                              # must be empty
swift test
```
