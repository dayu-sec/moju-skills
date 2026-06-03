---
name: moju-align-loop
description: How to align code annotations to the MoJu model. Covers the one-way alignment loop, diff diagnosis, and common pitfalls.
triggers:
  - model-code alignment
  - moju-code diff
  - moju-code align
  - code annotations out of sync
---

# MoJu Align Loop

Use this skill to align code annotations with the MoJu model. The model is the single source of truth.

## Direction

```
model (authoritative)  ──align──>  code annotations (mirror)
```

Never the reverse. If code has changed in a way that should be reflected in the model, update the model first (via `moju/draft/` → `moju verify` → promote to `moju/model/`), then align code to it.

## The Loop

```
moju-code diff  →  review gaps  →  fix model (if needed)  →  moju verify  →  moju-code align --write  →  cargo check
       ↑                                                                                                          |
       +----------------------------------------------------------------------------------------------------------+
```

| Step | Command | What it does |
|------|---------|-------------|
| 1. diff | `moju-code diff <project>` | Show what's out of sync between model and code annotations |
| 2. review | read the diff output | Decide: is the model wrong, or is the code missing annotations? |
| 3. fix model | edit `moju/draft/` | If the model needs updating: add/remove types, fix fields, update module owns |
| 4. verify | `moju verify` | Ensure `.mju` files parse, flow references resolve, owns are complete |
| 5. align | `moju-code align <project> --write` | Push model metadata (`kind`, `domain`, `module`) into code as `#[moju]` annotations |
| 6. check | `cargo check` / `mvnw compile` | Ensure annotated code compiles |

If step 2 determines the model is already correct and only annotations are missing, skip steps 3-4 and go directly to align.

## Diff Output Categories

| Category | Meaning | Action |
|----------|---------|--------|
| 注解不匹配 | Model says one thing, code annotation says another | Model is correct — align to fix the annotation |
| 模型有、代码无 | Type exists in model but has no `#[moju]` in code | Run `align --write` to add annotations |
| 代码已注解、模型无 | Code has `#[moju]` but model has no matching type | If the type should be modeled, add it to draft first; otherwise remove the code annotation |
| 代码无注解、模型也无 | Type in code without annotation, not in model | Decide if it should be modeled; if yes, add to draft first |

## Common Pitfalls

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "模型有、代码无" for types that exist | Type name mismatch between model and code | Rename one side to match (model is authoritative) |
| align adds `module = ""` | Empty module field | Check model's module attribution in architecture.mju |
| Same diff entries persist after align | Multi-line owns in architecture.mju | Merge owns onto single line |
| align removes annotations | Model no longer owns the type | Add type to module's owns list |
| `#[serde]` before `#[derive]` error (edition 2024) | Derive helper attributes out of order | `#[derive]` must come before `#[serde]` |

## Do

- Model is always the source of truth. Change it first, then align code.
- Run `diff` before and after every alignment session.
- Use `--check` before `--write` to preview changes.

## Do Not

- Do not align code → model. The model is authoritative.
- Do not run `align --write` on uncommitted code.
- Do not edit both model and code simultaneously — always pick a direction for each change.
