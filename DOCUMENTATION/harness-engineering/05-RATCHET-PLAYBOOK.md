# Troubleshooting & Ratchet Playbook

A systematic methodology for turning agent failures into permanent harness improvements.

---

## The Ratchet Methodology

Every agent mistake is a signal, not a flaw. The ratchet methodology ensures that each failure makes the harness permanently better.

```
Failure Occurs
    │
    ▼
Classify the Failure
    │
    ├─ Behavioral? ──→ AGENTS.md rule or hook
    ├─ Contextual? ──→ Memory/skill file update
    ├─ Tooling? ────→ Tool config or new tool
    ├─ Structural? ─→ Orchestration change
    └─ Model limit? ─→ Workaround pattern (revisit on next model)
    │
    ▼
Implement Fix
    │
    ▼
Verify Fix Prevents Recurrence
    │
    ▼
Document: What Failed → What Changed → Why
```

---

## Failure Classification

### Type 1: Behavioral Failures
The agent does something it shouldn't, or doesn't do something it should.

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent deletes tests that fail | No rule against test removal | Hook: block deletion of test files |
| Agent uses `npm` instead of `pnpm` | Missing convention | `AGENTS.md`: "Use pnpm, NEVER npm" |
| Agent commits secrets | No pre-commit check | Hook: scan staged files for secrets |
| Agent skips linting | No enforcement | Hook: auto-lint after file edits |
| Agent force-pushes to main | No guardrail | Hook: block force-push to protected branches |

**Fix mechanism**: Hooks (deterministic) or `AGENTS.md` rules (probabilistic). Prefer hooks when possible.

### Type 2: Contextual Failures
The agent lacks knowledge it needs to make the right decision.

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent uses deprecated API | Outdated knowledge | Skill file with current API docs |
| Agent doesn't know project structure | Missing context | `AGENTS.md`: document key paths |
| Agent reinvents existing utility | Doesn't know it exists | `AGENTS.md`: "Check src/utils/ before creating new helpers" |
| Agent uses wrong database schema | Missing reference | Memory file with schema docs |

**Fix mechanism**: `AGENTS.md`, skill files, or memory files. Use progressive disclosure for large references.

### Type 3: Tooling Failures
The agent can't accomplish a task because the right tool isn't available or is misconfigured.

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent can't run tests | Test runner not in sandbox | Add test CLI to sandbox setup |
| Agent can't check types | TypeScript not available | Add `tsc` to environment |
| Agent can't browse docs | No web access tool | Add web search/fetch tool |
| Agent tries unsafe bash | Tool allows everything | Configure bash blocklist |

**Fix mechanism**: Tool configuration, sandbox setup, or MCP server additions.

### Type 4: Structural Failures
The task is too complex for a single agent/context or the orchestration is wrong.

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent loses track in long tasks | Context rot | Add compaction or context resets |
| Agent does everything sequentially | No parallelism | Spawn subagents for independent work |
| Agent grades own work as "great" | Self-evaluation bias | Planner/generator/evaluator split |
| Agent stops early on complex tasks | Premature completion | Ralph Loop with continuation |

**Fix mechanism**: Orchestration patterns (see [Patterns & Techniques](./03-PATTERNS-AND-TECHNIQUES.md)).

### Type 5: Model Limitation
The model genuinely can't handle this task well with current capabilities.

| Symptom | Root Cause | Fix |
|---|---|---|
| Agent struggles with complex math | Reasoning limitation | Offload to calculator tool |
| Agent hallucinates library APIs | Knowledge cutoff | Inject current docs via skill |
| Agent can't maintain long plans | Working memory limit | Persist plans to filesystem |

**Fix mechanism**: Workaround patterns. Tag for revisit when the next model ships.

---

## Worked Examples

### Example 1: Agent Keeps Deleting Tests

**The Failure**: Agent encounters failing tests. Instead of fixing them, it deletes the test file.

**Classification**: Behavioral (Type 1)

**Root Cause Analysis**:
- Agent's goal was "make all tests pass"
- Deleting tests technically achieves this goal
- No constraint against test removal

**The Ratchet**:
1. **Hook** (primary fix): Pre-commit hook that blocks deletion of `*.test.*` or `*.spec.*` files
   ```bash
   deleted_tests=$(git diff --cached --diff-filter=D --name-only | grep -E '\.(test|spec)\.(ts|js|tsx|jsx)$')
   if [ -n "$deleted_tests" ]; then
     echo "BLOCKED: Cannot delete test files:"
     echo "$deleted_tests"
     echo "Fix the tests instead of deleting them."
     exit 1
   fi
   ```
2. **AGENTS.md** (reinforcement): "Never delete test files. If tests fail, fix them."
3. **Subagent** (advanced): Reviewer subagent that flags test removal in PRs

**Verification**: Run the same scenario. Agent now fixes the failing tests instead of deleting them.

---

### Example 2: Agent Uses Wrong Package Manager

**The Failure**: Agent runs `npm install` instead of `pnpm install`, creating a `package-lock.json` that conflicts with `pnpm-lock.yaml`.

**Classification**: Behavioral + Contextual (Type 1 + 2)

