# AI OS Template v1

A template for building an AI-powered business operating system using Claude Code.

Fork this repo, populate it with your business context, and you have an AI that knows your business, runs workflows, tracks leads, manages clients, and gets smarter over time.

---

## Quick Start

### 1. Fork and clone this repo

One repo per business. Name it something meaningful (e.g., `ai-os-acme-corp`).

### 2. Fill in your identity

Open `CLAUDE.md` and replace the placeholders in the **Identity** section:
- Business name, owners, industry, timezone, currency

### 3. Run the onboarding discovery

Open `blueprint/onboarding.md` and work through each phase. This is a structured conversation — the AI will ask questions and use your answers to populate the context files.

The onboarding process fills in:
- `context/business.md` — who you are, what you do, products, customers, goals
- `context/processes.md` — how your business operates step by step
- `context/integrations.md` — what tools you use and what data lives where
- `context/rules.md` — hard rules the AI must always follow

### 4. Set up your first client

Create a folder under `clients/` using the structure in `clients/README.md`. See `clients/Example/` for the expected file layout.

### 5. Configure workflows

Review the workflow files in `workflows/`. Replace `[TIME]`, `[DAY]`, and `[TIMEZONE]` placeholders with your actual schedule. Add any business-specific workflows using `workflows/TEMPLATE.md`.

### 6. Connect integrations

Set up Google Workspace skills and any MCP servers you need. Document each in `integrations/`. See `integrations/mcps/TEMPLATE.md` for the MCP documentation format.

### 7. Start operating

Run a morning briefing (`workflows/morning-briefing.md`) to test the system. The AI will read your context, check your tools, and produce a structured briefing.

---

## What's in the box

| Directory | Purpose |
|-----------|---------|
| `blueprint/` | Architecture, runtime stack, and onboarding docs |
| `context/` | Business knowledge base — read every session |
| `clients/` | One folder per active client |
| `data/` | Schema, sources, historical snapshots, vector index |
| `integrations/` | MCP servers and skills |
| `workflows/` | Operational procedures the AI follows |
| `memory/` | Persistent business intelligence (leads, clients, metrics, learnings) |
| `logs/` | Append-only task and action audit trail |

See the full file map in `CLAUDE.md`.

---

## Architecture

The AI OS is built on 8 layers. See `blueprint/architecture.md` for the full breakdown.

For the runtime stack (OpenClaw, n8n, Pinecone, tooling), see `blueprint/stack.md`.

---

## Placeholder conventions

All template placeholders use `[Square Brackets]` and should be replaced with real values:
- `[Business Name]` — replace with your actual business name
- `[TIME]` — replace with a real time (e.g., `07:00`)
- `[DAY]` — replace with a real day (e.g., `Friday`)

Placeholders in file paths use `[lowercase-with-dashes]`:
- `clients/[client-name]/` — replace with the actual client folder name

HTML comments (`<!-- ... -->`) contain instructions for maintainers — read them, follow them, then optionally remove them.
