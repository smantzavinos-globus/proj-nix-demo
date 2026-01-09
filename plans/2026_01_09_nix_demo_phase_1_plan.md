# Phase 1 Implementation Plan — Nix Flakes demo (corelib + viewer + editor)

**Scope:** Implement Phase 1 as described in `/README.md`.

**Repos (submodules):**

- `corelib/` → `nix-demo-corelib` (shared C++ library)
- `viewer/` → `nix-demo-viewer` (Qt5/QML read-only consumer)
- `editor/` → `nix-demo-editor` (Qt5/QML read+write consumer)

---

## 1) Goals / Non-goals

### 1.1 Goals (Phase 1)

Phase 1 is complete when the following are true:

1. **Three independent repos** (corelib/viewer/editor) each build in isolation using Nix Flakes.
2. **flake-only dependency wiring:** viewer/editor depend on corelib **via flake inputs** (no relative paths, no umbrella repo coupling).
3. **Versioned corelib upgrade demo:** corelib has tags:
   - `v1.0.0`
   - `v2.0.0`
4. **Compatibility story is deterministic:**
   - viewer pinned to corelib `v1.0.0` builds and runs
   - editor pinned to corelib `v1.0.0` builds and runs
   - after upgrading the pin to `v2.0.0`:
     - viewer still builds (no code changes)
     - editor fails at compile time with an obvious signature mismatch
   - a *small* editor patch restores compatibility with v2
5. **Strict TDD is followed** for all code changes (corelib and apps).

### 1.2 Non-goals (explicitly out of scope for Phase 1)

- Persistent storage / file IO / JSON migrations
- Networking or a backend service (that is Phase 2)
- CI pipelines, matrices, or caching (Phases 3–4)
- Multi-platform support (Linux-only for now)
- Polished UI/UX (UI should be minimal; correctness and build determinism matter)

---

## 2) Constraints / Guidelines (non-negotiable)

### 2.1 Constraints

- Consumers depend on corelib **only via flake inputs**.
  - No `add_subdirectory(../corelib)` or relative include/link paths.
  - The umbrella repo must never become a build system.
- Corelib versions are represented as **git tags on `main`**: `v1.0.0`, `v2.0.0`.
- The breaking change must produce a **clear compile-time error** in Editor after upgrade.
- Storage is **pure in-memory** for Phase 1.
- Qt is **Qt5**.
- Linux-only is acceptable.

### 2.2 Repo conventions

Each repo should provide:

- `flake.nix` and `flake.lock`
- `packages.<system>.default` so `nix build` works
- For apps (viewer/editor): `apps.<system>.default` so `nix run` works
- A `.envrc` containing only:

  ```bash
  use flake
  ```

### 2.3 Build system guideline (CMake packaging)

Corelib must be CMake-installable and export a config package so consumers can use:

```cmake
find_package(corelib CONFIG REQUIRED)
target_link_libraries(app PRIVATE corelib::corelib)
```

This must work **without** knowledge of the umbrella layout.

---

## 3) Strict TDD protocol (required)

Every implementation step below must follow TDD. This is not optional.

### 3.1 The cycle

For each feature/behavior:

1. Write a **failing test** that captures the intended behavior.
2. Run tests to confirm they **fail for the right reason**.
3. Implement the minimal code to pass the test.
4. Run tests to confirm they **pass**.
5. Refactor only if needed; re-run tests after refactors.

### 3.2 What counts as a “test” in Phase 1

- **corelib:** C++ unit tests run by CTest (framework is allowed, but keep dependencies minimal).
- **viewer/editor:** at minimum, the build itself is a test gate:
  - `nix build` must fail when wiring is wrong
  - `nix build` must pass when correct

UI testing is not required in Phase 1.

### 3.3 Evidence requirements

For every milestone, record in the Progress Log:

- the “red” step: command + observed failure
- the “green” step: command + observed success

For the breaking upgrade milestone, capture the exact compiler error produced by Editor.

### 3.4 Prohibitions

- no “test later”
- no skipping red → green
- no weakening tests to hide failures
- no suppressing errors/warnings to make builds pass

