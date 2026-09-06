---
name: jumo-code-quality
description: How to generate and interpret model-independent code quality reports with jumo-code code-quality. Covers the code-quality.json contract (file scale, function complexity, the modules[] directory tree with own vs subtree rollups, warnings), cargo llvm-cov coverage import, thresholds/exclude config, --check CI gating, and reading reports to plan refactors.
triggers:
  - generate a quality report
  - code-quality.json
  - jumo-code code-quality
  - code quality analysis
  - llvm-cov coverage import
  - refactor targets from quality view
---

# Jumo Code Quality

Use this skill when a project needs a source-code quality report or when a quality-driven refactor is selected (e.g. the Code Quality view / `code.refactor_target` tasks). `jumo-code code-quality` is **model-independent**: it does not read `.mju` models, Jumo annotations, or `#[jumo]` attributes. Directory modules are source directories, not Jumo model modules (do not confuse this report with `jumo-code quality`, which measures the Jumo model itself).

## Command

```bash
# From the jumo-code repository (or with jumo-code on PATH):
cargo run --quiet -- code-quality <project>
# or: jumo-code code-quality <project>

jumo-code code-quality <project> [--out <file>] [--check] [--coverage <llvm-cov.json>]
                                [--exclude <pat>[,<pat>...]] [--thresholds k=v,k=v]
```

Run from any directory; `<project>` must resolve to a crate root (`Cargo.toml` + `src/`, a `jumo`/`jumo-model` root, or a Cargo workspace root).

**Analysis scope**: the crate's own `<project>/src`, plus the `src` of every Cargo workspace member (root `Cargo.toml` `[workspace] members`, globs like `crates/*` supported). File paths stay project-relative, so member files report as `crates/<name>/src/...`. Excluded: `tests.rs` / `*_tests.rs` / paths under `tests/` and `#[cfg(test)]` items.

**Output location**: with no `--out`, the report is written to `<model_root>/jumo-layout/code-quality.json` (same folder as `quality.json`) when that `jumo-layout` directory exists — e.g. `jumo/model/jumo-layout/` or `jumo/draft/jumo-layout/` — otherwise `<project_root>/code-quality.json`. Summaries go to stderr.

