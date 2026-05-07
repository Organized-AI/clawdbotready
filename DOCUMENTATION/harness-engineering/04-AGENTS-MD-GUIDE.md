# AGENTS.md Best Practices

How to write and maintain effective `AGENTS.md` / `CLAUDE.md` files — the rulebook that shapes every agent interaction in your project.

---

## What Is AGENTS.md?

A markdown file at the repository root that lands in every system prompt. It encodes your project's conventions, constraints, and hard-won lessons — the institutional knowledge that the agent needs to do its job correctly.

Other names for the same concept:
- `CLAUDE.md` (Claude Code)
- `AGENTS.md` (generic convention)
- `.cursorrules` (Cursor)
- `CONVENTIONS.md` (some teams)

The name doesn't matter. The discipline does.

---

## The Golden Rule

> **"Pilot's checklist, not style guide."**
> — HumanLayer

Your `AGENTS.md` should be under **60 lines**. Each line competes for the model's attention — more rules diminish each rule's salience. A 500-line `AGENTS.md` is worse than a 30-line one because the model can't hold the entire thing in working memory.

---

## Two Hard-Won Lessons

### 1. Keep It Short

| Length | Effect |
|---|---|
| <30 lines | Every rule gets attention |
| 30-60 lines | Most rules get attention |
| 60-100 lines | Rules start getting ignored |
| 100+ lines | Agent cherry-picks; critical rules missed |
| 500+ lines | Effectively noise |

