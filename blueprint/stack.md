# AI OS — Runtime Stack Map

*The definitive reference for how the AI OS runs in production.*
*Every tool has one job. No overlap. Each client gets this full setup, completely isolated.*

**Related:** `blueprint/architecture.md` (the 8-layer architecture this implements) · `blueprint/onboarding.md` (how new clients are set up on this stack)

---

## Stack at a Glance

```
┌─────────────────────────────────────────────────────────────────────┐
│                         CLIENTS                                     │
│          Telegram · WhatsApp · Slack · Email · Web                  │
│          How clients interact with their AI OS                      │
└──────────────────────────┬──────────────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────────────┐
│  PAPERCLIP — THE OPERATOR                    Always on (local/VPS)  │
│  1 company per business · multiple specialist agents                │
│                                                                     │
│  ┌──────────────┐ ┌───────────────┐ ┌────────────┐ ┌─────────────┐ │
│  │  Heartbeat    │ │    Agent      │ │  Session   │ │   Org       │ │
│  │  scheduler    │ │  reasoning    │ │  memory    │ │  chart      │ │
│  │              │ │               │ │            │ │             │ │
│  │ Daily/weekly │ │ Claude Code   │ │ Persistent │ │ CEO →       │ │
│  │ /monthly     │ │ via claude_   │ │ between    │ │ specialists │ │
│  │ heartbeats   │ │ local adapter │ │ heartbeats │ │ + budgets   │ │
│  └──────────────┘ └───────────────┘ └────────────┘ └─────────────┘ │
│                                                                     │
│  Agents inherit CLAUDE.md via cwd · dashboard at localhost:3100     │
└───────┬──────▲────────────────────────────────┬──────▲──────────────┘
        │      │                                │      │
        ▼      │                                ▼      │
┌──────────────────────────────┐  ┌──────────────────────────────────┐
│  N8N — THE PLUMBING          │  │  PINECONE — AI MEMORY ONLY       │
│  Always on (VPS)             │  │  Always on (cloud)               │
│                              │  │                                  │
│  ┌────────────┐ ┌──────────┐ │  │  ┌────────────┐ ┌─────────────┐ │
│  │  Inbound   │ │ Outbound │ │  │  │ Embeddings │ │     RAG     │ │
│  │  hooks     │ │ actions  │ │  │  │            │ │  retrieval  │ │
│  │            │ │          │ │  │  │ Chunked    │ │             │ │
│  │ Stripe     │ │ Send     │ │  │  │ docs from  │ │ Query at    │ │
│  │ Forms      │ │ Update   │ │  │  │ proposals, │ │ runtime for │ │
│  │ CRM events │ │ Create   │ │  │  │ reports,   │ │ relevant    │ │
│  │ Email      │ │ Invoice  │ │  │  │ meeting    │ │ context     │ │
│  └────────────┘ └──────────┘ │  │  │ notes      │ │             │ │
│                              │  │  └────────────┘ └─────────────┘ │
│  Credential vault            │  │                                  │
│  Signature verification      │  │  NOT a document store            │
│  Saves AI tokens on          │  │  AI recall only                  │
│  data transforms             │  │  Originals stay in client's      │
│                              │  │  Drive / Notion / own tools      │
└──────────┬───────▲───────────┘  └──────────▲───────────────────────┘
           │       │                         │
           ▼       │                         │ Embed from
┌─────────────────────────────────────────────────────────────────────┐
│  CLIENT'S OWN TOOLS                                                 │
│  Gmail · Drive · Stripe · Calendars · CRM · Ad platforms            │
│  Source of truth for all documents and data — client controls these  │
└─────────────────────────────────────────────────────────────────────┘


═══════════════════════════════════════════════════════════════════════
  Your team opens these to build, improve, and evolve each client's
  AI OS. Nothing below this line runs in production.
═══════════════════════════════════════════════════════════════════════


┌────────────────────┐  ┌────────────────────┐  ┌───────────────────┐
│  CLAUDE CODE       │  │  ANTIGRAVITY IDE   │  │  GIT REPO         │
│  The engineer      │  │  The scaler        │  │  The handoff      │
│                    │  │                    │  │                   │
│  Deep work         │  │  Parallel work     │  │  1 repo per       │
│  Single client     │  │  Multi-client      │  │  client           │
│  focus             │  │  batch ops         │  │                   │
│                    │  │                    │  │  The contract     │
│  • Strategy +      │  │  • Agent Manager   │  │  between          │
│    workflow        │  │    for parallel    │  │  engineering      │
│    authoring       │  │    tasks           │  │  and production   │
│  • Onboarding +    │  │  • Browser testing │  │                   │
│    context files   │  │    + UI validation │  │  Claude Code and  │
│  • Debugging +     │  │  • Template        │  │  Antigravity      │
│    architecture    │  │    rollouts to     │  │  write to it.     │
│  • Embed docs      │  │    all clients     │  │  Paperclip reads   │
│    into Pinecone   │  │                    │  │  from it.         │
│                    │  │                    │  │                   │
└────────┬───────────┘  └─────────┬──────────┘  └─────────┬─────────┘
         │                        │                        │
         └────────────────────────┼────── push ───────────▶│
                                  └─────── push ──────────▶│
                                                           │
                                              git pull ────┘
                                                   │
                                                   ▼
                                          Paperclip picks up
                                          changes on next
                                          task run
```

