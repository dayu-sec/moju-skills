---
name: moju-model-understanding
description: How to understand current MoJu language and model concepts when drafting models, reviewing moju-studio views, or implementing generated code. Covers domains, subsystems, use cases, layout regions, topology, bindings, profiles, validation, and common pitfalls.
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

The current canonical model root is `moju/model/`. Legacy roots such as `moju-model/` and `moju/` may still be read by tools, but new projects should use `moju/model/`.

Typical layout:

```text
moju/model/
  domain/<domain>/
    domain.mju
    behavior.mju
    architecture.mju
    binding.mju
    verify.mju
    layout.mju
  subsystem/<subsystem>/
    architecture.mju
    usecase.mju
    layout.mju
  usecase.mju
  topology.mju
  target.mju
  assembly.mju
  profile.mju
  moju-layout.json
```

`domain/<domain>/...` defines domain facts. `subsystem/<name>/...` defines system-scoped views and subsystem-level use cases. Root-level files define system-wide use cases, topology, deployment targets, assembly, and generation profiles.

## Model Concepts

- `struct<domain>` is a domain concept. Fields may be typed, for example `id: UserId`, `items: List<CartItem>`, or `token: Secret`.
- `struct<config>` describes configuration contracts.
- `struct<ui>` describes UI/view data used by layout and generated prototypes.
- `state` declares a finite state space.
- `variant` declares tagged alternatives and may include payload fields.
- `message<command/query/response>` is the protocol-facing message contract. Command messages commonly trigger flows.
- `event` is a domain fact emitted or consumed by flows, lifecycles, scenarios, and dataflows.
- `actor` defaults to a human actor. `actor<human>` and `actor<system>` are supported.
- `interface` is the stable external entry contract. Protocol exposure is declared by provider modules and `binding.mju`.
- `flow` describes orchestration, required conditions, calls, creates, emits, handlers, match routing, and ensures.
- `cap` describes an abstract capability. Concrete adapters are implementation details and are wired through modules/bindings.
- `storage` describes logical persistence shape. Bindings map it to adapters such as `sqldb<postgres>`, `cache<redis>`, `queue<kafka>`, `object<oss>`, or `search<opensearch>`.
- `dataflow` is a first-class model element for data movement and traceability.
- `module` describes ownership, responsibility, dependencies, interface providers, and capability implementations.
- `subsystem` groups modules with `uses module ...`; a module must not `own` a subsystem.
- `usecase` ties actors, triggers, flows, scenarios, verifies, and outcomes together.
- `region`, `region<page>`, `region<window>`, and `region<section>` describe UI layout regions.
- `node`, `resource`, `network`, `link`, `target`, and `assembly` describe topology and deployment views.
- `profile` describes code generation strategy. It is not a domain fact.

## File Responsibilities

| File | Primary content |
|------|-----------------|
| `domain.mju` | `struct`, `state`, `variant`, `message`, `event`, `actor`, `interface`, `storage`, `config`, `failure` |
| `behavior.mju` | `lifecycle`, `cap`, `flow`, `scenario`, `failure_policy`, `retry_policy` |
| `architecture.mju` | `module`, `dependency_rule`, `dataflow`, `decision`, subsystem declarations |
| `binding.mju` | `target`, interface route/status/outcome binding, storage/config binding |
| `verify.mju` | `verify` cases for flows |
| `usecase.mju` | `usecase` blocks for system or subsystem scopes |
| `layout.mju` | UI `struct<ui>`, `message<...,ui>`, `event`, `region`, and `bind Struct to Region` |
| `topology.mju` | `node`, `resource`, `network`, `link`, deployment `bind` |
| `target.mju` | named executable/site/platform targets |
| `assembly.mju` | concrete runtime node implementations |
| `profile.mju` | generation profile choices |

These are conventions used by the current tools and studio views. The parser accepts many elements in any `.mju` file, but putting them in the expected file keeps navigation and scoped views correct.

## Use Cases

System-level use cases belong at `moju/model/usecase.mju`. Subsystem use cases belong beside the subsystem architecture, for example `moju/model/subsystem/backup/usecase.mju`.

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

Subsystem declarations use modules; they do not own modules or concepts.

```mju
subsystem Backup {
  meta {
    label zh "备份子系统"
    label en "Backup Subsystem"
  }

  uses module Foundation.BackupService, Foundation.RestoreService
  uses module Foundation.BackupInspection
}
```

In `moju-studio`, subsystem architecture/usecase/layout files are loaded as the subsystem's system domain. Subsystems should appear as peers of Architecture in navigation, with concrete subsystem nodes underneath.

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

bind Global.CustomerDataVault to CustomerDataVault with topology
link<network> AppServiceNetwork -> AuditNetwork
```

Named targets can declare modules, while platform targets can declare subsystems:

```mju
target<bin,http> custody-api {
  modules Business.DataCustody, Foundation.AppGateway
}

target<platform> data-sec-platform {
  subsystem system/customer-data-vault
  subsystem system/access-audit
}
```

## Metadata

Most top-level elements can carry `meta`:

```mju
actor<human> PlatformOperator {
  meta {
    label zh "平台运营"
    label en "Platform Operator"
    summary zh "平台方负责日常运营的人员。"
    tag "platform"
  }
}
```

Use metadata for display labels, summaries, aliases, and tags. Keep model identity stable in English/PascalCase names and put localized text in `meta`.

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
| Put subsystem use cases in root Architecture view | Wrong view scope | Use `moju/model/subsystem/<name>/usecase.mju` |
| Put system use cases inside `architecture.mju` | Use cases are independent traceability views | Use root `usecase.mju` |
| `subsystem X { owns M }` | Subsystems only support `uses module` | Declare modules separately, then `uses module M` |
| `module M { owns SomeSubsystem }` | Modules cannot own subsystems | Put subsystem under `subsystem/` and reference modules |
| `actor<service>` | Current actor kinds are `human` and `system` | Use `actor<system>` for non-human actors |
| `target<platform>` with `modules` only | Platform targets are for subsystem composition | Use `subsystem ...` lines |
| Layout only in `moju-layout.json` | Model semantics are lost | Express region hierarchy/placement in `layout.mju`; use layout JSON only for manual view positions |
| Invent routes/status/storage adapters | These are binding facts | Add them only when known, in `binding.mju` |

## Do

- Treat source `.mju` files as authoritative; generated summaries are navigation aids.
- Keep system, subsystem, domain, topology, layout, and generation concerns separate.
- Use qualified names across domains and subsystem scopes.
- Preserve MoJu names when mapping to code.
- Use `meta` for Chinese/English display labels instead of changing identifiers.
- Run `moju verify` and `moju-code diff` after model edits.

## Do Not

- Do not rely on stale restrictions from older MoJu versions: typed fields, `dataflow`, `usecase`, `subsystem`, and `region` are current syntax.
- Do not move framework choices into `domain.mju`.
- Do not treat `MOJU_MODEL.md` as more authoritative than `moju/model`.
- Do not manually edit `moju-layout.json` as the only source of layout semantics.
