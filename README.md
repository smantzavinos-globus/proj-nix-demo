# proj-nix-demo — Nix Flakes demo (Phase 1)

This repo is an **umbrella/workspace** that aggregates three independent flake-based repos via **git submodules**:

- `corelib/` — `nix-demo-corelib` (shared C++ library)
- `viewer/` — `nix-demo-viewer` (Qt5/QML read-only app)
- `editor/` — `nix-demo-editor` (Qt5/QML CRUD-lite app)

Phase 1 demonstrates a realistic upgrade story:

1. Two apps depend on one shared library.
2. We upgrade the library from **v1 → v2**.
3. **Viewer** (read-only) stays compatible.
4. **Editor** (write path) breaks at compile time.
5. The fix is small and deterministic.

The goal is to show what Nix Flakes gives you:

- pinned, reproducible environments across machines
- repeatable builds locally and in CI
- explicit, auditable dependency upgrades
- clear, localized failures when APIs break

## Prerequisites

- **Linux** (demo is Linux-only for now)
- **Nix with Flakes enabled**
- `git`
- Optional but recommended: `direnv` (each submodule provides a `.envrc` that should just contain `use flake`)

## Repo topology

This repo is intentionally *not* a monorepo build.

Each submodule:

- has its own `flake.nix` + `flake.lock`
- can be built and run independently (`nix build`, `nix run`)
- depends on `corelib` only via **flake inputs** (not relative paths)

The umbrella repo exists purely for convenience (one clone, one place for docs/scripts).

## Quickstart

```bash
# Clone and initialize submodules
git clone --recurse-submodules git@github.com:smantzavinos-globus/proj-nix-demo.git
# If already cloned:
# git submodule update --init --recursive

# Optional: direnv
# (you'll typically run this inside each submodule)
# direnv allow
```

Build and run each app from its own repo:

```bash
cd viewer
nix build
nix run

cd ../editor
nix build
nix run
```

## Phase 1 domain + compatibility story

We model a tiny "Item List" domain.

- **corelib v1** defines an `Item` with `id` and `title`.
- **corelib v2** adds a new field: `flagged`.

The read path remains compatible; the write path intentionally breaks.

### Conceptual API

corelib v1:

- `listItems() -> std::vector<Item>`
- `upsertItem(id, title)`
- `deleteItem(id)`

corelib v2:

- `listItems() -> std::vector<Item>` (unchanged)
- `upsertItem(id, title, flagged)` (**breaking change**; old overload removed)
- `deleteItem(id)`

Storage is **in-memory** in Phase 1.

## Demo runbook (speaker-friendly)

### 0) Baseline: apps pinned to corelib v1

In `viewer/flake.nix` and `editor/flake.nix`, the corelib input should reference `v1.0.0`.

Build both:

```bash
(cd viewer && nix build)
(cd editor && nix build)
```

Run them:

```bash
(cd viewer && nix run)
(cd editor && nix run)
```

### 1) Upgrade: bump corelib from v1 → v2

**Edit** both app repos:

- `viewer/flake.nix`: change corelib `ref` from `v1.0.0` → `v2.0.0`
- `editor/flake.nix`: change corelib `ref` from `v1.0.0` → `v2.0.0`

Then (optional but recommended) update the lock files so the upgrade is explicit and reviewable:

```bash
(cd viewer && nix flake lock --update-input corelib)
(cd editor && nix flake lock --update-input corelib)
```

Rebuild:

```bash
(cd viewer && nix build)
(cd editor && nix build)
```

Expected result:

- Viewer still builds (read-only usage)
- Editor fails to build with an obvious signature mismatch (write path)

### 2) Fix: update Editor for v2

Apply the minimal Editor patch to pass `flagged` (use `false` as the default).

Rebuild and rerun:

```bash
(cd editor && nix build)
(cd editor && nix run)
```

## Helper scripts (umbrella repo)

These are convenience wrappers; the authoritative commands are still per-submodule.

Planned scripts:

- `scripts/init.sh` — init/update submodules
- `scripts/build_all.sh` — build `corelib`, `viewer`, `editor`
- `scripts/run_viewer.sh` — run Viewer
- `scripts/run_editor.sh` — run Editor
- `scripts/demo_break.sh` — bump pins to v2 and show editor break (optional)
- `scripts/demo_fix.sh` — apply the editor fix (optional)

## Notes / conventions

- Repos should use SSH URLs in their git remotes (submodules already do).
- Demo-critical corelib states are tags on `main`:
  - `v1.0.0`
  - `v2.0.0`

## Phase 1 acceptance criteria

- `nix build` works for Viewer and Editor pinned to corelib `v1.0.0`
- after bumping corelib to `v2.0.0`:
  - Viewer still builds
  - Editor fails
- a small Editor change restores compatibility
