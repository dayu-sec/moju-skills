# Skill: Facts To MoJu Draft

Use this skill when converting `moju-extract` Facts JSON from an existing codebase into a draft MoJu model.

## Goal

Produce reviewable files under `moju-draft/<domain>/`, not authoritative design files under `moju/`.

```text
facts.json + project context
  -> moju-draft/<domain>/domain.mju
  -> moju-draft/<domain>/extraction.meta.json
  -> moju-draft/<domain>/review.md
```

## Authority Rules

- Facts JSON is evidence, not design truth.
- `moju-draft` is a candidate model for human review.
- Only a reviewed model copied into `moju/` is authoritative.
- Do not invent routes, protocols, storage adapters, permissions, or business decisions as confirmed facts.
- If inference is useful but uncertain, include it in the draft and mark it in metadata/review as inferred.

## Mapping Rules

- `type_defs.kind=struct` maps to `struct`.
- enum type definitions map to `state` when naming, derives, docs, or writes indicate finite domain state.
- command/query/response messages should only be created when code facts or annotations indicate boundary DTO semantics.
- trait interface facts usually map to `cap`; do not map every trait to an inbound `interface`.
- package/module structure maps to `module` only when it reflects a stable responsibility boundary.
- state writes and guards can suggest `lifecycle`, but transitions must be marked inferred unless directly annotated.
- call chains can suggest `flow`, but flow names, step names, and actor intent need review.
- auth facts can suggest `actor can` and `access protocol<...>`, but missing auth facts do not mean public access.
- test scenarios can suggest `verify`; keep them focused and mark weak mappings.
- significant comments can suggest `decision`, `responsible_for`, or review questions.

## Metadata

For every generated item, record source evidence in `extraction.meta.json`:

- item name and kind
- source files and line hints when available
- facts fields used
- confidence: `high`, `medium`, or `low`
- review status: `needs_review`, `accepted`, or `rejected`
- inference notes for anything not directly present in code

## Review File

Write `review.md` with:

- high-confidence facts that can likely be accepted
- inferred flows/lifecycles requiring human review
- missing information that code cannot reveal
- conflicts between naming, annotations, tests, and call graph
- suggested next code annotations after review

## Output Discipline

Keep `domain.mju` parseable. Prefer a smaller valid draft over a broad invalid model. Put uncertain reasoning in `extraction.meta.json` and `review.md`, not in comments inside `.mju`.
