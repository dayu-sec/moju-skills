---
name: jumo-extract
description: How to extract Jumo facts from Rust and Java projects. Covers current jumo-code extract usage, Rust/Java annotation scanning, type mapping, field filtering, facts.json, and reverse-modeling handoff to jumo/draft.
triggers:
  - extracting jumo facts
  - jumo-code extract
  - facts.json
  - reverse modeling from code
  - annotation scanning
---

# Jumo Extract

Use this skill when extracting Jumo model facts from Rust or Java projects. `jumo-code extract` auto-detects the project type and produces `facts.json` for AI semantic merge into `jumo/draft/`.

## Command

```bash
jumo-code extract <project-path>
# Optional: --out <output-path> (default: <project-path>/facts.json)
jumo-code --version
```

## Rust Extraction

Rust extraction uses `syn` to parse source files. It works on any Rust project; `#[jumo]` annotations are not required for basic facts.

### What Gets Extracted

For every struct and enum:
- **`type_defs`**: name, file, mod_path
- **`jumo_annotations`**: extracted or inferred entries with `kind` (struct/state/etc.), field names and Jumo types, enum variants
- **`struct_methods`**: all `pub`/`pub(crate)` methods with `&mut self` — AI selects up to 5 per struct to become `op` declarations
- **`struct_relations`**: field type references and op method param references between structs

### Rust → Jumo Type Mapping

| Rust Type | Jumo Type |
|-----------|-----------|
| `String`, `str` | `String` |
| `i8`, `i16`, `i32`, `i64`, `isize`, `u8`, `u16`, `u32`, `u64`, `usize` | `Int` |
| `f32`, `f64` | `Float` |
| `bool` | `Bool` |
| `Vec<T>`, `HashSet<T>`, `BTreeSet<T>` | `List<T>` |
| `HashMap<K,V>`, `BTreeMap<K,V>` | `Map<K,V>` |
| `Option<T>` | `T?` |
| Other PascalCase types | Same name |

Infrastructure fields (`logger`, `log`, `_*` prefixed) are automatically filtered. The AI merge step should still review generated fields before writing `jumo/draft`.

## Java Extraction

Java extraction uses JavaParser. Requires JDK 17+ and Maven.

### Prerequisites

- JDK 17+ (`JAVA_HOME` must point to a valid JDK; macOS may need explicit `JAVA_HOME=/opt/homebrew/opt/openjdk`)
- Maven 3.2+ (for building the Java extractor JAR)
- The `jumo-code/java-extract/` directory must exist in the workspace

### Multi-Module Support

Automatically discovers `src/main/java` roots in the project root and immediate subdirectories.

### What Gets Extracted

For each Java type:
- **`attrs`**: All key=value pairs from `@Jumo(k1="v1", k2="v2")`. Without `@Jumo`, fields and enum values are still extracted.
- **`fields`**: Non-static, non-transient instance fields with Java type and mapped Jumo type.
- **`enum_values`**: Enum constant names.
- **`super_type`**: Simple class name of extended class or implemented interface.
- **`struct_methods`**: All public instance methods with params (excluding getters/setters) — AI selects up to 5 per class.
- **`struct_relations`**: Field type references and method param references between classes.

### Java → Jumo Type Mapping

| Java Type | Jumo Type |
|-----------|-----------|
| `String` | `String` |
| `int`, `Integer`, `long`, `Long`, `short`, `Short`, `byte`, `Byte` | `Int` |
| `boolean`, `Boolean` | `Bool` |
| `float`, `Float`, `double`, `Double` | `Float` |
| `byte[]`, `Byte[]` | `Bytes` |
| `List<T>`, `Collection<T>` | `List<T>` |
| `Set<T>` | `List<T>` |
| `Map<K,V>` | `Map<K,V>` |
| `Optional<T>` | `T?` |
| Other objects | PascalCase simple name |

Infrastructure fields (`serialVersionUID`, log/logger fields, fields with type ending in `Logger`, `_*` prefixed) are automatically filtered.

## Annotation Metadata

Rust `#[jumo(...)]` and Java `@Jumo(...)` metadata can provide:

- `kind`: `struct`, `state`, `message`, `failure`, `storage`, `actor`, `config`
- `domain`
- `role`: `command`, `query`, `response` for messages
- `storageKind`, `durability`
- `identity`, `tag`, `description`
- `unique` field markers

Do not expect extraction to fully infer flows, use cases, topology, or UI layout. It provides evidence for the AI semantic merge.

## Troubleshooting

### "Unable to locate a Java Runtime" on macOS

```bash
JAVA_HOME=/opt/homebrew/opt/openjdk PATH="/opt/homebrew/opt/openjdk/bin:$PATH" jumo-code extract <project>
```

### Empty facts output

Check that source roots are in standard layout and (for Java) the JAR built successfully.

## After Extraction

The `facts.json` output is input to the AI semantic merge process (see `facts-to-jumo-draft` skill). The AI handles field cleaning, merge decisions, struct op selection, domain clustering, scenario inference, usecase/subsystem/layout/topology inference, and behavior/architecture generation.

## Do Not

- Do not manually edit `facts.json`; it is generated and will be overwritten.
- Do not treat extracted annotations as the authoritative model. Promote reviewed `.mju` files into `jumo/model/`.
- Do not expect flows, subsystem use cases, layout regions, or topology to be fully deterministic; those need AI plus human review.
