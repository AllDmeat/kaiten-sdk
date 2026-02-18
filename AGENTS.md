# KaitenSDK — Development Guidelines

## Language Policy

**English only.** All content in this repository MUST be in English:
- Code, comments, documentation
- Commit messages, PR titles and descriptions
- Issue titles and descriptions
- Specs, READMEs, and any other markdown files
- YAML descriptions in OpenAPI spec

No exceptions. Existing Russian content will be translated (see #163).

## Spec-First Development

Specifications in `specs/` are the single source of truth for what
is being built and how.

### Workflow

1. **Spec first** — before implementing new functionality,
   update or create a specification in `specs/`.
2. **Then implement** — code is written strictly according to the spec.
3. **Every change** to functionality MUST be accompanied by
   an update to the corresponding spec.

### Spec Structure

- `specs/001-kaiten-sdk-core/spec.md` — SDK: OpenAPI generation,
  typed errors, convenience wrappers
- `specs/002-kaiten-cli/spec.md` — CLI: thin wrapper over SDK,
  config file, subcommands

### Constitution

Architectural principles and constraints are documented in
`.specify/memory/constitution.md`. The constitution takes priority
over all other project practices.

### Rules for Agents

- DO NOT implement functionality not described in the spec.
- If a discrepancy between code and spec is found,
  clarify with the user which is correct.
- When adding new functionality — update the spec first,
  get confirmation, then implement.
- Always update READMEs when public APIs change. Any PR that
  modifies public API surface must include corresponding README
  updates. Specifically: the "API Reference" tables and "CLI Commands"
  section in README.md. No exceptions.

## Kaiten API Documentation

Detailed guide for parsing Kaiten API documentation: [docs/kaiten-docs-parsing.md](docs/kaiten-docs-parsing.md)

### Mandatory Rule

**Before any change to the OpenAPI spec** (`openapi/kaiten.yaml`) — you must verify against the Kaiten API documentation (https://developers.kaiten.ru) how the endpoint actually works:
- Which query/path parameters it accepts
- Which response fields are required (`integer`, `string`) and which are nullable (`null | string`)
- Whether pagination is supported (`offset`/`limit`)

Do not modify the spec based on guesses or empirical data. Only based on documentation.

## Code Formatting

This project uses [swift-format](https://github.com/swiftlang/swift-format) (bundled with the Swift toolchain) with default configuration.

**Before every commit**, run:

```bash
swift format format --in-place --recursive Sources/ Tests/
```

CI runs `swift format lint --strict --recursive Sources/ Tests/` on every PR. Unformatted code will fail the lint check.
