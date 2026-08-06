# MoJu Skills

MoJu skills are long-lived AI working rules for drafting MoJu designs and implementing generated skeletons.

They can be installed into `~/.claude/skills/` or `~/.codex/skills/` so coding agents can load them as project-agnostic guidance.

## Install

```bash
# Install from GitHub (default: dayu-sec/moju-skills, main branch)
./install-skill.sh moju-model-understanding

# Install to specific platform
./install-skill.sh moju-project-init --codex

# Install all available skills
./install-skill.sh --all

# Install to custom directory
./install-skill.sh facts-to-moju-draft --dir ~/my-skills

# Install from a specific branch/tag
MOJU_SKILLS_REF=v1.0 ./install-skill.sh moju-model-understanding
```

## Current Skills

### Model Reading & Understanding
- `moju-model-understanding`: how to understand current MoJu 2.0 language concepts, static domain packages, runtime subsystems/services, use cases, layout regions, topology, bindings, and profiles.

### Model-Code Synchronization
- `moju-model-align`: how to use `moju-code diff` and `moju-code align` to keep `moju/model/` and Rust/Java annotations synchronized.

### Reverse Modeling
- `moju-extract`: how to extract Rust/Java facts with `moju-code extract`.
- `facts-to-moju-draft`: how to synthesize a reviewed `moju/draft` model from `facts.json`.
- `moju-project-init`: setting up the current MoJu 2.0 `moju/model/` static/runtime directory structure and tooling pipeline for a project.

### Skeleton Implementation
- `generated-skeleton-implementation`: how to work inside Rust or Java skeletons produced by `moju-code generate`.
- `http-rust-axum`: how to implement runtime service `target<bin,http>` / `HttpRust` skeletons.
- `http-java-spring-boot`: how to implement runtime service `target<bin,http>` / `HttpJava` Spring Boot skeletons.

## Rule

Generated files such as `AI_TASKS.md` may reference these skills, but they should not invent new skills.
