---
name: moju-model-diff
description: How to use moju-code diff to analyze model-code differences in 4 categories. Covers command usage, output interpretation, and root cause diagnosis.
triggers:
  - running moju-code diff
  - analyzing model-code differences
  - diagnosing diff output
  - model and code drift
---

# MoJu Model Diff

Use this skill to analyze differences between MoJu model files (`moju/draft/` or `moju/model/`) and code annotations (`#[moju(...)]`).

## Goal

Quickly see what has drifted between model and code, using `moju-code diff` to produce a structured report.

## Command

```bash
mojo-code diff <project-path> [--model <model-path>]
```

Works for both Rust and Java projects. The command auto-detects project type.

The command:
1. Runs `align` to compare model specs against code annotations (finds mismatches + missing annotations)
2. Runs `extract` to get all code-level facts (all types, all `#[moju]` / `@MoJu` annotations)
3. Cross-references the two to produce a 4-category report

## Output Categories

| Category | Meaning | Action |
|----------|---------|--------|
| 注解不匹配 | Model spec differs from code annotation | Review which side is correct, update the other |
| 模型有、代码无注解 | Model has type, code has no `#[moju]` | Add `#[moju]` to code or remove from model |
| 代码已注解、模型无 | Code has `#[moju]`, model has no matching type | Add to model or remove annotation from code |
| 代码无注解、模型也无 | Rust type without `#[moju]` and not in model | Decide if it should be modeled or is an implementation detail |

## Diagnosing Root Causes

When `diff` shows many entries in a category, check:

- **owns missing from architecture.mju**: If a type exists in `domain.mju` but the module's `owns` list doesn't include it, the model parser won't recognize it. Merge all owns onto a single line (the parser discards earlier owns lines).
- **struct+kind not merged**: Model uses `struct X { kind: XKind }` + `state XKind`, but code uses a single `state X` enum directly. The model must be merged to match.
- **naming inconsistency**: Model and code use different names for the same concept. Rename one side.

## Do Not

- Do not run `align --write` blindly after seeing diff output. Understand why each difference exists first.
- Do not add `#[moju]` annotations to purely internal implementation types.
- Do not remove model entries just because code doesn't have them — the model may represent planned work.
