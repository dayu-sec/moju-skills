---
name: moju-code-sync
description: How to sync reviewed MoJu metadata back into code annotations. Covers what to sync, what not to sync, drift handling, and patch discipline.
triggers:
  - syncing moju metadata to code
  - adding moju annotations
  - moju derive macros
  - code annotation drift
---

# MoJu Code Sync

Use this skill after a `moju-draft` model has been reviewed, validated, and promoted into `moju/`.

## Goal

Sync stable MoJu metadata back into source code so future extraction has stronger anchors and drift can be detected.

## Source Of Truth

- `moju/` is authoritative.
- Code annotations are mirrors and anchors.
- Generated code, `MOJU_MODEL.md`, and old `moju-draft` files are not authoritative.

## What To Sync

Sync only local, stable, mechanically checkable metadata:

- item kind: `struct`, `state`, `message`, `failure`, `storage`, `actor`
- domain
- message role: `command`, `query`, `response`
- unique fields
- failure identity, tag, and short description
- storage kind and durability when represented by a concrete code type
- actor parent when represented by a concrete code type

For Rust, use `moju-derive` style annotations:

```rust
#[derive(MoJu)]
#[moju(kind = "message", role = "command", domain = "Business")]
pub struct SubmitOrder {
    #[moju(unique)]
    pub id: String,
}
```

For Java, use `@MoJu` annotations:

```java
@MoJu(kind = "message", role = "command", domain = "Business")
public record SubmitOrder(
    String id,
    String customerId
) {}
```

```java
@MoJu(kind = "storage", storageKind = "postgres", domain = "Business")
public record Order(
    @Id Long id,
    String status
) {}
```

The Java `@MoJu` annotation carries the same metadata fields: `kind`, `domain`, `role`, `storageKind`, `durability`, `identity`, `tag`.

## What Not To Sync By Default

Do not push these into ordinary type annotations unless a dedicated code construct exists:

- flow step ordering
- dataflow graph edges
- interface routes and response status codes
- storage adapter providers such as `postgres`, `redis`, `kafka`
- config file paths and secret sources
- design decisions and rejected options
- generation profile choices such as `axum`, `tokio`, `Spring Boot`, or `JPA`

These remain in `moju/`, `binding.mju`, or `profile.mju`.

## Drift Handling

When code annotations differ from `moju/`:

- report the difference first
- do not silently overwrite code
- prefer small patches scoped to metadata attributes
- if code behavior contradicts the reviewed model, create a review item rather than forcing sync

## Rust: Setting Up `moju-derive`

`moju-code align --write` adds `#[derive(::moju_derive::MoJu)]` and `#[moju(...)]` annotations to Rust source. The project must have `moju-derive` as a dependency.

### Git Dependency (Recommended)

In workspace `Cargo.toml`:

```toml
[workspace.dependencies]
moju-derive = { git = "https://github.com/dayu-sec/moju-derive.git", branch = "main" }
```

In each crate's `Cargo.toml`:

```toml
[dependencies]
moju-derive = { workspace = true }
```

### Why Git Instead of Path

`moju-derive` has its own `[workspace]` (it contains a proc-macro sub-crate). Cargo cannot resolve a path dependency to a separate workspace. Use git dependency to avoid this conflict.

## Rust Edition 2024: Derive Helper Attribute Ordering

Rust 2024 edition requires derive helper attributes (`#[serde(...)]`, `#[moju(...)]`) to appear **after** the `#[derive(...)]` line that introduces them. `moju-code align` may place `#[serde]` before `#[derive]`, causing:

```
error: derive helper attribute is used before it is introduced
```

Fix by swapping attribute order. A perl one-liner for bulk fix:

```bash
find crates -name "*.rs" -exec grep -l "serde" {} \; | while read f; do
  perl -i -0777 -pe 's/#\[serde\(([^)]*)\)\]\n(#\[derive\([^)]*::moju_derive::MoJu[^)]*\)\])/\2\n#[serde(\1)]/g' "$f"
done
```

This swaps `#[serde(...)]\n#[derive(...MoJu...)]` to `#[derive(...MoJu...)]\n#[serde(...)]`.

## End-to-End Reverse Modeling Pipeline

For a Rust project without existing `#[moju]` annotations:

```
1. Manual facts curation
   Read Rust source → build facts.json (type_defs with kind/fields/variants)
   ↓
2. AI semantic merge (facts-to-moju-draft skill)
   facts.json → draft/*.mju (domain + architecture + behavior + verify)
   ↓
3. Verify
   moju verify moju/draft
   ↓
4. Review
   Write review.md, mark high-confidence vs inferred changes
   ↓
5. Promote to model
   cp -r moju/draft/domain moju/model/domain
   ↓
6. Add moju-derive dependency (see above)
   ↓
7. Write annotations
   moju-code align <crate> --write --model moju/model
   ↓
8. Fix edition 2024 ordering (see above)
   ↓
9. Verify
   cargo check
   moju-code diff <crate> --model moju/model
```

After the first pass, `moju-code extract` will work automatically because annotations are now present.

## Patch Discipline

Generated sync patches should be reviewable and reversible. Avoid broad formatting churn. Do not add MoJu annotations to public API types unless the corresponding model item has been reviewed.