---

## 4) Status tracking

### 4.1 Work item states

- **TODO** — not started
- **IN PROGRESS** — actively being worked
- **BLOCKED** — cannot proceed (must describe blocker and unblock condition)
- **DONE** — completed and verified (with evidence recorded)

### 4.2 Milestone scoreboard

| Milestone | Description | Owner | Status | Evidence |
|---|---|---:|---|---|
| M0 | Baseline repo hygiene and scaffolding |  | DONE | All three repos: `nix build` ✅, `.envrc` = `use flake` ✅ |
| M1 | `corelib` v1 API + tests + flake + CMake package export |  | DONE | `nix build` ✅, `nix flake check` ✅, tag `v1.0.0` pushed |
| M2 | `viewer` v1 consumes corelib v1 + runs |  | DONE | `nix build` ✅, `nix run` ✅, flake input pinned to v1.0.0 |
| M3 | `editor` v1 consumes corelib v1 + runs |  | DONE | `nix build` ✅, `nix run` ✅, CRUD operations working |
| M4 | `corelib` v2 breaking change + tests + tag |  | DONE | `nix build` ✅, tag `v2.0.0` pushed, breaking API verified |
| M5 | Upgrade viewer/editor to corelib v2 (viewer ok, editor breaks) |  | DONE | Viewer builds ✅, Editor fails with expected signature error |
| M6 | Fix editor for v2 + verify end-to-end demo |  | DONE | `nix build` ✅, minimal fix (add `false` for flagged arg) |
| M7 | Umbrella helper scripts implemented + documented |  | DONE | All scripts verified: init.sh, build_all.sh, run_*.sh |

---

## 5) Phase 1 deliverables (Definition of Done)

A Phase 1 “done” means:

- Corelib:
  - tags exist: `v1.0.0`, `v2.0.0`
  - `nix build` succeeds for both tagged versions
  - core API is covered by unit tests
  - CMake package export works (`find_package(corelib CONFIG REQUIRED)`)
- Viewer:
  - pinned to corelib `v1.0.0`: `nix build` and `nix run` succeed
  - pinned to corelib `v2.0.0`: `nix build` and `nix run` succeed with **no code changes**
- Editor:
  - pinned to corelib `v1.0.0`: `nix build` and `nix run` succeed
  - pinned to corelib `v2.0.0` before fix: `nix build` fails with a clear signature mismatch
  - after minimal fix: `nix build` and `nix run` succeed
- Umbrella repo:
  - helper scripts exist and work as wrappers around per-repo commands
  - docs reflect the intended demo flow

---

## 6) Implementation milestones (explicit steps)

### 6.0 Gate checklist (milestone entry/exit criteria)

These gates are **hard requirements**.

- Do not start a milestone until its **entry gate** is satisfied.
- Do not mark a milestone **DONE** until its **exit gate** is satisfied and the required evidence is recorded in the Progress Log.

#### M0 gates

- **Entry gate:**
  - Submodules initialized: `git submodule update --init --recursive`
- **Exit gate:**
  - `(cd corelib && nix build)` succeeds
  - `(cd viewer && nix build)` succeeds
  - `(cd editor && nix build)` succeeds
  - `.envrc` in each repo is exactly:

    ```bash
    use flake
    ```

#### M1 gates (corelib v1)

- **Entry gate:**
  - M0 exit gate satisfied
- **Exit gate:**
  - Corelib unit tests exist and run as part of the flake build/check flow
  - `(cd corelib && nix build)` succeeds from a clean tree
  - Consumer-level proof exists that `find_package(corelib CONFIG REQUIRED)` works (can be a tiny throwaway consumer in the viewer/editor repo during wiring, captured in Progress Log)
  - Tag `v1.0.0` created and pushed in `nix-demo-corelib`

#### M2 gates (viewer pinned to corelib v1)

- **Entry gate:**
  - M1 exit gate satisfied (including `v1.0.0` tag available remotely)
