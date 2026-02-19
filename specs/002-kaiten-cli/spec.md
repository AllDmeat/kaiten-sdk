# Feature Specification: Kaiten CLI

**Feature Branch**: `002-kaiten-cli`
**Created**: 2026-02-16
**Status**: Draft
**Input**: User description: "An executable target — a thin wrapper over the SDK with no logic, forwards commands to the SDK"

## User Scenarios & Testing *(mandatory)*

### User Story 1 - CLI Access to Kaiten (Priority: P1)

A DevOps engineer or developer uses the CLI to access Kaiten data
without writing code. The CLI is a thin wrapper over the SDK — it
parses CLI arguments and the config file, assembles a unified set
of parameters, and passes them to the SDK. No business logic.

**Why this priority**: The sole purpose of this feature is to
provide CLI access to the SDK.

**Independent Test**: Run the binary with `--url`, `--token`
and a subcommand (e.g. `list-spaces`). Structured output in
stdout confirms it works.

**Acceptance Scenarios**:

1. **Given** valid `--url` and `--token` flags, **When** the
   user runs a subcommand (e.g. `list-spaces`), **Then** the
   CLI outputs structured data to stdout.
2. **Given** a valid config file exists at
   `~/.config/kaiten/config.json`, **When** the user runs
   a subcommand without flags, **Then** the CLI reads parameters
   from the config file.
3. **Given** both flags and a config file with different values
   are present, **When** the user specifies `--url` or `--token`,
   **Then** flags take priority over the config file.
4. **Given** neither flags nor the config file provide a required
   parameter, **When** the user runs a subcommand, **Then** the
   CLI exits with a clear error message indicating which parameter
   is missing and where it can be set (flag or config file).
5. **Given** the SDK returns an error, **When** the user runs a
   subcommand, **Then** the CLI outputs a human-readable error
   message to stderr and exits with a non-zero exit code.

---

### Edge Cases

- What if the CLI is run without a subcommand? The CLI MUST print
  help and exit with a non-zero code.
- What if the config file exists but contains invalid JSON? The CLI
  MUST output an error describing the configuration problem.
- What if the config file does not exist and no flags are passed?
  The CLI MUST output an error with instructions: pass flags or
  create `~/.config/kaiten/config.json`.

## Requirements *(mandatory)*

### Functional Requirements

- **FR-001**: The CLI MUST be a thin wrapper over the SDK with no
  business logic of its own. The CLI parses arguments and the
  config file, assembles a unified Input, and passes it to the SDK.
- **FR-002**: The CLI MUST provide a subcommand for each SDK
  convenience method with corresponding arguments.
- **FR-003**: The CLI MUST resolve connection parameters in
  priority order: command-line flags > config file.
  Environment variables are NOT used.
- **FR-004**: The CLI MUST output structured data to stdout and
  errors to stderr.
- **FR-005**: The CLI MUST exit with code 0 on success and
  non-zero on error.
- **FR-006**: Configuration is stored in two files in a shared
  directory `~/.config/kaiten/` (all platforms):
  - **`config.json`** — connection settings (url, token):
    ```json
    {
      "url": "https://company.kaiten.ru/api/latest",
      "token": "your-api-token"
    }
    ```
  - **`preferences.json`** — user preferences (favorite boards,
    spaces). Managed by KaitenMCP. The CLI does not read or write
    this file.

  The CLI reads only `config.json`.
- **FR-007**: The CLI MUST use `swift-configuration`
  (`ConfigReader` + `FileProvider<JSONSnapshot>`) to read the
  config file. `swift-configuration` is a dependency of the CLI
  target only, not the SDK.
- **FR-008**: The CLI MUST NOT expose destructive delete commands for
  spaces, boards, or lanes.

### Non-Functional Requirements

- **NFR-001**: The CLI MUST compile and run on macOS (ARM) and
  Linux (x86-64 and ARM).
- **NFR-002**: CLI command source files MUST mirror the SDK/API domain
  grouping from Kaiten documentation (for example: cards, boards,
  spaces, users) while preserving existing command behavior.

## Success Criteria *(mandatory)*

### Measurable Outcomes

- **SC-001**: The CLI can be used in automation scripts — each
  subcommand accepts all input via flags or config file and
  produces machine-readable output.
- **SC-002**: The CLI contains no duplication of SDK logic — each
  subcommand only calls the corresponding SDK method.
- **SC-003**: The CLI compiles and runs on macOS (ARM) and
  Linux (x86-64 and ARM).