If your `AGENTS.md` is growing past 60 lines, it's time to:
- Move reference material to separate docs (link, don't inline)
- Promote enforcement-worthy rules to hooks (deterministic > probabilistic)
- Delete rules that haven't prevented a real failure recently
- Use skills for context that's only needed during specific tasks

### 2. Earn Each Line

> **"Every line in a good `AGENTS.md` should be traceable back to a specific thing that went wrong."**

Rules should trace to:
- **A specific past failure**: "Agent kept using `npm` instead of `pnpm`"
- **A hard external constraint**: "Production database is read-only from this environment"
- **A non-obvious convention**: "We use barrel exports, not direct imports"

Rules should NOT come from:
- Brainstorming sessions ("what could go wrong?")
- General best practices ("always write tests" — too vague)
- Redundant model behavior ("be helpful" — it already tries)
- Style preferences with no impact ("prefer single quotes" — use a linter)

**Ratchet, don't brainstorm.**

---

## Structure Template

```markdown
# Project Name

## Stack
- Runtime: Node.js 20+
- Package manager: pnpm (NEVER npm or yarn)
- Language: TypeScript (strict mode)
- Test framework: Vitest
- Linting: ESLint + Prettier

## Critical Rules
- Run `pnpm typecheck` after every file edit
- Never modify files in `src/generated/` — they're auto-generated
- All API endpoints require auth middleware — no exceptions
- Database migrations go in `drizzle/migrations/`, never manual SQL

## Conventions
- Imports: barrel exports from `src/index.ts`, not deep imports
- Error handling: throw typed errors from `src/errors.ts`
- Tests: co-located (`foo.test.ts` next to `foo.ts`)
- Commits: conventional commits (feat/fix/docs/refactor)

## Don't
- Don't add `console.log` — use the logger from `src/logger.ts`
- Don't create new top-level directories without asking
- Don't skip tests — if tests fail, fix them, don't delete them
- Don't commit `.env` files or anything in `.secrets/`
```

This is ~25 lines. Every line earned by a real failure or hard constraint.

---

## What Goes Where

Not everything belongs in `AGENTS.md`. Use the right mechanism for each type of guidance:

| Type of Guidance | Where It Goes | Why |
|---|---|---|
| **Always-on rules** | `AGENTS.md` | Needs to be in every prompt |
| **Enforcement** | Hooks | Deterministic > probabilistic |
| **Task-specific** | Skills / tool prompts | Progressive disclosure |
| **Reference docs** | Separate files, linked | Don't bloat the prompt |
| **Security policy** | exec-approvals / hooks | Must be deterministic |
| **Style/formatting** | Linter config | Tools enforce, not rules |

### The Decision Test

Before adding a line to `AGENTS.md`, ask:

1. **Can a hook enforce this?** → Use a hook instead. Hooks are deterministic. `AGENTS.md` rules are probabilistic.
2. **Is this only needed for specific tasks?** → Put it in a skill file with progressive disclosure.
3. **Is this general knowledge?** → The model probably already knows. Test before adding.
4. **Did this come from a real failure?** → If not, don't add it yet. Wait for the failure.
5. **Will removing this cause a regression?** → If no, remove it.

---

## Anti-Patterns

### The Novel
```markdown
# AGENTS.md

## About This Project
This project was started in 2024 by our team at Acme Corp...
[200 lines of history and context nobody needs]
```
The agent doesn't need your company's origin story.

### The Style Guide
```markdown
- Use 2-space indentation
- Prefer const over let
- Use arrow functions for callbacks
- Single quotes for strings
- Trailing commas in arrays
```
Put this in `.eslintrc` and `.prettierrc`. Linters enforce style deterministically.

### The Wishlist
```markdown
- Always write comprehensive tests
- Make sure code is well-documented
- Consider performance implications
- Think about edge cases
```
These are vague aspirations, not actionable rules. The model already tries to do all of these.

### The Copy-Paste
```markdown
[Rules copied from another project without adapting them]
```
Your harness should reflect YOUR failure history, not someone else's.

### The Kitchen Sink
```markdown
[150 rules covering every conceivable scenario]
```
When everything is important, nothing is. Cut to 60 lines max.

---

## Maintenance Discipline

### Adding Rules

```
1. Agent failure occurs
2. Root-cause the failure
3. Can a hook prevent this? → Add hook, not rule
4. Is it task-specific? → Add to skill file
5. Is it always-relevant? → Add to AGENTS.md
6. Write the rule as a clear, actionable directive
7. Test that the rule changes agent behavior
```

### Removing Rules

```
1. New model release ships
2. Test: does the model still need this rule?
3. Comment out the rule, run typical tasks
4. No regressions? → Delete the rule
5. Regression? → Keep the rule
```

### Auditing

Periodically review every line:
- Can I trace this to a specific failure? Keep it.
- Has this been violated recently despite being here? Maybe a hook is better.
- Is this redundant with a hook or linter? Remove it.
- Is this too vague to act on? Rewrite or remove.

---

## Real-World Example: Evolution

### Week 1 (After first session)
```markdown
# MyApp
- Use pnpm, not npm
- TypeScript strict mode
```

### Week 3 (After agent broke production)
```markdown
# MyApp
- Use pnpm, not npm
- TypeScript strict mode
- Never modify `src/generated/` — auto-generated from schema
- Run `pnpm test` before any commit
```

### Week 6 (After security review)
```markdown
# MyApp
- Use pnpm, not npm
- TypeScript strict mode
- Never modify `src/generated/` — auto-generated from schema
- All API routes must use `authMiddleware()` — no exceptions
- Never commit .env files
```

### Week 10 (After model upgrade)
```markdown
# MyApp
- Use pnpm, not npm
- Never modify `src/generated/` — auto-generated from schema
- All API routes must use `authMiddleware()` — no exceptions
```

Note: "TypeScript strict mode" removed (new model does this by default). "Never commit .env" removed (now enforced by pre-commit hook). "Run tests before commit" removed (now a hook, not a rule).

The rulebook gets **tighter and leaner**, not bigger. Rules graduate to hooks or become unnecessary as models improve.

---

## Key Takeaways

1. **60 lines max.** Pilot's checklist, not operations manual.
2. **Earned, not brainstormed.** Every line traces to a real failure.
3. **Graduate to hooks.** If a rule can be enforced deterministically, it should be.
4. **Prune regularly.** Remove rules that models no longer need.
5. **Your harness, your rules.** Don't copy someone else's `AGENTS.md`.
