---
name: http-java-spring-boot
description: How to implement target<bin,http> / HttpJava skeletons with Spring Boot. Covers controller construction, binding.mju routes/statuses/outcomes, actor identity, service wiring, config/storage bindings, and JPA repositories.
triggers:
  - implementing HttpJava
  - target<bin,http> profile java
  - Spring Boot
  - java spring boot web server
  - http java profile
---

# HTTP Java Spring Boot

Use this skill for `profile HttpJava for ... target<bin,http>`.

## Read First

- `AI_TASKS.md`
- `MOJU_MODEL.md`
- `src/main/java/*/api/*` (controllers)
- `src/main/java/*/service/*` (business logic)
- `src/main/java/*/domain/*` (records, enums)
- `src/main/java/*/repository/*` (JPA repositories)
- source `binding.mju`, `behavior.mju`, `verify.mju`, and `target.mju`

## Do

- Build `@RestController` classes from routes declared in `binding.mju`.
- Decode command/query messages using `@RequestBody` and `@RequestParam` annotations.
- Call the generated `@Service` layer from controllers.
- Convert response messages to HTTP status codes declared in `binding.mju` using `ResponseEntity<T>`.
- Honor `auth`, `actor_identity`, and `outcome ... on ...` declarations from interface bindings.
- Keep protocol concerns in `api/` package, orchestration in `service/`, and data access in `repository/`.
- Use `@MoJu` annotations on all generated domain types (records, enums, exceptions).
- Wire storage adapters and config properties from `binding.mju`; keep provider-specific code outside controllers.

## Spring Boot Conventions

- Controller: `@RestController` + `@RequestMapping("/api/...")`
- HTTP methods: `@PostMapping`, `@GetMapping`, `@PutMapping`, `@DeleteMapping`
- Service: `@Service` with constructor injection
- Repository: `interface extends JpaRepository<T, ID>` with `@Repository`
- Configuration: `@ConfigurationProperties(prefix = "...")` on config records
- Main class: `@SpringBootApplication`
- Build: `mvnw spring-boot:run` or `mvnw package`

## @MoJu Annotation in Java

Generated Java types carry structured MoJu metadata via `@MoJu`:

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

The `@MoJu` annotation interface is auto-generated in the target project. It carries: `kind`, `domain`, `role`, `storageKind`, `durability`, `identity`, `tag`.

## Do Not

- Do not invent HTTP routes or statuses.
- Do not put storage adapter code in controllers.
- Do not return a single generic success response when MoJu declares multiple response messages.
- Do not bypass the service layer from controllers.
- Do not remove `@MoJu` annotations from generated types.
- Do not ignore actor identity or authorization declarations just because the generated controller compiles.

## Acceptance

- Routes match `binding.mju`.
- Controller input/output types use generated record classes.
- Status codes and response variants match declared outcomes.
- Config and storage bindings are represented outside the API layer.
- `mvnw compile` passes.
- All domain types carry `@MoJu` annotations matching the source model.
