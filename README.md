<p align="center"><img src="assets/decodie-logo.png" alt="Decodie" width="200"></p>

# Decodie Skill

**Turn every coding session into a structured learning trail.**

A collection of [Agent Skills](https://agentskills.io/specification) that generate structured learning entries as a byproduct of AI-assisted coding sessions. As the agent writes code, the skills simultaneously document the reasoning, patterns, and language features used -- producing a cumulative, browsable knowledge base in a `.decodie/` directory.

Compatible with 70+ AI coding agents including Claude Code, Gemini CLI, Cursor, Cline, Windsurf, and more.

## What it does

While you code with an AI agent, the Decodie skills observe each meaningful decision the agent makes and write structured learning entries capturing:

- **What** the code does (code snippets, key concepts)
- **Why** this approach was chosen (rationale, alternatives considered)
- **Where** it lives (content-based code references that survive refactoring)
- **Related resources** (links to official docs for PHP, JavaScript, Python, React, and more)

Entries are tagged by experience level (`foundational` through `advanced`), decision type (`explanation`, `rationale`, `pattern`, `warning`, `convention`, `overview`), and topic. Duplicate concepts are detected and cross-referenced automatically.

## Installation

Install with the [Skills CLI](https://github.com/vercel-labs/skills):

```bash
# Install all skills
npx skills add owenbush/decodie-skill --all

# Install a specific skill
npx skills add owenbush/decodie-skill -s decodie-analyze

# Install for a specific agent
npx skills add owenbush/decodie-skill --all -a claude-code
```

### Global install (all projects)

```bash
npx skills add owenbush/decodie-skill --all -g
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

The skills create a `.decodie/` directory at the project root with the following structure:

```
.decodie/
├── config.json                  # User preferences (experience level, topic filters)
├── index.json                   # Lightweight index of all entries (metadata only)
├── rules/                       # Output rules (optional, user-created)
│   ├── tone.md
│   └── ...
└── sessions/
    ├── 2026-03-27-001.json      # Full entries from session 1
    ├── 2026-03-27-002.json      # Full entries from session 2
    └── ...
```

- **`index.json`** -- contains metadata for every entry: title, topics, experience level, code references, external doc links, and lifecycle state.
- **`sessions/*.json`** -- contain the full content of each entry: code snippets, explanations, alternatives considered, and key concepts.
- **`config.json`** -- user preferences such as preferred/excluded topics and archival thresholds.
- **`rules/*.md`** -- optional output rules that control tone, language, verbosity, and format of generated documentation.

### Adding `.decodie/` to version control

You can commit `.decodie/` to share learning entries with your team, or add it to `.gitignore` to keep it personal.

## Skills

| Skill | Description |
|-------|-------------|
| `decodie-observe` | Document decisions as you code in real-time |
| `decodie-analyze` | Analyze existing code retroactively (selective or exhaustive) |
| `decodie-overview` | Generate a high-level summary of a file, directory, or project |
| `decodie-explain` | Explain a code selection (ephemeral by default) |
| `decodie-ask` | Ask questions about existing entries |
| `decodie-verify` | Confirm entries still match source code and stamp with commit SHA |
| `decodie-flag-stale` | Fast CI-friendly check for entries affected by recent changes |

## Output rules

You can control the tone, language, verbosity, and format of generated documentation by adding rule files to `.decodie/rules/`. Each `.md` file is a standalone rule written in plain natural language.

### Project rules

Create `.decodie/rules/` in your project and add `.md` files:

`.decodie/rules/tone.md`:
```
Use simple, conversational language suitable for junior developers.
Avoid jargon unless it is defined in the explanation.
```

`.decodie/rules/brevity.md`:
```
Keep explanations concise — aim for 2-3 sentences for the main explanation.
Use bullet points for key concepts rather than prose paragraphs.
```

### Global rules

Rules placed in `~/.decodie/rules/*.md` apply to all projects. Project rules take precedence over global rules when they conflict.

### How rules work

- Every content-producing skill (observe, analyze, explain, overview, ask) reads rules during setup.
- Rules are additive — multiple rule files combine to form the full set of output instructions.
- No schema is enforced — rules are free-form text, so you can control any aspect of the output.
- The `rules/` directory is created automatically when a skill bootstraps `.decodie/` for the first time.

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
