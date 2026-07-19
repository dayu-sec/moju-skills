---
name: http-rust-axum
description: How to implement target<bin,http> / HttpRust skeletons. Covers axum Router construction, binding.mju routes/statuses/outcomes, actor identity, config/storage wiring, handler structure, and protocol separation.
triggers:
  - implementing HttpRust
  - target<bin,http>
  - axum web server
  - http rust profile
---

# HTTP Rust Axum

Use this skill for `profile HttpRust for ... target<bin,http>`.

## Read First

- `AI_TASKS.md`
- `MOJU_MODEL.md`
- `src/api/*`
- `src/app/*`
- `src/domain/messages/*`
- source `binding.mju`, `behavior.mju`, `verify.mju`, and `target.mju`

## Do

- Build an `axum::Router` from routes declared in `binding.mju`.
- Decode command/query messages using JSON extractors when the profile includes `serde`.
- Call the generated app service or flow layer from handlers.
- Convert response messages to the HTTP status codes declared in `binding.mju`.
- Honor `auth`, `actor_identity`, and `outcome ... on ...` declarations from interface bindings.
- Wire config loaders and storage adapters from `binding.mju`; keep provider-specific code outside handlers.
- Keep protocol concerns in `src/api` and orchestration in `src/app`.
- Preserve `#[derive(MoJu)]` and `#[moju(...)]` metadata on generated domain types.

## Do Not

- Do not invent HTTP routes or statuses.
- Do not put storage adapter code in handlers.
- Do not return a single generic success response when MoJu declares multiple response messages.
- Do not ignore actor identity or authorization declarations just because the generated handler compiles.
- Do not collapse capability clients into domain types.

## Acceptance

- Routes match `binding.mju`.
- Handler input/output types use generated message structs.
- Status codes and response variants match declared outcomes.
- Config and storage bindings are represented outside the API layer.
- `cargo check` passes.
