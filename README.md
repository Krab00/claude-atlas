# claude-atlas

Simple project file index for Claude Code - a "map" with descriptions of what's where.

## Problem

Claude Code uses Glob/Grep to search the project on every code question. This works, but:
- Takes time
- Uses context
- Repeats the same searches

## Solution

Local file index with descriptions (tags). Claude checks the index first, then searches if needed.

## Installation

### Add as marketplace (recommended)

In Claude Code, run:
```
/plugin marketplace add Krab00/claude-atlas
```

Then install the plugin:
```
/plugin install claude-atlas
```

### Manual installation

```bash
git clone https://github.com/Krab00/claude-atlas.git ~/.claude/plugins/claude-atlas
```

## Usage

### Initialize in a project

After installing the plugin, in any project:

```bash
# Option 1: Script
~/.claude/plugins/claude-atlas/scripts/init.sh

# Option 2: Automatically
# Just start using Claude Code - on first search
# the skill will ask to create an index
```

### How it works

1. **Hook intercepts Glob/Grep** - automatically checks `.claude/file-index.json`
2. **Found in index** - adds matching paths as context (hit)
3. **Not found** - searches normally, Claude adds result to index (miss)
4. **After reading a file** - Claude automatically updates index

The plugin uses a PreToolUse hook to intercept all Glob and Grep calls before they execute, checking the index first and providing matching entries as additional context.

## Index structure

File `.claude/file-index.json`:

```json
{
  "auth": {
    "path": "src/auth/oauth.ts",
    "tags": "oauth google github login refresh token authentication",
    "hash": "a1b2c3d4"
  },
  "database": {
    "path": "src/db/connection.ts",
    "tags": "postgres mysql connection pool query database",
    "hash": "e5f6g7h8"
  }
}
```

### Fields

- **key** - short name identifying the file
- **path** - path to file
- **tags** - keywords separated by spaces (easy to match)
- **hash** - file hash for freshness check (git hash-object or md5)

## Ignoring files

File `.claude/atlas-ignore` (syntax like .gitignore):

```
node_modules/
*.min.js
dist/
coverage/
.git/
```

## Statistics

File `.claude/atlas-stats.json`:

```json
{
  "lookups": 42,
  "hits": 35,
  "misses": 7,
  "updates": 12,
  "last_review": "2025-01-15T10:00:00Z"
}
```

### Measuring effectiveness

- **Hit rate** = hits / lookups × 100%
- Good index: >80% hit rate
- Goal: fewer Glob/Grep calls, faster responses

```bash
# Check hit rate
cat .claude/atlas-stats.json | jq '.hits / .lookups * 100'
```

## Validation

File hash detects changes:
- Hash matches → file is current, can use tags
- Hash differs → file changed, need to read and update tags

## Git-aware

- With git: `git hash-object <path>` (fast, without reading entire file)
- Without git: `md5 <path>` (fallback)

## Plugin structure

```
claude-atlas/
├── .claude-plugin/
│   └── marketplace.json   # Plugin configuration
├── hooks/
│   ├── hooks.json         # Hook configuration
│   └── check-index.sh     # PreToolUse hook script
├── skills/
│   └── claude-atlas/
│       └── SKILL.md       # Main skill
├── scripts/
│   └── init.sh            # Project initialization
├── examples/
│   ├── file-index.json    # Example index
│   └── atlas-ignore       # Example ignore file
├── README.md
└── LICENSE
```

## Hooks

The plugin includes a `PreToolUse` hook that:
- Intercepts all Glob and Grep calls
- Searches `.claude/file-index.json` for matching entries
- Adds matches as `additionalContext` before the tool executes
- Updates hit/miss statistics automatically

This means the index is checked automatically - no need to invoke the skill manually.

## License

MIT
