---
name: moju-align-loop
description: Capability design feedback loop — edit model, diff, align, iterate. Covers model-first and code-first flows, align --write safety, and common loop pitfalls.
triggers:
  - design iteration loop
  - model-first design
  - code-first reverse modeling
  - align --write workflow
  - model-code feedback loop
---

# MoJu Align Loop

Use this skill during capability design iterations — the feedback loop between editing model files and aligning code annotations.

## Goal

Keep model and code in sync during design work so that each iteration starts from a clean baseline.

## The Loop

```
edit model  -->  moju-code diff  -->  review gaps  -->  align --write
    ^                                                       |
    |                                                       |
    +-------------------------------------------------------+
                       (or reverse direction)
```

## Model-First Flow (Designing New Capability)

When designing a new feature starting from the model:

1. **Edit model files** (`moju/draft/` or `moju/model/`)
   - Add new types, messages, flows, actors, etc.
   - Update `architecture.mju` module owns

2. **Run diff** to see what code is missing
   ```bash
   mojo-code diff <project-path>
   ```
   Focus on "模型有、代码无注解" — these are types to implement or annotate.

3. **Implement code** for new types, adding `#[moju]` annotations

4. **Verify sync**
   ```bash
   mojo-code align <project-path> --check
   ```
   Should report no changes needed. If not, fix annotations.

## Code-First Flow (Reverse-Modeling)

When code changes first and the model needs to catch up:

1. **Edit code** (add/remove types, change fields)

2. **Run diff** to see model gaps
   ```bash
   mojo-code diff <project-path>
   ```
   Focus on "代码已注解、模型无" — these need model entries.

3. **Update model** to match code:
   - Add missing types to `domain.mju`
   - Update `architecture.mju` owns
   - Apply struct+kind merge if needed

4. **Run diff again** — should converge to zero

## Align --Write Safety

`align --write` modifies source code in place (Rust or Java). Before running:

- Commit or stash current changes
- Review the diff output first to understand what will change
- Run `--check` first to preview without writing

```bash
# Safe preview
mojo-code align <project-path> --check

# Apply changes
mojo-code align <project-path> --write
```

Works for both Rust and Java projects. For Java, `align --write` updates `@MoJu` annotations on generated classes.

## Common Loop Pitfalls

| Symptom | Likely Cause | Fix |
|---------|-------------|-----|
| "模型有、代码无" shows types that exist in code | Type name mismatch between model and code | Rename one side to match |
| align adds `module = ""` to annotations | Empty module field in model or code | Check model's `module` attribution |
| Same diff entries persist after sync | Multi-line owns in architecture.mju | Merge owns onto single line |
| align removes annotations | Model no longer owns the type | Add type to module's owns list |

## Do

- Run `diff` at the start and end of every design session.
- Commit after reaching zero differences as a checkpoint.
- Use `--check` before `--write` when modifying code annotations.

## Do Not

- Do not run `align --write` on uncommitted code.
- Do not ignore persistent diff entries — each one indicates a real inconsistency.
- Do not edit both model and code simultaneously without running diff in between.
