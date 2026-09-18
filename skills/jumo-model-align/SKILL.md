---
name: jumo-model-align
description: How to keep current Jumo 2.0 models and code annotations in sync. Covers diff diagnosis, alignment loop, typed fields, repeated owns, static domain module splits, runtime subsystem/service awareness, rename propagation, and code annotation discipline.
triggers:
  - model-code alignment
  - jumo-code diff
  - jumo-code align
  - code annotations out of sync
  - syncing model and code
  - fixing diff mismatches
  - typed field sync
  - module owns maintenance
  - subsystem model sync
---

# Jumo Model Align

Use this skill to keep Jumo model files and code annotations consistent.

## Goal

`jumo-code diff` reports zero differences between `jumo/model/` and code annotations —
per crate, within the part of the model that crate implements (see Scoping below).

## Direction

There is no fixed direction. The model is the reviewed record of the design, but it
**does lag behind the code** — implementation often moves first, and the model is
refreshed to catch up. **Which side moves is the user's call, per session**, not a
standing rule:

- Model ahead of code (design was reviewed, code has not caught up): align code to
the model.
- Code ahead of model (naming or structure moved during implementation): refresh the
model through `jumo/draft/`, run `jumo verify`, promote to `jumo/model/`, then align
code to the updated model.

Never pick a side silently. Say which side you are treating as newer and why, so the
user can correct you before any file is rewritten. Once the decision is made, the
model stays the file of record for that session: land the model change first, then
mirror it into code.

## The Alignment Loop

```
jumo-code diff  ->  review gaps  ->  fix model if needed  ->  jumo verify  ->  jumo-code align --write  ->  cargo check / mvnw compile
       ↑                                                                                                          |
       +----------------------------------------------------------------------------------------------------------+
```

| Step | Command | What it does |
|------|---------|-------------|
| 1. diff | `jumo-code diff <project> [--scope <name>]` | Show what's out of sync |
| 2. review | read the diff output | Decide: model wrong, or code missing annotations? |
| 3. fix model | edit `jumo/draft/` or reviewed `jumo/model/` | If model needs updating: add/remove items, fix typed fields, update module owns/subsystems/usecases |
| 4. verify | `jumo verify` | Ensure `.mju` files parse, flow references resolve, owns are complete |
| 5. align | `jumo-code align <project> --write [--scope <name>]` | Push model metadata into code as `#[jumo]` annotations |
| 6. check | `cargo check` / `mvnw compile` | Ensure annotated code compiles |

If step 2 determines the model is already correct, skip steps 3-4 and go directly to align.

## Scoping: When One Crate Is Not The Whole Model

`jumo-code <cmd> <project>` reads Rust sources from `<project>/src`, so `<project>` is
a single crate — while the model usually describes the whole system. Comparing one
crate against the whole model reports every other crate's types as `模型有、代码无`
(hundreds of entries) and buries the real gaps.

Pass `--scope` to limit the comparison to the modules the crate implements:

```sh
jumo-code diff  <crate> --model <model-root> --scope <name>
jumo-code align <crate> --model <model-root> --scope <name> --write
```

`<name>` resolves in this order, fully qualified (`System.WistCenter`) or by last
segment (`WistCenter`):

| Kind | Module set comes from | Use when |
|------|----------------------|----------|
| `target` | the `target`'s `modules` list | **preferred** — a deployable artifact names exactly what one crate implements |
| `subsystem` | its `uses module`, plus its `uses service` services' `uses module` | the crate implements a whole subsystem |
| `service` | that service's `uses module` | the crate implements one runtime service |
| `module` | that module alone | narrowest |

- Scope is **not** transitive over `module depends`: a dependency belongs to its own
crate, and following it would re-introduce the noise scoping exists to remove.
- `diff` prints the resolved scope — kind, module list, and the in-scope / out-of-scope
/ unattributed counts. Always read it: a scope that resolves to the wrong modules
still looks like a clean diff.
- Model items the module map cannot attribute are skipped by every scope. A large
skipped count means ownership is incomplete; fix that before trusting a scoped diff.
- An unknown name fails with the candidate list, and a scope resolving to zero modules
is an error rather than a report of zero differences.
- `align` honours `--scope` too, so a scoped `diff` followed by a scoped `align` cannot
push the rest of the model into one crate. **Never run `align --write` unscoped on a
crate that implements only part of the model.**

## Diff Output Categories

| Category | Meaning | Action |
|----------|---------|--------|
| 注解不匹配 | Model spec differs from code annotation | Review which side is correct, update the other |
| 模型有、代码无 | Type exists in model but has no `#[jumo]` | Run `align --write` to add annotations |
| 代码已注解、模型无 | Code has `#[jumo]` but model has no matching type | If the type should be modeled, add to draft first; otherwise remove annotation |
| 代码无注解、模型也无 | Type in code without annotation, not in model | Decide if it should be modeled |

## Diagnosing Root Causes

When `diff` shows many entries, check:

- **owns missing**: If a code-facing type exists in any `jumo/model/static/<domain>/*.mju` file but no module owns it (in the directory-per-module layout ownership is inferred; in file-style modules it is declared in the module header), code alignment may not know which module annotation to write.
- **module kind too generic**: Domain structs/states often belong in `module<entity>`; rules, policies, and calculations often belong in `module<logic>`.
- **struct+kind not merged**: Model uses `struct X { kind: XKind }` + `state XKind`, but code uses a single `state X` enum directly.
- **naming inconsistency**: Model and code use different names for the same concept.
- **wrong scope**: A subsystem use case or layout region was added under static domain files instead of `jumo/model/runtime/subsystem/<name>/`.
- **service/module confusion**: A deployable process was modeled as only `module<service>` instead of a runtime `service` under `runtime/service/<name>/`.
- **missing `meta` labels**: Studio display falls back to raw identifiers when `meta label zh/en` is absent.
- **stale draft shadowing model**: A leftover `jumo/draft/` can make tools read the wrong copy depending on command and context.

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

