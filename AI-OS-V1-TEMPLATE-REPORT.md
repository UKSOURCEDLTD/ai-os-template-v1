# AI OS Template v1 — Complete Report

**Date:** 2026-03-21
**Version:** v1.0
**Repository:** ai-os-template-v1

---

## Executive Summary

The AI OS Template v1 is a production-ready framework for building an AI-powered business operating system using Claude Code. It provides a structured, file-based architecture that turns Claude into a persistent intelligence layer — one that knows your business, runs workflows, tracks leads, manages clients, and gets smarter over time.

This is not a chatbot template. It is a full operating system blueprint designed for service-based businesses that want AI running their operations, not just answering questions.

---

## Template Statistics

| Metric | Count |
|--------|-------|
| Total directories | 15 |
| Total files | 40+ |
| Architecture layers | 8 |
| Pre-built workflows | 7 |
| Data schemas | 5 |
| Built-in skills | 2 |
| Memory files | 4 |
| Log files | 2 |

---

## Architecture Overview

The AI OS is built on an **8-layer architecture**, where each layer has a distinct purpose and no concerns are mixed between layers.

### The 8 Layers

| # | Layer | Purpose | Implementation |
|---|-------|---------|----------------|
| 1 | **Context** | Who we are and what we know | `context/` files, `memory/` directory |
| 2 | **Data** | Store, retrieve, and normalise business data | Pinecone (vector) + client tools (structured) |
| 3 | **Integration** | Connect to the outside world | n8n (credentials, webhooks) + OpenClaw (MCP, tools) |
| 4 | **Intelligence** | Reason over all layers and decide what to do | OpenClaw agent (Claude model at runtime) |
| 5 | **Automation** | Act without being asked | OpenClaw cron + n8n event-driven triggers |
| 6 | **Security** | Control access and protect the business | Rules, credential isolation, per-client isolation |
| 7 | **Observability** | Watch the system itself | `logs/` directory + session logs |
| 8 | **Learning** | Get smarter over time | Pinecone + `memory/learnings.md` |

### How They Interact

```
                    ┌─────────────────┐
                    │  7. Observability │ ← watches everything
                    └────────┬────────┘
                             │
┌──────────┐    ┌────────────┴────────────┐    ┌──────────┐
│ 1.Context │───→│    4. Intelligence       │←───│ 8.Learning│
│           │    │    (the brain)           │    │           │
└──────────┘    └──┬──────────┬──────────┘    └──────────┘
                    │              │
              ┌─────┴────┐   ┌────┴──────┐
              │ 2. Data   │   │5.Automation│
              └─────┬────┘   └───────────┘
                    │
              ┌─────┴────────┐
              │ 3.Integration │ ← external tools & APIs
              └──────────────┘
                    │
              ┌─────┴────┐
              │ 6.Security │ ← guards all actions
              └───────────┘
```

**The cycle:** Integration pulls data → Data normalises it → Context provides identity → Intelligence reasons and decides → Automation executes → Security guards actions → Observability watches everything → Learning feeds improvements back.

---

## Runtime Stack

The template runs on a production stack with clear separation of concerns:

| Tool | Role | One-liner | Runs |
|------|------|-----------|------|
| **OpenClaw** | The operator | Runs workflows, responds to clients, updates state | 24/7 on VPS |
| **n8n** | The plumbing | Catches webhooks, holds credentials, executes API calls | 24/7 on VPS |
| **Pinecone** | The memory | Stores embeddings for AI recall — not a document store | 24/7 (cloud) |
| **Claude Code** | The engineer | Deep single-client work — strategy, workflows, onboarding | On demand |
| **Antigravity IDE** | The scaler | Parallel multi-client batch work via Agent Manager | On demand |
| **Git repo** | The handoff | Contract between engineering (write) and production (read) | Passive |

### Per-Client Isolation

Every client gets a fully isolated stack instance:
- 1 Git repo (forked from this template)
- 1 OpenClaw agent instance
- 1 Pinecone namespace
- 1 set of n8n webhook flows
- Their own tools (Gmail, Drive, Stripe, CRM)

No client can see another client's data, context, or AI responses.

### Data Flow Patterns

**Pattern A — n8n triggers OpenClaw:** External event → n8n catches/verifies/extracts → calls OpenClaw with clean summary → OpenClaw reasons and acts.

