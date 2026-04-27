---
description: "Flag learning entries whose source files have changed since they were last verified — fast check designed for CI"
---

# Decodie Flag Stale

You are a staleness detector. Your job is the cheap, CI-friendly counterpart to `/decodie:verify`: for every entry that has been verified before, check whether any of its source files have changed since `verified_sha`, and flip `stale: true` on the entries that have. You do not read source files or recompute anchor hashes — that is `verify`'s job. You only diff filenames against git history.

This command **modifies `.decodie/index.json` only**. It never modifies session files, source code, or anything outside `.decodie/`.

Follow every instruction below for the entire run.

## Activation

This command takes no arguments. It always operates on the full index.

## Setup

1. Confirm `.decodie/` exists at the project root. If it does not, report "No `.decodie/` directory found — nothing to check." and stop.
2. Confirm the project is a git repository by running:
   ```bash
   git rev-parse --git-dir
   ```
   If it is not, report "Not a git repository — `flag-stale` requires git history. Run `/decodie:verify` instead for a deep check." and stop.
3. Read `.decodie/index.json`. If the `entries` array is empty, report "No entries to check." and stop.

## Detection Process

For each entry in the index:

1. **Skip entries with no `verified_sha`.** They have never been verified, so there is no baseline to diff against. They are reported as `unverified` in the summary.
2. **Skip entries with no `sources`** (and no `references[].file` to fall back on). They have nothing to check. Report as `no-sources`.
3. **Compute the changed files** between the entry's `verified_sha` and HEAD:
   ```bash
   git diff --name-only <verified_sha>..HEAD
   ```
   - If the SHA is unknown to git (for example, history was rewritten), treat the entry as stale and note it in the report.
4. **Compare against the entry's source files.** Resolve sources by preferring `sources` and falling back to the unique values of `references[].file`. If any of those paths appears in the diff output, the entry is stale.
5. **Update the entry:**
   - Newly stale (was `false` or absent, now `true`) → set `stale: true`. Leave `verified_sha` alone so the operator can see when it last passed.
   - Was already stale → no change, but still include in the count.
   - No source files in the diff → leave `stale` as it was (typically `false`). Do **not** flip a stale entry back to fresh — only `/decodie:verify` can do that, because only verify confirms the anchor still resolves.

6. **Write the updated entry back** to `.decodie/index.json`. Preserve all other fields exactly. Keep the existing sort order.

## Reporting

After all entries are processed, print a summary in this exact shape:

```
Decodie flag-stale
  Newly stale:  N entries
  Already stale: M entries
  Fresh:        F entries
  Unverified:   U entries (no verified_sha — run /decodie:verify)
  No sources:   K entries
```

If any entries went newly stale, list them with the offending files:

```
Newly stale:
  - entry-1711540000-a1b2 — src/lib/foo.ts
  - entry-1711540123-c3d4 — src/lib/bar.ts, src/lib/baz.ts
```

This output is intentionally machine-friendly so wrapping tools (such as `decodie-github-action`) can parse it and decide whether to fail a PR.

## Important Notes

- **No exit-code policy.** This command always reports its findings textually. Whether stale entries should block a PR is a per-repo decision made by the calling tooling, not by this command.
- **One-way flag.** This command only flips `stale` from `false`/absent to `true`. Clearing the flag requires running `/decodie:verify`, which actually re-checks the anchors.
- **No source file reads.** Detection is based purely on `git diff --name-only`. This is what makes the command fast enough for CI on every PR.
- **No session file updates.** This command does not touch `.decodie/sessions/`.
- **No git history rewriting.** This command only runs read-only git commands (`rev-parse`, `diff --name-only`).
