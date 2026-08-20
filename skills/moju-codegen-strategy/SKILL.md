---
name: moju-codegen-strategy
description: How to choose between moju-code generate (skeleton/scaffold from a complete model) and AI direct code generation (feature increments), and how to run post-generation initial verification against the model — surfacing differences and asking the engineer for the handling direction before proceeding.
triggers:
  - choosing code generation approach
  - moju-code generate vs AI
  - generate skeleton from model
  - feature increment codegen
  - greenfield scaffold
  - post-generation model comparison
  - verify generated code against model
  - code differs from model
---

# MoJu Codegen Strategy

Use this skill when deciding **how** to produce code from a MoJu model, and when validating the result against the model **before** committing to implementation.

## Decision: `moju-code generate` vs AI

| Situation | Approach | Why |
|-----------|----------|-----|
| **Greenfield** — target has **0 or very little code**, and the model is **large / complete** (full static domains + runtime subsystems/services + bindings + topology) | Use `moju-code generate <project> --out <dir>` to produce the code **skeleton and structure** (crate/package layout, DTO types, route scaffolds, module split, `AI_TASKS.md`) | The model is authoritative and complete enough to scaffold from; generation guarantees the structure matches the model instead of being hand-invented. |
| **Feature increment** — extending an **existing** codebase that already has generated or hand-written code | Use **AI to write the code directly** inside the existing structure | `moju-code generate` would regenerate/overwrite existing work; a targeted feature only needs a small slice that respects the current layout, conventions, and already-implemented behavior. |

### Rules of thumb

- **0 code / 极少代码 + 模型大而完整** → 用 `moju-code generate` 出代码框架与结构。
- **特性增量（在既有代码上加功能）** → 用 AI 直接在现有结构内生成代码，不重新跑 moju-code 生成。
- If the target already has substantial code, prefer AI even if the model is complete — generating would clobber what exists.
- If the model is thin / exploratory and code is nearly empty, prefer evolving the model first (draft → review → promote) before generating.

## Post-Generation Initial Verification

After code is produced (by `moju-code generate` **or** by AI), run an initial verification against the model and surface any difference to the engineer:

1. **Model still parses**: `moju verify` (and `moju readiness` when checking owns / typed fields).
2. **Compare generated/implemented code with the model**:
   - `moju-code diff <project>` — model vs code annotations, at the whole-project level.
   - Check the touched slice: DTO fields match the `message` / `struct`; routes/statuses match `binding.mju`; flows produce the declared outcomes; module owns / annotations are present.
3. **Classify each difference** — which side is authoritative:
   - Model authoritative → fix the code to match the model.
   - Code authoritative → update the model through `moju/draft/` → review → promote.
   - Intentionally not implemented yet, or an acceptable simplification → record as a gap, not a silent pass.
4. **Ask the engineer for the handling direction** — present the differences and concrete options:
   - 修代码对齐模型（model is authoritative）。
   - 修模型对齐代码（code is authoritative；走 draft → review → promote）。
   - 接受并暂缓（记录 gap，继续推进）。
   - 终止 / 更换生成方式。

Do not silently proceed past a model↔code difference. The engineer decides the direction.

## Do

- Check the existing code volume before choosing the approach — the decision is situation-dependent, not a fixed preference.
- Keep the model authoritative: when model and code disagree, prefer fixing code unless the code is clearly right.
- Run `moju verify` before and after generating, and `moju-code diff` to see the real gap.
- Present differences as a short, actionable list with a recommended direction.

## Do Not

- Do not run `moju-code generate` on a codebase that already has meaningful code just to "refresh" it.
- Do not assume AI output is correct without comparing it to the model.
- Do not treat the post-generation comparison as a formality — if there is a difference, surface it and ask.
