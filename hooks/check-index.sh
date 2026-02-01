#!/bin/bash
# Hook that checks .claude/file-index.json before Glob/Grep executes
# Returns matching entries as additionalContext

set -e

# Read input from stdin
INPUT=$(cat)

# Get current working directory from hook input
CWD=$(echo "$INPUT" | jq -r '.cwd // "."')
INDEX_FILE="$CWD/.claude/file-index.json"
STATS_FILE="$CWD/.claude/atlas-stats.json"

# If no index exists, allow tool to proceed normally
if [ ! -f "$INDEX_FILE" ]; then
  exit 0
fi

# Get tool name and search pattern
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name')
PATTERN=""

if [ "$TOOL_NAME" = "Glob" ]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
elif [ "$TOOL_NAME" = "Grep" ]; then
  PATTERN=$(echo "$INPUT" | jq -r '.tool_input.pattern // ""')
fi

# If no pattern, allow tool to proceed
if [ -z "$PATTERN" ]; then
  exit 0
fi

# Search index for matching entries
# Look for pattern in keys and tags
MATCHES=$(jq -r --arg pattern "$PATTERN" '
  to_entries | map(
    select(
      (.key | test($pattern; "i")) or
      (.value.tags | test($pattern; "i"))
    )
  ) | map("\(.key): \(.value.path) [\(.value.tags)]") | join("\n")
' "$INDEX_FILE" 2>/dev/null || echo "")

# Update stats
if [ -f "$STATS_FILE" ]; then
  if [ -n "$MATCHES" ]; then
    # Hit - found in index
    jq '.lookups += 1 | .hits += 1' "$STATS_FILE" > "$STATS_FILE.tmp" && mv "$STATS_FILE.tmp" "$STATS_FILE"
  else
    # Miss - not found
    jq '.lookups += 1 | .misses += 1' "$STATS_FILE" > "$STATS_FILE.tmp" && mv "$STATS_FILE.tmp" "$STATS_FILE"
  fi
fi

# If we found matches, add them as context
if [ -n "$MATCHES" ]; then
  # Create JSON output with additional context
  CONTEXT="[atlas-index] Found in file index:\n$MATCHES\n\nYou can use these paths directly. If the index entry is outdated, proceed with the original search."

  echo "{
    \"hookSpecificOutput\": {
      \"hookEventName\": \"PreToolUse\",
      \"permissionDecision\": \"allow\",
      \"additionalContext\": $(echo "$CONTEXT" | jq -Rs .)
    }
  }" | jq
else
  # No matches, just allow the search to proceed
  exit 0
fi
