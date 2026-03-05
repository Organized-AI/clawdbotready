# Phase 4 — MCP Server Setup

## Context
Read CLAUDE.md and PHASE-3-COMPLETE.md first.

## Tasks
1. Check gws MCP server docs: `gws mcp --help` or check GitHub README
2. Configure gws as MCP server (stdio mode preferred for local use)
3. Add to ~/.claude/mcp.json (or project-level .claude/mcp.json):
   { "gws": { "command": "gws", "args": ["mcp"], "type": "stdio" } }
4. Test MCP connection from Claude Code: invoke a Drive list tool
5. Document MCP config in DOCUMENTATION/mcp-setup.md
6. Create CONFIG/mcp-server.json with the config reference

## Success Criteria
- [ ] gws MCP server starts without error
- [ ] Claude Code can invoke gws tools via MCP
- [ ] DOCUMENTATION/mcp-setup.md written
