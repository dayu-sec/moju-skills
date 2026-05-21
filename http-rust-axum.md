# Skill: HTTP Rust Axum

Use this skill for `profile HttpRust for Target<bin,http>`.

## Read First

- `AI_TASKS.md`
- `MOJU_MODEL.md`
- `src/api/*`
- `src/app/*`
- `src/domain/messages/*`

## Do

- Build an `axum::Router` from routes declared in `binding.mju`.
- Decode command/query messages using JSON extractors when the profile includes `serde`.
- Call the generated app service or flow layer from handlers.
- Convert response messages to the HTTP status codes declared in `binding.mju`.
- Keep protocol concerns in `src/api` and orchestration in `src/app`.

## Do Not

- Do not invent HTTP routes or statuses.
- Do not put storage adapter code in handlers.
- Do not return a single generic success response when MoJu declares multiple response messages.

## Acceptance

- Routes match `binding.mju`.
- Handler input/output types use generated message structs.
- `cargo check` passes.
