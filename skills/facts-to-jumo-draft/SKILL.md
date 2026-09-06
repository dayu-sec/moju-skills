---
name: facts-to-jumo-draft
description: How to synthesize a reviewed Jumo 2.0 draft model from jumo-code extract facts JSON. Covers static/runtime file separation, typed fields, runtime services, use cases, subsystems, layout regions, topology, semantic merge, and review output.
triggers:
  - converting code to jumo model
  - jumo-code extract
  - reverse modeling from code
  - creating jumo/draft
  - facts.json to model
  - semantic merge model and code
---

# Facts To Jumo Draft

Use this skill when converting `jumo-code extract` Facts JSON from an existing codebase into a draft Jumo model, or when updating an existing model with newly extracted facts.

## Goal

Produce reviewable files under `jumo/draft/`, then verify the model parses before handing off for review.

```
facts.json + project source
  -> jumo/draft/static/<domain>/domain.mju
  -> jumo/draft/static/<domain>/<module-or-responsibility>.mju  # optional split files
  -> jumo/draft/static/<domain>/behavior.mju
  -> jumo/draft/static/<domain>/architecture.mju
  -> jumo/draft/static/<domain>/binding.mju
  -> jumo/draft/static/<domain>/verify.mju
  -> jumo/draft/runtime/subsystem/<name>/subsystem.mju
  -> jumo/draft/runtime/subsystem/<name>/usecase.mju
  -> jumo/draft/runtime/subsystem/<name>/layout.mju
  -> jumo/draft/runtime/service/<service>/service.mju
  -> jumo/draft/runtime/service/<service>/target.mju
  -> jumo/draft/runtime/topology.mju
  -> jumo/draft/extraction.meta.json
  -> jumo/draft/review.md
  -> jumo verify jumo/draft
```

## Pipeline

```
source code -> jumo-code extract -> facts.json -> AI semantic merge -> jumo/draft/static + jumo/draft/runtime -> jumo verify -> human review -> merge to jumo/model/
```

`jumo-code extract` works on Rust syntax directly — struct names, fields, and enum variants are extracted from source without needing `#[jumo]` annotations. Annotations (`#[jumo(kind = "...", domain = "...")]`) enrich the extraction with kind/domain metadata, enabling precise diff and align, but they are not a prerequisite for basic extraction.

## Rules vs AI Boundary

This is the core design principle for the pipeline. Split every decision:

### Rules Can Do (deterministic, in tool)

- Parse Java/Rust source into structured data (fields, types, annotations)
- Map Java types → Jumo types (`String`→`String`, `int`→`Int`, `List<T>`→`List<T>`, `Set<T>`→`List<T>`, `Map<K,V>`→`Map<K,V>`)
- Extract enum constants, super class names, annotation attributes
- Format `.mju` syntax from structured data
- These are **parse → map → format** data pipelines with no semantic judgment

### AI Must Do (semantic judgment, in skill)

- **Field cleaning**: identify and remove infrastructure fields (logger, serialVersionUID, DB timestamps, DI-injected services, internal caches)
- **Merge decisions**: when model and code disagree on a type's fields, decide which side is authoritative
- **Naming resolution**: `ConfigInfo4Beta` vs `ConfigInfoBeta` — same concept or different? Decide whether to merge, alias, or keep both
- **Struct op selection**: from a dump of all qualifying methods, pick up to 5 per struct that express "this struct handles these business facts"
- **Domain clustering**: use `struct_relations` density to decide which structs belong in the same static domain directory
- **Scenario inference**: use `struct_relations` direction (op_param edges) to infer message flow between structs
- **Behavior generation**: deriving flows, caps, scenarios, verifies, and failure policies from controller/service code requires understanding architectural intent
- **Architecture generation**: static module boundaries, runtime subsystem/service composition, dataflows, topology, targets, and layout regions

### The Split In Practice

```
Java source
  ──[jumo-code extract: rules]──> facts.json (fields, types, enum values, attrs)
  ──[AI semantic merge: skill]──> updated domain package files (cleaned fields, merged items)
```

Rules produce standardized facts. AI consumes facts and makes decisions.

## Semantic Merge Algorithm

When updating an existing model with extracted facts, do NOT replace — merge:

| Scenario | Action |
|----------|--------|
| Item in model, NOT in code | **Keep** — design intent may not have code yet (events, messages, cap result types) |
| Item in code, NOT in model | **Add** — code is evidence for new types; use code field names and types unless review says otherwise |
| Both, fields differ | **Update** — code field names/types are ground truth; keep model-only design fields |
| Both, naming differs | **Judge** — decode naming patterns (e.g., `ConfigInfo4Beta` in Java = `ConfigInfoBeta` in model); may alias or merge |

After merge, run `jumo verify` to confirm parseability.

