<p align="center"><img src="assets/decodie-logo.png" alt="Decodie" width="200"></p>

# Decodie Skill

**Turn every coding session into a structured learning trail.**

A [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skill that generates structured learning entries as a byproduct of AI-assisted coding sessions. As the agent writes code, it simultaneously documents the reasoning, patterns, and language features used -- producing a cumulative, browsable knowledge base in a `.decodie/` directory.

## What it does

While you code with Claude Code, the Decodie skill observes each meaningful decision the agent makes and writes a structured learning entry capturing:

- **What** the code does (code snippets, key concepts)
- **Why** this approach was chosen (rationale, alternatives considered)
- **Where** it lives (content-based code references that survive refactoring)
- **Related resources** (links to official docs for PHP, JavaScript, Python, React, and more)

Entries are tagged by experience level (`foundational` through `advanced`), decision type (`explanation`, `rationale`, `pattern`, `warning`, `convention`), and topic. Duplicate concepts are detected and cross-referenced automatically.

## Installation

The easiest way to install is via npm:

```bash
npx @owenbush/decodie-ui install-skill
```

This downloads `SKILL.md`, `SKILL-ANALYZE.md`, and scripts into `~/.claude/skills/decodie/`. The skills will be available in every project you open with Claude Code.

### Project-level (shared with team)

To install at project level so the skill is shared via version control:

```bash
npx @owenbush/decodie-ui install-skill --scope project
```

This installs into `.claude/skills/decodie/` in your project directory. Commit it to share with your team.

### Manual installation

If you prefer not to use npm, copy the files manually:

```bash
mkdir -p ~/.claude/skills/decodie
cp SKILL.md SKILL-ANALYZE.md ~/.claude/skills/decodie/
cp -r scripts/ ~/.claude/skills/decodie/scripts/
```

### Enterprise / Team plans

Organisation owners can provision the skill for all team members through admin settings.

## What gets generated

The skill creates a `.decodie/` directory at the project root with the following structure:

```
.decodie/
├── config.json                  # User preferences (experience level, topic filters)
├── index.json                   # Lightweight index of all entries (metadata only)
└── sessions/
    ├── 2026-03-27-001.json      # Full entries from session 1
    ├── 2026-03-27-002.json      # Full entries from session 2
    └── ...
```

- **`index.json`** -- contains metadata for every entry: title, topics, experience level, code references, external doc links, and lifecycle state. This is the file the agent reads for duplicate detection and the presentation layer reads for navigation.
- **`sessions/*.json`** -- contain the full content of each entry: code snippets, explanations, alternatives considered, and key concepts. One file per coding session.
- **`config.json`** -- user preferences such as default experience level, preferred/excluded topics, and archival thresholds.

### Adding `.decodie/` to version control

You can commit `.decodie/` to share learning entries with your team, or add it to `.gitignore` to keep it personal. Both approaches work -- the data is self-contained.

## Commands

Decodie provides three commands in Claude Code:

### `/decodie:observe` — Document as you code

Activate this at the start of a coding session. It documents decisions, patterns, and concepts as the agent writes code in real-time.

```
/decodie:observe
```

The agent will:
1. Set up the `.decodie/` directory if it does not exist.
2. Start a new session for the current coding interaction.
3. Write a learning entry after each meaningful coding decision.
4. Cross-reference related entries and link to external documentation.
5. Mark entries as superseded when referenced code is rewritten or removed.
6. Close the session when the conversation ends.

### `/decodie:analyze` — Analyze existing code

Generate learning entries from existing code — even code that wasn't written with Claude:

```
/decodie:analyze src/auth/              # Analyze a directory
/decodie:analyze src/utils/helpers.ts   # Analyze a single file
/decodie:analyze                        # Analyze the whole project
/decodie:analyze --exhaustive src/      # Document everything (default is 3-5 per file)
```

By default, analyze runs in **selective mode** — it picks the 3–5 most significant, non-obvious patterns per file. Add the `--exhaustive` flag to document every meaningful pattern without per-file limits.

Analysis entries are stored in their own sessions (prefixed `analyze-`) so you can distinguish them from entries generated during coding. The same duplicate detection and cross-referencing applies.

#### Source annotations

You can place annotation markers in source code comments to control what `/decodie:analyze` documents. These markers work in both selective and exhaustive modes and do not affect unannotated code.

Two actions are available — `@decodie-include` (always analyze) and `@decodie-ignore` (never analyze) — each with a scope modifier:

| Marker | Scope |
|---|---|
| `@decodie-include:file` | Entire file |
| `@decodie-include:class` | Next class/interface/enum |
| `@decodie-include:function` | Next function/method |
| `@decodie-include:start` / `end` | Block region |
| `@decodie-ignore:file` | Entire file |
| `@decodie-ignore:class` | Next class/interface/enum |
| `@decodie-ignore:function` | Next function/method |
| `@decodie-ignore:start` / `end` | Block region |

Markers are recognized inside any comment syntax (`//`, `#`, `/* */`, `<!-- -->`, etc.). `@decodie-ignore` always takes precedence over `@decodie-include` when scopes overlap. Included code does not count against the 3–5 entry limit in selective mode.

```php
/**
 * @decodie-ignore:class
 */
class GeneratedFormHandler { ... }
```

```python
# @decodie-include:function
def calculate_risk_score(portfolio):
    ...
```

### `/decodie:ask` — Ask questions about entries

Query your existing learning entries. Finds the most relevant entry by keyword or entry ID, and answers using the entry content and live source code as context.

```
/decodie:ask "why did we use the strategy pattern here?"
/decodie:ask "entry-1711540000-a1b2"
```

## Viewing your entries

### With DDEV

If you use [DDEV](https://ddev.readthedocs.io/) for local development, the Decodie add-on installs everything — the UI and the commands — in one step:

```bash
ddev add-on get owenbush/decodie-ddev
ddev restart
ddev decodie
```

This opens the Decodie UI in your browser at `https://decodie.SITENAME.ddev.site`. Use `ddev decodie status` to see entry statistics.

### Without DDEV

Install the commands and run the UI with npx (requires Node.js 18+):

```bash
npx @owenbush/decodie-ui install-skill
npx @owenbush/decodie-ui serve
```

This installs the commands into `~/.claude/commands/decodie/` and opens `http://localhost:8081` pointing at the current project directory.

## Preprocessing script

The `scripts/summarize-index.sh` script produces a compact summary of the learning index for the agent's context window. It requires `jq` for full functionality but falls back to basic text parsing if `jq` is not available.

```bash
# Run manually to see the summary
bash scripts/summarize-index.sh /path/to/project
```

Works on both macOS and Linux.

## Schema

The JSON schemas for all data files are in the `schema/` directory:

- `schema/index.schema.json` -- schema for `.decodie/index.json`
- `schema/session.schema.json` -- schema for `.decodie/sessions/*.json`
- `schema/config.schema.json` -- schema for `.decodie/config.json`

See `schema/README.md` for detailed documentation of all fields, conventions, and lifecycle states.

## Related repositories

- [decodie.owenbush.dev](https://decodie.owenbush.dev) -- Project homepage and documentation.
- [owenbush/decodie-ui](https://github.com/owenbush/decodie-ui) -- The presentation layer that renders a browsable interface for the `.decodie/` data.
- [owenbush/decodie-ddev](https://github.com/owenbush/decodie-ddev) -- DDEV add-on that serves the UI as a DDEV service.
- [owenbush/decodie-github-action](https://github.com/owenbush/decodie-github-action) -- GitHub Action for automatic PR analysis. [View on Marketplace](https://github.com/marketplace/actions/decodie-analyze).
- [owenbush/decodie-github-bot](https://github.com/owenbush/decodie-github-bot) -- Interactive bot for on-demand analysis and explanations in PR comments.
- [owenbush/decodie-vscode](https://github.com/owenbush/decodie-vscode) -- VSCode extension with sidebar entry browser and right-click analysis. [Install from Marketplace](https://marketplace.visualstudio.com/items?itemName=owenbush.decodie-vscode).
- [owenbush/decodie-core](https://github.com/owenbush/decodie-core) -- Shared data layer (types, parser, reference resolver).

## Compatibility

The skill is designed for Claude Code but the `SKILL.md` format is compatible with other agentic coding tools that support custom skills (Cursor, Gemini CLI, etc.). The `.decodie/` data format is tool-agnostic -- any application that reads JSON can consume it.
