# krab00-claude-plugins

Claude Code plugins by Krab00 - file indexing, TODO lists, and more.

## Plugins

| Plugin | Description |
|--------|-------------|
| **claude-atlas** | File index with tags, dependency graph, reduces Glob/Grep usage |
| **claude-todo** | Project-local TODO list, persists between sessions |

## Installation

### Add marketplace

```
/plugin marketplace add Krab00/claude-atlas
```

### Install plugins

```
/plugin install claude-atlas
/plugin install claude-todo
```

### Initialize in project

```bash
# Run init script (creates .claude/ with all files)
~/.claude/plugins/krab00-claude-plugins/scripts/init.sh

# Or let plugins create files on first use
```

---

# claude-atlas

File index for Claude Code - a "map" with descriptions of what's where.

## Problem

Claude Code uses Glob/Grep on every search:
- Takes time
- Uses context
- Repeats same searches

## Solution

Local file index with tags. Claude checks index first, then searches if needed.

## How it works

1. **Hook intercepts Glob/Grep** - checks `.claude/file-index.json`
2. **Found in index** - uses cached path (hit)
3. **Not found** - searches normally, adds result to index (miss)
4. **After reading file** - updates index with tags

## Index structure

```json
{
  "auth": {
    "path": "src/auth/oauth.ts",
    "tags": "oauth google login token authentication",
    "hash": "a1b2c3d4"
  }
}
```

## Dependency graph

Tracks imports in `.claude/graph/`:

```
.claude/graph/
├── oauth.json         # {"deps": ["./config", "jsonwebtoken"]}
└── _reverse.json      # {"oauth": ["login-controller"]}
```

When modifying a file, Claude warns about impact on dependent files.

## Statistics

```bash
# Hit rate
cat .claude/atlas-stats.json | jq '.hits / .lookups * 100'
```

---

# claude-todo

Project-local TODO list with multiple named lists. Persists between sessions.

**Trigger:** Include `:TODO:` anywhere in your message. Claude infers what you want from context.

## Usage

```
User: "App idea for making salads :TODO:"
Claude: Added to TODO (Normal): App idea for making salads

User: "high priority :TODO: fix the login bug"
Claude: Added to TODO (High): fix the login bug

User: ":TODO: show"
Claude: Your TODOs:
  High (1): fix the login bug
  Normal (1): App idea for making salads

User: ":TODO: done with login bug"
Claude: Marked as done: fix the login bug
```

## Multiple lists

```
User: ":TODO: create a list"
Claude: What should I name the list? Any initial items to add?
User: "bugs"
Claude: Created list: bugs

User: ":TODO: fix auth redirect"
Claude: You have multiple lists (todo, bugs). Which one?
User: "bugs"
Claude: Added to bugs (Normal): fix auth redirect

User: ":TODO: show all lists"
Claude: Your lists:
  - todo (default): 1 item
  - bugs: 1 item

User: ":TODO: show bugs"
Claude:
**bugs**
Normal (1):
- fix auth redirect

User: ":TODO: delete a list"
Claude: Which list do you want to delete?
  - bugs (1 open item)
```

## File structure

```
.claude/
├── todo.md              # Default list (always exists)
└── lists/               # Named lists (created on demand)
    ├── bugs.md
    └── ideas.md
```

---

## Project structure (after init)

```
your-project/
└── .claude/
    ├── file-index.json      # atlas: file index
    ├── atlas-stats.json     # atlas: hit/miss stats
    ├── atlas-ignore         # atlas: patterns to ignore
    ├── graph/               # atlas: dependency graph
    │   └── _reverse.json
    ├── todo.md              # todo: default task list
    └── lists/               # todo: named lists
        ├── bugs.md
        └── ideas.md
```

## License

MIT