- **Exit gate:**
  - `viewer/flake.nix` pins corelib via `ref=v1.0.0` and `viewer/flake.lock` is updated
  - Viewer CMake uses `find_package(corelib CONFIG REQUIRED)` (no manual include/link to local paths)
  - `(cd viewer && nix build)` succeeds
  - `(cd viewer && nix run)` launches successfully

#### M3 gates (editor pinned to corelib v1)

- **Entry gate:**
  - M1 exit gate satisfied (including `v1.0.0` tag available remotely)
- **Exit gate:**
  - `editor/flake.nix` pins corelib via `ref=v1.0.0` and `editor/flake.lock` is updated
  - Editor CMake uses `find_package(corelib CONFIG REQUIRED)`
  - `(cd editor && nix build)` succeeds
  - `(cd editor && nix run)` launches successfully

#### M4 gates (corelib v2)

- **Entry gate:**
  - M2 + M3 exit gates satisfied (viewer/editor green on `v1.0.0`)
- **Exit gate:**
  - Corelib unit tests cover `flagged` and the new write API
  - Old v1 `upsertItem(id, title)` overload is removed (cannot compile against it)
  - `(cd corelib && nix build)` succeeds
  - Tag `v2.0.0` created and pushed in `nix-demo-corelib`

#### M5 gates (upgrade pins to v2)

- **Entry gate:**
  - M4 exit gate satisfied (including `v2.0.0` tag available remotely)
- **Exit gate:**
  - Viewer pinned to `ref=v2.0.0` (lock updated) and `(cd viewer && nix build)` succeeds
  - Editor pinned to `ref=v2.0.0` (lock updated) and `(cd editor && nix build)` **fails**
  - The editor compiler error is captured verbatim in the Progress Log

#### M6 gates (editor fix)

- **Entry gate:**
  - M5 exit gate satisfied (editor failing on v2 in the expected way)
- **Exit gate:**
  - Minimal editor change applied (passes `flagged`, default `false`)
  - `(cd editor && nix build)` succeeds
  - `(cd editor && nix run)` launches successfully

#### M7 gates (umbrella scripts)

- **Entry gate:**
  - M6 exit gate satisfied
- **Exit gate:**
  - Scripts exist in `proj-nix-demo/scripts/` and run successfully on a clean checkout:
    - `scripts/init.sh`
    - `scripts/build_all.sh`
    - `scripts/run_viewer.sh`
    - `scripts/run_editor.sh`
  - Scripts remain wrappers only (no relative-path dependency wiring)

> **Important:** The umbrella repo is not where dependencies are wired. All wiring is per-submodule, through flakes.

### M0 — Baseline repo hygiene and scaffolding

**Goal:** Make sure all three repos are ready for iterative implementation.

**Steps:**

1. Ensure each submodule repo has:
   - a working `flake.nix`
   - a `.envrc` with `use flake`
   - `flake.lock` committed
   - simple `README.md` (umbrella README is primary)
2. Standardize commands supported by each repo:
   - `nix build`
   - `nix develop`
   - `nix run` (viewer/editor)

**TDD note:** Here “tests” are mostly build gates. Your “red” can be a failing `nix build` caused by intentionally missing wiring, then “green” after fixing.

**Verification / evidence:**

- `(cd corelib && nix build)`
- `(cd viewer && nix build)`
- `(cd editor && nix build)`

**Status:** TODO

---

### M1 — corelib v1 API + tests + flake + CMake package export

**Goal:** Implement corelib v1 as a CMake-installable package with stable read API and write APIs that will later break.

**Proposed API (final names can vary, but must be consistent across repos):**

- `listItems() -> std::vector<Item>`
- `upsertItem(id, title)`
- `deleteItem(id)`

**Data model (v1):**

- `Item { std::string id; std::string title; }`

**Storage:** in-memory store seeded with a few items.

**TDD steps:**

1. Write failing unit tests for:
   - listing seeded items returns expected count/contents
   - upsert creates a new item
   - upsert updates title for existing id
   - delete removes an item
