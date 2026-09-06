---
name: generated-skeleton-implementation
description: How to work inside Rust or Java skeletons produced by jumo-code generate. Covers reading order, Jumo 2.0 static/runtime model layout, implementation discipline, annotations, config/storage bindings, runtime services, and acceptance criteria.
triggers:
  - implementing generated skeleton
  - working inside jumo-code generate output
  - AI_TASKS.md implementation
  - jumo-code generate
---

# Generated Skeleton Implementation

Use this skill when editing a project produced by `jumo-code generate`.

## Read First

- `AI_TASKS.md`
- `JUMO_MODEL.md`
- `.jumo-gen.json`
- source Jumo model directory referenced by `AI_TASKS.md`
- relevant `jumo/model/static/<domain>/*.mju` static domain package files, including any module/responsibility split files
- relevant `jumo/model/runtime/subsystem/<name>/{subsystem,usecase,layout}.mju` if the target is subsystem-scoped
- relevant `jumo/model/runtime/service/<service>/{service,target,assembly}.mju` if the target is a generated runnable service/site/daemon
- relevant `jumo/model/runtime/{topology,target}.mju` for platform or deployment concerns

## Rust Projects

- Keep `cargo check` passing after each implementation slice.
- Preserve generated module layout unless there is a reviewed reason to change it.
- Preserve Jumo metadata comments and derive attributes (`#[derive(Jumo)]`, `#[jumo(...)]`).
- Prefer implementing behind generated traits and modules instead of bypassing them.
- Keep API/protocol code separate from app orchestration, domain types, storage adapters, and external capability clients.
- Use binding-declared routes, statuses, outcomes, storage adapters, config sources, and actor identity mappings.

## Java Projects

- Keep `mvnw compile` passing after each implementation slice.
- Preserve generated package layout (`api/`, `service/`, `domain/`, `repository/`).
- Preserve `@Jumo` annotations on all generated domain types.
- Use constructor injection for service and repository dependencies.
- Prefer implementing behind generated interfaces instead of bypassing them.
- Use `binding.mju` as the source for request mappings, status codes, repositories, and config properties.

## Model Facts To Respect

- Static domain package files: generated domain structs/states/messages/events/failures/config/storage/interface contracts, whether they live in `domain.mju` or module/responsibility split files.
- `static/<domain>/behavior.mju`: flows, cap operations, failure policies, scenarios, and lifecycle constraints.
- `static/<domain>/architecture.mju`: module ownership, dependencies, providers, capability implementations, dataflows, and decisions.
- `static/<domain>/binding.mju`: protocol, route, status, outcome, storage adapter, and config binding details.
- `static/<domain>/verify.mju`: scenarios that must keep passing.
- `runtime/subsystem/<name>/subsystem.mju`: subsystem composition through `uses service` and optional `uses module`.
- `runtime/service/<service>/service.mju`: runnable service kind/surface, exposed interfaces, and used static modules.
- `runtime/subsystem/<name>/layout.mju`: UI region/page/window/section structure when generating prototypes or UI targets.
- `runtime/topology.mju` and `runtime/target.mju`: deployment nodes, resources, networks, named targets, and subsystem composition.

## Do

- Leave explicit TODOs only where an external service, credential, schema, or policy decision is missing.
- Run the appropriate local checks before handing off.
- Keep `.jumo-gen.json` and generated metadata in sync with the source model.
- Treat `module<entity>` as entity/state ownership, `module<logic>` as business rule ownership, `module<service>` as static orchestration ownership, and runtime `service` as the runnable entity.

## Do Not

- Do not remove `.jumo-gen.json`.
- Do not rename public generated types without updating Jumo or the generated task files.
- Do not collapse API, app, domain, and infra layers into one module / package.
- For Java: do not remove `@Jumo` annotations or change generated package structure.
- Do not invent unmodeled routes, outcomes, adapter providers, quotas, or authorization rules.
- Do not implement a subsystem by directly coupling to unrelated subsystem internals when the model declares a cap/interface boundary.
- Do not add routes, target details, or deployment resources into static domain files when they belong under `runtime/service` or `runtime/topology`.

## Acceptance

- The crate compiles (`cargo check` or `mvnw compile`).
- Unit/integration tests relevant to the touched flow pass.
- Public behavior still matches `AI_TASKS.md`.
- Any remaining TODOs are narrow and tied to missing external decisions.
