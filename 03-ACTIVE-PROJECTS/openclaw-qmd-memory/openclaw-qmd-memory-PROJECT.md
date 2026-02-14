# OpenClaw QMD Memory Enablement

## Vision
Enable the QMD (Query/Memory Database) semantic search backend on the client Mac Mini's OpenClaw Gateway so the agent can recall past conversations, search workspace documentation, and provide contextually aware responses — with dual embedding providers for resilience.

## Primary User
OpenClaw Gateway agent running on M1 Mac Mini (`openclaw@100.66.145.48`), serving Telegram bot @SAMyosin_bot for two users (Sean Clayton and Jordaaan Hill).

## Success Criteria
- [ ] QMD CLI installed and on PATH
- [ ] Memory backend switched from builtin to QMD
- [ ] Session JSONL files indexed for semantic search (30-day retention)
- [ ] Memory files (MEMORY.md, memory/*.md) indexed
- [ ] Custom docs (TOOLS.md, workspace references) indexed as collections
- [ ] OpenAI embeddings active as primary provider
- [ ] Local GGUF embeddings active as fallback provider
- [ ] `memory_search` tool returns relevant results via Telegram
- [ ] File descriptors stable at ~64 (no EMFILE regression)
- [ ] Gateway boots without blocking on QMD sync
- [ ] Fallback to builtin works if QMD binary is unavailable

## Non-Goals
- Not upgrading the OpenClaw Gateway version (staying on v2026.2.1)
- Not building a custom embedding service
- Not exposing QMD CLI to the agent for direct use
- Not indexing binary files, images, or non-text content
- Not changing the agent model or routing configuration
