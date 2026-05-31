---
name: facts-to-moju-draft
description: How to synthesize a reviewed moju-draft from moju-code extract facts JSON. Covers pipeline, file separation, mapping rules, metadata, and review output.
triggers:
  - converting code to moju model
  - moju-code extract
  - reverse modeling from code
  - creating moju draft
  - facts.json to model
---

# Facts To MoJu Draft

Use this skill when converting `moju-code extract` Facts JSON from an existing codebase into a draft MoJu model.

## Goal

Produce reviewable files under `moju-draft/<domain>/` (project-level, sibling to `moju/`), then verify the model parses before handing off for review.

```
facts.json + project source
  -> moju-draft/<domain>/domain.mju
  -> moju-draft/<domain>/behavior.mju
  -> moju-draft/<domain>/architecture.mju
  -> moju-draft/<domain>/extraction.meta.json
  -> moju-draft/<domain>/review.md
  -> moju verify moju-draft
```

## Pipeline

```
source code -> moju-code extract -> facts.json -> LLM synthesis -> moju-draft/*.mju -> moju verify -> human review -> merge to moju/
```

## File Separation

| File | Contains | Does NOT contain |
|------|----------|------------------|
| `domain.mju` | struct, state, event, failure, message, actor, interface entry, config, storage | lifecycle, flow, cap trait, module, dataflow, decision |
| `behavior.mju` | lifecycle, cap trait (with ops), flow (with steps), failure_policy | struct/state/event/message definitions |
| `architecture.mju` | module, dataflow, decision | behavior definitions |

> `cap` trait definitions (op list) go in `behavior.mju`. `cap` name references (e.g., `depends InventoryPort`) can appear in `architecture.mju` module sections.
> `interface entry` goes in `domain.mju` as the stable external contract declaration. Route/HTTP binding details belong in `binding.mju`.

## Authority Rules

- Facts JSON is evidence, not design truth.
- `moju-draft` is a candidate model for human review, placed at project level (sibling to `moju/`).
- Only a reviewed model copied into `moju/` is authoritative.
- Do not invent routes, protocols, storage adapters, permissions, or business decisions as confirmed facts.
- If inference is useful but uncertain, include it in the draft and mark it in metadata/review as inferred.

## Mapping Rules

- `type_defs` with `#[moju(kind = "struct")]` maps to `struct<domain>`.
- `type_defs` with `#[moju(kind = "state")]` maps to `state`.
- `type_defs` with `#[moju(kind = "event")]` maps to `event`.
- `type_defs` with `#[moju(kind = "message", role = "command")]` maps to `message<command>`.
- `type_defs` with `#[moju(kind = "message", role = "response")]` maps to `message<response>`.
- `type_defs` with `#[moju(kind = "failure", ...)]` maps to `failure` with identity hierarchy.
- `type_defs` with `#[moju(kind = "actor", ...)]` maps to `actor` with parent chain.
- `type_defs` with `#[moju(kind = "storage", ...)]` maps to `storage` with kind and durability.
- `moju_annotations` provide the authoritative kind/role/domain for each type.
- Trait definitions under `domain/caps/` map to `cap` with `op` for each method signature.
- `state_writes` and `state_guards` can suggest `lifecycle` transitions, but should be marked inferred.
- The checkout/application flow code maps to `flow` with `step` breakdown.
- Package/module structure maps to `module` when it reflects stable responsibility boundaries.
- Config structs (e.g., `*Config`) map to `struct<config>`.
- Failure type hierarchy (e.g., `StripePaymentFailure : PaymentGatewayFailure`) maps to `failure Child : Parent`.

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

- Keep all `.mju` files parseable. Run `moju verify moju-draft` to confirm.
- Prefer a smaller valid draft over a broad invalid model.
- Put uncertain reasoning in `extraction.meta.json` and `review.md`, not in comments inside `.mju`.
- `moju-draft/` is at project level (sibling to `moju/`), not inside the crate.