2. Implement minimal corelib code to pass tests.
3. Implement CMake install/export:
   - install headers
   - install library target
   - install/export `corelibConfig.cmake` (or equivalent)
   - exported target name: `corelib::corelib`
4. Ensure flake builds and runs tests in checks (either via `doCheck = true` with `ctest`, or via `checks.<system>`).

**Tag:** create and push `v1.0.0`.

**Verification / evidence:**

- `(cd corelib && nix build)`
- `(cd corelib && nix flake check)` (if enabled)
- record unit test command + output (ctest)

**Status:** TODO

---

### M2 — viewer v1 consumes corelib v1 (read-only)

**Goal:** Viewer compiles and runs against corelib v1 using only the read API.

**Dependency wiring requirement:** Viewer depends on corelib via flake input pinned by ref:

- `inputs.corelib.url = "github:smantzavinos-globus/nix-demo-corelib?ref=v1.0.0"`

**TDD steps:**

1. Make CMake require corelib via:

   ```cmake
   find_package(corelib CONFIG REQUIRED)
   ```

   This should initially fail (red) until the flake provides corelib in the build environment/path.
2. Update `flake.nix` to include the corelib package in build inputs and pass any required CMake flags so `find_package` can locate it.
3. Implement minimal C++ glue to call `listItems()` and expose data to QML.
4. QML renders a list (minimal UI is fine).

**Verification / evidence:**

- `(cd viewer && nix build)`
- `(cd viewer && nix run)`

**Status:** TODO

---

### M3 — editor v1 consumes corelib v1 (read + write)

**Goal:** Editor compiles and runs against corelib v1 and exercises write APIs.

**Dependency wiring requirement:** Editor depends on corelib via flake input pinned by ref:

- `inputs.corelib.url = "github:smantzavinos-globus/nix-demo-corelib?ref=v1.0.0"`

**TDD steps:**

1. Wire corelib via `find_package(corelib CONFIG REQUIRED)`.
2. Implement minimal editor logic:
   - list items
   - add/update item via `upsertItem(id, title)`
   - delete item via `deleteItem(id)`

**Verification / evidence:**

- `(cd editor && nix build)`
- `(cd editor && nix run)`

**Status:** TODO

---

### M4 — corelib v2 breaking change + tests + tag

**Goal:** Create v2 that keeps viewer-compatible read behavior but breaks editor write API at compile-time.

**Change:**

- Add `flagged` to Item
- Keep `listItems()` usable without source changes
- Break write API by removing the v1 overload:
  - v1: `upsertItem(id, title)`
  - v2: `upsertItem(id, title, flagged)`

**TDD steps:**

1. Add failing unit tests for v2 behavior:
   - `listItems()` still works and returns items with `flagged` set deterministically
   - `upsertItem(id, title, flagged)` stores `flagged`
2. Implement the v2 changes.
3. Ensure the old overload is removed.

**Tag:** create and push `v2.0.0`.

**Verification / evidence:**

- `(cd corelib && nix build)`
- unit test output captured

**Status:** TODO

---

### M5 — Upgrade viewer/editor to corelib v2 (viewer ok, editor breaks)

**Goal:** Demonstrate the upgrade behavior in a controlled way.

**Steps:**

1. In `viewer/flake.nix`, change the corelib ref:
   - `v1.0.0` → `v2.0.0`
2. In `editor/flake.nix`, change the corelib ref:
   - `v1.0.0` → `v2.0.0`
3. (Recommended) update locks:

   ```bash
   (cd viewer && nix flake lock --update-input corelib)
   (cd editor && nix flake lock --update-input corelib)
   ```

4. Rebuild:

   ```bash
   (cd viewer && nix build)
   (cd editor && nix build)
   ```

**Expected / evidence:**

- Viewer: build success
- Editor: compile-time error about missing `flagged` argument
  - paste the full compiler error into the Progress Log

**Status:** TODO

---

### M6 — Fix editor for v2 + verify end-to-end demo

**Goal:** Minimal editor change restores compatibility with corelib v2.

**TDD steps:**

1. Use the failing compiler error from M5 as the “red”.
2. Apply minimal change: pass a default `flagged` (use `false`).
3. Rebuild and re-run.