---

## Each Tool's One Job

| Tool | Role | One-liner | Runs |
|------|------|-----------|------|
| **Paperclip** | The operator | Orchestrates specialist agents on heartbeat schedules, manages budgets and org chart | 24/7 (local or VPS) |
| **n8n** | The plumbing | Catches webhooks, holds credentials, executes API calls | 24/7 on VPS |
| **Pinecone** | The memory | Stores embeddings for AI recall — not a document store | 24/7 (cloud) |
| **Claude Code** | The engineer | Deep single-client work — strategy, workflows, onboarding | On demand |
| **Antigravity** | The scaler | Parallel multi-client batch work via Agent Manager | On demand |
| **Git repo** | The handoff | Contract between engineering (write) and production (read) | Passive |

---

## Per-Client Isolation

Every client gets their own fully isolated instance of the stack:

| Component | Per-client instance |
|-----------|-------------------|
| Git repo | 1 repo, forked from `ai-os-template-v1` |
| Paperclip | 1 company with its own agents, budgets, and org chart (multi-company isolation built in) |
| Pinecone | 1 namespace in shared Pinecone index |
| n8n | 1 set of webhook flows (client-specific routes) |
| Client tools | Their own — Gmail, Drive, Stripe, CRM (we connect, never migrate) |

No client can see another client's data, context, or AI responses.

---

## Data Flow

### Event-driven flow (webhook → action)

```
External event (Stripe payment fails, form submitted, new email)
    │
    ▼
n8n catches webhook
    │── Verifies signature (Stripe, GitHub, etc.)
    │── Extracts relevant data
    │── Transforms payload into clean summary
    │
    ▼
n8n calls Paperclip /hooks/wake
    │── "Payment failed for Client X, £2,400, invoice #1234"
    │
    ▼
Paperclip agent wakes up
    │── Reads client context files (business.md, rules.md, clients/)
    │── Queries Pinecone for relevant history
    │── Reasons over everything
    │── Decides what to do
    │
    ├──▶ n8n: "Send chase email via Gmail API"
    ├──▶ Session memory: "Logged payment chase for Client X"
    └──▶ Channel delivery: "Notified account owner via Telegram"
```

### Scheduled flow (cron → briefing)

```
Cron fires at 07:00 weekday
    │
    ▼
Paperclip agent wakes up
    │── Reads context/business.md, memory/leads.md, memory/clients.md
    │── Checks Gmail via built-in tools (new emails since yesterday?)
    │── Checks calendar (meetings today?)
    │── Queries Pinecone (any relevant historical context?)
    │
    ▼
Produces morning briefing
    │
    ▼
Delivers via Telegram / WhatsApp / email to client
    │
    ▼
Logs to logs/tasks.md
```

### Engineering flow (improvement → deploy)

