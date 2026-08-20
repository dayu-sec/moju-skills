---
name: moju-model-understanding
description: How to understand current MoJu 2.0 language and model concepts when drafting models, reviewing moju-studio views, or implementing generated code. Covers static domains, runtime subsystems/services, use cases, layout regions, topology, bindings, profiles, validation, and common pitfalls.
triggers:
  - drafting MoJu models
  - interpreting MoJu model files
  - understanding moju/model
  - understanding domain.mju
  - understanding behavior.mju
  - understanding architecture.mju
  - understanding binding.mju
  - understanding usecase.mju
  - understanding layout.mju
  - understanding topology.mju
  - understanding profile.mju
  - reading MoJu model files
  - implementing generated MoJu skeleton
  - reading AI_TASKS.md
---

# MoJu Model Understanding

Use this skill before drafting MoJu models, editing `moju/model`, reviewing moju-studio views, or implementing generated code from a MoJu model.

## Current Model Layout

The current canonical model root is `moju/model/`. New projects use the MoJu 2.0 split between static design facts and runtime deployable boundaries.

Recommended 2.0 layout (see `project-organization.md` for full reference):

```text
moju/model/
  architecture.mju              # root-level: layer + dependency_rule (cross-domain)
  profile.mju                   # generation strategy, not a domain fact
  static/
    <domain>/
      domain.mju                # struct, state, event, command, actor, interface
      module.mju                # module definitions with layer, owns, responsible_for
      architecture.mju          # layer, dependency_rule (cross-domain only)
      module/                   # one directory per module (recommended)
        <module-a>/
          _mod.mju              # module header (meta, layer, depends, provides)
          items.mju             # items owned by the module (owns inferred from the dir)
        <module-b>/
          _mod.mju
          items.mju
      behavior.mju              # flow, scenario, lifecycle
      verify.mju                # verify cases for flows
      binding.mju               # implementation bindings (route, storage, config)
      rules.md                  # optional: natural language rules for codegen
  runtime/
    subsystem/
      <subsystem>/
        subsystem.mju           # uses service + uses module
        usecase.mju             # subsystem-level use cases
        layout.mju              # UI regions/windows/sections
    service/
      <service>/
        service.mju             # kind bin<http> + uses module
        target.mju              # target<bin,http> + modules list
        assembly.mju            # optional: kind, scale, run
    topology.mju                # node, resource, network, bind, link
  moju-layout.json
```

Key principles:
- `static/<domain>/module.mju` defines module ownership and layer — NOT `architecture.mju`
- `runtime/service/<service>/service.mju` declares the service (kind + uses module)
- `runtime/service/<service>/target.mju` declares the build target (target<bin,http> + modules list)
- A `service` can combine modules from multiple domains
- `subsystem uses service` and `subsystem uses module` for composition
- Root `architecture.mju` only contains cross-domain `layer` and `dependency_rule`
- `binding.mju` is for implementation bindings; `target<bin,http>` goes in `runtime/service/`

## Model Concepts

All elements may carry a `meta` block for display labels, summaries, and tags.

### Core Syntax (verified with current CLI)