Consumers must search both layout roots, draft first: `jumo/draft/jumo-layout/` → `jumo/model/jumo-layout/` → `<project_root>/code-quality.json`. A reader that only knows `jumo/model/` silently renders a stale report (jumo-studio's quality view applies exactly this order; new output locations must be added there too).

### Thresholds (all optional)

```
file_code_lines=1000   # max effective code lines per file
fn_length=200          # max function span in lines
cyclomatic=20          # max cyclomatic complexity per function
nesting_depth=4        # max control-flow nesting depth
line_coverage=80       # minimum line coverage percent (only judged on valid collected data)
```

`--exclude` accepts `*suffix`, `prefix*`, or substring patterns (repeatable, comma-separated).

## Report Contract (schema 6)

The JSON has one file-level entry `files[]`, per-function `functions[]`, `warnings[]`, `diagnostics[]`, and:

- **`files[].module`** — directory path of the file relative to the project root (e.g. `src/ui/app`). Files directly under the crate root (`src/lib.rs`, `src/main.rs`) carry `null`.
- **`files[].file_complexity`** — whole-file cyclomatic **density** per KLOC: Σ function cyclomatic (each includes its +1 base) × 1000 ÷ `code_lines`. Normalizes decision volume against file size; `null` when the file has no code lines. Raw Σ is not serialized — recompute from `functions[]` if a decision-volume total is needed.
- **`modules[]`** — a **directory tree** (schema 5). Each node carries `module`, `parent` (tree roots: `null`), `files` (own, sorted), then two rollup families:
  - own (direct files only): `code_lines`, `function_count`, `max_cyclomatic`, `over_cyclomatic_function_count`, `over_length_function_count`, **`module_complexity`** (own weighted density per KLOC), `coverage`.
  - subtree (this node + all descendants): `subtree_code_lines`, `subtree_functions`, **`subtree_complexity`** (weighted density over the whole tree, never an average of node densities), `subtree_max_cyclomatic`, `subtree_over_cyclomatic_function_count`, `subtree_over_length_function_count`, `subtree_coverage`.
  - `coverage` / `subtree_coverage` roll up collected files only; `null`/absent when none collected.
- **`coverage_report`** / **`coverage_summary`** — present only when `--coverage` was given. Summary is Σcovered/Σexecutable over collected files, never an average of file percentages.
- **`metrics_algorithm_version`** — `rust-v2`: nested item fns do not count into the enclosing fn; guarded match arms count once.

Locations use project-relative paths and 1-based lines. Missing/uncollected data is explicit state, never a fabricated `0`.

### Tree construction rules

- Every directory that owns files is a node.
- A directory with no own files is kept **only** when it splits ≥2 child modules (`src`, `src/ui` in the studio report). These shell nodes own 0 code lines, so `module_complexity` is `null` (not 0) while `subtree_complexity` carries the whole tree's density.
- Single-chain empty shells are omitted: `src/ui/paint/actor_hierarchy` hangs directly under `src/ui/paint`, with no hollow intermediate.
- Cargo workspaces: roots are the crate roots (`crates/wf-engine/src`), not a synthetic workspace node.
- Files with `module: null` (crate-root files such as `src/lib.rs`) belong to **no** tree node — they still appear in `files[]` and in file-level warnings, so a tree-only view must not be presented as covering all files.

### Reading own vs subtree

- Compare directories at **subtree** scale — that is what a tile, a bar, or a ranking of "biggest area" should use; own alone hides everything nested below.
- Use **own** to answer "how big is this directory's own files" (e.g. `src/ui` owns 4 720 lines while its subtree is 52 009).
- Never sum `subtree_*` across levels or across siblings-in-a-chain: parent subtree already contains descendants, so adding them double counts.
- Walk levels by matching `parent == <current>`; roots are the entries whose `parent` is `null` (or points at a node that does not exist).
- **Backward compatibility (units!)**: schema ≤5 complexity fields are raw Σ integers, not densities. `as_f64()` happily returns `6752.0` for them, so a consumer that reads the number without converting will display "6752/KLOC" where the truth is ≈118/KLOC — two orders of magnitude off, and every tile saturates the same hot color. Convert with `Σ × 1000 ÷ code_lines` (subtree: `Σ × 1000 ÷ subtree_code_lines`); `None` when the line count is 0. Detect by JSON type: `is_f64()` → already a density, integer → legacy Σ. jumo-studio applies this conversion in `density_kloc`.
  - schema ≤4 reports are also flat — no `parent`, no `subtree_*`: treat every entry as a root leaf and fall back `subtree_*` → own values.

Example (jumo-studio, schema 6): `src` (shell, own density `null`, subtree 118.5/KLOC) → `src/ui` (own 100.0, subtree 113.9) → `src/ui/paint` (92.1) → `actor_hierarchy` (92.5); the hottest sibling at the `src` level is `runner` (188.9/KLOC over only 1 625 lines — density is what surfaces it, raw Σ would not).

### Densities do not add up

Densities are ratios, so they can be compared and ranked but never summed or averaged — a parent's subtree density is `Σcyc × 1000 ÷ Σlines` over the whole tree, computed from the raw sums, never from child densities. To aggregate, first reconstruct `Σcyc = density × lines ÷ 1000`, then re-divide.

### Warnings

`fn_length`, `cyclomatic`, `nesting_depth`, `file_code_lines`, `line_coverage` — each with `metric`/`value`/`threshold`/`level`/`location`. Reports are deterministic for the same source + config except `generated_at`.

## Coverage Import (cargo llvm-cov)

Coverage is imported, never run implicitly:

```bash
cargo llvm-cov --lib --json > llvm-cov.json          # generate (needs cargo-llvm-cov)
jumo-code code-quality <project> --coverage llvm-cov.json \
    --thresholds line_coverage=80 --check
```

Per-file states: `collected` / `not_collected` (report lacks the file) / `not_applicable` (file present, no executable lines). Files in the report that cannot be mapped to an analyzed source (e.g. path-dependency crates, `tests/`, excluded files) become **diagnostics**, not 0% entries. `summary.lines` from the tool is the authoritative denominator — never the static LOC count.

## CI Gate (`--check`)

`--check` exits non-zero when the gate fails. Two distinct failures, incomplete takes precedence:

1. **analysis incomplete** — some files failed to parse/read/walk; do not treat as a full pass.
2. **quality warnings** — thresholds exceeded (including low `line_coverage`).

Without `--check`, warnings never fail the command. stdout carries only JSON when no `--out` is given; human summaries go to stderr.

## Reading the Report for Refactors

- Find oversized directories via `subtree_code_lines` / `subtree_complexity` (whole subtree) and use `code_lines` / `module_complexity` when the question is only about a directory's own files; a shell node's own numbers are 0 by construction.
- Find oversized files via `file_code_lines` warnings or `modules[].code_lines`.
- Find long/high-complexity functions by sorting `functions[]` on `length` / `cyclomatic_complexity` within the target file.
- Function entries carry `name`, `type_name` (impl/trait), `signature`, `start_line`/`end_line` — enough for precise location without recomputing metrics.
- Coverage not collected is not 0%: never claim files are uncovered from a missing `--coverage` run.

## Do Not

- Do not hand-edit `code-quality.json`; it is generated and will be overwritten.
- Do not confuse `code-quality.json` (source code, directory modules) with `quality.json` (Jumo model quality, model modules).
- Do not add Jumo-model semantics to the directory module rollups; `module` means the source directory.
- Do not sum `subtree_*` over parents and children, and do not rank a parent against its own descendants — subtree values already nest.
- Do not sum or average densities; reconstruct Σ before aggregating. Do not render a missing density (`null`) as 0 — that paints "no code lines" as "cleanest code".
- Do not invent missing tree levels on the consumer side; shells are only emitted when they branch ≥2 ways, so a gap in the path is intentional, not data loss.
- Do not let a static report drive rewrites that delete functionality or tests; use it to locate candidates, keep public behavior compatible.
