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
- Framework choices such as `axum`, `tokio`, and `serde` belong in profile/generation strategy, not in `domain.mju`.
- Route paths, HTTP methods, statuses, storage adapters, actor identity mapping, transactions, and external capability adapter bindings belong in `binding.mju`.
- Generated code should preserve the separation between API/protocol, app orchestration, domain types, and infra adapters.

## Do

- Keep design facts, binding facts, and generation strategy separate.
- Use qualified names when reasoning across domains.
- Treat generated summaries as navigation aids only.
- Preserve response statuses and storage adapter providers declared in `binding.mju`.
- Use MoJu names as the source vocabulary for generated Rust types, modules, traits, and handlers.

## Do Not

- Do not infer unmodeled permissions, routes, status codes, storages, or capabilities as confirmed facts.
- Do not move framework choices such as `axum`, `tokio`, or `serde` into `domain.mju`.
- Do not treat `MOJU_MODEL.md` as more authoritative than the source model.