- `struct` is a domain concept. Fields use PascalCase types: `unique id: String`, `name: String`, `count: Int`, `created_at: DateTime`, `active: Boolean`. Use `unique` prefix for primary key fields. For lists: `tags: List<String>`.
- `command` is the triggering message contract. Command messages commonly trigger flows. Field syntax: `name: String`, `task_id: String`.
- `event` is a domain fact emitted or consumed by flows. Fields use the same typed syntax as struct. Example: `event BackupCompleted { record_id: String snapshot_id: String }`.
- `actor` declares an actor and which commands it can trigger. Supports `meta` for labels. Example: `actor Admin { can CreateBackupTask can StartBackup }`. For system actors, add `access protocol<http>`.
- `interface` is the stable external entry contract. Protocol exposure is declared by provider modules and `binding.mju`. Supports `meta` for labels and summaries. An `entry`'s `output` may reference a `message<response>`, a plain `struct`, `List<Struct>`, or `Projection<...>` (`Projection<Struct>` / `Projection<List<Struct>>`) — `output SomeStruct` is a direct response, so wrapper response messages can be dropped. An `entry`'s `calls` is optional and defaults to `<entry>Flow`. **DTO/View principle**: query/aggregate views (counts summaries, status cards, `Returned` wrappers) are NOT strictly modeled — they live at the implementation layer; the model uses `List<Struct>` or `Projection<T>` to express "read shape of the domain", and code carries the concrete DTO fields. `Projection<T>` is only for non-trivial read shapes; plain lists use `List<Struct>`.
- `message<command> Name = BaseStruct { ... }` (and `command Name = BaseStruct { ... }`) inherit all fields of `BaseStruct` and may add more. This shares request context (e.g. `requested_by`) across commands instead of repeating the field. Also works for `message<response>`.
- `state` declares a state space with typed fields. Example: `state BackupRecordState { unique id: String status: String started_at: DateTime }`.
- `variant` declares tagged alternatives. Example: `variant BackupType { Full Incremental }`. Variants may have `meta`.
- `flow` describes orchestration using actors, responsibility lanes, entry triggers, signal triggers, and steps. Prefer binding the external command to the first activity: `flow BackupFlow { actor Admin step Start in Admin by StartBackup { ... next Persist } step<stop> Persist in Worker by BackupRequested { ... } }`. `in` may reference a declared lane or a flow participant directly. The first `by Command` is projected to `Flow.trigger`; a later `by Event` step starts an independent signal-driven sequence, and a later `by Command` step is a linear driver reached through an explicit `next` / `goto` edge — never through source order. **Control flow is fully explicit: every normal step must terminate with `next <step>` / `goto <step>` / `match { }`, or be declared `step<stop>` / `step<exit>`; source order is layout only and `moju verify` rejects a step with no explicit exit.** The legacy flow-level `trigger` remains compatible and must match the first `by` when both are present. React steps cannot declare `by`. `step` is optional: a step-less placeholder flow uses its flow-level `trigger` as the implicit entry.
- `module` describes ownership, responsibility, and layer assignment. Syntax: `module Name { layer Application responsible_for "..." }`. In the directory-per-module layout, `owns` is inferred from file placement and can be omitted; `responsible_for` is optional and defaults to the meta summary.
- `layer` and `dependency_rule` in root `architecture.mju` define the system's layered architecture.
- `verify` blocks assert flow correctness. Syntax: `verify Name for flow FlowName { given { ... } when Command expect { ... } }`.

### Currently available in moju-studio views only (not in CLI parser)

These elements are parsed and rendered by moju-studio but are not yet supported by the `moju verify` CLI parser:

- `struct<domain>`, `struct<config>`, `struct<ui>` — typed struct annotations
- `actor<human>`, `actor<system>` — actor role annotations
- `service` — runtime deployable unit declaration
- `subsystem` — runtime subsystem boundary
- `usecase` — use case traceability node
- `region`, `region<page>`, `region<window>`, `region<section>` — UI layout regions
- `dataflow` — data movement modeling
- `cap` — abstract capability description
- `storage` — logical persistence shape
- `decision` — architecture decision record
- `lifecycle`, `scenario`, `failure_policy` — behavior modeling
- Handler-level flow constructs: `handler on`, `call`, `match`, `ensures`

## File Responsibilities

| File | Primary content |
|------|-----------------|
| `static/<domain>/domain.mju` | `struct`, `state`, `variant`, `command`, `event`, `actor`, `interface` |
| `static/<domain>/module.mju` | `module` declarations with `layer`, `owns`, `responsible_for` |
| `static/<domain>/behavior.mju` | `flow`, `scenario`, `lifecycle` |
| `static/<domain>/verify.mju` | `verify` cases for flows |
| `static/<domain>/binding.mju` | implementation bindings (route, storage, config) |
| `architecture.mju` (root) | `layer`, `dependency_rule` (cross-domain) |
| `runtime/subsystem/<name>/subsystem.mju` | `subsystem` with `uses service` + `uses module` |
| `runtime/subsystem/<name>/usecase.mju` | `usecase` blocks for the subsystem |
| `runtime/service/<name>/service.mju` | `service` with `kind bin<http>` + `uses module` |
| `runtime/service/<name>/target.mju` | `target<bin,http> name { modules ... }` build target |
| `runtime/topology.mju` | `node`, `resource`, `network`, `link`, `bind` |
| `profile.mju` | generation profile choices |

