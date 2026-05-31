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

Use this skill when setting up MoJu modeling for a new or existing Rust project.

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

```
source code
  -> moju-code extract -> facts.json
  -> LLM synthesis (facts-to-moju-draft skill) -> moju/draft/*.mju
  -> moju verify moju/draft
  -> human review
  -> merge to moju/model/
  -> moju-code align --write (sync to code)
  -> moju-code diff (verify zero differences)
```

## resolve_project_root Behavior

The tool detects a project root by checking in order:
1. Directory containing `moju/` or `moju-model/`
2. Directory containing `Cargo.toml` + `src/`
3. Parent directories upward

## resolve_model_root Behavior

The tool finds model files by checking in order:
1. `--model` CLI argument
2. `<project-root>/moju/draft/`
3. `<project-root>/moju/model/`

## Initial Reverse-Modeling

For an existing codebase without a model:

```bash
# 1. Extract facts from code
mojo-code extract <crate-path>

# 2. Synthesize draft model (use facts-to-moju-draft skill)
# 3. Verify draft parses
mojo verify moju/draft

# 4. Review and promote to model/
cp -r moju/draft/domain moju/model/domain

# 5. Sync annotations back to code
mojo-code align <crate-path> --write

# 6. Verify zero differences
mojo-code diff <crate-path>
```

## Do Not

- Do not commit `moju/draft/` to git.
- Do not skip the `moju verify` step — broken model files cascade into broken tooling.
- Do not create model files manually in `moju/model/` without going through the draft-review-promote pipeline.
