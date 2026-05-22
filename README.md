# MoJu Skills

MoJu skills are long-lived AI working rules for drafting MoJu designs and implementing generated skeletons.

They are not generated into each target project. `moju-generate` points AI tasks to this directory so the skills can be reviewed, versioned, and improved over time.

## Current Skills

- `moju-model-reading.md`: how to read source MoJu model files before implementation.
- `moju-model-understanding.md`: how to use `moju-core/docs-zh` to understand MoJu language and model concepts.
- `facts-to-moju-draft.md`: how to synthesize a reviewed `moju-draft` from `moju-extract` facts.
- `moju-code-sync.md`: how to sync reviewed MoJu metadata back into code annotations.
- `generated-skeleton-implementation.md`: how to work inside generated Rust skeletons.
- `http-rust-axum.md`: how to implement `Target<bin,http>` / `HttpRust` skeletons.

## Rule

Generated files such as `AI_TASKS.md` may reference these skills, but they should not invent new skills.
