---
argument-hint: "[path]"
description: "Verify that learning entries still match the source code they reference, and stamp them with the current commit SHA"
---

# Decodie Verify

You are a verification agent. Your job is to confirm that every learning entry in `.decodie/index.json` still matches the source code it references, mark mismatches as stale, and stamp confirmed entries with the current commit SHA so that future runs of `/decodie:flag-stale` have a reference point to diff against.

This command **modifies `.decodie/index.json` only**. It never modifies session files, source code, or anything outside `.decodie/`.

Follow every instruction below for the entire verification run.

## Activation and Argument Parsing

When this command is invoked as `/decodie:verify [path]`, parse the arguments:

1. **Extract the optional path** from the first non-flag argument.
   - If no argument is provided, verify **all entries**.
   - If a path is provided, verify only entries whose `sources` (or `references[].file` if `sources` is absent) overlap that path. The path may be a file or a directory; for a directory, an entry is in scope if any of its source files starts with that directory.
2. **Validate the target.** If a path was provided and does not exist, report the error and stop.

## Setup

1. Confirm `.decodie/` exists at the project root. If it does not, report "No `.decodie/` directory found — nothing to verify." and stop.
2. Read `.decodie/index.json`. If the `entries` array is empty, report "No entries to verify." and stop.
3. Determine the **current commit SHA** by running:
   ```bash
   git rev-parse HEAD
   ```
   - If the project is not a git repository, report a warning and continue. In that case, anchor checks still run and `stale` is still updated, but `verified_sha` cannot be set.

## Verification Process

For each entry in scope:

1. **Resolve the entry's source files.**
   - If `sources` is present and non-empty, use it.
   - Otherwise, derive sources from the unique values of `references[].file` and **backfill** the `sources` field on the entry as part of this run.

2. **Check each reference.** For every `{ file, anchor, anchor_hash }` in the entry's `references` array:
   - If the file does not exist on disk, the reference fails.
   - Otherwise, read the file and search for the literal `anchor` string. If found, recompute the SHA-256 hash of the anchor text and confirm the first 8 hex characters match `anchor_hash`. If both match, the reference resolves.
   - Compute the anchor hash with:
     ```bash
     echo -n "<anchor_text>" | shasum -a 256 | cut -c1-8
     ```

3. **Decide the entry's verification outcome:**
   - **All references resolve** → set `stale: false` and set `verified_sha` to the current HEAD SHA (only if a SHA was determined in setup).
   - **Any reference fails** → set `stale: true`. Do **not** update `verified_sha`; leave its previous value (or absence) untouched so the operator can see when it last passed.

4. **Write the updated entry back** to `.decodie/index.json`. Preserve all other fields exactly as they were. Keep the existing sort order (newest timestamp first).

## Reporting

After all in-scope entries are processed, print a summary in this exact shape:

```
Decodie verify
  Verified:  N entries (verified_sha → <short-sha>)
  Stale:     M entries
  Skipped:   K entries (out of scope)
  Backfilled sources on: B entries
```

If any entries went stale, list their IDs and the failing reference for each:

```
Stale entries:
  - entry-1711540000-a1b2 — references/0: src/lib/foo.ts (anchor not found)
  - entry-1711540123-c3d4 — references/1: src/lib/bar.ts (file missing)
```

## Important Notes

- **Read-only with respect to source code.** Source files are read but never modified.
- **Append-only with respect to entry content.** Only the verification fields (`sources`, `verified_sha`, `stale`) may be updated. Never touch `title`, `explanation`, `references`, etc. Re-resolving an anchor that has merely moved within the file is fine — the hash check above is what counts.
- **Idempotent.** Running verify twice in a row with no source changes is a no-op for `stale` and updates `verified_sha` to the same SHA.
- **Path argument is a filter, not a guarantee.** Entries outside the path are reported as "skipped" — they retain whatever `verified_sha` and `stale` they already had. To verify everything, run with no argument.
- **Never re-verify session files.** This command does not touch `.decodie/sessions/`.
- **No git history rewriting.** This command never runs destructive git operations. It only reads HEAD via `git rev-parse`.
