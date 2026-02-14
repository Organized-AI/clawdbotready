# Phase 4: mcporter MCP Tool Discovery

## Claude Code Prompt

```
claude --dangerously-skip-permissions

Read PLANNING/OPENCLAW-UPLEVEL-PLAN.md, CLAUDE.md for context.
Verify Phases 1-3 are complete (packages/sandbox, packages/nanoclaw-bridge, packages/clawrouter-bridge).

You are integrating mcporter (https://github.com/Organized-AI/mcporter) as the MCP tool discovery and composition layer for OpenClaw.

## Branch Setup
git checkout main && git pull
git checkout -b feature/mcporter-tools

## Tasks

### 1. Add mcporter to project
- git submodule add https://github.com/Organized-AI/mcporter.git packages/mcporter
- Review architecture: TypeScript, Bun, MCP transports (HTTP, stdio, OAuth)
- Build and verify: cd packages/mcporter && bun install && bun run build

### 2. Create tool registry service
Create packages/tool-registry/src/index.ts:
- On startup, use mcporter to discover all installed MCP servers
- Parse tool definitions from discovered servers
- Generate TypeScript type definitions for each tool
- Maintain live registry of available tools
- Expose registry to Gateway and agent runtime

### 3. Agent tool interface
Create packages/tool-registry/src/agent-tools.ts:
- Provide function-call style interface for agents to invoke tools
- Route tool calls through ClawRouter for model selection if needed
- Handle OAuth caching for authenticated tools
- Implement retry logic with exponential backoff
- Log all tool invocations for analytics

### 4. Daemon mode for stateful servers
Create packages/tool-registry/src/daemon.ts:
- Keep stateful MCP servers warm (chrome-devtools, databases, etc.)
- Health check background processes
- Auto-restart on failure
- Configurable keep-alive intervals

### 5. Tool configuration
Create config/tools.json:
```json
{
  "discovery": {
    "sources": ["claude", "cursor", "codex", "windsurf", "vscode"],
    "auto_discover": true,
    "scan_interval_ms": 60000
  },
  "daemon": {
    "enabled": true,
    "keep_alive_interval_ms": 30000,
    "auto_restart": true
  },
  "permissions": {
    "allow_all": false,
    "allowlist": [],
    "blocklist": []
  }
}
```

### 6. CLI generation for customers
Create scripts/generate-tool-cli.sh:
- Use mcporter to generate CLI binaries for customer-specific tools
- Bundle with type definitions
- Create installation instructions
- Output to dist/tools/ directory

### 7. Integration tests
Create tests/mcporter-integration.test.ts:
- Test MCP server discovery
- Test tool invocation with type safety
- Test OAuth caching
- Test daemon mode keep-alive
- Test fuzzy matching ("Did you mean?")
- Test tool permission enforcement

### 8. Git commit
git add -A
git commit -m "feat: integrate mcporter for MCP tool discovery and composition

- Auto-discover MCP servers from multiple sources
- TypeScript type emission for type-safe tool calling
- Daemon mode for stateful servers
- Tool permission system (allowlist/blocklist)
- CLI generation for customer-specific tooling

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"

## Success Criteria
- [ ] Agent discovers available MCP tools automatically
- [ ] Tools are callable with type-safe interfaces
- [ ] Tool calls route through ClawRouter for cost optimization
- [ ] Stateful servers stay warm via daemon mode
- [ ] Customer can configure which tools are available
```

## Environment Variables for Claude Code Web

```
ANTHROPIC_API_KEY=sk-ant-...
```

mcporter discovers tools from local config files — no additional API keys needed for discovery itself. Individual MCP servers may need their own credentials.
