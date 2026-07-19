---
name: generated-skeleton-implementation
description: How to work inside Rust or Java skeletons produced by moju-code generate. Covers reading order, current model layout, implementation discipline, annotations, config/storage bindings, and acceptance criteria.
triggers:
  - implementing generated skeleton
  - working inside moju-code generate output
  - AI_TASKS.md implementation
  - moju-code generate
---

# Generated Skeleton Implementation

Use this skill when editing a project produced by `moju-code generate`.

## Read First

- `AI_TASKS.md`
- `MOJU_MODEL.md`
- `.moju-gen.json`
- source MoJu model directory referenced by `AI_TASKS.md`
- relevant `moju/model/domain/<domain>/{domain,behavior,architecture,binding,verify}.mju`
- relevant `moju/model/subsystem/<name>/{architecture,usecase,layout}.mju` if the target is subsystem-scoped

## Rust Projects

- Keep `cargo check` passing after each implementation slice.
- Preserve generated module layout unless there is a reviewed reason to change it.
- Preserve MoJu metadata comments and derive attributes (`#[derive(MoJu)]`, `#[moju(...)]`).
- Prefer implementing behind generated traits and modules instead of bypassing them.
- Keep API/protocol code separate from app orchestration, domain types, storage adapters, and external capability clients.
- Use binding-declared routes, statuses, outcomes, storage adapters, config sources, and actor identity mappings.

## Java Projects

- Keep `mvnw compile` passing after each implementation slice.
- Preserve generated package layout (`api/`, `service/`, `domain/`, `repository/`).
- Preserve `@MoJu` annotations on all generated domain types.
- Use constructor injection for service and repository dependencies.
- Prefer implementing behind generated interfaces instead of bypassing them.
- Use `binding.mju` as the source for request mappings, status codes, repositories, and config properties.

## Model Facts To Respect

- `domain.mju`: generated domain structs/states/messages/events/failures/config/storage contracts.
- `behavior.mju`: flows, cap operations, failure policies, scenarios, and lifecycle constraints.
- `architecture.mju`: module ownership, dependencies, providers, capability implementations, dataflows, and decisions.
- `binding.mju`: protocol, route, status, outcome, storage adapter, and config binding details.
- `verify.mju`: scenarios that must keep passing.
- `layout.mju`: UI region/page/window/section structure when generating prototypes or UI targets.
- `topology.mju` and `target.mju`: deployment nodes, resources, networks, named targets, and subsystem composition.

## Do

- Leave explicit TODOs only where an external service, credential, schema, or policy decision is missing.
- Run the appropriate local checks before handing off.
- Keep `.moju-gen.json` and generated metadata in sync with the source model.

## Do Not

- Do not remove `.moju-gen.json`.
- Do not rename public generated types without updating MoJu or the generated task files.
- Do not collapse API, app, domain, and infra layers into one module / package.
- For Java: do not remove `@MoJu` annotations or change generated package structure.
- Do not invent unmodeled routes, outcomes, adapter providers, quotas, or authorization rules.
- Do not implement a subsystem by directly coupling to unrelated subsystem internals when the model declares a cap/interface boundary.

## Acceptance

- The crate compiles (`cargo check` or `mvnw compile`).
- Unit/integration tests relevant to the touched flow pass.
- Public behavior still matches `AI_TASKS.md`.
- Any remaining TODOs are narrow and tied to missing external decisions.