**Verification / evidence:**

- `(cd editor && nix build)`
- `(cd editor && nix run)`

**Status:** TODO

---

### M7 — Umbrella helper scripts implemented + documented

**Goal:** Make the live demo repeatable from `proj-nix-demo` without turning it into a monorepo build.

**Scripts:**

- `scripts/init.sh` — init/update submodules
- `scripts/build_all.sh` — runs `nix build` per submodule
- `scripts/run_viewer.sh` — runs viewer
- `scripts/run_editor.sh` — runs editor
- `scripts/demo_break.sh` — bumps refs to v2 (optional)
- `scripts/demo_fix.sh` — guides/apply editor fix (optional)

**Rules:**

- Scripts are wrappers around per-repo commands.
- No relative-path dependency wiring.

**Verification / evidence:**

- run each script successfully on a clean checkout with submodules initialized

**Status:** TODO

---

## 7) Progress log (append-only)

> Every entry must include date/time, repo, milestone, and command output summaries.

### Template

- **Date:** YYYY-MM-DD
- **Repo:** corelib | viewer | editor | proj-nix-demo
- **Milestone:** M#
- **Change summary:** …
- **TDD evidence:**
  - **Red:** command + failure summary
  - **Green:** command + success summary
- **Verification commands:**
  - `nix build`: ✅/❌
  - `nix run`: ✅/❌ (apps)
  - `nix flake check`: ✅/❌ (if enabled)
- **Notes / follow-ups:** …

---

### M0 — 2026-01-09

- **Repo:** editor (primary), corelib, viewer (verified)
- **Milestone:** M0
- **Change summary:** Scaffolded editor repo with Qt5/QML skeleton, flake.nix, .envrc. Verified all three repos build with `nix build`.
- **TDD evidence:**
  - **Red:** editor had no flake.nix, CMakeLists.txt, or source files
  - **Green:** created scaffolding; `(cd editor && nix build)` succeeds
- **Verification commands:**
  - `(cd corelib && nix build)`: ✅
  - `(cd viewer && nix build)`: ✅
  - `(cd editor && nix build)`: ✅
  - `.envrc` = `use flake` in all three repos: ✅
- **Notes / follow-ups:** editor committed with skeleton; proceed to M1

---

### M1 — 2026-01-09

- **Repo:** corelib
- **Milestone:** M1
- **Change summary:** Replaced gRPC calculator demo with Item API. Static library with CMake package export (`corelib::corelib`). Catch2 unit tests.
- **TDD evidence:**
  - **Red:** Tests written first; 5/6 failed (no implementation)
  - **Green:** ItemStore implemented; all 6 tests pass
- **Verification commands:**
  - `(cd corelib && nix build)`: ✅
  - `(cd corelib && nix flake check)`: ✅ (build + format checks pass)
- **Tag:** `v1.0.0` created and pushed
- **Notes / follow-ups:** Proceed to M2 (viewer) and M3 (editor)

---

### M2 — 2026-01-09

- **Repo:** viewer
- **Milestone:** M2
- **Change summary:** Wired viewer to corelib v1.0.0 via flake input. Implemented ItemListModel (QAbstractListModel) for read-only list display.
- **TDD evidence:**
  - **Red:** `find_package(corelib CONFIG REQUIRED)` failed before flake wiring
  - **Green:** Flake input + CMAKE_PREFIX_PATH configured; build succeeds
- **Verification commands:**
  - `(cd viewer && nix build)`: ✅
  - `(cd viewer && nix run)`: ✅
- **Notes / follow-ups:** Viewer displays item list; proceed to M3

---

### M3 — 2026-01-09

- **Repo:** editor
- **Milestone:** M3
- **Change summary:** Wired editor to corelib v1.0.0 via flake input. Implemented ItemListModel with addItem(), updateItem(), deleteItem() Q_INVOKABLE methods. QML UI with add/edit/delete controls.
- **TDD evidence:**
  - **Red:** Build failed before flake wiring
  - **Green:** Flake configured; CRUD operations working
