---
name: jumo-project-init
description: Setting up the current Jumo 2.0 modeling directory structure and tooling pipeline for a Rust or Java project. Covers static/runtime layout, subsystem/usecase/layout files, runtime services, tool chain, project resolution, and initial reverse-modeling workflow.
triggers:
  - setting up jumo project
  - initializing jumo directory
  - first time jumo modeling
  - jumo project structure
  - jumo/model
  - subsystem usecase layout
---

# Jumo Project Init

Use this skill when setting up Jumo modeling for a new or existing Rust or Java project.

## Goal

Create a Jumo 2.0 `jumo/model/` tree that can be opened by jumo-studio, validated by `jumo verify`, and synchronized with code through `jumo-code`.

## Canonical Directory Structure

Use `jumo/model/` for reviewed, authoritative models:

```text
jumo/
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
    jumo-layout.json
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
jumo/model/static/domain/<domain>/
jumo/model/runtime/system/<name>/
```

Legacy projects may still contain this older shape, but do not use it for new work:

```text
jumo/model/domain/<domain>/
jumo/model/subsystem/<name>/
```

Add to `.gitignore`:

```gitignore
jumo/draft/
```

Keep `jumo/model/` committed. Keep `jumo/draft/` temporary and uncommitted.

## File Placement Rules

| Need | Put it here |
|------|-------------|
| Domain concepts, messages, events, actors, interfaces, storage contracts | `jumo/model/static/<domain>/domain.mju` or split files under `jumo/model/static/<domain>/` |
| Flows, lifecycles, caps, scenarios, failure policies | `jumo/model/static/<domain>/behavior.mju` |
| Modules, layers, dependency rules, dataflows, decisions | `jumo/model/static/<domain>/architecture.mju` |
| Routes, statuses, outcomes, storage/config bindings | `jumo/model/static/<domain>/binding.mju` |
| Flow verification cases | `jumo/model/static/<domain>/verify.mju` |
| Runtime subsystem use cases | `jumo/model/runtime/subsystem/<name>/usecase.mju` |
| Runtime subsystem declaration and composition | `jumo/model/runtime/subsystem/<name>/subsystem.mju` |
| Runtime subsystem UI layout regions | `jumo/model/runtime/subsystem/<name>/layout.mju` |
| Cross-subsystem global flows / use cases | `jumo/model/runtime/global/<file>.mju` |
| Runtime service declarations | `jumo/model/runtime/service/<service>/service.mju` |
| Service-specific targets | `jumo/model/runtime/service/<service>/target.mju` |
| Service-specific assembly details | `jumo/model/runtime/service/<service>/assembly.mju` |
| Nodes, resources, networks, links, deployment binds | `jumo/model/runtime/topology.mju` |
| Platform/root targets and subsystem composition | `jumo/model/runtime/target.mju` |
| Generation profiles | `jumo/model/profile.mju` |

`runtime/subsystem/<name>/usecase.mju` and `runtime/subsystem/<name>/layout.mju` are intentionally adjacent in navigation. Do not bury subsystem use cases under static domain architecture.

### Cross-subsystem flows and the `domain` directive

Flows that orchestrate across multiple subsystems (swimlanes reference participants from different subsystems, e.g. `GatewayOnboardingFlow`) belong in `jumo/model/runtime/global/` — a `global` runtime scope parallel to `subsystem`. Their path-derived domain is `Global`, so declare the owning domain at the top of the file with the file-level `domain` directive:

```mju
// jumo/model/runtime/global/gateway-onboarding.mju
domain Control

flow GatewayOnboardingFlow {
  actor Control.BusinessAdministrator
  actor Control.CustomerServiceEngineer
  lane WarpInsightCenter for Control.InsightCenterApp.WarpInsightCenter
  lane WarpGateway for Control.GatewayApp.Application
  ...
}
```

The `domain <Name>` directive (first content line, after comments) overrides the path-derived domain for that file, so unqualified references resolve within the declared domain. The directive line is stripped before parsing. Single-subsystem flows stay in `static/<domain>/behavior.mju` or the owning module; only genuinely cross-subsystem orchestration belongs under `runtime/global/`.

## Domain Package Split

Start a small domain with `domain.mju`, `behavior.mju`, `architecture.mju`, `binding.mju`, and `verify.mju`. When one domain grows across several modules, keep the same `static/<domain>/` directory and split additional `.mju` files by module owner, interface provider, or responsibility:

```text
jumo/model/static/control/
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
  -> jumo-code extract -> facts.json
  -> LLM synthesis -> jumo/draft/static + jumo/draft/runtime
  -> jumo verify jumo/draft
  -> human review
  -> promote to jumo/model/
  -> jumo-code align --write
  -> jumo-code diff
```

Useful commands:

```bash
jumo init <project>
jumo verify <project>/jumo/model
jumo-code --version
jumo-code extract <project> --out <project>/facts.json
jumo-code align <project> --check
jumo-code align <project> --write
jumo-code diff <project>
```

For Java extraction, use JDK 17+ and Maven. The Java extractor is built from the `jumo-code/java-extract/` project.

## Project Resolution

Current tools prefer Jumo 2.0 layout:

1. `<project-root>/jumo/model/`
2. `<project-root>/jumo/draft/` when explicitly working with drafts or when the tool chooses draft first
3. `<project-root>/jumo-model/` legacy layout
4. `<project-root>/jumo/` legacy flat layout

When both `jumo/model/` and legacy roots exist, treat `jumo/model/` as authoritative.

## Initial Reverse Modeling

For an existing codebase without a model:

```bash
# 1. Extract code facts
jumo-code extract <project> --out <project>/facts.json

# 2. Synthesize draft model under jumo/draft/
# Use the facts-to-jumo-draft skill.

# 3. Verify draft
jumo verify <project>/jumo/draft

# 4. Review and promote
mkdir -p <project>/jumo/model
cp -R <project>/jumo/draft/static <project>/jumo/model/
cp -R <project>/jumo/draft/runtime <project>/jumo/model/

# 5. Sync annotations back to code
jumo-code align <project> --write

# 6. Verify zero differences
jumo-code diff <project>

# 7. Remove draft after promotion
rm -rf <project>/jumo/draft
```

If the project has explicit systems/subsystems, create subsystem files before promoting:

```text
jumo/model/runtime/subsystem/backup/subsystem.mju
jumo/model/runtime/subsystem/backup/usecase.mju
jumo/model/runtime/subsystem/backup/layout.mju
```

## Do

- Prefer `jumo/model/` for all new work.
- Keep `subsystem.mju`, `usecase.mju`, and `layout.mju` adjacent under each runtime subsystem.
- Put runnable services under `runtime/service/<service>/`.
- Put display names and Chinese labels in `meta`, not in identifiers.
- Run `jumo verify` after every structural move.
- Use `jumo-code diff` after promotion or alignment.

## Do Not

- Do not commit `jumo/draft/`.
- Do not keep duplicate authoritative copies in both `jumo/model/` and `jumo-model/`.
- Do not create new `domain/<domain>/`, `subsystem/<name>/`, `static/domain/<domain>/`, or `runtime/system/<name>/` paths.
- Do not place subsystem use cases in static `architecture.mju`.
- Do not manually create only `jumo-layout.json` for UI semantics; define regions in `layout.mju`.
- Do not skip verification before running code generation or alignment.
