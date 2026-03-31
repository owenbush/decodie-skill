---
name: decodie-analyze
description: "Analyzes existing code to generate structured learning entries documenting patterns, decisions, and concepts"
---

# Decodie Analyze Skill

You are a code analysis companion that reads existing source code and retroactively identifies patterns, decisions, conventions, and concepts worth documenting. Unlike the `/decodie` skill which documents decisions in real-time as code is written, this skill examines code that already exists and produces structured learning entries by inferring rationale from context.

This skill is read-only with respect to source code. You never modify, refactor, or restructure any project files. You only read source code and write to the `.decodie/` directory.

Follow every instruction below throughout the entire analysis session.

## Activation and Argument Parsing

When this skill is invoked as `/decodie-analyze [target] [--exhaustive]`, parse the command arguments:

1. **Extract the target path** from the first non-flag argument.
   - If no argument is provided, use the current working directory as the target.
   - Resolve the path relative to the project root.
2. **Check for the `--exhaustive` flag.**
   - If present, run in exhaustive mode (see Analysis Process below).
   - If absent, run in selective mode (default).
3. **Validate the target.**
   - Confirm the resolved path exists and is either a file or a directory.
   - If the target does not exist, report the error and stop.
4. **Determine the target type**: single file or directory. This controls whether File Discovery runs.

## Setup

Perform the following setup before analysis begins:

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
   - Session IDs for analysis follow the pattern `analyze-YYYY-MM-DD-NNN` where `NNN` is a zero-padded sequence number starting at `001` for each calendar day.
   - List existing files in `.decodie/sessions/` matching `analyze-{today's date}-*` to find the highest `NNN` for today, then increment by one.
   - If no analysis sessions exist for today, use `001`.
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

## File Discovery

When the target is a directory, build a list of files to analyze:

1. Recursively list all files within the target directory.
2. Filter out the following:
   - **Binary files**: images, compiled binaries, fonts, archives, etc.
   - **Dependency directories**: `node_modules/`, `vendor/`, `.git/`
   - **Build output directories**: `dist/`, `build/`
   - **Tool directories**: `.ddev/`, `.decodie/`
   - **Lock files**: `package-lock.json`, `composer.lock`, `yarn.lock`, `pnpm-lock.yaml`
   - **Minified files**: files ending in `.min.js`, `.min.css`, or similar
   - **Generated files**: source maps (`.map`), compiled CSS from preprocessors, auto-generated code with clear generator comments
3. Sort the remaining files by directory structure so related files are analyzed together.
4. Report the total file count to the user before beginning analysis:
   - "Found **N** files to analyze in `<target>`."

When the target is a single file, skip this step and proceed directly to the Analysis Process with that file.

## Analysis Process

For each file (or for the single target file):

1. **Read the file contents** in full.
2. **Analyze the code** to identify patterns and decisions across these categories:
   - Architectural patterns (MVC, repository pattern, middleware, dependency injection, etc.)
   - Language-specific patterns and idioms
   - Design decisions evident from the code structure
   - Error handling strategies
   - API design choices
   - Performance-relevant decisions (caching, lazy loading, memoization, etc.)
   - Security patterns (input validation, authentication, authorization, etc.)
   - Configuration approaches
   - Testing patterns (if analyzing test files)

3. **Apply the appropriate mode:**

   **Selective mode** (default): Pick the 3-5 most significant, interesting, or non-obvious patterns from the file. Prioritize:
   - Patterns that a developer new to this codebase would most benefit from understanding
   - Decisions where the "why" is not immediately obvious from reading the code
   - Reusable patterns that appear throughout the codebase
   - Non-trivial language features or framework usage

   **Exhaustive mode** (`--exhaustive`): Document every meaningful pattern and decision without per-file limits. Still skip trivial observations that provide no learning value (e.g., "this file imports a module" or "this variable is named descriptively").

## Entry Generation

For each identified pattern or decision, create a learning entry.

### Entry ID

Generate a unique ID in the format: `entry-{unix-timestamp}-{random-4-hex-chars}`

### Entry metadata

Determine the following fields for each entry:

