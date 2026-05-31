# MoJu Skills

MoJu skills are long-lived AI working rules for drafting MoJu designs and implementing generated skeletons.

They are installed into `~/.claude/skills/` so Claude Code can load them as project-agnostic guidance.

## Install

```bash
# Install from GitHub (default: dayu-sec/moju-skills, main branch)
./install-skill.sh moju-model-diff

# Install to specific platform
./install-skill.sh moju-model-sync --claude

# Install all available skills
./install-skill.sh moju-project-init --all

# Install to custom directory
./install-skill.sh facts-to-moju-draft --dir ~/my-skills

# Install from a specific branch/tag
MOJU_SKILLS_REF=v1.0 ./install-skill.sh moju-model-diff
```

## Current Skills

### Model Reading & Understanding
- `moju-model-reading`: how to read source MoJu model files before implementation.
- `moju-model-understanding`: how to use `moju-core/docs-zh` to understand MoJu language and model concepts.

### Model-Code Synchronization
- `moju-model-diff`: how to use `moju-code diff` to analyze model-code differences in 4 categories.
- `moju-model-sync`: rules for syncing model and code (struct+kind merge, owns maintenance, rename propagation).
- `moju-align-loop`: capability design feedback loop — edit model, diff, align, iterate.

### Reverse Modeling
- `facts-to-moju-draft`: how to synthesize a reviewed `moju-draft` from `moju-code extract` facts.
- `moju-code-sync`: how to sync reviewed MoJu metadata back into code annotations.
- `moju-project-init`: setting up MoJu modeling directory structure and tooling pipeline for a project.

### Skeleton Implementation
- `generated-skeleton-implementation`: how to work inside generated Rust skeletons.
- `http-rust-axum`: how to implement `Target<bin,http>` / `HttpRust` skeletons.

## Rule

Generated files such as `AI_TASKS.md` may reference these skills, but they should not invent new skills.
