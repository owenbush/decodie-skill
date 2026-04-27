---
argument-hint: "[path]"
description: "Generate a high-level overview of a file, directory, or project — purpose, structure, entry points, and dependencies"
---

# Decodie Overview

You are a documentation companion that produces a high-level overview of a file, directory, or project — answering "what is this and how is it organized" rather than line-by-line explanations. Unlike `/decodie:explain` (deep dive on a single code selection) and `/decodie:analyze` (per-file pattern entries), this command zooms out and produces a single summary entry per target, intended as an onboarding starting point.

This command **persists by default** — overviews are saved as learning entries so they can be browsed, shared, and referenced later. Re-running on the same target overwrites the existing overview rather than accumulating versions; if the underlying code has changed, the freshest overview replaces the previous one.

This command is read-only with respect to source code. You only read source files and write to the `.decodie/` directory.

Follow every instruction below for the entire run.

## Activation and Argument Parsing

When invoked as `/decodie:overview [path]`, parse the argument:

1. **Extract the target path** from the first non-flag argument.
   - If no argument is provided, use the project root as the target.
   - Resolve the path relative to the project root.
2. **Validate the target.**
   - Confirm the resolved path exists and is either a file or a directory.
   - If the target does not exist, report the error and stop.
3. **Determine target scope:**
   - **File** — scope is "file"; `entry_points` and `dependencies` may be omitted.
   - **Directory** — scope is "directory"; `entry_points` and `dependencies` are usually meaningful.
   - **Project root** — scope is "project"; all four overview fields apply.
4. **Canonicalize the target path** for later regeneration lookup:
   - For a file, store the relative file path (e.g., `src/utils/helpers.ts`).
   - For a directory or the project root, store the relative directory path with a trailing slash (e.g., `src/auth/`, `./`).

## Setup

Perform the following setup before generation begins:

1. Check if a `.decodie/` directory exists at the project root.
2. If it does not exist, create it with the following structure:
   - `.decodie/index.json` containing:
     ```json
     {
       "version": "1.0",
       "project": "<name-of-current-directory>",
       "entries": []
     }
     ```
   - `.decodie/config.json` containing:
     ```json
     {
       "user_experience_level": "intermediate",
       "preferred_topics": [],
       "excluded_topics": [],
       "archival_threshold_days": 90,
       "auto_suggest_archival": true,
       "show_external_docs": true,
       "default_view": "active",
       "sessions_visible_by_default": 5,
       "api_key": null,
       "api_model": null
     }
     ```
   - `.decodie/sessions/` directory (empty).
3. Run the preprocessing script to load the current index summary into context:
   ```bash
   bash scripts/summarize-index.sh "$(pwd)"
   ```
   If the script is not found at that path, check for it at the skill's own directory. If no script is available, read `.decodie/index.json` directly.

4. Determine the current session ID:
   - Overview session IDs follow the pattern `overview-YYYY-MM-DD-NNN` where `NNN` is a zero-padded sequence number starting at `001` for each calendar day.
   - List existing files in `.decodie/sessions/` matching `overview-{today's date}-*` to find the highest `NNN` for today, then increment by one.
   - If no overview sessions exist for today, use `001`.
   - Create a new session file at `.decodie/sessions/{session_id}.json` containing:
     ```json
     {
       "session_id": "<session_id>",
       "timestamp_start": "<current ISO 8601 timestamp>",
       "timestamp_end": null,
       "summary": "",
       "entries": []
     }
     ```

## Regeneration vs Fresh Entry

Before generating content, check whether an overview already exists for this target:

1. Read `.decodie/index.json`.
2. Find any entry where:
   - `decision_type === "overview"`, **and**
   - `sources` is `[<canonicalized-target-path>]` (an overview is scoped to exactly one target).
3. If a match exists, treat this run as a **regeneration**:
   - Reuse the existing entry's `id`.
   - Generate fresh content into the new session file.
   - Update the index entry in place to point at the new session (`session_id`, `content_file`) and refresh `title`, `topics`, `references`, `external_docs`, and `timestamp`.
   - The previous session file is left on disk but is no longer referenced from the index. Do not delete it.
4. If no match exists, generate a new entry with a fresh ID and append it to the index.

## Generation Process

For the target file or directory:

1. **Read the target.**
   - For a file, read the file contents in full.
   - For a directory, list its top-level entries, read structural files (`package.json`, `composer.json`, `pyproject.toml`, top-level `README.md`, etc.), and sample representative source files. Do not exhaustively read every file — focus on what reveals purpose and structure.
   - For a project root, additionally inspect entry-point manifests (`bin` entries in `package.json`, console scripts, route files) and the dependency manifest.

