---
name: moju-model-understanding
description: How to understand MoJu language and model concepts when drafting models or implementing generated code. Covers domain concepts, generation boundaries, and separation of concerns.
triggers:
  - drafting MoJu models
  - interpreting MoJu model files
  - understanding domain.mju
  - understanding binding.mju
  - understanding profile.mju
---

# MoJu Model Understanding

Use this skill before drafting MoJu models or implementing generated code from a MoJu model.

## Model Concepts

- `domain.mju` contains confirmed design facts: domain concepts, messages, actors, interfaces, flows, storages, dataflows, modules, failures, and verifies.
- `binding.mju` contains confirmed implementation bindings: target, route, status, storage adapter, table/key/index, actor identity, transaction, and capability adapter bindings.
- `moju/profile.mju` contains generation strategy: target matcher, language, runtime, dependencies, and scaffold. It is not a domain fact.
- `struct` is a domain concept, not necessarily a Rust struct or database table.
- `message<command/query/response>` is the protocol-facing input/output contract. Command messages can trigger flows.
- `interface` is the stable external entry contract. Protocol exposure is declared by provider modules and binding details.
- `actor access protocol<...>` constrains which inbound protocols an actor may use.
- `flow` describes business orchestration and state/value changes, not just a list of functions.
- `storage` describes logical persistence shape. `binding.mju` maps it to concrete adapters such as `sqldb<postgres>` or `cache<redis>`.
- `dataflow` describes data movement between messages, flows, structs, storages, capabilities, and modules.
- `module` describes responsibility and provider boundaries, not Rust `mod`.
- `cap` describes an abstract capability. Concrete clients/adapters are implementation details.

## Generation Boundaries

- `target<kind,protocol>` selects a generation target shape. It does not name a concrete service like `CheckoutService`.
- `profile Name for Target<kind,protocol>` maps target shape to implementation strategy.
- Framework choices such as `axum`/`tokio` (Rust) or `Spring Boot`/`JPA` (Java) belong in profile/generation strategy, not in `domain.mju`.
- Route paths, HTTP methods, statuses, storage adapters, actor identity mapping, transactions, and external capability adapter bindings belong in `binding.mju`.
- Generated code should preserve the separation between API/protocol, app orchestration, domain types, and infra adapters. In Java this maps to: `api/` (controllers), `service/` (business logic), `domain/` (records, enums), `repository/` (data access).

## .mju Syntax Reference

When drafting `.mju` files, always start by running `moju init /tmp/example` to see the current canonical syntax. The init output is the authoritative reference.

### domain.mju

```
// Fields: no type annotations — just concept names
struct Item {
  id
  name
  status
}

// State variants: one per line, no commas
state ItemStatus {
  Active
  Archived
  Pending
}

// Command: trigger for flows. Must have at least one field.
// Empty body `{ }` is NOT valid.
command CreateItem {
  name
}

command UpdateItem {
  id
  new_name
}
```

### behavior.mju

```
// trigger MUST reference a command (not a struct or state).
// creates MUST reference a struct.
// Every step MUST contain at least one action (create / update).
// Empty step `step X { }` is NOT valid.
flow CreateItemFlow {
  trigger CreateItem
  creates Item

  step DoCreate {
    create Item {
      id = CreateItem.name
      name = CreateItem.name
    }
  }
}

// Flow without produces: no `creates` clause needed.
// Still, every step must have an action.
flow PublishItem {
  trigger UpdateItem

  step Notify {
    create Item {
      status = UpdateItem.new_name
    }
  }
}
```

### architecture.mju

```
// owns: must only reference items defined in domain.mju
module Catalog {
  layer Domain
  owns Item, ItemStatus

  responsible_for "Item lifecycle management"
}

module CatalogApi {
  layer Interface
  owns CreateItem, UpdateItem

  responsible_for "Item HTTP API"
}

dependency_rule CatalogLayers {
  CatalogApi -> Catalog
}
```

### verify.mju

```
verify CreateOk for flow CreateItemFlow {
  given {
    CreateItem.name = "example"
  }

  when CreateItem

  expect {
    Item.name == "example"
  }
}
```

### Common Pitfalls

| Mistake | Why It Fails | Fix |
|---------|-------------|-----|
| `struct X { name: String }` | No type annotations in .mju | `struct X { name }` |
| `command X { }` | Empty command body | Add at least one field |
| `flow F { trigger SomeStruct }` | trigger must be a command | Define a command for the trigger |
| `step S { }` | Empty step body | Add a `create` or other action |
| `module M { owns MyFlow }` | owns must reference domain.mju items | Only list struct/state/command |
| `dataflow X { ... }` | Not a valid keyword in this version | Use `dependency_rule` instead |

### Validation Loop

```bash
# 1. See canonical syntax
moju init /tmp/example && cat /tmp/example/moju-model/domain/business/domain.mju

# 2. Write a small piece, verify immediately
moju verify moju/draft/domain/<name>/

# 3. Never batch-write without verifying — one syntax error blocks the entire model
```

## Do

- Keep design facts, binding facts, and generation strategy separate.
- Use qualified names when reasoning across domains.
- Treat generated summaries as navigation aids only.
- Preserve response statuses and storage adapter providers declared in `binding.mju`.
- Use MoJu names as the source vocabulary for generated types, modules/classes, traits/interfaces, and handlers (in Rust or Java).
- In Java, `@MoJu` annotations carry the same metadata as Rust `#[moju(...)]` — both are generated from the model and should be preserved.
- Run `moju init` before drafting `.mju` files to see the current canonical syntax.
- Verify frequently with `moju verify` — never batch-write a full model without incremental validation.

## Do Not

- Do not infer unmodeled permissions, routes, status codes, storages, or capabilities as confirmed facts.
- Do not move framework choices such as `axum`, `tokio`, `Spring Boot`, or `JPA` into `domain.mju`.
- Do not treat `MOJU_MODEL.md` as more authoritative than the source model.
- Do not add type annotations to struct fields (e.g., `name: String`).
- Do not use empty bodies for `command`, `step`, or `flow` blocks.
- Do not reference a `struct` as a `flow` trigger — triggers must be `command` types.
- Do not guess `.mju` syntax without checking `moju init` output first.
