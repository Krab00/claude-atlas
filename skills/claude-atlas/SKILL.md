---
name: claude-atlas
description: File index for Claude Code - checks local index before using Glob/Grep to find files. Reduces search time and context usage.
license: MIT
metadata:
  author: Krab00
  tags: index, search, optimization, file-map, caching
---

# claude-atlas

Project file index - a map with descriptions of what's where.

## Main Rule

**BEFORE using Glob, Grep or Task(Explore) to search for a file:**

1. Check if `.claude/file-index.json` exists
   - Doesn't exist → suggest onboarding (see below)
   - Exists → go to step 2
2. Read the index and search:
   - By key (exact match)
   - By tags (contains on words)
3. Found? → Use the path from index, skip Glob/Grep
4. Not found? → Use Glob/Grep, then add result to index

## Onboarding

On first search in a project without index:

```
No file map found for this project.
Create .claude/file-index.json?
```

If user agrees:
1. Create `.claude/file-index.json` with empty object `{}`
2. Create `.claude/atlas-stats.json` with statistics
3. From now on, automatically add files to index

## Lookup - searching the index

```javascript
// Pseudocode
function lookup(query) {
  const index = readJSON(".claude/file-index.json");

  // 1. Exact match on key
  if (index[query]) {
    return index[query];
  }

  // 2. Search in tags
  for (const [key, entry] of Object.entries(index)) {
    if (entry.tags.includes(query)) {
      return entry;
    }
  }

  return null;
}
```

**Example:**
- Query: "oauth"
- Finds: `{"path": "src/auth/oauth.ts", "tags": "oauth google login..."}`

## Validation - checking freshness

After finding an entry in the index, validate the hash:

```bash
# With git (preferred)
git hash-object <path>

# Without git (fallback)
md5 -q <path>   # macOS
md5sum <path>   # Linux
```

- Hash matches → file is current, use tags
- Hash differs → file has changed:
  1. Read file
  2. Generate new tags
  3. Update index entry

## Update - updating the index

After reading a file (if project has index):

1. Generate key (short name, e.g., filename without extension)
2. Generate tags - keywords describing content:
   - Main functions/classes
   - Used libraries
   - File purpose
   - Important concepts
3. Calculate hash
4. Save to index

**Tag format:** Loose keywords separated by spaces.

```json
{
  "oauth": {
    "path": "src/auth/oauth.ts",
    "tags": "oauth google github login refresh token authentication passport",
    "hash": "a1b2c3d4e5f6"
  }
}
```

## Statistics

File `.claude/atlas-stats.json`:

```json
{
  "lookups": 0,
  "hits": 0,
  "misses": 0,
  "updates": 0,
  "last_review": null
}
```

Update on each operation:
- `lookups` - each index check
- `hits` - found in index
- `misses` - not found, used Glob/Grep
- `updates` - added/updated entry
- `last_review` - timestamp of last change review

## Change Review (optional, session start)

At session start you can:

1. Check changes since last time:
   ```bash
   git diff --name-status HEAD@{<last_review>}
   ```

2. For each file:
   - **A (added)** - add to "to index" list
   - **M (modified)** - mark hash as stale
   - **D (deleted)** - remove from index

3. Update `last_review` in stats

## Ignoring files

Check `.claude/atlas-ignore` before adding to index.
Syntax like `.gitignore`:

```
node_modules/
*.min.js
dist/
coverage/
.git/
*.lock
```

## Example flow

### User asks: "Where is login handling?"

1. **Check index** - search "login", "auth", "authentication"
2. **Found:** `auth: {path: "src/auth/oauth.ts", tags: "login..."}`
3. **Validate hash** - `git hash-object src/auth/oauth.ts`
4. **Hash OK** → Answer: "Login handling is in `src/auth/oauth.ts`"
5. **Update stats:** `lookups++`, `hits++`

### User asks: "Where is payment handling?"

1. **Check index** - search "payment", "stripe", "billing"
2. **Not found** → Use Grep
3. **Grep finds:** `src/payments/stripe.ts`
4. **Read file, add to index:**
   ```json
   "stripe": {
     "path": "src/payments/stripe.ts",
     "tags": "payment stripe checkout subscription webhook",
     "hash": "abc123"
   }
   ```
5. **Update stats:** `lookups++`, `misses++`, `updates++`

## Best practices

1. **Don't index everything** - only files that make sense (source code, config)
2. **Tags should be specific** - "stripe webhook payment" > "payment file"
3. **Keys should be unique** - if conflict, add prefix (e.g., "auth-middleware", "api-middleware")
4. **Regularly check stats** - low hit rate = weak tags or missing entries

## Helper commands

```bash
# Show statistics
cat .claude/atlas-stats.json | jq

# Count index entries
cat .claude/file-index.json | jq 'keys | length'

# Hit rate
cat .claude/atlas-stats.json | jq '.hits / .lookups * 100'
```
