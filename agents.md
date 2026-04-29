# AI OS — Multi-Agent Configuration

This project is designed to work across multiple AI agents. Each agent has its own instruction file, but **[CLAUDE.md](CLAUDE.md) is the primary system prompt** and single source of truth.

All other agent files inherit from and defer to CLAUDE.md for business context, rules, file structure, and workflows.

---

## Agent Files

| Agent | File | Role |
|-------|------|------|
| **Claude** | [CLAUDE.md](CLAUDE.md) | **Primary** — full system prompt, rules, file map, workflows, and business context |
| **Gemini** | [gemini.md](gemini.md) | Secondary — adapted instructions for Google Gemini, referencing CLAUDE.md as source of truth |

---

## How It Works

1. **CLAUDE.md** contains the complete AI OS configuration — identity, rules, file map, workflows, memory, integrations, and operating instructions.
2. **Other agent files** (e.g. `gemini.md`) are lightweight wrappers that:
   - Point the agent to CLAUDE.md for full context
   - Translate any Claude-specific conventions for that platform
   - Maintain the same rules, structure, and behaviour

This means you only need to maintain **one source of truth** (CLAUDE.md). When the business changes, update CLAUDE.md and all agents stay aligned.

---

## Adding a New Agent

1. Create a new file at the project root (e.g. `copilot.md`, `gpt.md`)
2. Reference CLAUDE.md as the primary instruction set
3. Add any platform-specific adaptations
4. Add the agent to the table above
