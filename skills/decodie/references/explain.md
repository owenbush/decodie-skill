# Explain Mode

Walk a developer through a specific piece of code they have selected or pasted. Produces a conversational, human-readable explanation directly in the chat.

This mode is **read-only with respect to source code** and **ephemeral by default** — nothing is written to `.decodie/` unless the user explicitly asks to save.

## Scope and Inputs

Operates on code the user has selected, pasted, or pointed at. Does not scan projects or discover files.

If no code has been provided, ask the user to share the code they want explained.

## Output Format

Produce the explanation as **conversational markdown in the chat**. Do not write to disk unless asked.

### 1. Summary

A short paragraph (2-3 sentences) describing what the code does at a high level.

### 2. Detailed Breakdowns

For each complex or non-obvious section:
- A fenced code block with the **code excerpt**
- An **explanation** of what it does, why, and any patterns/idioms it uses
- The **pattern** name if applicable (e.g., "guard clause", "memoization")

Aim for 2-5 breakdowns depending on complexity. Skip trivial code.

### 3. Potential Issues

List bugs, security concerns, performance problems, edge cases. For each:
- **severity**: `info`, `warning`, or `error`
- **description**: what is wrong and when it manifests
- **suggestion**: how to address it

If you find no issues, say so plainly.

### 4. Improvements

Refactoring opportunities, modern alternatives, readability wins. For each:
- **description**: the proposed change
- **rationale**: why it helps

### 5. Key Concepts

Bulleted list of core patterns, principles, and language features to take away.

## Saving an Explanation (on explicit request only)

Only persist if the user explicitly asks ("save this", "keep this as an entry", "write this to decodie").

### Setup

Perform the common setup from the main skill file. Use session ID pattern `explain-YYYY-MM-DD-NNN`.

### Session entry fields

Write to the session file with:
- **`code_snippet`**: The selected code as provided.
- **`explanation`**: The Summary section.
- **`alternatives_considered`**: Alternative approaches if relevant; empty string otherwise.
- **`key_concepts`**: Array of core concepts.
- **`breakdowns`**: Array of `{ code_excerpt, explanation, pattern? }`.
- **`issues`**: Array of `{ severity, description, suggestion }`.
- **`improvements`**: Array of `{ description, rationale }`.

### Index entry

Set `decision_type` to `"explanation"`. If the code came from an identifiable file, include a reference with content-based anchoring. If pasted without a known origin, `references` may be empty.

### Session Closure

Set `timestamp_end`, write a brief `summary`, and confirm: "Saved explanation as entry `<id>` in session `<session_id>`."

## Important Notes

- **Ephemeral unless asked.** Do not touch `.decodie/` unless the user explicitly requests persistence.
- **Calibrate depth to the code.** A five-line utility does not need five breakdowns.
- **Be honest about uncertainty.** If code is ambiguous, say so.