**Critical distinction**: `module.mju` (static) declares logical module ownership. `service.mju` (runtime) declares deployable process boundary. `target.mju` declares build/compile target for that service. Do NOT put `target<bin,http>` in `binding.mju`.

## Domain Package Split

For small domains, keep core facts in `static/<domain>/domain.mju`. When the domain grows, split by module owner, provider, or responsibility while keeping every file in the same static domain directory:

```text
moju/model/static/control/
  domain.mju                    # domain overview or index
  module.mju                    # layer, module declarations (owns inferred or explicit)
  user-facing-interface.mju     # user/admin interfaces, entries, messages, entry flows
  agent-facing-interface.mju    # agent/daemon interfaces, entries, messages
  enrollment.mju                # Enrollment-owned facts and flows
  identity.mju                  # Identity-owned facts
  session.mju                   # session/lease/heartbeat facts
  actors.mju                    # actors crossing several modules
```

In the directory-per-module layout, file placement **does** define ownership: a non-package module declared in `module/<name>/_mod.mju` (the only module in its directory) owns every ownable item in sibling files under that directory, so `owns` lists can be omitted. A `module<interface>` is a provider module and may `provides` multiple `interface` contracts; the provided interfaces and their entry messages can live in the matching interface directory.

For file-style modules (module header plus items in one file, or several modules sharing a package directory), explicit `owns StructName` remains the ownership source of truth.

## Use Cases

Runtime subsystem use cases belong beside the subsystem declaration, for example `moju/model/runtime/subsystem/backup/usecase.mju`. Root/platform use cases can live in `runtime/usecase.mju` only when they are explicitly cross-subsystem.

```mju
usecase ViewDailyAuditReport {
  meta {
    label zh "查看每日审计报告"
    label en "View Daily Audit Report"
    summary zh "监管者查看每日访问审计统计和异常明细。"
  }

  actor DataSec.Regulator
  trigger DataSec.ViewDailyAuditReport
  outcome DataSec.DailyAuditReport
  flow DataSec.DailyAuditReportViewing
  scenario DataSec.DailyAuditReportReview
  verify DataSec.DailyAuditReportViewed
}
```

Use cases are traceability nodes, not containers for architecture. Do not put use cases under `Architecture`; put them in `usecase.mju` at the correct system or subsystem scope.

## Subsystems

Runtime subsystem declarations compose services and may also use static modules directly. They do not own modules, services, or concepts.

```mju
subsystem Backup {
  meta {
    label zh "备份子系统"
    label en "Backup Subsystem"
  }

  uses module Foundation.BackupService, Foundation.RestoreService
  uses service backup-api
  uses module Foundation.BackupInspection
}
```

In `moju-studio`, `runtime/subsystem/<name>/usecase.mju` and `layout.mju` are loaded as the subsystem's `System.<Name>` scope. `service` entries are runtime composition facts; they should make the subsystem visible, but a service-only subsystem must not open an empty static layer diagram unless it also uses modules.

## Static Module Kinds

Use specialized module kinds to make static responsibility explicit:

- `module<entity>` owns domain entities, states, aggregates, and value objects.
- `module<logic>` owns business rules, policies, calculations, and domain logic.
- `module<service>` owns static application/service orchestration. It is not a runnable process.
- `module<interface>`, `module<repository>`, `module<adapter>`, `module<worker>`, `module<pipeline>`, and `module<ui>` keep their protocol, persistence, integration, async, dataflow, and UI meanings.

Studio layer diagrams group by `layer` first and use `module<kind>` only as a secondary visual bucket inside the same layer. UI/interface buckets sit higher, logic sits above entity, and entity/service buckets sit lower. Do not move modules across layers just to group them by kind.

## Runtime Services

Use `service` for runnable entities such as HTTP APIs, web sites, daemons, workers, and BFFs. Do not use `module<service>` to mean a process; `module<service>` is a static logical module and must still be interpreted through its layer.

```mju
service warp-insight-admin {
  kind bin<http>
  exposes Control.AgentControlInterface
  uses module Control.AdminApplication
}

subsystem WarpInsightAdmin {
  uses service warp-insight-admin
}
```

## Layout Regions

Layout views use `region` elements. Plain `region Name` is the default generic region and remains valid for compatibility. Prefer typed regions when the UI intent is known:

