---
name: claude-todo
description: "Project-local TODO list with multiple named lists. Activates when user includes the keyword :TODO: in their message. Read the full message, infer intent, and operate on .claude/todo.md or .claude/lists/*.md."
license: MIT
metadata:
  author: Krab00
  tags: todo, memory, tasks, notes, list
---

# claude-todo

Project-local TODO list with multiple named lists. Persists between sessions.

## Trigger

The keyword `:TODO:` anywhere in the user's message activates this skill. Read the entire message and **infer the intent** from context.

## File structure

```
.claude/
├── todo.md              # Default list (always exists)
└── lists/               # Named lists (created on demand)
    ├── bugs.md
    ├── features.md
    └── ideas.md
```

Each list uses the same format:

```markdown
# {name}

## High

## Normal

## Low

## Done
```

## How to infer intent

When you see `:TODO:`, read the rest of the message and decide what the user wants. The keyword can appear anywhere in the message.

### Adding items

If the message contains a task/idea/note to remember:

```
User: "App idea for making salads :TODO:"
User: ":TODO: we need to fix the auth timeout"
User: "high priority :TODO: deploy hotfix to prod"
```

**Logic:**
1. Check if `.claude/lists/` has any named lists
2. If only default `todo.md` exists → add directly to `todo.md`
3. If named lists exist → **ask the user** which list to add to (show available lists)
4. Infer priority from context ("high priority", "critical", "urgent" → High; "maybe", "someday", "low" → Low; otherwise → Normal)
5. Confirm: "Added to {list} ({priority}): {item}"

### Creating a list

If the message asks to create/make a new list:

```
User: ":TODO: create a list"
User: ":TODO: I need a new list for bugs"
```

**Logic:**
1. If the list name is clear from context (e.g. "list for bugs") → ask to confirm name + ask for initial items
2. If no name given → **ask the user** for: list name, optional initial items
3. Create `.claude/lists/{name}.md` with the template
4. Confirm: "Created list: {name}"

### Deleting a list

If the message asks to delete/remove a list:

```
User: ":TODO: delete a list"
User: ":TODO: remove the bugs list"
```

**Logic:**
1. If only default `todo.md` exists → ask if they want to **clear** the default list (don't delete the file)
2. If named lists exist and the target is specified → confirm deletion, then delete `.claude/lists/{name}.md`
3. If named lists exist but no target specified → **ask which list** to delete (show available)
4. Never delete `todo.md` itself, only clear it

### Showing a list

If the message asks to show/display a list:

```
User: ":TODO: show me the bugs list"
User: ":TODO: what's on my list?"
User: ":TODO: show"
```

**Logic:**
1. If a list name is mentioned → read and display `.claude/lists/{name}.md`
2. If no name specified → show default `todo.md`
3. Display open items grouped by priority (skip empty sections)
4. Show item counts per priority level

### Showing all lists

If the message asks about available lists:

```
User: ":TODO: what lists do I have?"
User: ":TODO: show all lists"
```

**Logic:**
1. Read `todo.md` and list all `.claude/lists/*.md`
2. For each: show name and count of open items (`- [ ]`)
3. Format:
   ```
   Your lists:
   - todo (default): 5 items
   - bugs: 3 items
   - ideas: 8 items
   ```

### Marking as done

If the message indicates something is completed:

```
User: ":TODO: done with the auth fix"
User: ":TODO: finished login timeout bug"
```

**Logic:**
1. Search in `todo.md` first (fuzzy match on item text)
2. If not found → search in all `.claude/lists/*.md`
3. Change `- [ ]` to `- [x]`
4. Move the item to `## Done` section
5. Confirm with list name: "Marked as done in {list}: {item}"

### Removing an item

If the message asks to remove/delete a specific item (not a list):

```
User: ":TODO: remove the salad app idea"
```

**Logic:**
1. Search across all lists (fuzzy match)
2. Delete the line
3. Confirm: "Removed from {list}: {item}"

## Parsing rules

- `- [ ]` = open item
- `- [x]` = completed item
- Section = `## Priority` where Priority is High/Normal/Low/Done
- Match items by fuzzy search on text after checkbox

## Best practices

1. **Always ask when ambiguous** - if you're not sure which list or what action, ask
2. **Keep items actionable** - "Fix auth bug" not "Auth has issues"
3. **One item per line** - no multi-line items
4. **Move, don't delete** - completed items go to Done section for history
5. **Fuzzy matching** - "auth bug" matches "Fix critical auth bug"
6. **Create lists/ dir on demand** - if `.claude/lists/` doesn't exist, create it when first named list is needed

## Example session

```
User: "App idea for making salads :TODO:"
Claude: Added to TODO (Normal): App idea for making salads

User: ":TODO: create a list"
Claude: What should I name the list? Any initial items to add?
User: "bugs, and add: fix login timeout, fix auth redirect"
Claude: Created list: bugs
  Added (Normal): fix login timeout
  Added (Normal): fix auth redirect

User: "critical :TODO: auth bypass in production"
Claude: You have multiple lists (todo, bugs). Which one?
User: "bugs"
Claude: Added to bugs (High): auth bypass in production

User: ":TODO: show all lists"
Claude: Your lists:
  - todo (default): 1 item
  - bugs: 3 items

User: ":TODO: show bugs"
Claude:
**bugs**

High (1):
- auth bypass in production

Normal (2):
- fix login timeout
- fix auth redirect

User: ":TODO: done with auth bypass"
Claude: Marked as done in bugs: auth bypass in production

User: ":TODO: delete a list"
Claude: Which list do you want to delete?
  - bugs (2 open items)
User: "bugs"
Claude: Deleted list: bugs (2 open items moved to Done before deletion)
```
