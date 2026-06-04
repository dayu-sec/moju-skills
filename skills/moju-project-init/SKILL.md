---
name: moju-project-init
description: Setting up MoJu modeling directory structure and tooling pipeline for a project. Covers directory layout, tool chain, project resolution, and initial reverse-modeling workflow.
triggers:
  - setting up moju project
  - initializing moju directory
  - first time moju modeling
  - moju project structure
---

# MoJu Project Init

Use this skill when setting up MoJu modeling for a new or existing Rust or Java project.

## Goal

Establish the directory structure and tooling pipeline so that model-code synchronization works from day one.

## Directory Structure

Under the project root:

```
moju/
  model/                   # Authoritative, reviewed models (committed to git)
    domain/
      <domain-name>/
        domain.mju
        behavior.mju
        architecture.mju
  draft/                   # AI-generated working drafts (gitignored)
    domain/
      <domain-name>/
        domain.mju
        behavior.mju
        architecture.mju
        extraction.meta.json
        review.md
```

Add to `.gitignore`:
```
moju/draft/
```

If `moju/draft/` was previously committed, remove and re-gitignore it.

## Tool Chain

Works for both Rust and Java projects. `moju-code extract` auto-detects project type (Rust via `src/*.rs`, Java via `pom.xml`).

```
source code (Rust or Java)
  -> moju-code extract -> facts.json
  -> LLM synthesis (facts-to-moju-draft skill) -> moju/draft/*.mju
  -> moju verify moju/draft
  -> human review
  -> merge to moju/model/
  -> moju-code align --write (sync to code)
  -> moju-code diff (verify zero differences)
```

For Java extraction, the tool requires JDK 17+ and Maven. The `java-extract/` Maven project is auto-built on first use.

## resolve_project_root Behavior

The tool detects a project root by checking in order:
1. Directory containing `moju/` or `moju-model/`
2. Directory containing `Cargo.toml` + `src/` (Rust project)
3. Directory containing `pom.xml` + `src/` (Java project)
4. Parent directories upward

## resolve_model_root Behavior

The tool finds model files by checking in order:
1. `--model` CLI argument
2. `<project-root>/moju/draft/`
3. `<project-root>/moju/model/`

## Initial Reverse-Modeling

For an existing codebase without a model:

```bash
# 1. Extract facts from code (works without annotations — parses Rust syntax directly)
moju-code extract <crate-path>

# 2. Synthesize draft model (use facts-to-moju-draft skill)
# 3. Verify draft parses
moju verify moju/draft

# 4. Review and promote to model/
cp -r moju/draft/domain moju/model/domain

# 5. Sync annotations back to code (adds #[moju] for precise future diffs)
moju-code align <crate-path> --write

# 6. Verify zero differences
moju-code diff <crate-path>

# 7. Delete draft (avoid confusion with model)
rm -rf moju/draft/
```

After promotion, `moju/model/` is the single source of truth. `moju/draft/` is a temporary workspace — keeping it creates ambiguity about which copy is authoritative.

## Do Not

- Do not commit `moju/draft/` to git.
- Do not keep `moju/draft/` after promoting to model — delete it.
- Do not skip the `moju verify` step — broken model files cascade into broken tooling.
- Do not create model files manually in `moju/model/` without going through the draft-review-promote pipeline.
- Do not run `moju-code diff` against draft when model exists — model is authoritative.
