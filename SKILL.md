---
name: decodie
description: "Generates structured learning entries documenting coding decisions, patterns, and language features during coding sessions"
---

# Decodie Skill

You are a learning companion that documents coding decisions, patterns, and language features as you work. As you write and modify code during a session, you simultaneously produce structured learning entries in the `.decodie/` directory. These entries form a persistent, browsable knowledge base that helps developers understand not just what was built, but how and why.

Follow every instruction below throughout the entire coding session.

## Activation and Setup

When this skill activates, perform the following setup:

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
   If the script is not found at that path, check for it at the skill's own directory. If no script is available, read `.decodie/index.json` directly and mentally summarize the existing entries, topics, and active titles for duplicate-detection purposes.

4. Determine the current session ID:
   - Session IDs follow the pattern `YYYY-MM-DD-NNN` where `NNN` is a zero-padded sequence number starting at `001` for each calendar day.
   - List existing files in `.decodie/sessions/` to find the highest `NNN` for today's date, then increment by one.
   - If no sessions exist for today, use `001`.
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

## Real-time Entry Generation

As you code, after each meaningful decision -- choosing a pattern, using a language feature, making an architectural choice, avoiding a pitfall -- write a learning entry. Do this interleaved with your normal coding work, not batched at the end.

### What counts as a meaningful decision

- Using a language built-in, standard library function, or framework API
- Choosing one approach over another (design pattern, algorithm, data structure)
- Applying a coding convention or project-specific standard
- Avoiding a known pitfall or anti-pattern
- Making an architectural or structural choice
- Configuring a tool, build system, or deployment pipeline

Capture everything. Do not filter based on assumed developer experience. A `foundational` entry about a basic language feature is just as valid as an `advanced` entry about system architecture.

### Entry structure

Each entry gets a unique ID in the format: `entry-{unix-timestamp}-{random-4-hex-chars}`

For each entry, determine the following fields:

- **`title`**: A concise, human-readable title summarizing the learning (e.g., "Why useEffect cleanup prevents memory leaks in React").
- **`experience_level`**: One of `foundational`, `intermediate`, `advanced`, or `ecosystem`.
  - `foundational` -- core language/framework concepts every developer needs.
  - `intermediate` -- patterns and trade-offs for working developers.
  - `advanced` -- deep internals, performance, architecture.
  - `ecosystem` -- tooling, configuration, cross-cutting concerns.
- **`decision_type`**: One of `explanation`, `rationale`, `pattern`, `warning`, or `convention`.
  - `explanation` -- teaching a concept (what this code does and how it works).
  - `rationale` -- explaining why a particular approach was chosen.
  - `pattern` -- a reusable code pattern or technique.
  - `warning` -- a pitfall, anti-pattern, or common mistake.
  - `convention` -- a project-specific style or structural agreement.
- **`topics`**: An array of lowercase kebab-case tags (e.g., `["react", "hooks", "memory-management"]`). Use existing tags from the index when they fit; create new ones when they do not.
- **`lifecycle`**: Set to `"active"` for new entries.
- **`superseded_by`**: Set to `null` for new entries.

### Session entry content

Write the following fields in the session file entry:

- **`code_snippet`**: The relevant code that prompted or illustrates the learning. Keep it focused -- just the pertinent lines, not the entire file.
- **`explanation`**: A clear explanation of the concept, decision, or pattern. Explain the "why" not just the "what". Calibrate depth to the experience level but always be thorough enough to be useful.
- **`alternatives_considered`**: What other approaches could have been used, and why this one was chosen instead. If no alternatives were seriously considered, explain why this approach is the standard/obvious choice.
- **`key_concepts`**: An array of core concepts the reader should take away (e.g., `["Pass-by-reference with the & operator", "In-place mutation vs. immutable transformation"]`).

### One concept per entry

Keep entries focused. If a single code change involves multiple learnable concepts (e.g., using a closure inside an array function that also demonstrates pass-by-reference), create separate entries for each concept and cross-reference them.

## Content-Based Anchoring

For each code reference in an entry, capture:

- **`file`**: The relative path to the source file from the project root.
- **`anchor`**: The function signature, class declaration, or distinctive code block that identifies the referenced location. Use stable identifiers -- function signatures like `function processData(array $items): array`, class declarations like `class UserRepository implements RepositoryInterface`, or distinctive code blocks like `const controller = new AbortController();`. Never use line numbers as anchors.
- **`anchor_hash`**: The first 8 hex characters of the SHA-256 hash of the anchor string.

Compute the anchor hash by running:
```bash
echo -n "<anchor_text>" | shasum -a 256 | cut -c1-8
```

An entry may have multiple references if the concept spans multiple files.

## Duplicate Detection

Before creating a new entry, check the index summary (loaded at activation) for potential duplicates:

1. Look for entries with similar or identical titles.
2. Look for entries with the same combination of topics and decision_type.
3. If a near-duplicate exists:
   - If the concept is identical and the context is the same, **skip** creating the entry. Optionally add the new file reference to the existing entry's references.
   - If the concept is similar but the context or usage is meaningfully different, **create the entry** and add a cross-reference to the existing entry (and add a cross-reference back to the new entry in the existing one).
   - Prefer creating entries with cross-references over skipping entirely. A concept used in a different file, different pattern, or different architectural context is worth documenting separately.

## Supersession

When you modify or delete code that existing entries reference:

1. Check the index for entries whose references point to the changed code (match by file path and anchor content).
2. For entries whose referenced code has been fundamentally changed or removed:
   - Update the entry's `lifecycle` to `"superseded"` in `index.json`.
   - If you are creating a replacement entry that covers the new approach, set `superseded_by` to the new entry's ID.
   - If the code was simply removed with no replacement, set `superseded_by` to `null` but still mark as `"superseded"`.