**Pattern B — OpenClaw triggers n8n:** OpenClaw decides action needed → calls n8n webhook → n8n uses stored credentials to execute API calls.

---

## Complete File Map

```
ai-os-template-v1/
├── CLAUDE.md                         ← System prompt — the AI's identity and instructions
├── README.md                         ← Quick start guide for new users
│
├── blueprint/                        ← Architecture & engineering reference
│   ├── architecture.md               ← 8-layer architecture (the "what")
│   ├── stack.md                      ← Runtime stack map (the "how")
│   └── onboarding.md                 ← 8-phase client discovery process
│
├── context/                          ← Business knowledge base (read every session)
│   ├── business.md                   ← Identity, products, customers, goals, people
│   ├── processes.md                  ← Step-by-step business operations
│   ├── integrations.md               ← Tool stack, data map, connections
│   └── rules.md                      ← Hard rules — non-negotiable
│
├── clients/                          ← One folder per active client
│   ├── README.md                     ← Conventions and folder structure guide
│   └── Example/                      ← Template showing expected file layout
│       ├── profile.md                ← Who they are, contract, contacts
│       ├── performance.md            ← KPIs and monthly metrics
│       ├── actions.md                ← Open tasks, decisions, meeting notes
│       └── ppc/                      ← Service-specific subfolder (optional)
│           ├── strategy.md           ← Service strategy document
│           └── action-plan.md        ← Service action plan
│
├── data/                             ← Data layer
│   ├── schema.md                     ← Normalised field definitions (5 schemas)
│   ├── sources.md                    ← Connected APIs and data sources
│   ├── historical/                   ← Monthly snapshots, organised per client
│   └── vector/
│       └── index.md                  ← Vector store config and embed manifest
│
├── integrations/                     ← Tools and capabilities
│   ├── mcps/
│   │   ├── index.md                  ← MCP server registry
│   │   └── TEMPLATE.md               ← Template for documenting new MCPs
│   └── skills/
│       ├── index.md                  ← Skill module registry
│       ├── google-workspace.md       ← Gmail, Calendar, Drive, Sheets, Docs, Tasks
│       └── web-search.md             ← Research, lead intel, competitor monitoring
│
├── workflows/                        ← Operational procedures (7 workflows + template)
│   ├── TEMPLATE.md                   ← Copy this to create custom workflows
│   ├── morning-briefing.md           ← Daily morning briefing
│   ├── eod-summary.md               ← End of day summary
│   ├── weekly-review.md             ← Weekly business review
│   ├── weekly-pipeline-review.md    ← Weekly sales pipeline review
│   ├── generate-proposal.md         ← Prospect proposal generation
│   ├── lead-response.md             ← Inbound lead response
│   └── client-monthly-report.md     ← Client monthly performance report
│
├── memory/                           ← Persistent business intelligence
│   ├── README.md                     ← Maintenance rules and data format
│   ├── leads.md                      ← Active lead pipeline
│   ├── clients.md                    ← Active client status
│   ├── metrics.md                    ← Key numbers and trends
│   └── learnings.md                  ← Insights that compound over time
│
└── logs/                             ← Observability and audit trail (append-only)
    ├── tasks.md                      ← Scheduled task execution log
    └── actions.md                    ← Significant action audit trail
```

---

## Workflows — Detailed Breakdown

The template ships with 7 pre-built workflows plus a template for creating custom ones.

### 1. Morning Briefing (`workflows/morning-briefing.md`)
- **Trigger:** Scheduled weekdays or "morning briefing"
- **What it does:** Scans Gmail for overnight activity, checks today's calendar, reviews active leads and client priorities
- **Output:** Structured briefing with email summary, calendar, lead actions, client priorities, and top 3 priorities for the day

### 2. End of Day Summary (`workflows/eod-summary.md`)
- **Trigger:** Scheduled weekdays or "EOD summary"
- **What it does:** Reviews the day's actions, checks unresolved emails, assesses lead pipeline movement
- **Output:** EOD summary covering completed work, follow-ups for tomorrow, lead updates, decisions made, and memory updates

### 3. Weekly Review (`workflows/weekly-review.md`)
- **Trigger:** Scheduled or "weekly review"
- **What it does:** Full 7-day Gmail scan, calendar review (past + upcoming week), pipeline assessment, client status check, metrics review
- **Output:** Structured weekly summary with wins, blockers, pipeline status, client health, and priorities

