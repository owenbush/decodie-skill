# `.decodie/` Directory Schema

The `.decodie/` directory lives at the root of a project and stores structured records of concepts, decisions, and patterns captured during AI-assisted coding sessions. It serves as a persistent, queryable knowledge base that grows alongside the codebase.

## Files

### `index.json`

The central index of all learning entries. Each entry records a single insight — an explanation, a design rationale, a reusable pattern, a warning, or a convention — and links it to source-code locations, external docs, and related entries.

**Schema**: `index.schema.json`

### Session files (`sessions/YYYY-MM-DD-NNN.json`)

Each session file captures the full detail of entries created during one coding session, including code snippets, explanations, and alternatives considered. Session files are the primary authoring surface; `index.json` is the queryable summary.

**Schema**: `session.schema.json`

### `config.json`

Optional user preferences. Every field has a sensible default, so the file can be omitted entirely or contain only the fields the user wants to override.

**Schema**: `config.schema.json`

## Conventions

### Session IDs

Format: `YYYY-MM-DD-NNN` where `NNN` is a zero-padded sequence number starting at `001` for each calendar day. Examples: `2026-03-27-001`, `2026-03-27-002`.

### Reference anchoring

Entries reference source code via content-based anchors rather than line numbers (which shift on every edit). Each reference stores:

- **`file`** — relative path to the source file
- **`anchor`** — a recognizable snippet of the referenced code (e.g., a function signature)
- **`anchor_hash`** — the first 8 hex characters of the SHA-256 hash of the anchor string

The hash allows fast detection of stale anchors: if the anchor text no longer appears in the file at that hash, the reference needs updating.

### Experience levels

| Level            | Description                                              |
|------------------|----------------------------------------------------------|
| `foundational`   | Core language or framework concepts every developer needs |
| `intermediate`   | Patterns and trade-offs for working developers            |
| `advanced`       | Deep internals, performance, and architecture             |
| `ecosystem`      | Tooling, configuration, and cross-cutting concerns        |

### Decision types

| Type          | When to use                                               |
|---------------|-----------------------------------------------------------|
| `explanation` | Teaching a concept the developer asked about              |
| `rationale`   | Explaining *why* a particular approach was chosen         |
| `pattern`     | A reusable code pattern or technique                      |
| `warning`     | A pitfall, anti-pattern, or common mistake                |
| `convention`  | A project-specific style or structural agreement          |

### Lifecycle

| State         | Meaning                                                   |
|---------------|-----------------------------------------------------------|
| `active`      | Current and relevant                                      |
| `archived`    | No longer relevant but retained for history               |
| `superseded`  | Replaced by a newer entry (see `superseded_by` field)     |
