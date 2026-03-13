# AI OS — 8-Layer Architecture

*This is the blueprint. Every AI OS is built on these 8 layers.*
*Each layer has a distinct purpose. Do not mix concerns between layers.*

---

## 1. Context Layer
**Purpose: Who we are and what we know**

This is the foundation. Without context, the AI is generic and useless.

- **Business knowledge base** — goals, products, processes, people, history
- **Episodic memory** — important events the AI should always remember
- **Runtime state** — what's happening right now, active tasks, current priorities

**Files:** `context/business.md`, `context/processes.md`, `context/rules.md`
**Memory:** `memory/` directory — leads, clients, metrics, learnings

The richer the context, the smarter the AI OS. This layer is what makes it feel like it actually knows the business.

---

## 2. Data Layer
**Purpose: Store, retrieve, and normalise business data**

All business data in one place, regardless of where it came from.

- Central store for all business data (leads, clients, revenue, metrics)
- Source-agnostic — doesn't matter if it came from Gmail, Stripe, or a spreadsheet
- Retrieval interface so the AI can query what it needs
- Data normalisation — consistent structure regardless of source

**Implementation:** Memory files for lightweight tracking. Google Sheets for structured data. SQLite/database for the Telegram runtime tier.

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

---

## 4. Intelligence Layer
**Purpose: Reason over all layers and decide what to do**

The brain. Reads from every other layer and makes decisions.

- Builds understanding from Context + Data + State
- Agentic reasoning — can use tools, search, and take multi-step actions
- Chooses what to do, what to flag, what to ask about
- Gets better over time as the Learning Layer feeds back

**Implementation:** Claude (via Claude Code or API). The CLAUDE.md system prompt assembles context from all layers into every session.

---

## 5. Automation Layer
**Purpose: Act without being asked**

This is what makes it an OS, not a chatbot. Proactive, not just reactive.

- **Scheduled jobs** — things that run on a clock (morning briefing, EOD summary, weekly review)
- **Triggers** — things that react to events (new lead → alert, payment failed → chase)
- **Workflows** — multi-step processes triggered on demand (generate proposal, onboard client)

**Implementation:** Claude Code scheduled tasks for the subscription tier. APScheduler for the Telegram runtime tier. Workflows defined in CLAUDE.md.

---

## 6. Security Layer
**Purpose: Control access and protect the business**

Guardrails on what the AI can do autonomously vs what needs human approval.

- Who can access the system (user permissions)
- What actions require confirmation before executing
- Audit trail of all AI actions and decisions
- Sensitive data handling rules
- Escalation paths when something is outside the AI's authority

**Implementation:** Rules defined in `context/rules.md`. Confirmation requirements in CLAUDE.md. Audit via memory/learnings.

---

## 7. Observability Layer
**Purpose: Watch the system itself**

Know what the AI OS is doing, how well it's working, and when things break.

- System health — is everything connected and running?
- Task completion tracking — did scheduled jobs actually run?
- Error alerting — flag when something fails
- Performance metrics — response quality, task success rate
- Usage patterns — what's being used, what's not

**Implementation:** Logs, memory tracking, periodic self-assessment during scheduled reviews.

---

## 8. Learning Layer
**Purpose: Get smarter over time**

The compounding advantage. Every interaction makes the AI OS more valuable.

- **Outcome tracking** — was the advice right? Did the proposal land? Did the lead convert?
- **Feedback collection** — what did the user correct or override?
- **Pattern recognition** — what works for this business? What doesn't?
- **Context updates** — update business.md and rules.md based on new learnings
- **Memory consolidation** — turn individual observations into general principles

**Implementation:** `memory/learnings.md` captures insights. Periodic review (weekly/monthly) consolidates learnings into context updates.

---

## How the Layers Work Together

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

**The cycle:**
1. Integration Layer pulls data from external tools
2. Data Layer normalises and stores it
3. Context Layer provides business identity and memory
4. Intelligence Layer reasons over everything and decides what to do
5. Automation Layer executes scheduled/triggered tasks
6. Security Layer guards all actions
7. Observability Layer watches the whole system
8. Learning Layer feeds improvements back into Context and Intelligence

---

## Related Documents

- `blueprint/stack.md` — how this architecture maps to the runtime stack (OpenClaw, n8n, Pinecone, tooling)
- `blueprint/onboarding.md` — the structured discovery process for onboarding a new client onto this architecture