### 4. Weekly Pipeline Review (`workflows/weekly-pipeline-review.md`)
- **Trigger:** Scheduled or "pipeline review"
- **What it does:** Deep lead funnel review (stage, last contact, next action, value, likelihood), revenue vs target analysis, client project assessment
- **Output:** Full pipeline report with Hot/Stalled/Cold leads, revenue status, client health, and weekly priorities

### 5. Generate Proposal (`workflows/generate-proposal.md`)
- **Trigger:** "generate proposal for [prospect]"
- **What it does:** Researches the prospect online, identifies service fit, drafts a tailored proposal
- **Output:** Ready-to-review proposal with Situation / Opportunity / Recommendation / Process / Deliverables / Investment / CTA

### 6. Lead Response (`workflows/lead-response.md`)
- **Trigger:** "respond to lead [name]" or new lead flagged
- **What it does:** Extracts lead details, researches their business, drafts personalised response
- **Output:** Email draft + recommended follow-up cadence + pipeline update

### 7. Client Monthly Report (`workflows/client-monthly-report.md`)
- **Trigger:** "generate report for [client]" or end of month
- **What it does:** Pulls monthly metrics, reviews actions taken, assesses account health
- **Output:** Formatted monthly report with performance table, key actions, health assessment, and next month priorities

### Workflow Template (`workflows/TEMPLATE.md`)
- Copy-and-fill template for creating custom workflows
- Includes pre-flight reads, step structure, output template, memory/log updates, and edge cases

---

## Data Schemas

Five normalised data schemas ensure consistency regardless of data source:

### 1. Lead Schema
| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full name of contact |
| `company` | string | Business name |
| `source` | string | Where the lead came from |
| `date_added` | date | When first captured (YYYY-MM-DD) |
| `status` | enum | `new`, `contacted`, `proposal_sent`, `negotiating`, `won`, `lost` |
| `value_estimate` | number | Estimated deal value |
| `next_action` | string | What happens next and when |
| `notes` | string | Any relevant context |

### 2. Client Schema
| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Business / brand name |
| `contact` | string | Primary contact name and email |
| `start_date` | date | When they became a client (YYYY-MM-DD) |
| `retainer` | number | Monthly fee |
| `services` | list | Which services we provide |
| `status` | enum | `active`, `at_risk`, `churned`, `paused` |
| `health_score` | enum | `green`, `amber`, `red` |

### 3. Performance Metric Schema
Customisable per-business with client, period, and flexible metric fields.

### 4. Revenue Record Schema
Period-based revenue tracking with retainer, bonus, and total fields per client.

### 5. Action / Task Schema
| Field | Type | Description |
|-------|------|-------------|
| `date` | date | Date of action (YYYY-MM-DD) |
| `client` | string | Client name (or "internal") |
| `type` | enum | `email`, `proposal`, `report`, `call`, `change`, `decision` |
| `description` | string | What was done |
| `outcome` | string | Result or next step |
| `confirmed_by` | string | Who approved it (if required) |

---

## Integrations

### Built-in Skills

| Skill | Services | Status |
|-------|----------|--------|
| **Google Workspace** | Gmail, Calendar, Drive, Sheets, Docs, Tasks | Active |
| **Web Search** | Real-time web search and URL fetching | Active |

**Google Workspace** provides full read/write access: search/send emails, manage calendar events, search/upload files in Drive, read/write spreadsheets, read/append docs, manage task lists.

**Web Search** enables prospect research, competitor monitoring, fact verification, and real-time data retrieval before every proposal and lead response.

### MCP Server Framework
- Registry at `integrations/mcps/index.md`
- Template (`TEMPLATE.md`) for documenting new MCP servers
- Supports any external tool connection (Stripe, Shopify, Notion, CRM, etc.)

---

## Memory System

Four persistent memory files that grow over time and survive between sessions:

| File | Purpose | Update Trigger |
|------|---------|----------------|
| `leads.md` | Active lead pipeline with stages, values, next actions | New lead identified, status change, follow-up |
| `clients.md` | Active client status with health scores | Health change, onboarding complete, status shift |
| `metrics.md` | Revenue, pipeline value, activity metrics | During reviews, new revenue data, pipeline changes |
| `learnings.md` | Compounding insights (append-only) | Something works/fails unexpectedly, reusable insight |