```mju
region<page> ViewDailyAuditReportScreen {
  meta {
    label zh "查看每日审计报告"
    label en "View Daily Audit Report"
  }
  orientation grid
  contains DailyAuditReportFilterBar { area: filter, row: 1, col: 1, col_span: 2, width: fill }
  contains DailyAuditFindingList { area: findings, row: 2, col: 1, width: fill, height: fill }
  layout fill_remaining
}

region<section> DailyAuditFindingList {
  orientation vertical
  repeat DailyAuditFindingRow for finding in DailyAuditFindingView
  layout scrollable
}

bind System.AccessAudit.DailyAuditFindingView to DailyAuditFindingRow
```

Supported region kinds are `region`, `page`, `window`, and `section`. Supported orientation values are `vertical`, `horizontal`, and `grid`. `contains` may carry placement attributes such as `area`, `row`, `col`, `row_span`, `col_span`, `width`, `height`, and `align`. Nested region placement can be expressed in `.mju`; studio may also store manual view coordinates in `moju-layout.json`.

## Dataflows

`dataflow` is valid current syntax. It belongs most often in `architecture.mju`.

```mju
dataflow CheckoutDataFlow {
  node<message> SubmitOrder
  node<flow> Checkout
  node<storage> OrderStore
  node<cap> PaymentGateway

  edge<trigger> SubmitOrder -> Checkout {
    data SubmitOrder
  }

  edge<write> Checkout -> OrderStore {
    data Order
  }

  edge<call> Checkout -> PaymentGateway {
    data PaymentIntent
  }
}
```

Node kinds include `actor`, `message`, `event`, `struct`, `storage`, `flow`, `cap`, `module`, `transform`, `gateway`, `external`, and `resource`. Edge modes include `read`, `write`, `transform`, `call`, `return`, `emit`, `trigger`, `publish`, and `consume`.

## Topology And Targets

Topology models logical nodes, resources, network zones, and links:

```mju
node CustomerDataVault

resource PrimaryPostgres {
  kind sqldb<postgres>
}

network AppServiceNetwork {
  ingress internal_only
  trust_level internal
  contains CustomerDataVault
}

bind Backup.CustomerDataVault to CustomerDataVault with topology

link<network> AppServiceNetwork -> AuditNetwork
```

Named service targets belong under `runtime/service/<name>/target.mju`. Platform/root targets belong under `runtime/target.mju`:

```mju
target<bin,http> {
  package custody-api
}
```

## Metadata

Most top-level elements can carry `meta` with `label zh`, `label en`, `summary zh`, and tags. Tags can be written as repeated `tag "x"` lines or as one comma-separated `tags "a","b","c"` line (equivalent):

```mju
actor PlatformOperator {
  meta {
    label zh "平台运营"
    label en "Platform Operator"
    summary zh "平台方负责日常运营的人员。"
    tag "platform"
  }

  can ViewDashboard
}

struct BackupTask {
  meta {
    label zh "备份任务"
    label en "Backup Task"
    summary zh "定义一个文件备份任务的配置。"
    tags "backup", "scheduled"
  }

  unique id: String
  name: String
  source_paths: List<String>
  schedule: String
  status: String
}
```

Use metadata for display labels, summaries, aliases, and tags. Keep model identity stable in English/PascalCase names and put localized text in `meta`. Field types use PascalCase: `String`, `Int`, `DateTime`, `Boolean`, `List<Type>`.

A canonical-naming lexicon lives in the model root `dictionary.mju` and unifies spelling across the model. `term` names the canonical spelling; `aliases` list historical/alternative spellings. Validation scans identifiers and meta display text, emitting non-fatal warnings for any alias usage:

```mju
lexicon {
  term Gateway { aliases "GateWay", "WarpGateway", "WarpGateWay" }
  term Agentd  { aliases "WarpAgentd" }
}
```

Convenience defaults (omit to get the default, keep to override):
- `label en` — omitted English label falls back to the humanized item name (`AgentControlCommand` -> `Agent Control Command`).
- `responsible_for` on modules — defaults to the meta summary (zh, then en).
- `entry calls` — defaults to `<entry>Flow`.
- `entry input` — defaults to the entry name.
- flow-level `trigger` — optional when the first top-level step declares `by Command`; the derived trigger remains available to existing model consumers, while later `by Event` values remain independent step signals and later `by Command` values are linear driver steps reached via explicit `next` / `goto` (never source order).
- flow `step` — optional for placeholder flows that retain a flow-level `trigger`.

