# Skill: release

## When this applies

Cutting a version of FountainScenarioKit, and moving a consumer onto it. Use it whenever the public API, lifecycle,
MIDI2 contract, or failure-evidence set has changed — and whenever a consumer needs a change that has not been
released yet (FCIS-KIT-08 forbids patching this package inside a consumer, including temporarily).

Do not use it for documentation-only edits that change no behaviour.

## Steps

1. **Confirm the working tree is the tagged state.** `git status --porcelain` must be empty. A release must not be
   cut from a tree that differs from the commit being tagged (FCIS-KIT-07).
2. **Run the suite on that commit.** `swift test` must be green. Record the count.
3. **Check the seam is still generic.** `rg -ni -e 'Reframe' -e 'Storify' -e 'Copilot' -e 'manuscript' -e 'writer' Sources/` must return
   nothing. A consumer's vocabulary arriving in this package is a KIT-03 defect, not a naming preference.
4. **Check the dependency boundary.** `rg -n '\.package\(' Package.swift` may show only the org-owned `midi2`
   package at its declared exact release; path dependencies and unapproved third-party packages are forbidden.
5. **Verify the compliance record.** Run the falsification block at the end of `FCIS_COMPLIANCE.md`. If any command
   disagrees with the file, fix the file in this change.
6. **Choose the version.** Additive seam → minor. Removal or narrowing of public API → major, and only after a
   prior release that deprecated it (FCIS-KIT-12). Bug fix with no surface change → patch.
7. **Update `PLANS.md`** with the phase this release closes and anything left open.
8. **Tag annotated and publish.** `git tag -a vX.Y.Z -m "…"`, then `gh release create vX.Y.Z --notes "…"`. Notes
   MUST name the seam added or changed and MUST state any breaking surface explicitly.
9. **Bump the consumer as its own change.** Manifest and resolved file plus the minimum adaptation the new version
   requires, and nothing else (FCIS-KIT-09). Record in the consumer's plan which tag it arrived from and what it
   brings — "updated dependencies" is not a record (FCIS-KIT-10).

## Output guarantees

- A published GitHub release whose tag points at a commit with a green suite and a clean tree.
- Release notes naming the seam and any breaking surface.
- A consumer bump that is single-purpose and carries counterpart provenance.
- No consumer depending on unreleased work in this package.