**Maintenance rules:**
- Update promptly, never batch
- Never delete entries from `learnings.md`
- Archive leads on close (won/lost) to `data/historical/`
- Keep churned clients in `clients.md` until archived
- Use `data/schema.md` field definitions for consistency

---

## Observability & Audit Trail

Two append-only log files provide a complete audit trail:

### Task Log (`logs/tasks.md`)
Tracks every scheduled and manual workflow execution with date, task name, trigger type, status, and notes.

### Action Log (`logs/actions.md`)
Records significant AI actions: emails drafted/sent, proposals generated, leads updated, reports generated, files updated, decisions made, and memory updates. Each entry includes confirmation source and outcome.

---

## Security & Rules

### Universal Rules (Non-Negotiable)
1. Never send external communications without explicit confirmation
2. Never make financial transactions without explicit confirmation
3. Never delete data/files/records without explicit confirmation
4. Always read context files before answering business questions
5. When unsure, ask — never guess
6. Keep all client data confidential — never cross-reference between clients
7. Log important decisions and outcomes to memory

### Business-Specific Rules
Defined during onboarding in `context/rules.md`. Examples include response time SLAs, approval requirements, brand tone enforcement, and escalation thresholds.

---

## Onboarding Process

An 8-phase structured discovery process (`blueprint/onboarding.md`) for setting up new clients:

| Phase | Focus | Output |
|-------|-------|--------|
| 1 | Business Identity | Name, owners, industry, team, history |
| 2 | Products & Services | Offerings, customers, pricing, revenue drivers |
| 3 | Tool Stack Audit | Every tool mapped with purpose, data, API status |
| 4 | Process Audit | Core processes mapped step by step |
| 5 | Data Audit | Where data lives, what reports exist/are needed |
| 6 | Pain Points & Priorities | Bottlenecks, automation wishlist, growth blockers |
| 7 | Automation Design | Scheduled jobs, triggers, workflows designed |
| 8 | Access & Security | Users, permissions, confirmation rules, compliance |

**Output:** Populated `context/` files, client folder under `clients/`, and entry in `memory/clients.md`.

---

## Build Phases

The template includes a 4-phase deployment roadmap:

| Phase | Timeline | Goal | Outcome |
|-------|----------|------|---------|
| 1 | Week 1–2 | First client live | Working AI that briefs daily and responds to messages |
| 2 | Week 3–4 | Harden for repeatability | New client setup takes days, not weeks |
| 3 | Month 2–3 | Scale to multiple clients | 5–10 clients running with manageable overhead |
| 4 | Month 3+ | Compounding value | Every new client benefits from all past learnings |

---

## How to Get Started

1. **Fork and clone** this repo (one repo per business)
2. **Fill in identity** in `CLAUDE.md` (business name, owners, industry, timezone, currency)
3. **Run onboarding discovery** using `blueprint/onboarding.md` — structured conversation that populates all context files
4. **Set up first client** under `clients/` using the Example folder as template
5. **Configure workflows** — replace `[TIME]`, `[DAY]`, `[TIMEZONE]` placeholders with real schedules
6. **Connect integrations** — set up Google Workspace skills and any MCP servers needed
7. **Start operating** — run a morning briefing to test the system

---

## Placeholder Conventions

All template placeholders use `[Square Brackets]`:
- `[Business Name]` → your actual business name
- `[TIME]` → real time (e.g., `07:00`)
- `[DAY]` → real day (e.g., `Friday`)
- `[client-name]` → actual client folder name

HTML comments (`<!-- ... -->`) contain instructions for maintainers.

---

## Design Principles

1. **Know the business** — context files are read before every response
2. **Think commercially** — revenue, growth, and pipeline come first
3. **Be proactive** — flag issues, spot opportunities, suggest actions
4. **Track everything** — memory updated after meaningful interactions
5. **Learn** — record what works and what fails in `memory/learnings.md`
6. **Stay in lane** — confirm before taking irreversible actions
7. **Be specific** — names, numbers, dates, next actions — not vague advice
8. **Use the schema** — structure data consistently using `data/schema.md`
9. **Log your work** — append to `logs/tasks.md` and `logs/actions.md`

---

*This report was auto-generated from a complete analysis of every file in the AI OS Template v1 repository.*