When a domain has clear module clusters or a large ownership surface, split the draft inside `jumo/draft/static/<domain>/` by module owner, interface provider, or business responsibility instead of forcing all facts into `domain.mju`. Prefer the directory-per-module form (`module/<name>/_mod.mju` declares the module header, sibling `items.mju` holds its facts) so ownership is inferred from the directory and `owns` lists can be omitted. For file-style modules, `module owns ...` declares ownership explicitly.

## Infrastructure Field Filtering

When extracting fields from Java classes, skip these by default:

| Pattern | Examples | Reason |
|---------|----------|--------|
| Logger fields | `logger`, `log`, `LOG`, `LOGGER` | Logging infrastructure |
| Serialization | `serialVersionUID` | JVM serialization |
| DB timestamps | `gmtCreate`, `gmtModified`, `createdTime` (Timestamp type) | ORM auto-managed |
| Surrogate keys | `id` (only when auto-generated Long/int) | DB infrastructure |
| DI fields | Fields annotated with `@Autowired`, `@Inject`, `@Resource` | Runtime injection |
| Enum serialization | `value` field in enums used for Jackson mapping | Serialization helper |
| JVM synthetic | Fields starting with `_` | Compiler-generated |

These are heuristics. When in doubt, keep the field and add a note in `review.md`.

## File Separation

| File | Contains | Does NOT contain |
|------|----------|------------------|
| `static/<domain>/domain.mju` or split static files | `struct`, `state`, `variant`, `event`, `failure`, `message`, `actor`, `interface`, `config`, `storage` | flow bodies, dataflow edges, deployment topology |
| `static/<domain>/behavior.mju` | `lifecycle`, `cap` with ops, `flow`, `scenario`, `failure_policy`, `retry_policy` | struct/state/message definitions |
| `static/<domain>/architecture.mju` | `layer`, `module`, `dependency_rule`, `dataflow`, `decision` | binding details and verify cases |
| `static/<domain>/binding.mju` | interface route/status/outcome bindings, storage adapter bindings, config source bindings | domain concepts and flows |
| `static/<domain>/verify.mju` | `verify` cases | production behavior declarations |
| `runtime/subsystem/<name>/subsystem.mju` | `subsystem` declaration, `uses service`, optional `uses module` | static domain facts |
| `runtime/subsystem/<name>/usecase.mju` | subsystem-level `usecase` blocks | static architecture |
| `runtime/subsystem/<name>/layout.mju` | `struct<ui>`, UI messages/events, `region`, `bind Struct to Region` | storage or deployment binding |
| `runtime/service/<name>/service.mju` | runtime `service`, `kind`, `surface`, `exposes`, `uses module` | static module ownership |
| `runtime/service/<name>/target.mju` | service-specific `target<...>` details | domain concepts |
| `runtime/topology.mju` | `node`, `resource`, `network`, `link`, deployment `bind` | domain module ownership |
| `runtime/target.mju` | platform/root targets and subsystem composition | route or storage adapter details |

> `cap` trait definitions (op list) go in `static/<domain>/behavior.mju`. `cap` name references (e.g., `depends InventoryPort`) can appear in `static/<domain>/architecture.mju` module sections.
> `interface entry` goes in the domain package as the stable external contract declaration. Route/HTTP binding details belong in `binding.mju`.
> `module<interface>` belongs in `static/<domain>/architecture.mju` as the provider/owner declaration. One provider module may `provides` multiple `interface` contracts; the contracts and entry messages may live together in a provider-focused split file such as `agent-facing-interface.mju`.
> Use `module<entity>` for entity/state/aggregate/value-object ownership and `module<logic>` for rules, policies, calculations, and domain logic.
> `service` is runtime. Put it in `runtime/service/<service>/service.mju`; do not model a deployable process as only `module<service>`.

## Authority Rules

- Facts JSON is evidence, not design truth.
- `jumo/draft/` is a candidate model for human review.
- Only a reviewed model copied into `jumo/model/` is authoritative.
- Do not invent routes, protocols, storage adapters, permissions, or business decisions as confirmed facts.
- If inference is useful but uncertain, include it in the draft and mark it in metadata/review as inferred.
- **Code fields are ground truth for names and types** — when model and code disagree on a field, prefer the code version unless the model field represents a design concept not yet implemented.

## Mapping Rules

**Note**: These mappings reflect the Jumo 2.0 design language. The current `jumo verify` CLI parser supports a subset. When generating `.mju` files that must pass `jumo verify`, adapt as follows:
- `struct<domain>` → `struct` (omit angle-bracket annotation)
- `message<command>` → keep as `message<command>` (current syntax); plain `command` is legacy-compatible
- `message<response>` → keep, or reference the payload struct directly as an `entry`'s `output SomeStruct`
- `actor<human>`, `actor<system>` → `actor` (annotate role via `meta` tags)
- `struct<config>`, `struct<ui>` → `struct` (annotate via `meta` tags)
- `cap`, `storage`, `failure` → document in `architecture.mju` comments or plan for future CLI support
- All field types must use PascalCase: `String`, `Int`, `DateTime`, `Boolean`, `List<Type>`

