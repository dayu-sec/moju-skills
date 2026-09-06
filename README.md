# Jumo Skills

Jumo skills are long-lived AI working rules for drafting Jumo designs and implementing generated skeletons.

They can be installed into `~/.claude/skills/`, `~/.codex/skills/`, or `~/.agents/skills/` so coding agents can load them as project-agnostic guidance.

## Install

```bash
# Install from GitHub (default: dayu-sec/jumo-skills, main branch)
./install-skill.sh jumo-model-understanding

# Install to specific platform
./install-skill.sh jumo-project-init --codex
./install-skill.sh jumo-project-init --agents

# Install all available skills
./install-skill.sh --all

# Install to custom directory
./install-skill.sh facts-to-jumo-draft --dir ~/my-skills

# Install from a specific branch/tag
JUMO_SKILLS_REF=v1.0 ./install-skill.sh jumo-model-understanding
```

## Current Skills

### Model Reading & Understanding
- `jumo-model-understanding`: how to understand current Jumo 2.0 language concepts, static domain packages, runtime subsystems/services, use cases, layout regions, topology, bindings, and profiles.

### Model-Code Synchronization
- `jumo-model-align`: how to use `jumo-code diff` and `jumo-code align` to keep `jumo/model/` and Rust/Java annotations synchronized.
- `jumo-impl-track`: how to read, write, and validate `jumo/model/impl/usecases.json` — the usecase → code entry path mapping — with `jumo-code impl-check`.

### Reverse Modeling
- `jumo-extract`: how to extract Rust/Java facts with `jumo-code extract`.
- `facts-to-jumo-draft`: how to synthesize a reviewed `jumo/draft` model from `facts.json`.
- `jumo-project-init`: setting up the current Jumo 2.0 `jumo/model/` static/runtime directory structure and tooling pipeline for a project.

### Skeleton Implementation
- `generated-skeleton-implementation`: how to work inside Rust or Java skeletons produced by `jumo-code generate`.
- `http-rust-axum`: how to implement runtime service `target<bin,http>` / `HttpRust` skeletons.
- `http-java-spring-boot`: how to implement runtime service `target<bin,http>` / `HttpJava` Spring Boot skeletons.

### Code Generation Strategy
- `jumo-codegen-strategy`: decide when to use `jumo-code generate` (greenfield — 0 or very little code, large/complete model) vs AI direct code generation (feature increments), and run post-generation initial verification against the model — surfacing differences and asking the engineer for the handling direction.

### Code Quality
- `jumo-code-quality`: how to generate and interpret model-independent `code-quality.json` reports with `jumo-code code-quality` — file scale, function complexity, the `modules[]` directory tree with own vs subtree rollups, `cargo llvm-cov` coverage import, thresholds/exclude, and the `--check` CI gate.

## Rule

Generated files such as `AI_TASKS.md` may reference these skills, but they should not invent new skills.
