---
name: facts-to-moju-draft
description: How to synthesize a reviewed moju/draft model from moju-code extract facts JSON. Covers current moju/model file separation, typed fields, use cases, subsystems, layout regions, topology, semantic merge, and review output.
triggers:
  - converting code to moju model
  - moju-code extract
  - reverse modeling from code
  - creating moju/draft
  - facts.json to model
  - semantic merge model and code
---

# Facts To MoJu Draft

Use this skill when converting `moju-code extract` Facts JSON from an existing codebase into a draft MoJu model, or when updating an existing model with newly extracted facts.

## Goal

Produce reviewable files under `moju/draft/`, then verify the model parses before handing off for review.

```
facts.json + project source
  -> moju/draft/domain/<domain>/domain.mju
  -> moju/draft/domain/<domain>/behavior.mju
  -> moju/draft/domain/<domain>/architecture.mju
  -> moju/draft/domain/<domain>/binding.mju
  -> moju/draft/domain/<domain>/verify.mju
  -> moju/draft/subsystem/<name>/usecase.mju
  -> moju/draft/subsystem/<name>/layout.mju
  -> moju/draft/topology.mju
  -> moju/draft/extraction.meta.json
  -> moju/draft/review.md
  -> moju verify moju/draft
```

## Pipeline

```
source code -> moju-code extract -> facts.json -> AI semantic merge -> moju/draft/*.mju -> moju verify -> human review -> merge to moju/model/
```

`moju-code extract` works on Rust syntax directly — struct names, fields, and enum variants are extracted from source without needing `#[moju]` annotations. Annotations (`#[moju(kind = "...", domain = "...")]`) enrich the extraction with kind/domain metadata, enabling precise diff and align, but they are not a prerequisite for basic extraction.

## Rules vs AI Boundary

This is the core design principle for the pipeline. Split every decision:

### Rules Can Do (deterministic, in tool)

- Parse Java/Rust source into structured data (fields, types, annotations)
- Map Java types → MoJu types (`String`→`String`, `int`→`Int`, `List<T>`→`List<T>`, `Set<T>`→`List<T>`, `Map<K,V>`→`Map<K,V>`)
- Extract enum constants, super class names, annotation attributes
- Format `.mju` syntax from structured data
- These are **parse → map → format** data pipelines with no semantic judgment

### AI Must Do (semantic judgment, in skill)

- **Field cleaning**: identify and remove infrastructure fields (logger, serialVersionUID, DB timestamps, DI-injected services, internal caches)
- **Merge decisions**: when model and code disagree on a type's fields, decide which side is authoritative
- **Naming resolution**: `ConfigInfo4Beta` vs `ConfigInfoBeta` — same concept or different? Decide whether to merge, alias, or keep both
- **Struct op selection**: from a dump of all qualifying methods, pick up to 5 per struct that express "this struct handles these business facts"
- **Domain clustering**: use `struct_relations` density to decide which structs belong in the same domain directory
- **Scenario inference**: use `struct_relations` direction (op_param edges) to infer message flow between structs
- **Behavior generation**: deriving flows, caps, scenarios, verifies, and failure policies from controller/service code requires understanding architectural intent
- **Architecture generation**: module boundaries, subsystem composition, dataflows, topology, targets, and layout regions

### The Split In Practice

