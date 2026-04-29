# AI OS — Runtime Stack Map

*The definitive reference for how the AI OS runs in production.*
*The base stack is deliberately minimal. Everything else is optional and added per client.*

**Related:** `blueprint/architecture.md` (the 4-layer architecture this implements) · `workflows/client-mapping.md` (how new clients are mapped onto this stack)

---

## The Core Stack

Three things. Nothing else is required to run a working AI OS.

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENT INTERFACE                            │
│           Email · CLI · Whatever messaging channel they prefer      │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  VPS — THE HOST                                  Always on          │
│  1 box per client · isolated repo · own credentials                 │
│                                                                     │
│  ┌──────────────┐ ┌───────────────┐ ┌──────────────────────────┐   │
│  │   cron       │ │  Claude Code   │ │  File-based state        │   │
│  │              │ │  (CLI)         │ │                          │   │
│  │              │ │                │ │ JSON, CSV, markdown      │   │
│  │ Schedules    │ │ Reads          │ │ in workflows/<name>/data │   │
│  │ daily/weekly │ │ CLAUDE.md +    │ │                          │   │
│  │ /monthly     │ │ context/ +     │ │ Trivial to inspect,      │   │
│  │ jobs         │ │ memory/        │ │ back up, restore         │   │
│  └──────────────┘ └───────────────┘ └──────────────────────────┘   │
│                                                                     │
│  Each workflow folder is self-contained: config.py, scripts/, data/ │
└─────────────────────────────────────────────────────────────────────┘
```

That's it. The base stack is **VPS + cron + Claude Code** with file-based state on disk.

---

## The Tools

| Tool | Job | What it does | Lifecycle |
|------|-----|--------------|-----------|
| **VPS** (Hetzner / DigitalOcean) | The host | Single Linux box per client. Runs cron and stores the repo. | Always on (~£20/mo) |
| **cron** | The scheduler | Triggers workflow scripts on schedule. Single source of timing truth. | Always on |
| **Claude Code (CLI)** | The reasoning + the engineer | Invoked via subprocess inside workflow scripts to reason. Also used by the team to author and debug. Reads `CLAUDE.md` + `context/` + `memory/`. | Per-invocation |
| **Workflow scripts** | The execution engine | bash + python orchestrators in `workflows/<name>/scripts/`. Read state, call Claude, write state back. | Triggered by cron |
| **Git (GitHub)** | The handoff | Versions config, scripts, context. Engineers push, VPS pulls. | Persistent |

---

## How It Runs (cron-driven)

```
cron fires at scheduled time
       │
       ▼
workflow orchestrator script runs (e.g. run_daily_<name>.sh)
       │
       ├─► reads workflows/<name>/config.py
       ├─► reads state files in workflows/<name>/data/
       ├─► invokes Claude CLI with relevant context
       ├─► calls external APIs directly (Gmail, etc.)
       ├─► writes new state back to workflows/<name>/data/
       └─► appends to logs/<workflow>/run-YYYY-MM-DD.log
```

---

## Engineer-Driven Changes

```
Engineer updates workflow code or config in Claude Code
       │
       ▼
Push to git (GitHub)
       │
       ▼
VPS pulls (manually or via webhook)
       │
       ▼
Next scheduled run picks up the new code
```

---

## Optional Add-Ons (Per Client, As Needed)

The base stack covers most clients. Add these only when a specific client requires them.

| Add-on | When to add | What it does |
|--------|-------------|--------------|
| **n8n** | When event-driven webhooks are needed (Stripe, form submissions, CRM events) | Catches external events, verifies signatures, holds credentials, triggers workflow scripts |
| **Pinecone** | When vector recall over a large document corpus is needed (proposals, meeting notes, past reports) | Embeddings for AI recall (RAG) |
| **Supabase** | When state backup / disaster recovery is required | Daily backups of workflow state files |
| **MCP servers** | When deeper integration with a specific tool is needed | Tool-specific Claude Code extensions |

These are documented and configured per client during the build phase. They are NOT part of the base template.

---

## Layer Mapping

How the 4-layer architecture (see `blueprint/architecture.md`) maps to the core stack:

| AI OS Layer | Implemented by (core) |
|-------------|----------------------|
| 1. Context | Git repo — `context/`, `clients/`, `memory/`, `logs/`, `context/rules.md` |
| 2. Data | File-based state in `workflows/<name>/data/` + client's own tools (structured) + `data/schema.md` for normalisation |
| 3. Integration | Direct API calls from scripts using stored credentials in `.credentials/` |
| 4. Automation | cron (scheduled) + workflow scripts (the execution engine) + Claude CLI (the reasoning) |

---

## Why This Stack

1. **No orchestrator overhead.** cron + scripts + Claude CLI is well-understood, debuggable, and runs on a cheap VPS.
2. **File-based state.** All workflow state lives as JSON/CSV/markdown. Trivial to inspect, back up, and restore.
3. **Claude where it adds value.** The CLI is invoked only when reasoning is needed. The plumbing around it is plain scripts.
4. **Optionals stay optional.** No n8n, Pinecone, or Supabase by default. Add only when a specific client needs them.
5. **Git is the contract.** Engineers push, VPS pulls. No deploy pipelines, no Docker registries.

---

## Onboarding a New Client onto This Stack

1. Provision a VPS (run `scripts/bootstrap-vps.sh`)
2. Clone the AI OS template repo onto the VPS
3. Run `scripts/init-client.sh` to populate placeholders
4. Run `workflows/client-mapping.md` to discover their business
5. Set up OAuth tokens for required integrations (Gmail, Calendar, etc.) in `.credentials/`
6. Configure cron schedules per the mapping roadmap
7. Run `scripts/doctor.sh` to verify the deployment is healthy
8. Add any required optionals (n8n / Pinecone / Supabase) per the mapping recommendations
9. Hand over: client gets messaging channel, engineer gets git access
