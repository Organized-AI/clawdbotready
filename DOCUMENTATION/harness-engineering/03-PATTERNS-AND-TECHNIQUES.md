# Patterns & Techniques

Proven patterns for building effective agent harnesses, from context management to long-horizon autonomous execution.

---

## Context Rot Mitigation

Context rot is the degradation of reasoning quality as the context window fills with accumulated tool outputs, conversation history, and intermediate results.

### Pattern: Compaction

**Problem**: Agent has been working for 30+ turns. Early context is stale. Reasoning quality drops.

**Solution**: Periodically summarize older context and replace verbose history with compact summaries.

```
Turn 1-15: [Detailed conversation]     →  [3-line summary]
Turn 16-30: [Detailed conversation]    →  [3-line summary]
Turn 31+: [Full detail retained]
```

**When to use**: Automatically after N turns, or when context usage exceeds a threshold (e.g., 80% of window).

### Pattern: Tool-Call Offloading

**Problem**: A single `npm test` dumps 2,000 lines into context. Most of it is noise.

**Solution**: Retain head and tail tokens above a threshold. Offload full output to the filesystem.

```
[First 50 lines of output]
...
[Output truncated. Full output saved to /tmp/test-output-abc123.txt]
...
[Last 20 lines of output]
```

The agent can read the full file on-demand if it needs more detail.

**When to use**: Any tool output exceeding ~200 lines.

### Pattern: Progressive Disclosure (Skills)

**Problem**: Loading 50 tool descriptions at startup eats context and degrades tool selection.

**Solution**: Skills reveal instructions and tools only when the current task requires them.

```
Startup:  5 core tools loaded (bash, read, write, edit, search)
Task "run tests": +2 tools loaded (test runner, coverage reporter)
Task "deploy":    +3 tools loaded (deploy CLI, health check, rollback)
```

**When to use**: When you have more than ~10 tools. Ten focused tools outperform fifty overlapping ones.

---

## Long-Horizon Execution

Autonomous work that spans hours, multiple context windows, or complex multi-step processes.

### Pattern: Ralph Loops

**Problem**: Agent declares "I'm done!" when it's not actually done. Early stopping on complex tasks.

**Solution**: Intercept completion attempts and re-inject the original prompt into a fresh context window, forcing continuation against completion goals.

```
┌──────────────────────┐
│   Context Window 1   │
│   Work on task...    │
│   "I'm done!"       │──→ Completion intercepted
└──────────────────────┘
           │
           ▼
    Check: Actually done?
           │
    ┌──────┴──────┐
    No            Yes
    │              │
    ▼              ▼
┌──────────────┐  Done!
│ Context Win 2│
│ Fresh start  │
│ Read state   │
│ from disk    │
│ Continue...  │
└──────────────┘
```

Each iteration starts clean but reads state from filesystem-persisted prior work. The loop continues until acceptance criteria are met.

**When to use**: Tasks expected to take 30+ minutes of agent time, multi-file refactors, feature implementations.

### Pattern: Planning with Self-Verification

**Problem**: Agent dives into implementation without a plan, gets lost halfway through.

**Solution**: Decompose goals into step sequences persisted to disk. Self-verification hooks run predefined test suites and loop failures back to the model.

```
1. Agent writes plan to /tmp/plan.md
2. Agent executes step 1
3. Hook: run verification suite
4. Pass → mark step complete, move to step 2
5. Fail → inject error text into context, agent retries
```

**When to use**: Any task with more than 3 distinct steps.

### Pattern: Planner / Generator / Evaluator Split

**Problem**: Agents consistently grade their own work positively (like students grading their own homework).

**Solution**: Split the workflow into three roles, ideally with separate agents or at minimum separate prompts:

| Role | Job | Key Constraint |
|---|---|---|
| **Planner** | Decompose goal into steps | No implementation |
| **Generator** | Execute the plan | No self-evaluation |
| **Evaluator** | Grade the output | No implementation, adversarial |

The evaluator's job is to find problems. This adversarial dynamic produces better output than self-evaluation.

**When to use**: High-stakes outputs (production deployments, customer-facing content, security-sensitive changes).

### Pattern: Sprint Contracts

**Problem**: Generator and evaluator disagree on what "done" means after work is complete.

**Solution**: Generator and evaluator negotiate done-conditions **before** code writing begins.

