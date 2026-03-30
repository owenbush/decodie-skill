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

### Personal (all projects)

Copy the skill files into your personal Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/decodie
cp SKILL.md ~/.claude/skills/decodie/
cp -r scripts/ ~/.claude/skills/decodie/scripts/
```

The skill will be available in every project you open with Claude Code.

### Project-level (shared with team)

Copy the skill files into the project's Claude Code skills directory:

```bash
mkdir -p .claude/skills/decodie
cp SKILL.md .claude/skills/decodie/
cp -r scripts/ .claude/skills/decodie/scripts/
```

Commit the `.claude/skills/` directory to version control so that anyone who clones the repo gets the skill automatically.

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

## How to use

Just code normally with Claude Code. The skill activates automatically and generates entries as the agent works. There is nothing extra to do.

The agent will:

1. Set up the `.decodie/` directory if it does not exist.
2. Start a new session for the current coding interaction.
3. Write a learning entry after each meaningful coding decision.
4. Cross-reference related entries and link to external documentation.
5. Mark entries as superseded when referenced code is rewritten or removed.
6. Close the session when the conversation ends.

## Viewing your entries

### With DDEV

If you use [DDEV](https://ddev.readthedocs.io/) for local development, the Decodie add-on installs everything — the UI and the skill — in a single command:

```bash
ddev add-on get owenbush/decodie-ddev
ddev restart
ddev decodie
```

This opens the Decodie UI in your browser at `https://decodie.SITENAME.ddev.site`. No manual skill installation needed. Use `ddev decodie status` to see entry statistics.

### Without DDEV

Install the skill and run the UI with npx (requires Node.js 18+):

```bash
npx @owenbush/decodie-ui install-skill
npx @owenbush/decodie-ui serve
```

This installs the skill into `~/.claude/skills/decodie/` and opens `http://localhost:8081` pointing at the current project directory.

### Activating the skill

Once installed, start a Claude Code session and run `/decodie` to activate the skill. It will then document coding decisions as you work. You need to activate it once per session.

### Q&A mode: `/decodie ask`

Use `/decodie ask "your question"` to query your existing learning entries. The skill switches to read-only Q&A mode, finds the most relevant entry by keyword or entry ID, and answers your question using the entry content and live source code as context. After answering, it returns to normal generation mode.

```
/decodie ask "why did we use the strategy pattern here?"
/decodie ask "entry-1711540000-a1b2"
```

If no entries match, the skill will suggest browsing the index directly.

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

## Compatibility

The skill is designed for Claude Code but the `SKILL.md` format is compatible with other agentic coding tools that support custom skills (Cursor, Gemini CLI, etc.). The `.decodie/` data format is tool-agnostic -- any application that reads JSON can consume it.