```
Team member identifies improvement needed
    │
    ▼
Opens Claude Code (deep work) or Antigravity (batch work)
    │── Rewrites strategy, adds workflow, updates context
    │── Tests locally
    │
    ▼
Git commit + push to client's repo
    │
    ▼
Paperclip picks up changes on next task run
    │
    ▼
Client's AI OS now operates with updated intelligence
```

---

## Two Patterns: n8n ↔ Paperclip

### Pattern A — n8n triggers Paperclip

External event → n8n catches, verifies, extracts → calls Paperclip webhook with clean summary → Paperclip reasons and acts.

**Use when:** Something happens in the outside world that the AI needs to know about.

**Examples:**
- Stripe `payment_intent.failed` → n8n extracts customer + amount → Paperclip runs chase workflow
- Typeform submission → n8n extracts lead details → Paperclip runs lead response workflow
- Calendar event created → n8n extracts meeting details → Paperclip preps briefing notes

### Pattern B — Paperclip triggers n8n

Paperclip decides an action is needed → calls n8n webhook to execute → n8n uses stored credentials to make API calls.

**Use when:** The AI has decided what to do and needs to act on an external service.

**Examples:**
- Paperclip drafts chase email → calls n8n → n8n sends via Gmail API
- Paperclip flags overdue invoice → calls n8n → n8n creates follow-up task in CRM
- Paperclip generates report → calls n8n → n8n uploads to client's Google Drive

---

## Pinecone: AI Memory, Not Document Storage

Pinecone stores **embeddings** (numerical representations of text), not documents.

```
Client creates a proposal
    │
    ├──▶ Original stays in Google Drive (client's source of truth)
    │
    └──▶ Text is chunked and embedded into Pinecone (AI recall only)
             │
             └──▶ When Paperclip needs historical context:
                      Query Pinecone → get relevant chunks → use in reasoning
```

**If Pinecone disappeared tomorrow:** You'd lose nothing except the AI's ability to recall old documents quickly. Re-embed from originals and you're back.

**Clients never interact with Pinecone.** They don't know it exists. They just notice their AI seems to remember everything.

---

## Layer Mapping

How the 8-layer architecture (see `blueprint/architecture.md`) maps to the runtime stack:

| AI OS Layer | Implemented by |
|-------------|---------------|
| 1. Context | Git repo — `context/`, `clients/`, `memory/` |
| 2. Data | Pinecone (vector) + client's own tools (structured) |
| 3. Integration | n8n (credentials, webhooks) + Claude Code (MCP servers, tools) |
| 4. Intelligence | Paperclip orchestrates multiple Claude Code agents via `claude_local` adapter |
| 5. Automation | Paperclip heartbeats (scheduled) + n8n (event-driven triggers) |
| 6. Security | Paperclip governance (approval gates, per-agent budgets, role-based access) + n8n credential isolation |
| 7. Observability | Paperclip dashboard (traced conversations, tool call logs) + `logs/` files |
| 8. Learning | Pinecone (compounding knowledge) + `memory/learnings.md` |

---

## Build Phases

### Phase 1 — First client live (Week 1–2)
- Pick one client, run onboarding blueprint, populate context files via Claude Code
- Stand up Paperclip instance on VPS, load context, set cron schedule
- Connect client's messaging channel (Telegram / WhatsApp)
- Spin up n8n, wire first integration (likely email)
- **Outcome:** Client has a working AI that briefs them daily and responds to messages

### Phase 2 — Harden for repeatability (Week 3–4)
- Document the Paperclip ↔ template mapping
- Build repeatable setup playbook: fork template → populate → deploy
- Nail down git workflow and team ownership zones
- **Outcome:** New client setup takes days, not weeks

### Phase 3 — Scale to multiple clients (Month 2–3)
- Stand up clients routinely with isolated stacks
- Build reusable n8n webhook templates
- Start embedding documents into Pinecone per client
- Use Antigravity for parallel batch operations
- **Outcome:** 5–10 clients running with manageable overhead

### Phase 4 — Compounding value (Month 3+)
- Pinecone namespaces growing per client
- Learning layer capturing what works across clients
- Cross-client patterns fed back into base template
- **Outcome:** Every new client benefits from everything you've learned
