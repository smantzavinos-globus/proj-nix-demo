# Nix Demo — Long-term Vision + Implementation Phases

This document describes the **long-term vision** for the Nix demo program, and a **phased roadmap** (Phase 1–5) for evolving it from a small multi-repo upgrade demo into a realistic, org-scale pattern (CI, caching, templates, migration playbook).

## Why this demo exists

Many teams struggle with builds and upgrades because:

- dev machines drift (different compilers, Qt versions, transitive deps)
- CI builds differ from local builds
- upgrading a shared dependency across repos is painful and unpredictable

This demo makes those problems visible in a controlled scenario and demonstrates what **Nix Flakes** changes:

- pinned, reproducible development environments
- repeatable builds locally and in CI
- explicit, auditable upgrades (lockfile diffs)
- clear failure modes when an API breaks

## Audience

- Developers and tech leads
- DevOps / platform engineers
- Architects who need a clear mental model of “what Nix changes”

## The story (demo pitch)

1. Two apps rely on one shared library.
2. We upgrade the library.
3. One app keeps working; the other breaks.
4. The fix is small and deterministic.
5. Nix makes the build + upgrade reproducible across machines and (later) CI.

## Repository model

This is a **multi-repo** demo from the start.

- `nix-demo-corelib` — shared C++ library (versioned; intentionally introduces a breaking change)
- `nix-demo-viewer` — Qt5/QML app (read path only; stays compatible)
- `nix-demo-editor` — Qt5/QML app (read + write; breaks on upgrade until fixed)
- `proj-nix-demo` — umbrella/workspace repo that aggregates via git submodules and holds docs/scripts

### Why multi-repo?

- mirrors real org boundaries
- makes pinning and upgrade mechanics visible (one repo changes; many consumers react)
- naturally extends into CI and caching later

### Why an umbrella repo with submodules?

- one clone gives a “workspace” experience
- retains separate repo boundaries (the important part of the demo)
- provides a home for docs and helper scripts used during a live walkthrough

## Core design decisions

### Keep application logic intentionally simple

The demo is about Nix and dependency/version management, not app features.

### Breaking change should be compile-time and isolated

The upgrade should fail in an obvious, explainable way (e.g., function signature mismatch). This avoids runtime uncertainty during a live demo.

### Apps depend on corelib via flake inputs (not relative paths)

- Each app repo has its own `flake.lock`.
- Upgrades are performed by updating the pinned corelib reference (tag/ref) and re-locking.

### Linux-only (for now)

Phase 1 focuses on a single platform to reduce distraction and keep the demo reliable.

## Phase plan overview

Each phase is intended to be independently demoable. Later phases build on earlier phases but should not invalidate the simple Phase 1 story.

---

# Phase 1 — Shared library + two Qt/QML apps + controlled upgrade

## Goal

Establish the baseline demo:

- two Qt5/QML apps consume a shared C++ library
- corelib has two versions (`v1.0.0`, `v2.0.0`) with a deliberate breaking change
- viewer stays compatible; editor breaks then is fixed

## Design summary

### Domain model

A minimal “Item List”.

- v1: `Item { id, title }`
- v2: `Item { id, title, flagged }`

### Compatibility rules

- read path remains compatible
- write path introduces a breaking change

### Storage

- in-memory store with seeded data

### Build + packaging

- corelib is CMake installable and exports a config package
  - consumer uses `find_package(corelib CONFIG REQUIRED)`
- each repo provides a `flake.nix`:
  - pinned `nixpkgs`
  - dev shell with toolchain + Qt
  - `packages.default` for `nix build`
  - `apps.default` for `nix run` (apps only)

## Demo outcomes

- build/run viewer + editor against corelib v1
- upgrade pins to corelib v2
  - viewer still builds
  - editor fails to compile
- apply minimal editor fix
- rebuild: all green

---

# Phase 2 — Add a backend service that also depends on corelib

## Goal

Demonstrate that the same pinned dependency story works across different consumer types:

- desktop apps (Qt)
- a service / backend (gRPC/HTTP)

## Approach options

- **Minimal CLI service** built with CMake (fastest)
- **gRPC service** to demonstrate codegen + protobuf toolchain pinning

## What changes

- add a new repo (or module) for the backend service
- backend depends on corelib via flake input
- optional: backend stays compatible (read-only) or breaks (write usage)

## Demo extension

- upgrade corelib and show impact across 3 consumers

---

# Phase 3 — CI builds across repos + version pin matrix

## Goal

Show that the build is deterministic and that failures are due to code/API changes, not environment drift.

## Deliverables

- GitHub Actions (or equivalent) per repo:
  - `nix flake check`
  - `nix build`
- optional matrix:
  - apps pinned to corelib v1
  - apps pinned to corelib v2

## Demo outcomes

- consistent green builds across local + CI
- clear failure signals when a consumer is not updated

---

# Phase 4 — Binary cache

## Goal

Demonstrate org-scale speed gains and "build once, reuse everywhere".

## Deliverables

- integrate a binary cache provider (e.g., Cachix or internal cache)
- CI pushes build artifacts to cache

## Demo outcomes

- first build is the slow one
- subsequent builds (other machines/CI) are dramatically faster

---

# Phase 5 — Templates + migration playbook

## Goal

Convert the demo patterns into a reusable adoption toolkit for real teams.

## Deliverables

- “golden” repo templates:
  - a CMake core library repo template
  - a Qt application repo template
- migration playbook for existing CMake/Qt projects:
  - how to add a flake
  - how to structure packages/devShells
  - how to pin shared deps across repos
  - how to introduce CI + caching

## Demo outcomes

- teams can bootstrap new repos quickly
- teams can migrate existing repos with a clear, repeatable path

---

## Operational conventions

### Git URLs and submodules

- Submodules should use SSH URLs (e.g., `git@github.com:ORG/REPO.git`).
- Local machine conveniences (SSH config / `insteadOf`) are fine as long as they don’t create tracked diffs.

### Versioning and upgrade mechanics

- Demo-critical corelib states are tags on `main`:
  - `v1.0.0`
  - `v2.0.0`
- Apps upgrade corelib by changing the flake input ref and updating `flake.lock`.

## What “done” looks like, long term

- Phase 1: deterministic local builds and the break/fix story
- Phase 3: deterministic CI for all repos + clear upgrade signals
- Phase 4: cache-backed builds that are fast across machines
- Phase 5: the patterns are documented and repeatable for other projects
