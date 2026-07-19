---
name: moju-project-init
description: Setting up the current MoJu modeling directory structure and tooling pipeline for a Rust or Java project. Covers moju/model layout, subsystem/usecase/layout files, tool chain, project resolution, and initial reverse-modeling workflow.
triggers:
  - setting up moju project
  - initializing moju directory
  - first time moju modeling
  - moju project structure
  - moju/model
  - subsystem usecase layout
---

# MoJu Project Init

Use this skill when setting up MoJu modeling for a new or existing Rust or Java project.

## Goal

Create a `moju/model/` tree that can be opened by moju-studio, validated by `moju verify`, and synchronized with code through `moju-code`.

## Canonical Directory Structure

Use `moju/model/` for reviewed, authoritative models:

```text
moju/
  model/
    domain/
      <domain-name>/
        domain.mju
        behavior.mju
        architecture.mju
        binding.mju
        verify.mju
        layout.mju
    subsystem/
      <subsystem-name>/
        architecture.mju
        usecase.mju
        layout.mju
    usecase.mju
    topology.mju
    target.mju
    assembly.mju
    profile.mju
    moju-layout.json
  draft/
    domain/
      <domain-name>/
        domain.mju
        behavior.mju
        architecture.mju
        binding.mju
        verify.mju
        extraction.meta.json
        review.md
```

Add to `.gitignore`:

```gitignore
moju/draft/
```

Keep `moju/model/` committed. Keep `moju/draft/` temporary and uncommitted.

## File Placement Rules

| Need | Put it here |
|------|-------------|
| Domain concepts, messages, events, actors, storage contracts | `moju/model/domain/<domain>/domain.mju` |
| Flows, lifecycles, caps, scenarios, failure policies | `moju/model/domain/<domain>/behavior.mju` |
| Modules, dependency rules, dataflows, decisions | `moju/model/domain/<domain>/architecture.mju` |
| Routes, statuses, outcomes, storage/config bindings | `moju/model/domain/<domain>/binding.mju` |
| Flow verification cases | `moju/model/domain/<domain>/verify.mju` |
| System-level use cases | `moju/model/usecase.mju` |
| Subsystem use cases | `moju/model/subsystem/<name>/usecase.mju` |
| Subsystem declaration and module composition | `moju/model/subsystem/<name>/architecture.mju` |
| UI layout regions for a domain or subsystem | `layout.mju` beside the relevant domain/subsystem files |
| Nodes, resources, networks, links, deployment binds | `moju/model/topology.mju` |
| Named targets and platform subsystem composition | `moju/model/target.mju` |
| Runtime assembly details | `moju/model/assembly.mju` |
| Generation profiles | `moju/model/profile.mju` |

`subsystem/<name>/usecase.mju` and `subsystem/<name>/layout.mju` are intentionally adjacent in navigation. Do not bury subsystem use cases under the global architecture view.

## Tool Chain

Works for both Rust and Java projects:

```text
source code
  -> moju-code extract -> facts.json
  -> LLM synthesis -> moju/draft/
  -> moju verify moju/draft
  -> human review
  -> promote to moju/model/
  -> moju-code align --write
  -> moju-code diff
```

Useful commands:

```bash
moju init <project>
moju verify <project>/moju/model
moju-code --version
moju-code extract <project> --out <project>/facts.json
moju-code align <project> --check
moju-code align <project> --write
moju-code diff <project>
```

For Java extraction, use JDK 17+ and Maven. The Java extractor is built from the `moju-code/java-extract/` project.

## Project Resolution

Current tools prefer the new layout but still recognize legacy layouts:

1. `<project-root>/moju/model/`
2. `<project-root>/moju/draft/` when explicitly working with drafts or when the tool chooses draft first
3. `<project-root>/moju-model/` legacy layout
4. `<project-root>/moju/` legacy flat layout

When both `moju/model/` and legacy roots exist, treat `moju/model/` as authoritative.

## Initial Reverse Modeling

For an existing codebase without a model:

```bash
# 1. Extract code facts
moju-code extract <project> --out <project>/facts.json

# 2. Synthesize draft model under moju/draft/
# Use the facts-to-moju-draft skill.

# 3. Verify draft
moju verify <project>/moju/draft

# 4. Review and promote
mkdir -p <project>/moju/model
cp -R <project>/moju/draft/domain <project>/moju/model/

# 5. Sync annotations back to code
moju-code align <project> --write

# 6. Verify zero differences
moju-code diff <project>

# 7. Remove draft after promotion
rm -rf <project>/moju/draft
```

If the project has explicit systems/subsystems, create subsystem files before promoting:

```text
moju/model/subsystem/backup/architecture.mju
moju/model/subsystem/backup/usecase.mju
moju/model/subsystem/backup/layout.mju
```

## Do

- Prefer `moju/model/` for all new work.
- Keep `usecase.mju`, `architecture.mju`, and `layout.mju` adjacent under each subsystem.
- Put display names and Chinese labels in `meta`, not in identifiers.
- Run `moju verify` after every structural move.
- Use `moju-code diff` after promotion or alignment.

## Do Not

- Do not commit `moju/draft/`.
- Do not keep duplicate authoritative copies in both `moju/model/` and `moju-model/`.
- Do not place subsystem use cases in root `architecture.mju`.
- Do not manually create only `moju-layout.json` for UI semantics; define regions in `layout.mju`.
- Do not skip verification before running code generation or alignment.
