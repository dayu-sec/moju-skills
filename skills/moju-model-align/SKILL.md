---
name: moju-model-align
description: How to keep current MoJu 2.0 models and code annotations in sync. Covers diff diagnosis, alignment loop, typed fields, repeated owns, static domain module splits, runtime subsystem/service awareness, rename propagation, and code annotation discipline.
triggers:
  - model-code alignment
  - moju-code diff
  - moju-code align
  - code annotations out of sync
  - syncing model and code
  - fixing diff mismatches
  - typed field sync
  - module owns maintenance
  - subsystem model sync
---

# MoJu Model Align

Use this skill to keep MoJu model files and code annotations consistent.

## Goal

`moju-code diff` reports zero differences between `moju/model/` and code annotations.

## Direction

```
moju/model/ (authoritative)  --align-->  code annotations (mirror)
```

Never the reverse. If code has changed, update the model first through `moju/draft/`, run `moju verify`, promote to `moju/model/`, then align code.

## The Alignment Loop

```
moju-code diff  ->  review gaps  ->  fix model if needed  ->  moju verify  ->  moju-code align --write  ->  cargo check / mvnw compile
       ↑                                                                                                          |
       +----------------------------------------------------------------------------------------------------------+
```

| Step | Command | What it does |
|------|---------|-------------|
| 1. diff | `moju-code diff <project>` | Show what's out of sync |
| 2. review | read the diff output | Decide: model wrong, or code missing annotations? |
| 3. fix model | edit `moju/draft/` or reviewed `moju/model/` | If model needs updating: add/remove items, fix typed fields, update module owns/subsystems/usecases |
| 4. verify | `moju verify` | Ensure `.mju` files parse, flow references resolve, owns are complete |
| 5. align | `moju-code align <project> --write` | Push model metadata into code as `#[moju]` annotations |
| 6. check | `cargo check` / `mvnw compile` | Ensure annotated code compiles |

If step 2 determines the model is already correct, skip steps 3-4 and go directly to align.

## Diff Output Categories

| Category | Meaning | Action |
|----------|---------|--------|
| 注解不匹配 | Model spec differs from code annotation | Review which side is correct, update the other |
| 模型有、代码无 | Type exists in model but has no `#[moju]` | Run `align --write` to add annotations |
| 代码已注解、模型无 | Code has `#[moju]` but model has no matching type | If the type should be modeled, add to draft first; otherwise remove annotation |
| 代码无注解、模型也无 | Type in code without annotation, not in model | Decide if it should be modeled |

## Diagnosing Root Causes

When `diff` shows many entries, check:

- **owns missing from architecture.mju**: If a code-facing type exists in any `moju/model/static/<domain>/*.mju` file but no module owns it, code alignment may not know which module annotation to write.
- **module kind too generic**: Domain structs/states often belong in `module<entity>`; rules, policies, and calculations often belong in `module<logic>`.
- **struct+kind not merged**: Model uses `struct X { kind: XKind }` + `state XKind`, but code uses a single `state X` enum directly.
- **naming inconsistency**: Model and code use different names for the same concept.
- **wrong scope**: A subsystem use case or layout region was added under static domain files instead of `moju/model/runtime/subsystem/<name>/`.
- **service/module confusion**: A deployable process was modeled as only `module<service>` instead of a runtime `service` under `runtime/service/<name>/`.
- **missing `meta` labels**: Studio display falls back to raw identifiers when `meta label zh/en` is absent.
- **stale draft shadowing model**: A leftover `moju/draft/` can make tools read the wrong copy depending on command and context.

## Struct+Kind Merge Rule

When code uses a single `state` enum but model has `struct X { kind: XKind }` + `state XKind`:

```mju
// Before (does NOT match code)
struct Action { kind: ActionKind }
state ActionKind { Call, Create, Emit }

// After (merged, matches code)
state Action { Call, Create, Emit, ChangeAdd, Goto, Ensure }
```

Update the owning struct: `kind: ActionKind` → `kind: Action`.

## Typed Field Sync

Current MoJu supports typed fields with PascalCase types:

```mju
struct CustomerData {
  meta { label zh "客户数据" }

  unique id: String
  name: String
  email: String
  status: CustomerStatus
}

struct CustomerData {
  meta { label zh "客户数据" }

  unique id: String
  customer_id: String
  tags: List<String>
  metadata: Map<String, String>
}
```

When code and model differ on fields:

- Keep code field names/types when code is the implementation source of truth.
- Keep model-only fields when they represent reviewed design intent not implemented yet.
- Do not strip types from `.mju`; typed fields are current syntax.
- Preserve `unique` when the model declares an identity field.

## Module Owns Maintenance

Current parser accumulates repeated `owns` lines. Multi-line `owns` is valid:

```mju
module MoJuBinding {
  owns Binding, InterfaceBinding
  owns StorageBinding, ConfigBinding
  owns ConfigProvider, ConfigFileFormat
}
```