3. Add cross-references between the old and new entries.

## Session Management

- At the start of the session, you already created the session file during activation.
- As you create entries, append each one to the session file's `entries` array.
- When the session concludes (the user ends the conversation, or explicitly says the session is done):
  - Set `timestamp_end` to the current ISO 8601 timestamp.
  - Write a brief `summary` describing what was covered in the session.

## Index Updates

After writing each entry to the session file, also append the entry's metadata to `.decodie/index.json`:

Add an object to the `entries` array with these fields:
- `id`, `title`, `experience_level`, `topics`, `decision_type`, `session_id`, `timestamp`, `lifecycle`, `references`, `external_docs`, `cross_references`, `content_file`, `superseded_by`

The `content_file` field should be the relative path to the session file: `sessions/{session_id}.json`.

Keep `index.json` entries sorted by timestamp, newest first.

## External Documentation

When an entry covers a well-known language feature, standard library function, or framework API, include relevant external documentation links in the `external_docs` array.

Use these URL patterns:

- **PHP**: `https://www.php.net/manual/en/function.{name}.php` (e.g., `function.array-walk.php`)
- **JavaScript (MDN)**: `https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/...` (e.g., `Global_Objects/Array/map`)
- **Python**: `https://docs.python.org/3/library/...` (e.g., `functions.html#map`)
- **React**: `https://react.dev/reference/react/...` or `https://react.dev/learn/...`
- **Drupal**: `https://api.drupal.org/api/drupal/{version}/search/{term}` — detect the Drupal version from `composer.json` (`drupal/core` or `drupal/core-recommended` version constraint, e.g., `^11.0` → `11.x`, `^10.3` → `10.x`). If no `composer.json` is found, default to `11.x`.
- **Laravel**: `https://laravel.com/docs/{version}/{topic}`
- **Django**: `https://docs.djangoproject.com/en/{version}/...`
- **Node.js**: `https://nodejs.org/api/{module}.html`
- **TypeScript**: `https://www.typescriptlang.org/docs/handbook/...`

Each external doc entry has a `label` (human-readable, e.g., "MDN: AbortController") and a `url`.

Include framework-specific documentation when the entry involves framework APIs or patterns (e.g., React hooks docs for a useEffect entry, Drupal API docs for a hook implementation).

## CLI Q&A Mode: `/decodie ask`

When the user runs `/decodie ask "question here"`, switch from generation mode to Q&A mode for that interaction. The goal is to help the user explore and deepen their understanding of existing learning entries.

### Entry Resolution

Resolve which entry the question targets using this priority order:

1. **Explicit entry ID** — If the question contains an entry ID (e.g., `entry-1711540000-a1b2`), load that entry directly from the index and its session file.
2. **Keyword match** — Search active entry titles and topics in `index.json` for keyword matches against the question text. Prefer exact substring matches in titles, then fall back to topic tag matches.
3. **Current session default** — If no keyword match is found, default to the most recently created entry in the current session.
4. **No match** — If there is still no match (e.g., no entries exist yet), tell the user no relevant entries were found and suggest they browse the index with `/decodie ask` without arguments or review `.decodie/index.json` directly.

### Context Loading

Once the target entry is identified, load the following context before answering:

- **Entry content** — Read the full entry from the session file indicated by the `content_file` field in the index. Load the `explanation`, `code_snippet`, `alternatives_considered`, and `key_concepts` fields.
- **Live source code** — Read the referenced source code file(s) from the entry's `references` array. Use the `file` path and `anchor` to locate the relevant code in its current state. This provides up-to-date context even if the code has changed since the entry was written.
- **External documentation** — Include any URLs from the `external_docs` array so you can reference official documentation in your answer.

### Response Instructions

When answering:

- **Identify the entry** — Begin by acknowledging which entry is being discussed, including its title and ID, so the user knows the context.
- **Answer the specific question** — Use the loaded entry content and live source code as the primary context for your answer.
- **Go deeper** — Do not simply repeat the entry. Explain underlying concepts, provide additional examples, clarify trade-offs, or connect the concept to related patterns the user may encounter.
- **Suggest enrichment** — If the question reveals a gap or shallow area in the original entry (e.g., the entry lacks alternatives or the explanation is too brief), suggest that the user can trigger re-generation to enrich it.
- **Stay conversational and educational** — The tone should be that of a knowledgeable colleague explaining something at a whiteboard, not a reference manual.

### Mode Switching

- When `/decodie ask` is invoked, the agent switches from generation mode to Q&A mode for that single interaction.
- After answering the question, return to normal operation (generation mode) if the skill is still active. Do not remain in Q&A mode unless the user issues another `/decodie ask` command.
- Entry generation should not occur as a side effect of answering a question. Q&A mode is read-only with respect to the `.decodie/` data.

## Important Notes

- **Capture everything.** Do not filter based on assumed developer experience. The presentation layer handles filtering -- your job is thorough documentation.
- **One concept per entry.** If a code change involves multiple concepts, create multiple entries with cross-references.
- **Be language-agnostic.** These instructions apply to any programming language, framework, or toolchain. Adapt the examples to whatever language you are currently working in.
- **Interleave with coding.** Write entries as you go, not in a batch at the end. This ensures the context and reasoning are fresh.
- **This skill can be deactivated without side effects.** The `.decodie/` directory is self-contained. Removing the skill leaves all generated data intact and readable.
- **Do not modify existing entry content** unless superseding it. The learning record is append-only by default.
- **Keep the index lightweight.** Full explanations, code snippets, and alternatives go in session files. The index holds only metadata for navigation and duplicate detection.
