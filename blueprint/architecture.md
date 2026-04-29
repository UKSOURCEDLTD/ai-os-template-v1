# AI OS — 4-Layer Architecture

*This is the blueprint. Every AI OS is built on these 4 layers.*
*Each layer has a distinct purpose. Do not mix concerns between layers.*

---

## 1. Context Layer
**Purpose: Who we are and what we know**

This is the foundation. Without context, the AI is generic and useless.

- **Business knowledge base** — goals, products, processes, people, history
- **Memory** — leads, clients, metrics, learnings that persist across sessions
- **Rules & guardrails** — what the AI can do autonomously vs what needs human approval, sensitive data handling, escalation paths
- **Runtime state** — what's happening right now, active tasks, current priorities

**Files:** `context/business.md`, `context/processes.md`, `context/rules.md`
**Memory:** `memory/` directory — leads, clients, metrics, learnings
**Logs:** `logs/` directory — task execution log, action audit trail

The richer the context, the smarter the AI OS. This layer is what makes it feel like it actually knows the business. Rules, security, and learning all live here — they're aspects of context, not separate systems.

---

## 2. Data Layer
**Purpose: Store, retrieve, and normalise business data**

All business data in one place, regardless of where it came from.

- Central store for all business data (leads, clients, revenue, metrics)
- Source-agnostic — doesn't matter if it came from Gmail, Stripe, or a spreadsheet
- Retrieval interface so the AI can query what it needs
- Data normalisation — consistent structure regardless of source

**Implementation:** Memory files for lightweight tracking. Google Sheets for structured data. SQLite/database when scale demands it.

**Schema:** `data/schema.md` defines standard field definitions for consistency across all sources.

---

## 3. Integration Layer
**Purpose: Connect to the outside world**

Every tool the business uses becomes a data source and action channel.

- Individual connectors per tool (Gmail, Calendar, Drive, Stripe, Shopify, etc.)
- Authentication and credential management
- Rate limiting and retry logic
- Sync schedules — how often to pull fresh data
- Each connector feeds normalised data into the Data Layer

**Implementation:** Google Workspace skills (Gmail, Calendar, Drive, Sheets, Docs, Tasks) are built-in. Web search is built-in. Additional integrations (Stripe, Shopify, Notion, etc.) via MCP servers or API calls.

**Credentials:** `.credentials/` directory (gitignored) — OAuth tokens, API keys, env files.

---

## 4. Automation Layer
**Purpose: Act without being asked**

This is what makes it an OS, not a chatbot. Proactive, not just reactive.

- **Scheduled jobs** — things that run on a clock (morning briefing, EOD summary, weekly review)
- **Triggers** — things that react to events (new lead → alert, payment failed → chase)
- **Workflows** — multi-step processes triggered on demand (generate proposal, onboard client)

**Implementation:** cron schedules workflow scripts on the VPS. Each script reads state, invokes Claude Code (CLI) for reasoning, calls APIs directly, and writes state back. Workflows defined in CLAUDE.md and `workflows/`.

**The engine:** Claude Code (CLI) is the reasoning engine. It's not a separate layer — it's invoked from workflow scripts to read Context, query Data, act through Integrations, and execute Automations.

---

## How the Layers Work Together

```
  ┌──────────────────────────────────────────────┐
  │              AI Engine (Claude)               │
  │    Reads all layers, reasons, decides, acts   │
  └──────┬──────────┬──────────┬────────────────┘
         │          │          │
   ┌─────┴────┐ ┌──┴───┐ ┌───┴──────────┐
   │ 1.Context │ │2.Data│ │4.Automation  │
   │           │ │      │ │              │
   │ business  │ │schema│ │ workflows    │
   │ memory    │ │store │ │ schedules    │
   │ rules     │ │query │ │ triggers     │
   │ logs      │ │      │ │              │
   └───────────┘ └──┬───┘ └──────────────┘
                    │
              ┌─────┴────────┐
              │ 3.Integration │
              │               │
              │ Gmail, Sheets │
              │ Stripe, CRM   │
              │ APIs, webhooks │
              └───────────────┘
```

**The cycle:**
1. Integration Layer pulls data from external tools
2. Data Layer normalises and stores it
3. Context Layer provides business identity, rules, and memory
4. AI Engine reasons over everything and decides what to do
5. Automation Layer executes scheduled/triggered/on-demand workflows
6. Results feed back into Context (memory updates) and Data (state changes)

---

## Mapping the Architecture to a Client Build

When onboarding a new client, the mapping process (`workflows/client-mapping.md`) directly populates each layer:

| Mapping Phase | Architecture Layer | What Gets Built |
|--------------|-------------------|-----------------|
| Phase 1: Business & People Map | Context | `context/business.md`, `context/rules.md`, `memory/` |
| Phase 2: Tool Stack & Data Audit | Data + Integration | `data/sources.md`, `context/integrations.md` |
| Phase 3: Process Deep-Dive | Automation | Workflow list, trigger definitions, schedule design |
| Phase 4: Integration Architecture | Integration | API connections, credential setup, optional event plumbing |
| Phase 5: Workflow Roadmap | All layers | Prioritised build plan with delivery timeline |

---

## Related Documents

- `blueprint/stack.md` — how this architecture maps to the runtime stack (VPS + cron + Claude Code)
- `workflows/client-mapping.md` — the 5-phase process for mapping a new client onto this architecture
- `blueprint/workflow-pattern.md` — the canonical pattern every workflow follows
- `blueprint/cold-outreach-system.md` — worked implementation example

---

## Flow of Control (runtime view)

```
  cron trigger
       │
       ▼
  workflow script (e.g. workflows/cold-outreach/scripts/run_daily_outreach.sh)
       │
       ├─► reads config (workflows/<name>/config.py)
       ├─► reads state files (workflows/<name>/data/*.json + .csv)
       ├─► calls external APIs (Gmail, Claude CLI, etc.)
       ├─► writes state back to workflows/<name>/data/
       └─► appends to logs/<workflow>/run-YYYY-MM-DD.log

  Human interaction with Claude
       │
       ▼
  Claude reads CLAUDE.md → context/ → memory/ → relevant workflow/
       │
       ▼
  Claude proposes actions → human confirms → Claude or human executes
       │
       ▼
  Append to logs/actions.md + update memory/ as appropriate
```

---

## Design Principles

1. **File-based state.** JSON + CSV + markdown. No database until you actually need one (millions of rows).
2. **One config file per workflow.** All client-specific strings in one place — never scattered across scripts.
3. **Cron + nohup + file locks.** No orchestrator, no containers, no k8s. A modest VPS runs this.
4. **Read-before-act.** Every workflow script reads state from disk, acts, writes state back. Idempotent where possible. Guarded by file-lock when not.
5. **AI-first docs.** Written for Claude/Gemini as primary readers. Explicit paths, schemas, and "lessons learned" sections.
6. **Bugs get blueprints.** Every production outage is documented in the relevant blueprint so it isn't repeated.

---

## When to Add a New Folder

Resist adding cross-cutting abstractions. If a new concern appears, it maps to one of these homes:

- Is it a **capability** (like cold outreach, content farming)? → new folder under `workflows/`.
- Is it **knowledge about the business**? → new file under `context/`.
- Is it **state that changes over time**? → new file under `memory/` or `data/`.
- Is it **logged activity**? → append to `logs/`.
- Is it **architecture or implementation spec**? → new file under `blueprint/`.
- Is it **a utility used across workflows**? → new script under `scripts/`.