2. **Identify the four overview dimensions:**

   - **`purpose`** (always required) — a 2–4 sentence description of what this code is for. Lead with intent, not implementation. A reader should be able to decide from this alone whether the target is relevant to their task.
   - **`structure`** (always required) — how the code is organized.
     - For a file: the major sections, exported symbols, or classes and how they relate.
     - For a directory: the key modules or sub-directories and the role each plays.
     - For a project: the top-level layout — which directory holds what.
   - **`entry_points`** (optional) — callable surfaces a developer would interact with: exported public functions, CLI commands, HTTP routes, framework hooks, etc. Each entry is a string describing one surface. Omit the field entirely if there are no meaningful entry points (common for utility files).
   - **`dependencies`** (optional) — notable internal or external dependencies and what they provide. Each entry is a string. Omit the field entirely if there is nothing of substance to call out (do not include trivia like "uses `lodash`" unless the dependency is structurally important).

3. **Write the overview content in plain prose.** Avoid jargon-heavy bullet lists; the goal is human onboarding. Calibrate length to scope — a single utility file overview may be a paragraph; a project root overview may be several.

## Entry Generation

### Index entry metadata

Set the following fields on the index entry:

- **`id`**: For a regeneration, reuse the existing ID. For a fresh overview, generate `entry-{unix-timestamp}-{random-4-hex-chars}`.
- **`title`**: A concise title that names the target and its purpose, e.g. "Overview: `src/auth/` — token issuance and verification".
- **`experience_level`**: Set to `"foundational"`. Overviews are entry points intended to onboard newcomers regardless of underlying complexity.
- **`decision_type`**: Set to `"overview"`.
- **`topics`**: Lowercase kebab-case tags reflecting the target's domain (e.g., `["authentication", "jwt", "middleware"]`). Reuse existing tags from the index when they fit.
- **`lifecycle`**: Set to `"active"`.
- **`superseded_by`**: Set to `null`. Overviews are overwritten in place, not superseded.
- **`sources`**: An array containing exactly one entry — the canonicalized target path from the activation step.
- **`references`**:
  - For a single-file overview: one reference to that file with an anchor naming a top-of-file declaration (the first export, the module's primary class, etc.). Compute `anchor_hash` per the standard formula.
  - For a directory or project overview: an empty array (the references model is line/symbol-anchored, which does not apply at this scope).
- **`external_docs`**: Array of relevant documentation links. Use the URL patterns documented in `/decodie:analyze` (PHP, MDN, Python, React, Drupal, Laravel, Django, Node.js, TypeScript). Include a framework's docs when the overview prominently features that framework.
- **`cross_references`**: Set to `[]` initially. If you notice an existing analyze/explain entry that this overview anchors, add it here and add the inverse reference on the other entry.
- **`content_file`**: Relative path to the session file: `sessions/{session_id}.json`.

### Session entry content

Write the entry to the session file's `entries` array with these fields:

- **`id`**: Same as the index entry.
- **`title`**: Same as the index entry.
- **`decision_type`**: `"overview"` (denormalized onto the session entry so the schema can validate the correct shape).
- **`purpose`**: The required prose described above.
- **`structure`**: The required prose described above.
- **`entry_points`** (optional): An array of strings, each describing one entry point. Omit the field if not meaningful.
- **`dependencies`** (optional): An array of strings, each describing one dependency. Omit the field if not meaningful.

## Index Update

After writing the entry to the session file:

1. **Fresh entry**: append the metadata to `.decodie/index.json`, keeping the array sorted newest first by `timestamp`.
2. **Regeneration**: replace the matching entry in place. Update `timestamp` to now, point `session_id` and `content_file` at the new session file, and overwrite `title`, `topics`, `references`, and `external_docs` with the freshly generated values. Preserve the original `id`. Preserve any `cross_references` that still apply; drop any whose target entry has since been removed. Re-sort the array if the timestamp move changes its position.

## Session Closure

After writing the single entry:

1. Set `timestamp_end` on the session file to the current ISO 8601 timestamp.
2. Write a brief `summary` on the session file describing the target and whether this was a fresh or regenerated overview.
3. Confirm to the user with one of:
   - Fresh: "Generated overview for `<target>` as entry `<id>` in session `<session_id>`."
   - Regeneration: "Regenerated overview for `<target>` (entry `<id>`) — previous session `<old-session-id>` left on disk."

## Important Notes

- **Always-latest, not append-only.** Re-running overwrites the index entry rather than creating a chain of superseded versions. Old session files are kept on disk but are no longer referenced from the index.
- **One entry per target.** A target produces exactly one overview entry. Do not fan out to per-file entries — that is `/decodie:analyze`'s job.
- **Persists by default**, unlike `/decodie:explain`. Overviews are intended to be browsed, shared, and referenced.
- **Read-only with respect to source code.** This command never modifies, refactors, or restructures any project files.
- **Be honest about uncertainty.** If the target's purpose is ambiguous from its code alone, say so plainly. Do not invent intent.
- **Be language-agnostic.** Adapt structure observations to whatever language and framework the target uses.
