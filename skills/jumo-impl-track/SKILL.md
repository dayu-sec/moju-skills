---
name: jumo-impl-track
description: How to read, write, and validate the Jumo usecase implementation tracking file (jumo/model/impl/usecases.json) that maps usecases to their code entry paths. Covers the JSON structure, jumo-code impl-check, status/progress semantics, semantic anchors, and qualified usecase references.
triggers:
  - usecase implementation tracking
  - impl tracking
  - usecases.json
  - jumo-code impl-check
  - which usecases are implemented
  - code entry paths
  - implementation status
  - progress percentage
  - dangling usecase reference
  - impl schema_version
---

# Jumo Usecase Implementation Tracking

Use this skill when working with the file `<model-root>/impl/usecases.json`, which records each usecase's implementation status, progress, and **code entry paths** (a usecase usually maps to multiple endpoints/handlers).

## What it is

A data file (JSON) that establishes the **model ↔ code relationship** for AI and automation. It is deliberately separate from the model spec (`.mju`):

- `jumo/model/` — model spec (Jumo language)
- `jumo/model/impl/usecases.json` — implementation tracking (data)

The authoritative structure lives in `jumo-code/src/impl_track.rs` (serde types, `deny_unknown_fields`). Spec is never touched by this data.

## Structure

```json
{
  "schema_version": 1,
  "usecases": [
    {
      "name": "System.WarpInsightCenter.CreateGatewayInstance",
      "status": "Partial",
      "progress": 85,
      "flow": "Control.AdminCreateGatewayInstanceFlow",
      "entries": [
        { "name": "AdminCreateGatewayInstance", "route": "POST /api/v1/admin/gateways/instances", "handler": "admin_ops.rs:admin_create_gateway_instance", "covers": ["CreateInstance"] }
      ],
      "gaps": ["独立 GatewayCredentialBundle 签发未拆分"]
    }
  ]
}
```

Field rules:

- `schema_version` — required, must equal `impl_track::CURRENT_SCHEMA_VERSION` (1).
- `usecases[].name` — **fully-qualified usecase name** matching the model key (e.g. `System.WarpInsightCenter.CreateGatewayInstance`). Unqualified or wrong-domain names fail `impl-check`.
- `usecases[].status` — `Complete` / `Partial` / `Missing`.
- `usecases[].progress` — 0-100, **reference only**; trust `status`, not `progress` (progress goes stale as code changes).
- `usecases[].entries[]` — code entry paths; list ALL endpoints that implement the usecase.
- `entries[].route` — HTTP route, e.g. `POST /api/v1/admin/gateways/instances`.
- `entries[].handler` — **semantic anchor**: `file:function` (e.g. `admin_ops.rs:admin_create_gateway_instance`), NEVER a line number.
- `entries[].covers` — model elements this entry implements (optional).
- `usecases[].gaps` — unimplemented / deviating aspects (optional).

## Validation

```text
jumo-code impl-check <project> [--impl <path>]
```

- Default path: `<project>/jumo/model/impl/usecases.json`.
- Exit 0 = clean; exit 1 = errors found.
- What it checks:
  - `deny_unknown_fields` — extra/typo fields are rejected.
  - `schema_version` matches.
  - `status` enum + `progress` 0-100 + entries have `route`+`handler`.
  - `name` resolves against the parsed model's usecases (dangling ref = **error**).
  - `flow` resolves against model flows (missing = **warning**).

## Rules of thumb

1. **Semantic anchors only** — `handler` is `file:function`, never a line number.
2. **Qualified usecase names** — always the full model key; after a rename/move, `impl-check` will flag the dangling reference. That's its job — fix the JSON, don't silence it.
3. **Status is truth** — update `status` faithfully; keep `progress` as an approximate indicator.
4. **List all entry paths** — one usecase spanning several endpoints gets several `entries`.
5. **Keep spec and tracking separate** — never add impl fields to `.mju`; usecase_impl is a data-layer concept only.

## Workflow

```text
model/code change -> update jumo/model/impl/usecases.json -> jumo-code impl-check <project> -> green
```

Green `impl-check` means: structure matches the schema contract and every usecase/flow reference resolves against the model. Acceptance of the implementation itself still goes through `jumo-code diff` + tests.

## Related capability

- `jumo-code subsystem-flows <project> [--subsystem <name>]` derives the flows a subsystem depends on (declared `uses flow` + usecase `flow` refs + match transitive targets). Use it when the question is "which orchestration does this subsystem use" — complementary to impl-check's "where is this usecase implemented". Model subsystems may declare `uses flow X` to reference module-owned flows explicitly.