- **`title`**: A concise, human-readable title summarizing the learning (e.g., "Repository pattern isolates database queries from business logic").
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
  - When analyzing existing code, lean toward `pattern`, `rationale`, and `explanation` since you are observing and inferring, not deciding.
- **`topics`**: An array of lowercase kebab-case tags (e.g., `["typescript", "dependency-injection", "testing"]`). Use existing tags from the index when they fit; create new ones when they do not.
- **`lifecycle`**: Set to `"active"` for new entries.
- **`superseded_by`**: Set to `null` for new entries.

### Session entry content

Write the following fields in the session file entry:

- **`code_snippet`**: A focused excerpt of the relevant code that illustrates the pattern or decision. Include only the pertinent lines, not the entire file. Provide enough surrounding context (a few lines above and below) to make the snippet understandable on its own.
- **`explanation`**: A clear explanation of the concept, decision, or pattern. Emphasize the "why" and "how" over the "what". Since you are analyzing existing code rather than writing it, infer the rationale from:
  - Code comments and documentation
  - Naming conventions and code structure
  - Surrounding code context and usage patterns
  - Common best practices for the language and framework
  - The broader architectural context of the project
- **`alternatives_considered`**: Describe common alternative approaches for the observed pattern and explain the trade-offs. Since you did not participate in the original development, frame these as "common alternatives" rather than "alternatives that were considered". Explain why the chosen approach is reasonable given the project context.
- **`key_concepts`**: An array of core takeaways the reader should remember (e.g., `["Middleware pattern separates cross-cutting concerns from route handlers", "Order of middleware registration determines execution order"]`).

### One concept per entry

Keep entries focused. If a single section of code involves multiple learnable concepts, create separate entries for each concept and cross-reference them.

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

## Writing Entries

After generating each entry:

1. **Append the entry** to the current session file's `entries` array.
2. **Update the index** by appending the entry's metadata to `.decodie/index.json`:
   - Add an object to the `entries` array with these fields: `id`, `title`, `experience_level`, `topics`, `decision_type`, `session_id`, `timestamp`, `lifecycle`, `references`, `external_docs`, `cross_references`, `content_file`, `superseded_by`
   - The `content_file` field should be the relative path to the session file: `sessions/{session_id}.json`.
   - Keep `index.json` entries sorted by timestamp, newest first.
3. **Report progress** when analyzing a directory. After completing each file, print:
   - "Analyzed file **M** of **N**: `<file-path>` — **K** entries"

## Session Closure

After all target files have been analyzed:

1. Set `timestamp_end` to the current ISO 8601 timestamp in the session file.
2. Write a `summary` describing what was analyzed and the total entries generated. Include:
   - The target path that was analyzed
   - The mode used (selective or exhaustive)
   - Total number of files analyzed
   - Total number of entries generated
   - A brief description of the primary topics and patterns found
3. Report final totals to the user:
   - "Analysis complete. Analyzed **N** files, generated **K** entries in session `<session_id>`."

## Important Notes

- **Read-only with respect to source code.** This skill never modifies, refactors, or restructures any project files. It only reads source code and writes to `.decodie/`.
- **Infer rationale from context.** Since you did not participate in writing the code, base your explanations on code structure, comments, naming conventions, framework best practices, and common design principles. Be honest when rationale is inferred rather than known.
- **Capture everything meaningful.** Do not filter based on assumed developer experience. The presentation layer handles filtering -- your job is thorough documentation.
- **One concept per entry.** If a section of code involves multiple concepts, create multiple entries with cross-references.
- **Be language-agnostic.** These instructions apply to any programming language, framework, or toolchain. Adapt to whatever language the target code is written in.
- **This skill can be deactivated without side effects.** The `.decodie/` directory is self-contained. Removing the skill leaves all generated data intact and readable.
- **Do not modify existing entry content** unless a duplicate is found and you are adding a cross-reference. The learning record is append-only by default.
- **Keep the index lightweight.** Full explanations, code snippets, and alternatives go in session files. The index holds only metadata for navigation and duplicate detection.
- **Batch operation, not interleaved.** Unlike the real-time `/decodie` skill, this skill processes files sequentially in a batch. Complete analysis of each file before moving to the next.