Current Jumo supports typed fields with PascalCase types:

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
module JumoBinding {
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

Every code-facing item in the static domain package belongs to exactly one module. In the directory-per-module layout (`module/<name>/_mod.mju` + sibling item files) ownership is inferred from file placement, so no explicit `owns` list is needed. For file-style modules, ownership is declared via `module owns ...`:

- `struct` / `state` / `variant` / `message` / `event` / `actor` / `storage` / `config` — should be owned when they map to code or architecture responsibility
- Trigger `command` types — owned by the Interface layer module
- Error states — owned by the most relevant domain module

#### Not every item needs a module — check before attributing

`jumo-code diff` prints `N model item(s) skipped: the model gives them no module`, and scoped runs then hide those items from every scope. **That count is not a defect list.** The criterion is whether the item is code-facing: if no Rust type corresponds to it, no annotation can ever satisfy it, and inventing a module only records a claim that is false.

Items that legitimately have no module in a directory-per-module model:

- **Actors** declared in a domain-level `actors.mju`. They are cross-cutting (`BusinessAdministrator` authorises many modules) and usually have no Rust type. Verify with `grep -rn "\bActorName\b" <crate>/src` before acting.
- **UI-layer events** declared in a subsystem layout file (`runtime/subsystem/<name>/layout.*.mju`, an `event X` next to `on activate emit X`). These belong to the UiImpl layer, not to a static module.
- **Commands that only serve a placeholder verify flow.** If `grep -rn <Command> jumo/model/runtime` shows no usecase referencing it, it is a teaching fixture living beside its `flow` / `verify` in a domain-level `domain.mju`.

What *does* deserve attention is the opposite case: a module listed in some target's `modules` that no crate annotates. In warp-insight's model, `Control.Gateway.Security` and `Control.GatewayApp.Application` were exactly that — annotated in `wist-control` but listed in no target, so every scoped run silently skipped 11 items until they were added to `warp-insight-center`.

## Runtime Subsystem, Service, And Usecase Awareness

- Subsystem use cases belong in `jumo/model/runtime/subsystem/<name>/usecase.mju`.
- Subsystem layout belongs in `jumo/model/runtime/subsystem/<name>/layout.mju`.
- Subsystem declarations belong in `jumo/model/runtime/subsystem/<name>/subsystem.mju`.
- Runtime services belong in `jumo/model/runtime/service/<service>/service.mju`.
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

If `jumo-code diff` or studio views show duplicated `System.*` items, check whether files were placed in the wrong directory or loaded under the wrong domain scope.

## Rename Propagation

When renaming a type:
1. Update the domain package file that defines the type
2. Update the owning module: rename in the module's `owns` list (file-style modules) or move the item to the right module directory (directory-per-module layout)
3. Update all struct fields that reference the old name
4. Update usecase/flow/scenario/dataflow/layout references
5. Run `jumo verify` and `jumo-code diff`

## Code Annotation Discipline

After a `jumo/draft` model has been reviewed, validated, and promoted into `jumo/model/`, sync metadata back to code:

### Rust

```rust
#[derive(Jumo)]
#[jumo(kind = "message", role = "command", domain = "Business")]
pub struct SubmitOrder {
    #[jumo(unique)]
    pub id: String,
}
```

### Java

```java
@Jumo(kind = "message", role = "command", domain = "Business")
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
| `模型有、代码无` lists hundreds of types from unrelated domains | one crate compared against the whole model | pass `--scope <target\|subsystem\|service\|module>` |
| Usecase appears in wrong tree node | File placed in wrong scope | Move to `runtime/subsystem/<name>/usecase.mju` or an explicit runtime root usecase file |
| Service-only subsystem opens an empty layer diagram | Runtime service counted as static module | Add `uses module` for static layer views or inspect runtime service/topology views |

## Do

- Decide with the user which side is newer before rewriting anything (see Direction), then land that change first and mirror it.
- Pass `--scope` for any crate that implements only part of the model, and read the resolved scope before trusting the diff.
- Run `diff` before and after every alignment session.
- Use `--check` before `--write` to preview changes.
- Keep `jumo/model/` as the reviewed source and remove stale drafts after promotion.
- Keep new authoritative paths in `static/<domain>` and `runtime/...`; do not add new legacy `domain/` or `subsystem/` roots.

## Do Not

- Do not run `align --write` blindly. Understand why each difference exists first.
- Do not pick a direction on the user's behalf. The model is not unconditionally authoritative — it is allowed to lag behind the code.
- Do not add `#[jumo]` / `@Jumo` to types that are pure implementation details.
- Do not delete model types just to make diff pass.
- Do not let a single module own >15 types — split by business responsibility.
- Do not hide domain entity ownership or business rules in an unrelated `module<service>` when `module<entity>` or `module<logic>` is the clearer static boundary.
- Do not move subsystem/usecase/layout facts into unrelated static domain files just to make navigation look right.
- Do not use `module<service>` as a substitute for a runtime `service`.
