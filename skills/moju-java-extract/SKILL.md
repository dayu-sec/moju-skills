---
name: moju-java-extract
description: How to extract MoJu facts from Java projects with @MoJu annotations. Covers multi-module Maven/Gradle support, the JavaExtractor pipeline, Java type mapping, field filtering, and troubleshooting extraction failures.
triggers:
  - extracting moju facts from Java
  - moju-code extract for Java
  - Java facts.json
  - @MoJu annotation scanning
  - multi-module Maven extraction
---

# MoJu Java Extract

Use this skill when extracting MoJu model facts from a Java project that has `@MoJu` annotations on its types. Covers the `moju-code extract` command for Java, the JavaExtractor pipeline, and common troubleshooting.

## Goal

Run `moju-code extract <project>` on a Java project and get enriched `facts.json` with annotation attributes, fields, enum values, and type hierarchies, ready for AI semantic merge into `.mju` model files.

## Command

```bash
moju-code extract <project-path>
# Optional: --out <output-path> (default: <project-path>/facts.json)
```

Auto-detects Java projects by checking for `pom.xml` (Maven) or `build.gradle` (Gradle) at the project root. Falls back to Rust extraction if neither is found.

## Prerequisites

- JDK 17+ (`JAVA_HOME` must point to a valid JDK; macOS may need explicit `JAVA_HOME=/opt/homebrew/opt/openjdk`)
- Maven 3.2+ (for building the Java extractor JAR if not already built)
- The `moju-code/java-extract/` directory must exist in the workspace

## Multi-Module Support

The extractor automatically discovers `src/main/java` roots in:

1. The project root: `<project>/src/main/java/`
2. Immediate subdirectories: `<project>/*/src/main/java/`

This covers standard Maven/Gradle multi-module layouts:
```
nacos/
  api/src/main/java/          ✓ scanned
  config/src/main/java/       ✓ scanned
  naming/src/main/java/       ✓ scanned
  core/src/main/java/         ✓ scanned
  src/main/java/              ✓ scanned (if exists)
```

If your project uses a non-standard layout, update `JavaExtractor.java:extract()` to add the path pattern.

## What Gets Extracted

For each Java type with `@MoJu` annotation, the extractor produces:

```json
{
  "type_name": "ConfigInfo",
  "file": "config/src/main/java/.../ConfigInfo.java",
  "mod_path": "com.alibaba.nacos.config.server.model.ConfigInfo",
  "attrs": {
    "kind": "struct",
    "domain": "Config",
    "module": "Config.ConfigDomain"
  },
  "fields": [
    {"name": "dataId", "java_type": "String", "moju_type": "String"},
    {"name": "lastModifiedTs", "java_type": "long", "moju_type": "Int"}
  ],
  "enum_values": ["INSERT", "UPDATE", "DELETE"],
  "super_type": "ConfigInfoBase"
}
```

### Parsed Fields

- **`attrs`**: All key=value pairs from `@MoJu(k1="v1", k2="v2")`. Always includes `kind` and `domain`. May include `module`, `role`, `identity`, `tag`, `storageKind`, `durability`.
- **`fields`**: Non-static, non-transient instance fields with Java type and mapped MoJu type.
- **`enum_values`**: Enum constant names (only for `kind = "state"` enum types).
- **`super_type`**: Simple class name of extended class or implemented interface. `null` if none.

## Java → MoJu Type Mapping

| Java Type | MoJu Type | Notes |
|-----------|-----------|-------|
| `String` | `String` | |
| `int`, `Integer`, `long`, `Long`, `short`, `Short`, `byte`, `Byte` | `Int` | All integer types collapse to `Int` |
| `boolean`, `Boolean` | `Bool` | |
| `float`, `Float`, `double`, `Double` | `Float` | |
| `byte[]`, `Byte[]` | `Bytes` | |
| `List<T>`, `Collection<T>` | `List<T>` | Generic types preserved |
| `Set<T>` | `List<T>` | MoJu has no Set type |
| `Map<K,V>` | `Map<K,V>` | |
| `Optional<T>` | `T?` | |
| Other objects | PascalCase simple name | Package prefix stripped |

## Infrastructure Field Filtering

The extractor automatically skips:
- `serialVersionUID` — JVM serialization
- `log`, `logger`, `LOG`, `LOGGER` — logging
- Fields with type ending in `Logger` — logging
- Fields starting with `_` — JVM synthetic
- `DEFAULT_GROUP` and similar — Nacos-specific constants

The extractor does NOT filter (defer to AI semantic merge):
- `id` fields — could be domain identity or DB surrogate
- `gmtCreate`, `gmtModified` — could be domain timestamps or ORM infrastructure
- `value` in enums — could be domain or serialization helper

## Language Level

The extractor uses `JAVA_17` language level by default. If your project uses newer features, update `JavaExtractor.java`:

```java
StaticJavaParser.getParserConfiguration().setLanguageLevel(
    com.github.javaparser.ParserConfiguration.LanguageLevel.JAVA_17);
```

## Troubleshooting

### "Unable to locate a Java Runtime" on macOS

macOS stub `/usr/bin/java` doesn't work. Set explicit `JAVA_HOME`:

```bash
JAVA_HOME=/opt/homebrew/opt/openjdk PATH="/opt/homebrew/opt/openjdk/bin:$PATH" moju-code extract <project>
```

### "Use of patterns with instanceof is not supported"

Your source uses Java 14+ features. Upgrade the language level in `JavaExtractor.java` to `JAVA_17` or higher.

### "java-extract directory not found"

The `moju-code/java-extract/` directory must exist in the workspace root (sibling to `moju-code/`, not inside it). The workspace root is found by searching upward from the project path for a directory containing `moju-derive/` or `moju-code/`.

### JAR build fails

```bash
cd moju-code/java-extract
JAVA_HOME=/path/to/jdk mvn package -DskipTests
```

### Empty facts output (0 annotations)

Check that:
1. Java source roots are in standard `src/main/java/` layout
2. Types have `@MoJu` annotations with correct import
3. The annotation import is `import com.alibaba.nacos.config.server.annotation.MoJu;` (or whatever package the `MoJu.java` file declares)

## After Extraction

The `facts.json` output is input to the AI semantic merge process (see `facts-to-moju-draft` skill). The AI handles:
- Cleaning infrastructure fields not caught by rules
- Merging code fields with existing model fields
- Resolving naming conflicts
- Adding code-only types to the model

## Do Not

- Do not modify `JavaExtractor.java` to add domain-specific filtering — that's AI's job
- Do not manually edit `facts.json` — it's generated and will be overwritten
- Do not expect `behavior.mju` or `architecture.mju` to be auto-generated — those need AI + human review
