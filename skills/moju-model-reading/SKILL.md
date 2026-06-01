---
name: moju-model-reading
description: How to read source MoJu model files before implementing code from a generated MoJu skeleton. Covers reading order, authoritative sources, and implementation constraints.
triggers:
  - implementing generated MoJu skeleton
  - reading AI_TASKS.md
  - reading MoJu model files
  - MOJU_MODEL.md navigation
---

# MoJu Model Reading

Use this skill before implementing code from a generated MoJu skeleton.

## Read First

1. Read `AI_TASKS.md` in the generated crate.
2. Read `moju-model-understanding` skill to understand MoJu language concepts.
3. Read the source MoJu model directory referenced by `AI_TASKS.md`.
4. Use `MOJU_MODEL.md` only as a navigation summary.

## Source Of Truth

The source MoJu files are authoritative:

- `moju/profile.mju`
- `moju/<domain>/domain.mju`
- `moju/<domain>/binding.mju`

Generated code (Rust or Java) and `MOJU_MODEL.md` may be stale or incomplete.

The MoJu language and model semantics are summarized in `moju-model-understanding`; use that skill to interpret the source model during implementation.

## Do

- Preserve MoJu names when mapping to code: Rust modules/structs/traits or Java packages/records/interfaces.
- Treat `interface`, `message`, `flow`, `storage`, and `binding` as implementation constraints.
- Keep response status codes, route paths, and adapter providers aligned with `binding.mju`.
- In Java projects: follow the `http-java-spring-boot` skill for controller/service/repository patterns.

## Do Not

- Do not invent routes, response variants, storage adapters, or capability clients that are not present in the MoJu model.
- Do not modify source MoJu files unless the task explicitly asks for design changes.