```
Sprint Contract:
- [ ] All existing tests still pass
- [ ] New feature has >80% test coverage
- [ ] No TypeScript errors
- [ ] API response time < 200ms
- [ ] README updated with new endpoint docs
```

Both sides agree to these criteria upfront. The evaluator grades only against the contract.

**When to use**: Combined with Planner/Generator/Evaluator split for maximum clarity.

---

## Hook Patterns

### Pattern: Success-Silent, Failure-Verbose

The foundational hook principle:

```bash
result=$(npm run typecheck 2>&1)
if [ $? -ne 0 ]; then
  # FAILURE: inject full error into agent context
  echo "TYPECHECK FAILED:"
  echo "$result"
else
  # SUCCESS: produce no output (zero context cost)
  :
fi
```

This makes feedback nearly free in the common case (most typechecks pass) and directly actionable when there's a problem.

### Pattern: Destructive Command Blocklist

```bash
BLOCKED_PATTERNS=(
  "rm -rf /"
  "git push --force.*main"
  "git push --force.*master"
  "DROP TABLE"
  "DROP DATABASE"
  "git reset --hard"
  "git clean -fd"
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$command" | grep -qE "$pattern"; then
    echo "BLOCKED: '$command' matches destructive pattern."
    echo "This action requires human approval."
    exit 1
  fi
done
```

### Pattern: Auto-Verification After Edit

```bash
on_file_save() {
  local file="$1"
  case "$file" in
    *.ts|*.tsx)
      npm run typecheck 2>&1 | tail -20
      ;;
    *.py)
      python -m py_compile "$file" 2>&1
      ;;
    *.sh)
      shellcheck "$file" 2>&1
      ;;
  esac
}
```

### Pattern: Pre-Commit Quality Gate

```bash
pre_commit() {
  echo "Running pre-commit checks..."

  # Tests must pass
  npm test 2>&1 || { echo "BLOCKED: Tests failing"; exit 1; }

  # No secrets in staged files
  git diff --cached | grep -qE 'API_KEY|SECRET|PASSWORD|TOKEN' && \
    { echo "BLOCKED: Possible secret in commit"; exit 1; }

  # Lint clean
  npm run lint 2>&1 || { echo "BLOCKED: Lint errors"; exit 1; }
}
```

---

## Tool Design Patterns

### Pattern: Focused Tool Menu

**Problem**: 50 tools overwhelm the model. Tool selection accuracy drops.

**Solution**: Curate ~10 focused tools. Each tool name, description, and schema stamps into every request — treat them like prime context real estate.

```
Good (focused):
  read_file, write_file, edit_file, bash, search, web_fetch

Bad (overlapping):
  read_file, read_file_lines, read_file_range, read_file_head,
  read_file_tail, cat_file, view_file, open_file
```

### Pattern: Tool Description as Prompt

Tool descriptions populate the system prompt. This means:
- Sloppy descriptions waste context
- Well-written descriptions guide model behavior
- Malicious MCP tool descriptions can prompt-inject before any interaction

> **Security concern**: Tool descriptions from external MCP servers are untrusted input that lands in your system prompt. Treat them accordingly.

### Pattern: Bash-First Tooling

> "Rather than pre-building tools for every possible action, grant bash access."
> — Simon Willison

Instead of building `check_disk_space`, `run_tests`, `install_package`, `query_database` as separate tools, provide bash and let the model compose commands.

**Exception**: Build dedicated tools when you need:
- Input validation beyond what bash provides
- Structured output parsing
- Rate limiting or cost tracking
- Security boundaries (e.g., read-only database queries)

---

## Context Reset Pattern

For extremely long-running tasks that exceed a single context window.

### The Flow

```
Context Window 1:
  1. Receive task
  2. Create plan
  3. Execute steps 1-5
  4. Write handoff file to disk
  5. Session ends

Handoff File (handoff.md):
  - Original goal: [...]
  - Completed: steps 1-5
  - Current state: [...]
  - Next: steps 6-10
  - Key decisions made: [...]
  - Open questions: [...]

Context Window 2:
  1. Read handoff file
  2. Orient to current state
  3. Execute steps 6-10
  4. Write updated handoff file
  5. Continue or complete
```

This is closer to onboarding a new engineer than traditional memory. The agent starts fresh but reads a briefing document that captures everything it needs.

**When to use**: Tasks that take more than ~60 minutes of agent time, or when context quality visibly degrades.