- `type_defs` with `#[jumo(kind = "struct")]` (Rust) or `@Jumo(kind = "struct")` (Java) maps to `struct` (or `struct<domain>` in 2.0 design).
- `type_defs` with `#[jumo(kind = "state")]` (Rust) or `@Jumo(kind = "state")` (Java) maps to `state`. Enum constants become state variants.
- `type_defs` with `#[jumo(kind = "event")]` maps to `event`.
- `type_defs` with `#[jumo(kind = "message", role = "command")]` maps to `message<command>`.
- `type_defs` with `#[jumo(kind = "message", role = "response")]` maps to `message<response>`.
- `type_defs` with `#[jumo(kind = "failure", ...)]` maps to `failure` with identity hierarchy. `super_type` becomes `: ParentFailure`.
- `type_defs` with `#[jumo(kind = "actor", ...)]` maps to `actor` with parent chain.
- `type_defs` with `#[jumo(kind = "storage", ...)]` maps to `storage` with kind and durability.
- `jumo_annotations` provide the authoritative kind/role/domain for each type (from `#[jumo]` in Rust or `@Jumo` in Java).
- Java `@Jumo` annotation attributes (`kind`, `domain`, `role`, `storageKind`, `durability`, `identity`, `tag`) carry the same metadata as Rust `#[jumo(...)]`.
- Java enums annotated with `@Jumo(kind = "state")` map to `state` just as Rust enums do.
- Trait definitions under static domain capability areas map to `cap` with `op` for each method signature.
- **Rust `trait` is not valid Jumo syntax**. Rust traits map to Jumo `cap` (capability) definitions in `behavior.mju`. Do NOT write `trait X { ... }` in `.mju` files — it will fail `jumo verify`.
- `state_writes` and `state_guards` can suggest `lifecycle` transitions, but should be marked inferred.
- `struct_methods` contains all qualifying instance methods on each struct (Rust: `pub`/`pub(crate)` + `&mut self`; Java: public instance with params, excluding getters/setters). AI selects up to 5 per struct to become `op` declarations.
- `struct_relations` contains directed edges between structs. `signal`: `field` (A holds B in a field) or `op_param` (A's method receives B-type param). Extra detail: `Handler<Event>` trait impls (Rust) and `@EventListener` annotations (Java) are tagged in the detail field. AI uses this graph for domain clustering and scenario inference.
- Config structs/records (e.g., `*Config`, `*Properties`) map to `struct<config>` and may produce `config` contracts plus `binding` source hints.
- Failure type hierarchy (e.g., `StripePaymentFailure : PaymentGatewayFailure`) maps to `failure Child : Parent`.
- UI DTOs or screen/view classes may map to `struct<ui>` and `layout.mju` regions, but only when the source clearly represents UI state or view composition.
- HTTP controllers may suggest `interface` entries and `binding.mju` routes/statuses; mark inferred routes/statuses for review unless annotations or framework mappings are explicit.
- Scheduled jobs may suggest `actor<system>` timer actors for use cases.

## Usecase, Subsystem, Layout, And Topology Inference

Generate these only when the code or existing model gives enough evidence:

- `usecase`: from controller/job entry points, user roles, command triggers, flows, and response/outcome messages.
- `subsystem`: from deployable business system boundaries, product boundaries, platform boundaries, or explicit existing subsystem files.
- `service`: from runnable processes, HTTP API crates/apps, web sites, daemons, workers, scheduled jobs, or deployable units.
- `layout`: from UI view classes/components/screens, not from backend DTOs alone.
- `topology`: from deployment manifests, runtime module names, infrastructure clients, or existing target/binding files.

Example subsystem use case output:

```mju
usecase ConfigureBackupTarget {
  meta {
    label zh "配置备份目标"
    label en "Configure Backup Target"
  }

  actor Foundation.PlatformOperator
  trigger Foundation.ConfigureBackupTarget
  outcome Foundation.BackupTargetConfigured
  flow Foundation.BackupTargetConfiguring
  verify Foundation.BackupTargetConfigured
}
```

Example layout output:

```mju
region<page> AuditReportScreen {
  orientation grid
  contains AuditFilterBar { row: 1, col: 1, width: fill }
  contains AuditFindingList { row: 2, col: 1, height: fill }
  layout fill_remaining
}
```

## Java Type Mapping Table

| Java Type | Jumo Type |
|-----------|-----------|
| `String` | `String` |
| `int`, `Integer`, `long`, `Long`, `short`, `Short`, `byte`, `Byte` | `Int` |
| `boolean`, `Boolean` | `Bool` |
| `float`, `Float`, `double`, `Double` | `Float` |
| `byte[]`, `Byte[]` | `Bytes` |
| `List<T>` | `List<T>` |
| `Set<T>` | `List<T>` |
| `Map<K,V>` | `Map<K,V>` |
| `Optional<T>` | `T?` |
| Other objects | PascalCase class name (strip package) |

## Struct Op Selection

When `facts.struct_methods` is present, the AI must select up to **5 methods per struct** to become `op` declarations. The extractor dumps all qualifying methods; the AI picks which ones express "this struct handles these business facts."

Selection is based on the AI's understanding of business context — method names, parameter types, and the struct's role in the domain. Do not use mechanical heuristics.

Each selected method becomes an `op` declaration (Jumo 2.0 design syntax — for CLI-compatible output, document operations in meta tags or comments):

```mju
// Jumo 2.0 design syntax:
struct Inventory {
  meta {
    label zh "库存"
    label en "Inventory"
  }

  unique sku: String
  available: Int
  reserved: Int

  op<sync> InventoryReserved(cart, items);
  op<sync> InventoryReleased(cart, items);
}
```

For `jumo verify` compatibility, omit `op` declarations and record operations elsewhere:

```mju
struct Inventory {
  meta {
    label zh "库存"
    label en "Inventory"
    tag "op:reserve"
    tag "op:release"
  }

  unique sku: String
  available: Int
  reserved: Int
}
```

- Derive event name from method name: `handle_reserved` → `InventoryReserved`
- Default to `op<sync>` unless the method returns a `Future` or is in an async context — then use `op<async>`

For each selected op, record in `extraction.meta.json`:
- `source_method`: the original method name
- `confidence`: `high` / `medium`

## Struct Relations Analysis

When `facts.struct_relations` is present, the AI has a directed graph of struct-to-struct references. Use this graph for four analyses:

### 1. Domain Clustering

Relations with high density form a natural domain boundary. The AI groups structs into domain directories based on connection density:

```
High density cluster → same static/ directory
  Order ←→ PaymentIntent ←→ Cart ←→ Inventory
  -> jumo/draft/static/business/

Sparse / isolated → config or cross-cutting
  RunPolicy (0 relations) -> jumo/draft/static/business/ as struct<config>
  HttpServerConfig (0 relations) -> jumo/draft/static/business/ as struct<config>
```

AI uses its own judgment to decide the right domain names and boundaries. Do not hardcode "Business" for all clusters — infer domain names from the struct names in each cluster.

### 2. Scenario Inference

When a struct's `op_param` edges point to event types defined in other structs, this reveals message flow. The AI can infer `scenario` blocks:

```
Relations:
  Order → (op_param) → PaymentSucceeded → PaymentIntent  (Order handles PaymentIntent's event)
  PaymentIntent → (op_param) → OrderCreated → ConfigHistoryInfo
  Inventory → (op_param) → InventoryReserved → Cart

AI infers:
  scenario PlaceOrder {
    Cart send InventoryReserved → Inventory
    PaymentIntent send PaymentSucceeded → Order
    PaymentIntent send PaymentSucceeded → ConfigHistoryInfo
  }
```

The relation graph gives direction (who handles whose event) but not ordering. AI uses business understanding to sequence the steps. The scenario name is inferred from the cluster context.

### 3. Modeling Prioritization

Sort structs by connection count to determine which to model first:

```
Order            ← 6 relations → model first, core aggregate
PaymentIntent    ← 4 relations
Inventory        ← 3 relations
Cart             ← 2 relations
RunPolicy        ← 0 relations → model last, likely config
```

### 4. Missing Struct Detection

When an `op_param` or `Handler<Event>` edge references a type not in `type_defs`, flag it:

```
PaymentSucceeded event references ProviderRef
  → ProviderRef not in type_defs
  → AI adds to review.md: "可能缺失 struct ProviderRef"
```

## Naming Conflict Resolution

When code and model use different names for the same concept:

1. Check if they represent the same DB table / API contract
2. Common pattern: Java DTO uses `ConfigInfo4Beta`, model uses `ConfigInfoBeta`
3. If same concept: use the model's name as primary, note Java name in a comment
4. If different concepts (e.g., one extends another): keep both, note the relationship
5. If unsure: keep both, add to `review.md` for human decision

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

- Keep all `.mju` files parseable. Run `jumo verify jumo/draft` to confirm.
- Prefer a smaller valid draft over a broad invalid model.
- Put uncertain reasoning in `extraction.meta.json` and `review.md`, not in comments inside `.mju`.
- `jumo/draft/` is temporary. Promote reviewed content into `jumo/model/`, then remove draft.
