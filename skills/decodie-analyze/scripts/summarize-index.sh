#!/usr/bin/env bash
#
# summarize-index.sh — Reads .decodie/index.json and outputs a compact summary
# for the agent's context window (~500 tokens max).
#
# Usage: summarize-index.sh [project-root]
#   project-root defaults to the current directory.

set -euo pipefail

PROJECT_ROOT="${1:-.}"
INDEX_FILE="${PROJECT_ROOT}/.decodie/index.json"

# Exit cleanly with empty output if the index does not exist
if [ ! -f "$INDEX_FILE" ]; then
  exit 0
fi

# ------------------------------------------------------------------
# jq-based implementation (preferred)
# ------------------------------------------------------------------
if command -v jq &>/dev/null; then

  ENTRY_COUNT=$(jq '.entries | length' "$INDEX_FILE")
  if [ "$ENTRY_COUNT" -eq 0 ]; then
    echo "Decodie Index Summary (0 entries, 0 sessions):"
    echo "No entries yet."
    exit 0
  fi

  # Count distinct sessions
  SESSION_COUNT=$(jq '[.entries[].session_id] | unique | length' "$INDEX_FILE")

  echo "Decodie Index Summary (${ENTRY_COUNT} entries, ${SESSION_COUNT} sessions):"

  # 5 most recent entries (index should be sorted newest-first, but sort to be safe)
  jq -r '
    [.entries | sort_by(.timestamp) | reverse | .[:5][] |
      "Recent: \"\(.title)\" (\(.timestamp | split("T")[0])) [\(.lifecycle)]"
    ] | .[]
  ' "$INDEX_FILE"

  # Top 10 topics by frequency
  TOPICS=$(jq -r '
    [.entries[].topics[]] | group_by(.) | map({topic: .[0], count: length})
    | sort_by(-.count) | .[:10]
    | map("\(.topic)(\(.count))") | join(", ")
  ' "$INDEX_FILE")
  echo "Topics: ${TOPICS}"

  # All active entry titles with IDs (for duplicate checking and Q&A lookup)
  ACTIVE_TITLES=$(jq -r '
    [.entries[] | select(.lifecycle == "active") | "\(.id): \(.title)"] | join(" | ")
  ' "$INDEX_FILE")
  if [ -n "$ACTIVE_TITLES" ]; then
    echo "Active titles: ${ACTIVE_TITLES}"
  else
    echo "Active titles: (none)"
  fi

  exit 0
fi

# ------------------------------------------------------------------
# Fallback: basic parsing without jq
# ------------------------------------------------------------------

# Count entries (count occurrences of "id" fields)
ENTRY_COUNT=$(grep -c '"id"' "$INDEX_FILE" 2>/dev/null || echo "0")

# Count distinct sessions
SESSION_COUNT=$(grep -o '"session_id"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | sort -u | wc -l | tr -d ' ')

echo "Decodie Index Summary (${ENTRY_COUNT} entries, ${SESSION_COUNT} sessions):"

# Extract recent entries (title, timestamp, lifecycle) — last 5 entries by file order
# Since the file should be sorted newest-first, take the first 5 title/timestamp/lifecycle groups
TITLES=()
DATES=()
LIFECYCLES=()

while IFS= read -r line; do
  TITLES+=("$line")
done < <(grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | head -5 | sed 's/"title"[[:space:]]*:[[:space:]]*"//;s/"$//')

while IFS= read -r line; do
  DATES+=("$line")
done < <(grep -o '"timestamp"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | head -5 | sed 's/"timestamp"[[:space:]]*:[[:space:]]*"//;s/"$//;s/T.*//')

while IFS= read -r line; do
  LIFECYCLES+=("$line")
done < <(grep -o '"lifecycle"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | head -5 | sed 's/"lifecycle"[[:space:]]*:[[:space:]]*"//;s/"$//')

for i in "${!TITLES[@]}"; do
  echo "Recent: \"${TITLES[$i]}\" (${DATES[$i]}) [${LIFECYCLES[$i]}]"
done

# Extract all topics and count them
ALL_TOPICS=$(grep -o '"topics"[[:space:]]*:[[:space:]]*\[[^]]*\]' "$INDEX_FILE" \
  | grep -o '"[a-z][a-z0-9-]*"' | tr -d '"' | sort | uniq -c | sort -rn | head -10)

TOPIC_LINE=""
while IFS= read -r tline; do
  count=$(echo "$tline" | awk '{print $1}')
  topic=$(echo "$tline" | awk '{print $2}')
  if [ -n "$topic" ]; then
    if [ -n "$TOPIC_LINE" ]; then
      TOPIC_LINE="${TOPIC_LINE}, "
    fi
    TOPIC_LINE="${TOPIC_LINE}${topic}(${count})"
  fi
done <<< "$ALL_TOPICS"
echo "Topics: ${TOPIC_LINE}"

# Active titles with IDs for duplicate detection and Q&A lookup
# Extract IDs and titles paired together
# This is a rough heuristic without jq — we extract all entries since most are active
IDS=()
while IFS= read -r line; do
  IDS+=("$line")
done < <(grep -o '"id"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | sed 's/"id"[[:space:]]*:[[:space:]]*"//;s/"$//')

ALL_TITLES=()
while IFS= read -r line; do
  ALL_TITLES+=("$line")
done < <(grep -o '"title"[[:space:]]*:[[:space:]]*"[^"]*"' "$INDEX_FILE" \
  | sed 's/"title"[[:space:]]*:[[:space:]]*"//;s/"$//')

ACTIVE=""
for i in "${!ALL_TITLES[@]}"; do
  id="${IDS[$i]:-unknown}"
  title="${ALL_TITLES[$i]}"
  if [ -n "$ACTIVE" ]; then
    ACTIVE="${ACTIVE} | "
  fi
  ACTIVE="${ACTIVE}${id}: ${title}"
done

if [ -n "$ACTIVE" ]; then
  echo "Active titles: ${ACTIVE}"
else
  echo "Active titles: (none)"
fi
