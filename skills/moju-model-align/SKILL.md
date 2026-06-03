---
name: moju-model-align
description: How to keep MoJu model and code annotations in sync. Covers diff diagnosis, alignment loop, sync rules (struct+kind merge, owns maintenance, rename propagation), and code annotation discipline.
triggers:
  - model-code alignment
  - moju-code diff
  - moju-code align
  - code annotations out of sync
  - syncing model and code
  - fixing diff mismatches
  - struct+kind merge
  - module owns maintenance
---

# MoJu Model Align

Use this skill to keep MoJu model files and code annotations consistent.

## Goal

`moju-code diff` reports zero differences between model and code annotations.

## Direction

```
moju/model/ (authoritative)  ──align──>  code annotations (mirror)
```

Never the reverse. If code has changed, update the model first (via `moju/draft/` → `moju verify` → promote), then align code.

## The Alignment Loop

```
moju-code diff  →  review gaps  →  fix model (if needed)  →  moju verify  →  moju-code align --write  →  cargo check
       ↑                                                                                                          |
       +----------------------------------------------------------------------------------------------------------+
```

| Step | Command | What it does |
|------|---------|-------------|
| 1. diff | `moju-code diff <project>` | Show what's out of sync |
| 2. review | read the diff output | Decide: model wrong, or code missing annotations? |
| 3. fix model | edit `moju/draft/` | If model needs updating: add/remove types, fix fields, update module owns |
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

- **owns missing from architecture.mju**: If a type exists in `domain.mju` but the module's `owns` list doesn't include it, the model parser won't recognize it.
- **struct+kind not merged**: Model uses `struct X { kind: XKind }` + `state XKind`, but code uses a single `state X` enum directly.
- **naming inconsistency**: Model and code use different names for the same concept.

## Struct+Kind Merge Rule

When code uses a single `state` enum but model has `struct X { kind: XKind }` + `state XKind`:

```mju
// Before (does NOT match code)
struct<domain> Action { kind: ActionKind }
state ActionKind { Call, Create, Emit }

// After (merged, matches code)
state Action { Call, Create, Emit, ChangeAdd, Goto, Ensure }
```

Update the owning struct: `kind: ActionKind` → `kind: Action`.

## Module Owns Maintenance

- All `owns` for a module must be on a **single line**. The parser only keeps the last `owns` line.
- Every type defined in `domain.mju` must appear in its module's `owns` list in `architecture.mju`.
- After merging struct+kind, update owns to list the merged state name.

```mju
// Correct — single line
module MoJuBinding {
  owns Binding, InterfaceBinding, StorageBinding, ConfigBinding, ConfigProvider, ConfigFileFormat
}

// Wrong — parser only keeps the last line
module MoJuBinding {
  owns Binding, InterfaceBinding
  owns StorageBinding, ConfigBinding
  owns ConfigProvider, ConfigFileFormat
}
```

## Module Split Rules

When a module's `owns` list grows too large (>15 types), split by **business responsibility**:

- **Grouping principle**: Types that change together belong together.
- **Granularity**: Each module should represent a single business capability.
- **Uniqueness**: Each type belongs to exactly one module.

### Owns Completeness Check

Every item in `domain.mju` must appear in exactly one module's `owns`:

- `struct` / `state` / `command` / `actor` — all must be owned
- Trigger `command` types — owned by the Interface layer module
- Error states — owned by the most relevant domain module

## Cross-Domain Reference Limits

Flows can only reference types defined in the **same domain**. Inter-domain dependencies are expressed via `dependency_rule` in `architecture.mju`. If a flow needs to interact with another domain's types, model it as a `command` trigger rather than directly creating cross-domain types.

## Rename Propagation

When renaming a type:
1. Update `domain.mju`: rename the type definition
2. Update `architecture.mju`: rename in the module's `owns` list
3. Update all struct fields that reference the old name
4. Run `moju-code diff` to verify no new mismatches appear

## Code Annotation Discipline

After a `moju-draft` model has been reviewed, validated, and promoted into `moju/`, sync metadata back to code:

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

- item kind: `struct`, `state`, `message`, `failure`, `storage`, `actor`
- domain
- message role: `command`, `query`, `response`
- unique fields
- failure identity, tag, description
- storage kind and durability

### What NOT To Sync

- flow step ordering, dataflow graph edges
- interface routes and status codes
- storage adapter providers (`postgres`, `redis`, `kafka`)
- config file paths and secret sources
- design decisions and profile choices

## Common Pitfalls

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "模型有、代码无" for types that exist | Type name mismatch | Rename one side to match |
| align adds `module = ""` | Empty module field | Check module attribution in architecture.mju |
| Same diff entries persist after align | Multi-line owns | Merge owns onto single line |
| align removes annotations | Model no longer owns the type | Add type to module's owns list |

## Do

- Model is always the source of truth. Change it first, then align code.
- Run `diff` before and after every alignment session.
- Use `--check` before `--write` to preview changes.

## Do Not

- Do not run `align --write` blindly. Understand why each difference exists first.
- Do not add `#[moju]` / `@MoJu` to types that are pure implementation details.
- Do not delete model types just to make diff pass.
- Do not let a single module own >15 types — split by business responsibility.
- Do not use cross-domain type references in flow steps.
