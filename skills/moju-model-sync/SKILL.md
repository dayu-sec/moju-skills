---
name: moju-model-sync
description: Rules for syncing model and code after identifying differences via moju-code diff. Covers struct+kind merge, owns maintenance, rename propagation, and sync direction.
triggers:
  - syncing model and code
  - running moju-code align
  - fixing diff mismatches
  - struct+kind merge
  - module owns maintenance
---

# MoJu Model Sync

Use this skill when synchronizing MoJu model files with code annotations, after identifying differences via `moju-code diff`.

## Goal

Keep model and code annotations consistent so that `moju-code diff` reports zero differences.

## Source Of Truth

- `moju/model/` is authoritative for reviewed designs.
- `moju/draft/` is the working area for reverse-modeling from code.
- Code annotations are mirrors — update them to match the model. In Rust: `#[moju(...)]`. In Java: `@MoJu(...)`.

## Struct+Kind Merge Rule

When code uses a single `state` enum but the model has `struct X { kind: XKind }` + `state XKind`, merge them in the model:

```mju
// Before (model pattern, does NOT match code)
struct<domain> Action {
  kind: ActionKind
}
state ActionKind { Call, Create, Emit }

// After (merged, matches code)
state Action { Call, Create, Emit, ChangeAdd, Goto, Ensure }
```

Update the owning struct to reference the merged state directly:
```mju
struct<domain> Foo {
  kind: ActionKind  // before
  kind: Action      // after
}
```

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

## Rename Propagation

When renaming a type (e.g., `BindingKind` → `Binding`):
1. Update `domain.mju`: rename the type definition
2. Update `architecture.mju`: rename in the module's `owns` list
3. Update all struct fields that reference the old name
4. Run `moju-code diff` to verify no new mismatches appear

## Module Split Rules

When a module's `owns` list grows too large (>15 items), split by business sub-domain, not by technical file layout:

| Anti-Pattern | Correct |
|-------------|---------|
| `LangAst` owns 47 types (all AST nodes) | Split into `LangRule` (rule decl), `LangMatch` (match clauses), `LangExpr` (expressions), `LangJoin` (joins), `LangConv` (conversions), `LangTest` (test contracts) |
| `ConfigLoader` owns 26 types (all config) | Split into `WindowConfig`, `SourceConfig`, `LoggingMetrics` |
| Multiple modules own the same type | Each type belongs to exactly one module |

### Owns Completeness Check

Every item in `domain.mju` must appear in exactly one module's `owns` in `architecture.mju`:

- `struct` / `state` / `command` / `actor` — all must be owned
- `event` (trigger messages) — owned by the Interface layer module
- Error states (`*Reason`) — owned by the most relevant domain module

Run `moju verify` after each architecture change to catch missing owns.

## Cross-Domain Reference Limits

MoJu flows can only reference types within the same domain. Cross-domain references like `create Config.FusionConfig {}` in an orchestra flow will fail `moju verify` with `not defined`.

- Flows describe **intra-domain** orchestration
- Inter-domain dependencies are expressed via `dependency_rule` in `architecture.mju`
- If a flow needs types from another domain, model the interaction as a `command` trigger rather than a direct create

## Sync Direction

| Scenario | Direction |
|----------|-----------|
| Model is authoritative (reviewed design) | Update code annotations via `align --write` |
| Code is authoritative (reverse-modeling) | Update `moju/draft/` model files |
| Both changed independently | Review diff, decide case by case, sync the side that's wrong |

## Do Not

- Do not delete model types just to make diff pass. Understand the intent first.
- Do not add `#[moju]` (Rust) or `@MoJu` (Java) to types that are pure implementation details (DTOs, DB rows, HTTP handlers/controllers).
- Do not let a single module own >15 types — split by business responsibility.
- Do not use cross-domain type references in flow steps — they will fail verification.
