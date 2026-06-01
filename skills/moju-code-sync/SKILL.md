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

## Patch Discipline

Generated sync patches should be reviewable and reversible. Avoid broad formatting churn. Do not add MoJu annotations to public API types unless the corresponding model item has been reviewed.
