---
name: http-rust-axum
description: How to implement Jumo 2.0 runtime service target<bin,http> / HttpRust skeletons. Covers axum Router construction, binding.mju routes/statuses/outcomes, actor identity, config/storage wiring, handler structure, and protocol separation.
triggers:
  - implementing HttpRust
  - target<bin,http>
  - axum web server
  - http rust profile
---

# HTTP Rust Axum

Use this skill for `profile HttpRust for ... target<bin,http>` or a generated `runtime/service/<service>` with `kind bin<http>`.

## Read First

- `AI_TASKS.md`
- `JUMO_MODEL.md`
- `src/api/*`
- `src/app/*`
- `src/domain/messages/*`
- source `static/<domain>/binding.mju`, `static/<domain>/behavior.mju`, `static/<domain>/verify.mju`
- source `runtime/service/<service>/service.mju` and `runtime/service/<service>/target.mju`
- source `runtime/topology.mju` if deployment resources or networks affect configuration

## Do

- Build an `axum::Router` from routes declared in `binding.mju`.
- Use `runtime/service/<service>/service.mju` to identify the runnable service, exposed interfaces, and static modules used by the service.
- Decode command/query messages using JSON extractors when the profile includes `serde`.
- Call the generated app service or flow layer from handlers.
- Convert response messages to the HTTP status codes declared in `binding.mju`.
- Honor `auth`, `actor_identity`, and `outcome ... on ...` declarations from interface bindings.
- Wire config loaders and storage adapters from `binding.mju`; keep provider-specific code outside handlers.
- Keep protocol concerns in `src/api` and orchestration in `src/app`.
- Keep domain entities/states in the code generated from `module<entity>` and business rules/policies in code generated from `module<logic>`.
- Do not treat `module<service>` as the executable boundary; runtime `service` is the process/site/daemon boundary.
- Preserve `#[derive(Jumo)]` and `#[jumo(...)]` metadata on generated domain types.

## Do Not

- Do not invent HTTP routes or statuses.
- Do not put storage adapter code in handlers.
- Do not return a single generic success response when Jumo declares multiple response messages.
- Do not ignore actor identity or authorization declarations just because the generated handler compiles.
- Do not collapse capability clients into domain types.

## Acceptance

- Routes match `binding.mju`.
- Handler input/output types use generated message structs.
- Status codes and response variants match declared outcomes.
- Config and storage bindings are represented outside the API layer.
- `cargo check` passes.