- Every code-facing domain type should be owned by exactly one module.
- Repeated `owns` lines are fine when they improve readability.
- After merging struct+kind, update owns to list the merged state name.
- Modules may `depends`, `provides`, and `implements`; they must not own subsystems.
- In the directory-per-module layout, file placement **does** imply ownership: a module declared in `module/<name>/_mod.mju` (the only module in its directory) owns every ownable item in sibling files under that directory, so `owns` can be omitted. For file-style modules (header + items in one file, or several modules sharing a package directory), `module owns ...` remains authoritative.

## Module Split Rules

When a module's `owns` list grows too large (>15 types), split by **business responsibility**:

- **Grouping principle**: Types that change together belong together.
- **Granularity**: Each module should represent a single business capability.
- **Uniqueness**: Each type belongs to exactly one module.

### Owns Completeness Check

Every code-facing item in the static domain package (`moju/model/static/<domain>/*.mju`) must appear in exactly one module's `owns`:

- `struct` / `state` / `variant` / `message` / `event` / `actor` / `storage` / `config` — should be owned when they map to code or architecture responsibility
- Trigger `command` types — owned by the Interface layer module
- Error states — owned by the most relevant domain module

## Runtime Subsystem, Service, And Usecase Awareness

- Subsystem use cases belong in `moju/model/runtime/subsystem/<name>/usecase.mju`.
- Subsystem layout belongs in `moju/model/runtime/subsystem/<name>/layout.mju`.
- Subsystem declarations belong in `moju/model/runtime/subsystem/<name>/subsystem.mju`.
- Runtime services belong in `moju/model/runtime/service/<service>/service.mju`.
- `subsystem` blocks compose services and may directly use modules:

```mju
subsystem AccessAudit {
  uses service access-audit-api
  uses module DataSec.AccessAudit
  uses module DataSec.AuditReport
}
```

```mju
service access-audit-api {
  kind bin<http>
  exposes DataSec.AccessAuditInterface
  uses module DataSec.AccessAuditApplication
}
```

If `moju-code diff` or studio views show duplicated `System.*` items, check whether files were placed in the wrong directory or loaded under the wrong domain scope.

## Rename Propagation

When renaming a type:
1. Update the domain package file that defines the type
2. Update `static/<domain>/architecture.mju`: rename in the module's `owns` list
3. Update all struct fields that reference the old name
4. Update usecase/flow/scenario/dataflow/layout references
5. Run `moju verify` and `moju-code diff`

## Code Annotation Discipline

After a `moju/draft` model has been reviewed, validated, and promoted into `moju/model/`, sync metadata back to code:

### Rust

```rust
#[derive(MoJu)]
#[moju(kind = "message", role = "command", domain = "Business")]
pub struct SubmitOrder {
    #[moju(unique)]
    pub id: String,
}
```

### Java

```java
@MoJu(kind = "message", role = "command", domain = "Business")
public record SubmitOrder(String id, String customerId) {}
```

### What To Sync

- item kind: `struct`, `state`, `variant`, `message`, `failure`, `storage`, `actor`, `config`
- domain
- message role: `command`, `query`, `response`
- unique fields
- typed fields when represented in code
- failure identity, tag, description
- storage kind and durability

### What NOT To Sync

- flow step ordering, dataflow graph edges
- interface routes and status codes
- storage adapter providers (`postgres`, `redis`, `kafka`)
- config file paths and secret sources
- design decisions and profile choices
- usecase traceability and layout region placement

## Common Pitfalls

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "模型有、代码无" for types that exist | Type name mismatch | Rename one side to match |
| align adds `module = ""` | Empty module field | Check module attribution in architecture.mju |
| Same diff entries persist after align | Wrong domain/module attribution or stale draft | Check model root, `static/<domain>` names, and owns |
| align removes annotations | Model no longer owns the type | Add type to module's owns list |
| Studio shows raw English names only | Missing display metadata | Add `meta { label zh ... label en ... }` |
| Usecase appears in wrong tree node | File placed in wrong scope | Move to `runtime/subsystem/<name>/usecase.mju` or an explicit runtime root usecase file |
| Service-only subsystem opens an empty layer diagram | Runtime service counted as static module | Add `uses module` for static layer views or inspect runtime service/topology views |

## Do

- Model is always the source of truth. Change it first, then align code.
- Run `diff` before and after every alignment session.
- Use `--check` before `--write` to preview changes.
- Keep `moju/model/` as the reviewed source and remove stale drafts after promotion.
- Keep new authoritative paths in `static/<domain>` and `runtime/...`; do not add new legacy `domain/` or `subsystem/` roots.

## Do Not

- Do not run `align --write` blindly. Understand why each difference exists first.
- Do not add `#[moju]` / `@MoJu` to types that are pure implementation details.
- Do not delete model types just to make diff pass.
- Do not let a single module own >15 types — split by business responsibility.
- Do not hide domain entity ownership or business rules in an unrelated `module<service>` when `module<entity>` or `module<logic>` is the clearer static boundary.
- Do not move subsystem/usecase/layout facts into unrelated static domain files just to make navigation look right.
- Do not use `module<service>` as a substitute for a runtime `service`.
