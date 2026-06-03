# `.decodie/` Data Format

The `.decodie/` directory lives at the root of a project and stores structured records of concepts, decisions, and patterns. It serves as a persistent, queryable knowledge base that grows alongside the codebase.

## Files

### `index.json`

Central index of all learning entries. Each entry records a single insight and links it to source-code locations, external docs, and related entries.

**Schema**: `index.schema.json` in the skill's `schema/` directory.

### Session files (`sessions/*.json`)

Full detail of entries created during one session, including code snippets, explanations, and alternatives. Session files are the primary authoring surface; `index.json` is the queryable summary.

**Schema**: `session.schema.json`

### `config.json`

Optional user preferences. Every field has a sensible default.

**Schema**: `config.schema.json`

## Conventions

### Session IDs

Base format: `YYYY-MM-DD-NNN` (`NNN` zero-padded, starting at `001` per day).

Prefixed variants by mode: `analyze-YYYY-MM-DD-NNN`, `explain-YYYY-MM-DD-NNN`, `overview-YYYY-MM-DD-NNN`. Sequence numbers increment per-prefix per-day.

### Reference Anchoring

Entries reference source code via content-based anchors (not line numbers):

- **`file`** — relative path to the source file
- **`anchor`** — recognizable code snippet (function signature, class declaration)
- **`anchor_hash`** — first 8 hex chars of SHA-256 of the anchor string

### Experience Levels

| Level | Description |
|---|---|
| `foundational` | Core language/framework concepts every developer needs |
| `intermediate` | Patterns and trade-offs for working developers |
| `advanced` | Deep internals, performance, and architecture |
| `ecosystem` | Tooling, configuration, and cross-cutting concerns |

### Decision Types

| Type | When to use |
|---|---|
| `explanation` | Teaching a concept |
| `rationale` | Explaining why a particular approach was chosen |
| `pattern` | A reusable code pattern or technique |
| `warning` | A pitfall, anti-pattern, or common mistake |
| `convention` | A project-specific style or structural agreement |
| `overview` | High-level summary of a file, directory, or project |

### Lifecycle

| State | Meaning |
|---|---|
| `active` | Current and relevant |
| `archived` | No longer relevant but retained |
| `superseded` | Replaced by a newer entry (see `superseded_by`) |

### Verification Fields

- **`sources`** — file paths the entry touches (derived from `references[].file`)
- **`verified_sha`** — git commit SHA at which the entry was last confirmed
- **`stale`** — `true` when source files changed since `verified_sha` or anchors no longer resolve; `false` when freshly verified; absent when never verified

### Overview Entries

Entries with `decision_type: "overview"` use a different session-entry shape:

- **`purpose`** (required) — what the target code is for
- **`structure`** (required) — how the target is organized
- **`entry_points`** (optional) — callable surfaces
- **`dependencies`** (optional) — notable dependencies

Overviews are scoped to exactly one target (`sources` holds a single path). Re-running on the same target overwrites in place.