- **Verification commands:**
  - `(cd editor && nix build)`: ✅
  - `(cd editor && nix run)`: ✅
- **Notes / follow-ups:** Editor CRUD working; proceed to M4

---

### M4 — 2026-01-09

- **Repo:** corelib
- **Milestone:** M4
- **Change summary:** Added `bool flagged` field to Item struct. Changed `upsertItem(id, title)` to `upsertItem(id, title, flagged)` — old overload removed (breaking change).
- **TDD evidence:**
  - **Red:** Updated tests to require 3-arg upsertItem; failed before implementation
  - **Green:** ItemStore updated; all tests pass
- **Verification commands:**
  - `(cd corelib && nix build)`: ✅
- **Tag:** `v2.0.0` created and pushed
- **Notes / follow-ups:** Breaking API ready; proceed to M5

---

### M5 — 2026-01-09

- **Repo:** viewer, editor
- **Milestone:** M5
- **Change summary:** Upgraded both apps to corelib v2.0.0 via flake input ref change.
- **TDD evidence:**
  - **Viewer:** Build succeeds (read-only, no code changes needed)
  - **Editor:** Build fails with expected signature mismatch
- **Captured compiler error:**
  ```
  error: no matching function for call to 'corelib::ItemStore::upsertItem(std::string, std::string)'
  note: candidate: 'void corelib::ItemStore::upsertItem(const std::string&, const std::string&, bool)'
  note: candidate expects 3 arguments, 2 provided
  ```
- **Verification commands:**
  - `(cd viewer && nix build)`: ✅
  - `(cd editor && nix build)`: ❌ (expected)
- **Notes / follow-ups:** Demo break captured; proceed to M6

---

### M6 — 2026-01-09

- **Repo:** editor
- **Milestone:** M6
- **Change summary:** Minimal fix: added `false` as third argument to both `upsertItem()` calls in editor/src/main.cpp.
- **TDD evidence:**
  - **Red:** M5 compiler error (signature mismatch)
  - **Green:** After fix, `nix build` succeeds
- **Verification commands:**
  - `(cd editor && nix build)`: ✅
  - `(cd editor && nix run)`: ✅
- **Notes / follow-ups:** Demo cycle complete; proceed to M7

---

### M7 — 2026-01-09

- **Repo:** proj-nix-demo (umbrella)
- **Milestone:** M7
- **Change summary:** Created helper scripts in `scripts/` directory: init.sh, build_all.sh, run_viewer.sh, run_editor.sh
- **Verification commands:**
  - `scripts/init.sh`: ✅ (submodules initialized)
  - `scripts/build_all.sh`: ✅ (all three repos build)
  - `scripts/run_viewer.sh`: ✅ (launches viewer)
  - `scripts/run_editor.sh`: ✅ (launches editor)
- **Notes / follow-ups:** Phase 1 complete!

---

## 8) Open questions / decisions log

Track decisions here if anything needs to be chosen during implementation.

**Decided (pre-implementation):**

- [x] **Unit test framework for `corelib`: Catch2** (nixpkgs provides `catch2`; we will use CMake `find_package(Catch2 CONFIG REQUIRED)` and link `Catch2::Catch2WithMain`)
- [x] **QML data binding:** use `QAbstractListModel`
- [x] **CMake package + target naming:** `find_package(corelib CONFIG REQUIRED)` and link `corelib::corelib`
- [x] **Corelib library type:** static library
- [x] **CMake discovery (apps):** set `CMAKE_PREFIX_PATH` to include the corelib package output (via flake build inputs)

**Still open (only if needed during build-out):**

- [ ] Whether to use `ctest` discovery helpers vs explicit `add_test(...)` (we can start with explicit `add_test` to keep it deterministic)

---

## 9) Risks / mitigations

- **Qt complexity distracts from Nix story** → keep UI minimal; prefer template reuse.
- **Upgrade demo is finicky live** → add helper scripts and pre-stage known-good commits/tags.
- **Slow first build** → acceptable; later phases add caching (Phase 4).
