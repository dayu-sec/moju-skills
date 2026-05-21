# Skill: MoJu Model Reading

Use this skill before implementing code from a generated MoJu skeleton.

## Read First

1. Read `AI_TASKS.md` in the generated crate.
2. Read `moju-model-understanding.md` from the MoJu skills directory referenced by `AI_TASKS.md`.
3. Read the source MoJu model directory referenced by `AI_TASKS.md`.
4. Use `MOJU_MODEL.md` only as a navigation summary.

## Source Of Truth

The source MoJu files are authoritative:

- `moju/profile.mju`
- `moju/<domain>/domain.mju`
- `moju/<domain>/binding.mju`

Generated Rust code and `MOJU_MODEL.md` may be stale or incomplete.

The MoJu language and model semantics are summarized in `moju-model-understanding.md`; use that skill to interpret the source model during implementation.

## Do

- Preserve MoJu names when mapping to Rust modules, structs, handlers, and traits.
- Treat `interface`, `message`, `flow`, `storage`, and `binding` as implementation constraints.
- Keep response status codes, route paths, and adapter providers aligned with `binding.mju`.

## Do Not

- Do not invent routes, response variants, storage adapters, or capability clients that are not present in the MoJu model.
- Do not modify source MoJu files unless the task explicitly asks for design changes.