```
Java source
  ──[moju-code extract: rules]──> facts.json (fields, types, enum values, attrs)
  ──[AI semantic merge: skill]──> updated domain.mju (cleaned fields, merged items)
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

After merge, run `moju verify` to confirm parseability.

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
| `domain/<domain>/domain.mju` | `struct`, `state`, `variant`, `event`, `failure`, `message`, `actor`, `interface`, `config`, `storage` | flow bodies, dataflow edges, deployment topology |
| `domain/<domain>/behavior.mju` | `lifecycle`, `cap` with ops, `flow`, `scenario`, `failure_policy`, `retry_policy` | struct/state/message definitions |
| `domain/<domain>/architecture.mju` | `module`, `dependency_rule`, `dataflow`, `decision` | binding details and verify cases |
| `domain/<domain>/binding.mju` | interface route/status/outcome bindings, storage adapter bindings, config source bindings | domain concepts and flows |
| `domain/<domain>/verify.mju` | `verify` cases | production behavior declarations |
| `usecase.mju` | system-level `usecase` blocks | subsystem-only use cases |
| `subsystem/<name>/architecture.mju` | `subsystem` declaration and subsystem-scoped module composition | root topology |
| `subsystem/<name>/usecase.mju` | subsystem-level `usecase` blocks | global/system-level use cases |
| `layout.mju` | `struct<ui>`, UI messages/events, `region`, `bind Struct to Region` | storage or deployment binding |
| `topology.mju` | `node`, `resource`, `network`, `link`, deployment `bind` | domain module ownership |
| `target.mju` | named `target<...>` blocks, platform subsystem composition | route or storage adapter details |

> `cap` trait definitions (op list) go in `behavior.mju`. `cap` name references (e.g., `depends InventoryPort`) can appear in `architecture.mju` module sections.
> `interface entry` goes in `domain.mju` as the stable external contract declaration. Route/HTTP binding details belong in `binding.mju`.

## Authority Rules

- Facts JSON is evidence, not design truth.
- `moju/draft/` is a candidate model for human review.
- Only a reviewed model copied into `moju/model/` is authoritative.
- Do not invent routes, protocols, storage adapters, permissions, or business decisions as confirmed facts.
- If inference is useful but uncertain, include it in the draft and mark it in metadata/review as inferred.
- **Code fields are ground truth for names and types** — when model and code disagree on a field, prefer the code version unless the model field represents a design concept not yet implemented.

## Mapping Rules

- `type_defs` with `#[moju(kind = "struct")]` (Rust) or `@MoJu(kind = "struct")` (Java) maps to `struct<domain>`.
- `type_defs` with `#[moju(kind = "state")]` (Rust) or `@MoJu(kind = "state")` (Java) maps to `state`. Enum constants become state variants.
- `type_defs` with `#[moju(kind = "event")]` maps to `event`.
- `type_defs` with `#[moju(kind = "message", role = "command")]` maps to `message<command>`.
- `type_defs` with `#[moju(kind = "message", role = "response")]` maps to `message<response>`.
- `type_defs` with `#[moju(kind = "failure", ...)]` maps to `failure` with identity hierarchy. `super_type` becomes `: ParentFailure`.
- `type_defs` with `#[moju(kind = "actor", ...)]` maps to `actor` with parent chain.
- `type_defs` with `#[moju(kind = "storage", ...)]` maps to `storage` with kind and durability.
- `moju_annotations` provide the authoritative kind/role/domain for each type (from `#[moju]` in Rust or `@MoJu` in Java).
- Java `@MoJu` annotation attributes (`kind`, `domain`, `role`, `storageKind`, `durability`, `identity`, `tag`) carry the same metadata as Rust `#[moju(...)]`.
- Java enums annotated with `@MoJu(kind = "state")` map to `state` just as Rust enums do.
- Trait definitions under `domain/caps/` map to `cap` with `op` for each method signature.
- **Rust `trait` is not valid MoJu syntax**. Rust traits map to MoJu `cap` (capability) definitions in `behavior.mju`. Do NOT write `trait X { ... }` in `.mju` files — it will fail `moju verify`.
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
- `subsystem`: from service boundaries, package/module boundaries, deployment names, or explicit existing subsystem files.
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

| Java Type | MoJu Type |
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

Each selected method becomes an `op` declaration:

```mju
struct<domain> Inventory {
  sku: Sku
  available: Quantity
  reserved: Quantity

  op<sync> InventoryReserved(cart, items);
  op<sync> InventoryReleased(cart, items);
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
High density cluster → same domain/ directory
  Order ←→ PaymentIntent ←→ Cart ←→ Inventory
  -> moju/draft/domain/business/

Sparse / isolated → config or cross-cutting
  RunPolicy (0 relations) -> moju/draft/domain/business/ as struct<config>
  HttpServerConfig (0 relations) -> moju/draft/domain/business/ as struct<config>
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

- Keep all `.mju` files parseable. Run `moju verify moju/draft` to confirm.
- Prefer a smaller valid draft over a broad invalid model.
- Put uncertain reasoning in `extraction.meta.json` and `review.md`, not in comments inside `.mju`.
- `moju/draft/` is temporary. Promote reviewed content into `moju/model/`, then remove draft.
