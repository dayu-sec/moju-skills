---
name: generated-skeleton-implementation
description: How to work inside generated Rust skeletons produced by moju-generate. Covers reading order, implementation discipline, and acceptance criteria.
triggers:
  - implementing generated skeleton
  - working inside moju-generate output
  - AI_TASKS.md implementation
---

# Generated Skeleton Implementation

Use this skill when editing a crate produced by `moju-generate`.

## Read First

- `AI_TASKS.md`
- `MOJU_MODEL.md`
- `.moju-gen.json`
- source MoJu model directory referenced by `AI_TASKS.md`

## Do

- Keep `cargo check` passing after each implementation slice.
- Preserve generated module layout unless there is a reviewed reason to change it.
- Preserve MoJu metadata comments and derive attributes.
- Prefer implementing behind generated traits and modules instead of bypassing them.
- Leave explicit TODOs only where an external service, credential, schema, or policy decision is missing.

## Do Not

- Do not remove `.moju-gen.json`.
- Do not rename public generated types without updating MoJu or the generated task files.
- Do not collapse API, app, domain, and infra layers into one module.

## Acceptance

- The crate compiles.
- Public behavior still matches `AI_TASKS.md`.
- Any remaining TODOs are narrow and tied to missing external decisions.
