<p align="center"><img src="assets/decodie-logo.png" alt="Decodie" width="200"></p>

# Decodie Skill

**Turn every coding session into a structured learning trail.**

An [Agent Skill](https://agentskills.io/specification) that generates structured learning entries as a byproduct of AI-assisted coding sessions. As the agent writes code, it simultaneously documents the reasoning, patterns, and language features used -- producing a cumulative, browsable knowledge base in a `.decodie/` directory.

Compatible with 70+ AI coding agents including Claude Code, Gemini CLI, Cursor, Cline, Windsurf, and more.

## What it does

While you code with an AI agent, the Decodie skill observes each meaningful decision the agent makes and writes a structured learning entry capturing:

- **What** the code does (code snippets, key concepts)
- **Why** this approach was chosen (rationale, alternatives considered)
- **Where** it lives (content-based code references that survive refactoring)
- **Related resources** (links to official docs for PHP, JavaScript, Python, React, and more)

Entries are tagged by experience level (`foundational` through `advanced`), decision type (`explanation`, `rationale`, `pattern`, `warning`, `convention`, `overview`), and topic. Duplicate concepts are detected and cross-referenced automatically.

## Installation

Install with the [Skills CLI](https://github.com/vercel-labs/skills):

```bash
npx skills add owenbush/decodie-skill
```

This installs the Decodie skill for your agent of choice. For Claude Code, it lands in `.claude/skills/decodie/`.

### Install for a specific agent

```bash
npx skills add owenbush/decodie-skill -a claude-code
npx skills add owenbush/decodie-skill -a cursor
npx skills add owenbush/decodie-skill -a gemini-cli
```

### Global install (all projects)

```bash
npx skills add owenbush/decodie-skill -g
```

### Legacy installation

<details>
<summary>Using the deprecated <code>install-skill</code> command</summary>

The legacy installer still works but will be removed in a future release:

```bash
npx @owenbush/decodie-ui install-skill
npx @owenbush/decodie-ui install-skill --scope project
```

</details>

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

- **`index.json`** -- contains metadata for every entry: title, topics, experience level, code references, external doc links, and lifecycle state.
- **`sessions/*.json`** -- contain the full content of each entry: code snippets, explanations, alternatives considered, and key concepts.
- **`config.json`** -- user preferences such as preferred/excluded topics and archival thresholds.

### Adding `.decodie/` to version control

You can commit `.decodie/` to share learning entries with your team, or add it to `.gitignore` to keep it personal.

## Modes

The Decodie skill supports seven modes:

### Observe — Document as you code

Activate at the start of a coding session. Documents decisions, patterns, and concepts as the agent writes code in real-time. Creates entries interleaved with normal coding work, detects duplicates, and tracks supersession when code is rewritten.

### Analyze — Analyze existing code

Generate learning entries from existing code retroactively. Works on files, directories, or entire projects.

- **Selective mode** (default): 3-5 most significant patterns per file
- **Exhaustive mode**: every meaningful pattern without limits
- **Source annotations**: `@decodie-include` and `@decodie-ignore` markers in code comments control what gets documented

### Overview — Summarize a file, directory, or project

Generate a high-level overview entry — purpose, structure, entry points, and dependencies. Persisted by default. Re-running on the same target overwrites the existing overview.

### Explain — Explain a code selection

Detailed explanation of a specific code selection: summary, breakdowns, potential issues, improvements, and key concepts. Ephemeral by default (chat only) — persisted to `.decodie/` only on explicit request.

### Ask — Ask questions about entries

Query existing learning entries. Finds the most relevant entry by keyword or ID and answers using the entry content and live source code as context.

### Verify — Confirm entries match the code

Walk every entry's references, confirm anchored code still resolves, and stamp confirmed entries with the current commit SHA. Marks mismatches as `stale: true`.

### Flag Stale — Detect entries affected by recent changes

Fast CI-friendly check. For each verified entry, runs `git diff --name-only` and flags entries whose source files have changed. No source files are read — based purely on git history.

## Viewing your entries

### VSCode extension

Install the [Decodie VSCode extension](https://marketplace.visualstudio.com/items?itemName=owenbush.decodie-vscode) to browse entries in your editor sidebar, with gutter indicators, right-click analysis, and entry detail views.

### Web UI

```bash
npx @owenbush/decodie-ui serve
```

Opens a browsable interface at `http://localhost:8081` with lessons, progress tracking, and Q&A.

### DDEV

```bash
ddev add-on get owenbush/decodie-ddev
ddev restart && ddev decodie
```

## Schema

JSON schemas for all data files are in `schema/`:

- `schema/index.schema.json` -- `.decodie/index.json`
- `schema/session.schema.json` -- `.decodie/sessions/*.json`
- `schema/config.schema.json` -- `.decodie/config.json`

See `schema/README.md` for detailed documentation.

## Related repositories

- [decodie.owenbush.dev](https://decodie.owenbush.dev) -- Project homepage
- [owenbush/decodie-ui](https://github.com/owenbush/decodie-ui) -- Web-based browser with lessons and progress tracking
- [owenbush/decodie-vscode](https://marketplace.visualstudio.com/items?itemName=owenbush.decodie-vscode) -- VSCode extension
- [owenbush/decodie-github-action](https://github.com/owenbush/decodie-github-action) -- GitHub Action for automatic PR analysis ([Marketplace](https://github.com/marketplace/actions/decodie-analyze))
- [owenbush/decodie-github-bot](https://github.com/owenbush/decodie-github-bot) -- Interactive bot for PR comments
- [owenbush/decodie-ddev](https://github.com/owenbush/decodie-ddev) -- DDEV add-on
- [owenbush/decodie-core](https://github.com/owenbush/decodie-core) -- Shared data layer (types, parser, reference resolver)