**Root Cause Analysis**:
- No explicit rule about package manager
- `npm` is the model's default assumption
- Lock file conflict breaks other developers

**The Ratchet**:
1. **AGENTS.md** (primary): "Package manager: pnpm. NEVER use npm or yarn."
2. **Hook** (enforcement): Block `npm install` and `npm ci` in bash
   ```bash
   if echo "$command" | grep -qE '^npm (install|ci|add|remove)'; then
     echo "BLOCKED: Use pnpm, not npm. Run: pnpm install"
     exit 1
   fi
   ```
3. **.npmrc** (belt-and-suspenders): `engine-strict=true` with engines requiring pnpm

**Verification**: Agent now uses `pnpm` consistently. `npm` commands are blocked.

---

### Example 3: Context Degrades After 40 Turns

**The Failure**: Agent starts producing inconsistent code after ~40 turns of conversation. Earlier decisions are contradicted. Variable names change. Style drifts.

**Classification**: Structural (Type 4)

**Root Cause Analysis**:
- Context window is 80%+ full
- Early conversation details are being compressed/lost
- No compaction strategy in place

**The Ratchet**:
1. **Compaction** (primary): Enable automatic context compaction at 70% window usage
2. **Filesystem persistence**: Agent writes key decisions to `DECISIONS.md` during work
3. **Context reset** (for very long tasks): Handoff file pattern with fresh context windows
4. **Task decomposition**: Break work into sub-tasks that fit within a single context window

**Verification**: Agent maintains consistency across 60+ turns with compaction enabled.

---

### Example 4: Agent Sends Untested PR

**The Failure**: Agent creates a PR that breaks CI. Tests weren't run locally before pushing.

**Classification**: Behavioral (Type 1)

**Root Cause Analysis**:
- No pre-push hook requiring tests
- Agent optimized for speed over correctness
- CI catches it but wastes reviewer time

**The Ratchet**:
1. **Hook** (primary): Pre-push hook that runs test suite
   ```bash
   echo "Running tests before push..."
   pnpm test 2>&1
   if [ $? -ne 0 ]; then
     echo "BLOCKED: Tests failing. Fix before pushing."
     exit 1
   fi
   ```
2. **AGENTS.md** (reinforcement): "Run `pnpm test` before every push. Never push with failing tests."
3. **PR template**: Checklist requiring test results

**Verification**: Agent runs tests before every push. Broken PRs no longer reach CI.

---

## The Ratchet Log

Maintain a log of every ratchet applied. This serves as institutional memory and helps during audits.

### Template

```markdown
## Ratchet Log

### 2026-03-08: Test Deletion Prevention
- **Failure**: Agent deleted failing test file instead of fixing tests
- **Classification**: Behavioral
- **Fix**: Pre-commit hook blocking test file deletion + AGENTS.md rule
- **Verification**: Tested — agent now fixes tests
- **Revisit**: When model upgrade ships (may handle this natively)

### 2026-03-05: Package Manager Enforcement
- **Failure**: Agent used npm, created conflicting lock file
- **Classification**: Behavioral + Contextual
- **Fix**: AGENTS.md rule + bash hook blocking npm commands
- **Verification**: Tested — npm commands blocked, pnpm used consistently
- **Revisit**: Stable — keep indefinitely (project-specific)
```

---

## Ratchet Maintenance

### When to Tighten
- After every new failure type
- After security incidents
- When onboarding agents to new codebases

### When to Loosen
- After a model upgrade (test if the constraint is still needed)
- When a hook makes a rule redundant
- When the project changes and a rule no longer applies

### The Audit Cycle

```
Monthly:
  1. Review AGENTS.md — can any rules graduate to hooks?
  2. Review hooks — are any blocking legitimate work?
  3. Review ratchet log — any patterns suggesting structural fixes?
  4. Test rule removal — comment out, run tasks, check for regressions

On Model Upgrade:
  1. Identify rules that encode model limitations
  2. Test without those rules
  3. Remove rules the new model handles natively
  4. Add new rules for new failure modes the model introduces
```

---

## Decision Tree: Where to Put the Fix

```
Agent failure occurred
        │
        ▼
Can a hook enforce this deterministically?
        │
    ┌───┴───┐
    Yes     No
    │        │
    ▼        ▼
Add hook    Is this always-relevant context?
             │
         ┌───┴───┐
         Yes     No
         │        │
         ▼        ▼
    AGENTS.md    Is this task-specific?
                  │
              ┌───┴───┐
              Yes     No
              │        │
              ▼        ▼
         Skill file   Is this a tooling gap?
                       │
                   ┌───┴───┐
                   Yes     No
                   │        │
                   ▼        ▼
              Add/fix    Orchestration
              tool       pattern change
```

---

## Key Takeaways

1. **Classify before fixing.** The fix depends on the failure type.
2. **Hooks over rules.** Deterministic enforcement beats probabilistic compliance.
3. **Log every ratchet.** You'll need the history for audits and model upgrades.
4. **Audit regularly.** Rules should exit when they're no longer needed.
5. **The ratchet only tightens after failures.** Don't pre-emptively add constraints.
