#!/bin/bash
# Initialize claude-atlas in current project

set -e

CLAUDE_DIR=".claude"
INDEX_FILE="$CLAUDE_DIR/file-index.json"
STATS_FILE="$CLAUDE_DIR/atlas-stats.json"
IGNORE_FILE="$CLAUDE_DIR/atlas-ignore"

echo "Initializing claude-atlas..."

# Create .claude directory if it doesn't exist
if [ ! -d "$CLAUDE_DIR" ]; then
    mkdir -p "$CLAUDE_DIR"
    echo "✓ Created $CLAUDE_DIR/"
fi

# Create file-index.json
if [ ! -f "$INDEX_FILE" ]; then
    echo '{}' > "$INDEX_FILE"
    echo "✓ Created $INDEX_FILE"
else
    echo "• $INDEX_FILE already exists"
fi

# Create atlas-stats.json
if [ ! -f "$STATS_FILE" ]; then
    cat > "$STATS_FILE" << 'EOF'
{
  "lookups": 0,
  "hits": 0,
  "misses": 0,
  "updates": 0,
  "last_review": null
}
EOF
    echo "✓ Created $STATS_FILE"
else
    echo "• $STATS_FILE already exists"
fi

# Create atlas-ignore with default patterns
if [ ! -f "$IGNORE_FILE" ]; then
    cat > "$IGNORE_FILE" << 'EOF'
# Patterns to ignore (syntax like .gitignore)

# Dependencies
node_modules/
vendor/
.venv/
venv/

# Build
dist/
build/
out/
*.min.js
*.min.css

# Tests and coverage
coverage/
.nyc_output/
__pycache__/

# IDE and system
.git/
.idea/
.vscode/
.DS_Store

# Logs and cache
*.log
.cache/
.temp/

# Lock files
*.lock
package-lock.json
yarn.lock
EOF
    echo "✓ Created $IGNORE_FILE"
else
    echo "• $IGNORE_FILE already exists"
fi

echo ""
echo "claude-atlas initialized!"
echo ""
echo "Now Claude Code will:"
echo "  • Check index before using Glob/Grep"
echo "  • Automatically add read files to index"
echo "  • Track hit/miss statistics"
