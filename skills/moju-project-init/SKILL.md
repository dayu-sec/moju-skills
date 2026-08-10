---
name: moju-project-init
description: Setting up the current MoJu 2.0 modeling directory structure and tooling pipeline for a Rust or Java project. Covers static/runtime layout, subsystem/usecase/layout files, runtime services, tool chain, project resolution, and initial reverse-modeling workflow.
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

Create a MoJu 2.0 `moju/model/` tree that can be opened by moju-studio, validated by `moju verify`, and synchronized with code through `moju-code`.

## Canonical Directory Structure

Use `moju/model/` for reviewed, authoritative models:

```text
moju/
  model/
    static/
      <domain>/
        domain.mju
        <module-or-responsibility>.mju
        behavior.mju
        architecture.mju
        binding.mju
        verify.mju
        layout.mju
    runtime/
      subsystem/
        <subsystem>/
          subsystem.mju
          usecase.mju
          layout.mju
      service/
        <service>/
          service.mju
          target.mju
          assembly.mju
      topology.mju
      target.mju
    profile.mju
    moju-layout.json
  draft/
    static/
      <domain>/
        domain.mju
        <module-or-responsibility>.mju
        behavior.mju
        architecture.mju
        binding.mju
        verify.mju
        extraction.meta.json
        review.md
    runtime/
      subsystem/
        <subsystem>/
          subsystem.mju
          usecase.mju
          layout.mju
      service/
        <service>/
          service.mju
          target.mju
          assembly.mju
```

Do not create these invalid 2.0 draft paths:

```text
moju/model/static/domain/<domain>/
moju/model/runtime/system/<name>/
```

Legacy projects may still contain this older shape, but do not use it for new work:

```text
moju/model/domain/<domain>/
moju/model/subsystem/<name>/
```

Add to `.gitignore`:

```gitignore
moju/draft/
```

Keep `moju/model/` committed. Keep `moju/draft/` temporary and uncommitted.

## File Placement Rules

| Need | Put it here |
|------|-------------|
| Domain concepts, messages, events, actors, interfaces, storage contracts | `moju/model/static/<domain>/domain.mju` or split files under `moju/model/static/<domain>/` |
| Flows, lifecycles, caps, scenarios, failure policies | `moju/model/static/<domain>/behavior.mju` |
| Modules, layers, dependency rules, dataflows, decisions | `moju/model/static/<domain>/architecture.mju` |
| Routes, statuses, outcomes, storage/config bindings | `moju/model/static/<domain>/binding.mju` |
| Flow verification cases | `moju/model/static/<domain>/verify.mju` |
| Runtime subsystem use cases | `moju/model/runtime/subsystem/<name>/usecase.mju` |
| Runtime subsystem declaration and composition | `moju/model/runtime/subsystem/<name>/subsystem.mju` |
| Runtime subsystem UI layout regions | `moju/model/runtime/subsystem/<name>/layout.mju` |
| Runtime service declarations | `moju/model/runtime/service/<service>/service.mju` |
| Service-specific targets | `moju/model/runtime/service/<service>/target.mju` |
| Service-specific assembly details | `moju/model/runtime/service/<service>/assembly.mju` |
| Nodes, resources, networks, links, deployment binds | `moju/model/runtime/topology.mju` |
| Platform/root targets and subsystem composition | `moju/model/runtime/target.mju` |
| Generation profiles | `moju/model/profile.mju` |

`runtime/subsystem/<name>/usecase.mju` and `runtime/subsystem/<name>/layout.mju` are intentionally adjacent in navigation. Do not bury subsystem use cases under static domain architecture.

## Domain Package Split

Start a small domain with `domain.mju`, `behavior.mju`, `architecture.mju`, `binding.mju`, and `verify.mju`. When one domain grows across several modules, keep the same `static/<domain>/` directory and split additional `.mju` files by module owner, interface provider, or responsibility:

```text
moju/model/static/control/
  domain.mju                    # thin overview/index is acceptable
  module.mju                    # module declarations (owns/provides/depends) and dependency rules
  user-facing-interface.mju     # user/admin interface contracts and entry flows
  agent-facing-interface.mju    # agent/daemon interface contracts and entry flows
  enrollment.mju
  identity.mju
  session.mju
  actors.mju                    # actors shared by several modules
```

This split is only file organization. Domain scope still comes from the directory name. For larger modules, prefer the directory-per-module form: `module/<name>/_mod.mju` declares the module header, and a sibling `items.mju` holds its facts so ownership is inferred from the directory and `owns` can be omitted. For file-style modules, `module owns ...` declares ownership explicitly. A `module<interface>` is the provider module and may provide multiple `interface` contracts; `module<entity>` owns domain entities/states/aggregates, and `module<logic>` owns rules, policies, calculations, and domain logic. Do not add `domain X` inside the module body to express domain membership.

## Runtime Subsystems And Services

Use `runtime/subsystem/<name>/subsystem.mju` for deployable business boundaries, and `runtime/service/<name>/service.mju` for runnable units. `module<service>` remains a static logical module; it is not a process by itself.

```mju
service warp-insight-admin {
  kind bin<http>
  exposes Control.AgentControlInterface
  uses module Control.AdminApplication
}

subsystem WarpInsightAdmin {
  uses service warp-insight-admin
}
```

## Tool Chain

Works for both Rust and Java projects:

```text
source code
  -> moju-code extract -> facts.json
  -> LLM synthesis -> moju/draft/static + moju/draft/runtime
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

Current tools prefer MoJu 2.0 layout:

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
cp -R <project>/moju/draft/static <project>/moju/model/
cp -R <project>/moju/draft/runtime <project>/moju/model/

# 5. Sync annotations back to code
moju-code align <project> --write

# 6. Verify zero differences
moju-code diff <project>

# 7. Remove draft after promotion
rm -rf <project>/moju/draft
```

If the project has explicit systems/subsystems, create subsystem files before promoting:

```text
moju/model/runtime/subsystem/backup/subsystem.mju
moju/model/runtime/subsystem/backup/usecase.mju
moju/model/runtime/subsystem/backup/layout.mju
```

## Do

- Prefer `moju/model/` for all new work.
- Keep `subsystem.mju`, `usecase.mju`, and `layout.mju` adjacent under each runtime subsystem.
- Put runnable services under `runtime/service/<service>/`.
- Put display names and Chinese labels in `meta`, not in identifiers.
- Run `moju verify` after every structural move.
- Use `moju-code diff` after promotion or alignment.

## Do Not

- Do not commit `moju/draft/`.
- Do not keep duplicate authoritative copies in both `moju/model/` and `moju-model/`.
- Do not create new `domain/<domain>/`, `subsystem/<name>/`, `static/domain/<domain>/`, or `runtime/system/<name>/` paths.
- Do not place subsystem use cases in static `architecture.mju`.
- Do not manually create only `moju-layout.json` for UI semantics; define regions in `layout.mju`.
- Do not skip verification before running code generation or alignment.
