---
name: decodie
description: >-
  Document coding decisions, analyze existing code, generate project overviews,
  explain code selections, and maintain learning entries. Use when writing code
  and wanting to capture decisions in real-time, when analyzing existing code
  retroactively, when generating high-level overviews of files or projects,
  when explaining code selections, when asking questions about documented
  patterns, or when verifying and flagging stale entries.
license: MIT
metadata:
  author: owenbush
  version: "1.0"
---

# Decodie

Decodie is a learning companion that builds a structured knowledge base alongside your code. It captures coding decisions, patterns, and concepts in the `.decodie/` directory as browsable, persistent entries. These entries are consumed by the [VSCode extension](https://marketplace.visualstudio.com/items?itemName=owenbush.decodie-vscode), [web UI](https://github.com/owenbush/decodie-ui), and [GitHub integrations](https://github.com/owenbush/decodie-github-action).

This skill supports seven modes. Select the mode that matches your current task.

## Modes

| Mode | When to use | Reference |
|------|-------------|-----------|
| **Observe** | You are actively writing code and want decisions documented in real-time as you work | [references/observe.md](references/observe.md) |
| **Analyze** | You want to retroactively document patterns in existing code (file, directory, or project) | [references/analyze.md](references/analyze.md) |
| **Overview** | You want a high-level summary of a file, directory, or project — purpose, structure, entry points, dependencies | [references/overview.md](references/overview.md) |
| **Explain** | You want a detailed explanation of a specific code selection (ephemeral by default, no persistence unless asked) | [references/explain.md](references/explain.md) |
| **Ask** | You have a question about an existing Decodie entry and want to explore it deeper | [references/ask.md](references/ask.md) |
| **Verify** | You want to confirm entries still match the source code they reference and stamp them with the current commit SHA | [references/verify.md](references/verify.md) |
| **Flag Stale** | You want a fast CI-friendly check for entries whose source files have changed since last verification | [references/flag-stale.md](references/flag-stale.md) |

When a task matches one of these modes, load the corresponding reference file for detailed instructions.

## Data Format

All entries are stored in the `.decodie/` directory at the project root. See [references/schema.md](references/schema.md) for the full data format specification.

The key files are:
- **`index.json`** — central index with metadata for every entry (for navigation, filtering, duplicate detection)
- **`sessions/*.json`** — full entry content (code snippets, explanations, alternatives, key concepts)
- **`config.json`** — optional user preferences

## Common Setup

Modes that write entries (observe, analyze, overview, explain-when-saving) share this initialization:

1. Check if `.decodie/` exists at the project root. If not, create it:
   - `.decodie/index.json` with `{ "version": "1.0", "project": "<directory-name>", "entries": [] }`
   - `.decodie/config.json` with default preferences
   - `.decodie/sessions/` directory

2. Load the index summary for duplicate detection. Run:
   ```bash
   bash scripts/summarize-index.sh "$(pwd)"
   ```
   If unavailable, read `.decodie/index.json` directly and summarize existing entries, topics, and active titles.

3. Determine the session ID. Session ID patterns vary by mode:
   - Observe: `YYYY-MM-DD-NNN`
   - Analyze: `analyze-YYYY-MM-DD-NNN`
   - Explain: `explain-YYYY-MM-DD-NNN`
   - Overview: `overview-YYYY-MM-DD-NNN`

   Find the highest `NNN` for today in `.decodie/sessions/` matching the prefix, then increment.

## Common Patterns

### Entry IDs

Format: `entry-{unix-timestamp}-{random-4-hex-chars}`

### Content-Based Anchoring

Reference source code via stable identifiers, never line numbers:
- **`file`** — relative path from project root
- **`anchor`** — function signature, class declaration, or distinctive code block
- **`anchor_hash`** — first 8 hex chars of SHA-256 of the anchor text

Compute: `echo -n "<anchor_text>" | shasum -a 256 | cut -c1-8`

### Entry Metadata (index.json)

Each index entry includes: `id`, `title`, `experience_level`, `topics`, `decision_type`, `session_id`, `timestamp`, `lifecycle`, `references`, `external_docs`, `cross_references`, `content_file`, `superseded_by`.

- **`experience_level`**: `foundational` | `intermediate` | `advanced` | `ecosystem`
- **`decision_type`**: `explanation` | `rationale` | `pattern` | `warning` | `convention` | `overview`
- **`lifecycle`**: `active` (new entries) | `archived` | `superseded`
- **`content_file`**: relative path to session file, e.g. `sessions/2026-03-27-001.json`
- **`topics`**: lowercase kebab-case tags; reuse existing tags from the index when they fit

Keep `index.json` entries sorted by timestamp, newest first.

### Session Entry Content (standard shape)

For all decision types except `overview`:
- **`code_snippet`** — focused excerpt illustrating the concept
- **`explanation`** — clear explanation emphasizing "why" not just "what"
- **`alternatives_considered`** — other approaches and trade-offs
- **`key_concepts`** — array of core takeaways

### Session Entry Content (overview shape)

For `decision_type: "overview"`:
- **`purpose`** (required) — 2-4 sentences on what the target code is for
- **`structure`** (required) — how the target is organized
- **`entry_points`** (optional) — callable surfaces (functions, routes, CLI commands)
- **`dependencies`** (optional) — notable internal/external dependencies

### Duplicate Detection

Before creating an entry, check the index for potential duplicates:
1. Look for entries with similar titles
2. Look for entries with the same topics + decision_type combination
3. If near-duplicate: skip if identical context, or create with cross-references if meaningfully different

### External Documentation

Include relevant external doc links in the `external_docs` array when an entry covers well-known APIs.

URL patterns by ecosystem:
- **PHP**: `https://www.php.net/manual/en/function.{name}.php`
- **JavaScript**: `https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/...`
- **Python**: `https://docs.python.org/3/library/...`
- **React**: `https://react.dev/reference/react/...`
- **Drupal**: `https://api.drupal.org/api/drupal/{version}/search/{term}` (detect version from `composer.json`)
- **Laravel**: `https://laravel.com/docs/{version}/{topic}`
- **Django**: `https://docs.djangoproject.com/en/{version}/...`
- **Node.js**: `https://nodejs.org/api/{module}.html`
- **TypeScript**: `https://www.typescriptlang.org/docs/handbook/...`

## Important Notes

- **Language-agnostic.** Adapt to whatever language and framework the project uses.
- **Read-only with respect to source code** (except observe mode, which writes code as its primary task and documents alongside).
- **Self-contained data.** The `.decodie/` directory can be removed without affecting the project.
- **One concept per entry.** Multiple concepts = multiple entries with cross-references.
- **Keep the index lightweight.** Full content goes in session files; the index holds metadata only.