## Validation Loop

```bash
moju init /tmp/example
moju verify moju/model
moju-code diff <project>
moju-code align <project> --check
```

Use `moju init` as the current syntax reference when uncertain. Verify small edits frequently.

## Common Pitfalls

| Mistake | Why It Fails | Fix |
|---------|--------------|-----|
| `struct<domain> Name { id: str }` | `struct<domain>` and lowercase types (`str`, `int`) are not recognized by current CLI | Use `struct Name { id: String }` with PascalCase types |
| `message<command> Name { }` | `message<command>` is a planned syntax, not in current CLI | Use `command Name { }` |
| `interface Name { entry X }` | `entry` inside interface is not supported by current CLI | Declare interface without `entry`; route bindings go in comments or studio views |
| `handler on X { call Y }` in flow | Handler-level flow constructs are not in current CLI | Use `actor`/`trigger`/`creates`/`step`/`create` in flows |
| `meta { ... }` inside `struct<domain> { id: str }` | `meta` only works with unannotated `struct` and PascalCase types | Use `struct` without `<domain>` and capitalize types |
| `target<bin,http> name { modules X }` | target with `modules` field is not in current CLI | Use `target<bin,http> { package name }` |
| `list<str>` or `list: List<str>` | Lowercase generic types not supported | Use `List<String>` |
| Force all domain facts into a large `domain.mju` | Navigation and module ownership become hard to review | Split files inside the same domain package |
| Put new models under `static/domain/<domain>` or `runtime/system/<name>` | These are invalid 2.0 draft paths | Use `static/<domain>` and `runtime/subsystem/<name>` |
| Use lowercase field types like `str`, `int` | Current CLI expects PascalCase | Use `String`, `Int`, `DateTime`, `Boolean` |
| Omit `unique` on primary key fields | ID fields need `unique` prefix for identity tracking | Write `unique id: String` instead of `id: String` |

## Do

- Treat source `.mju` files as authoritative; generated summaries are navigation aids.
- Use `struct` (not `struct<domain>`) with PascalCase field types (`String`, `Int`, `DateTime`, `Boolean`, `List<Type>`).
- Use `unique` prefix for primary key fields.
- Use `meta` blocks for Chinese/English display labels, summaries, and tags; prefer the `tags "a","b","c"` list form for multiple tags.
- Prefer one module per directory (`module/<name>/_mod.mju` + `items.mju`) so `owns` can be inferred instead of declared.
- Prefer `output SomeStruct` over one-field `message<response> XReturned { field: SomeStruct }` wrapper messages.
- Use `message<command> Name = BaseStruct { ... }` / `command Name = BaseStruct { ... }` to share repeated request fields (e.g. `requested_by`).
- Run `moju verify` after every model edit — verify incrementally, one concept at a time.
- Use `moju init` as the current syntax reference when uncertain about supported syntax.
- Put module definitions in `static/<domain>/module.mju` — NOT `architecture.mju`.
- Put build targets in `runtime/service/<name>/target.mju` — NOT `binding.mju`.
- Put service declarations in `runtime/service/<name>/service.mju` with `kind bin<http>` + `uses module`.
- Put subsystem declarations in `runtime/subsystem/<name>/subsystem.mju` with `uses service` + `uses module`.
- Put flows in `behavior.mju`, verify cases in `verify.mju`, domain concepts in `domain.mju`.
- Keep root `architecture.mju` only for cross-domain `layer` and `dependency_rule`.
- Use `module Name { layer X responsible_for "..." }` syntax; in the directory-per-module layout omit `owns` (inferred) and omit `responsible_for` (defaults to the meta summary).

## Do Not

- Do not use `struct<domain>`, `message<command>`, `actor<human>` angle-bracket annotations — not yet in CLI parser.
- Do not use lowercase field types (`str`, `int`, `datetime`) — use PascalCase (`String`, `Int`, `DateTime`).
- Do not put `target<bin,http>` in `binding.mju` — put it in `runtime/service/<name>/target.mju`.
- Do not name the static module file `architecture.mju` — use `module.mju`.
- Do not put `layer` inside modules in `module.mju` — use `module Name { layer X }` syntax.
- Do not use `handler on`, `call`, `match`, `ensures` inside flows — use `actor`/`trigger`/`creates`/`step`/`create`.
