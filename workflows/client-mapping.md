# Workflow: Client Mapping

**Trigger:** `"map [client-name]"` or immediately after client signs (Stage 2 of `client-delivery.md`)
**Also triggered by:** `"run discovery for [client-name]"`, `"map processes for [client-name]"`

---

## Pre-flight

Before starting, read:

- `clients/[client-name]/profile.md` — basic client info from kickoff
- `sales/packages.md` — which package they bought (determines mapping depth)
- `blueprint/architecture.md` — the 4-layer architecture we're mapping them onto
- `data/schema.md` — standard field definitions for consistency

**Check package tier to determine depth:**

| Package | Phases | Workflows to map | Duration |
|---------|--------|-------------------|----------|
| **Essentials** (£1.5K + £300/mo) | Phases 1-3 + lightweight 5. Skip formal Phase 4. | 2-3 workflows | 1 session (90 min) |
| **Growth** (£3-5K + £750/mo) | All 5 phases, full depth. | 5-8 workflows | 1-2 sessions (2-3 hrs total) |
| **Partner** (£2K + £1K/mo) | All 5 phases, maximum depth. Full business process map. 90-day roadmap. | 8+ workflows | 2-3 sessions (4-5 hrs total) |

---

## Steps

### 1. Business & People Map → Context Layer

Understand the business as a whole before diving into specifics. This sets the lens for everything that follows.

**Ask / research:**

- **Business model** — What do they sell? To whom? How does money flow in?
- **Revenue streams** — Which are primary? Growing? Declining?
- **Team structure** — Who does what? Who makes decisions? Who is overloaded?
- **Growth goals** — What does success look like in 3, 6, and 12 months?
- **Competitive landscape** — What are competitors doing better or faster?
- **Seasonality** — Busy periods, quiet periods, deadline-driven cycles
- **Communication style** — How do they talk to customers? Internal comms norms?
- **Rules & constraints** — Compliance, brand guidelines, things the AI must never do

**Write output to:** `clients/[client-name]/mapping/business-map.md`
(Use the template at `clients/Example/mapping/business-map.md`)

---

### 2. Tool Stack & Data Audit → Data + Integration Layers

Map every tool the client uses and where their data actually lives. This is where you find the data silos, the copy-paste bridges, and the integration opportunities.

**For every tool they use, capture:**

| Field | What to record |
|-------|---------------|
| Tool name | What it is |
| Purpose | What it's used for |
| Users | Who uses it (role/person) |
| Data held | Specific fields and record types — not vague descriptions |
| Data in | How data gets in (manual entry, import, API, auto-sync) |
| Data out | How data gets out (export, API, reports, copy-paste) |
| API available | Yes/No, type (REST/webhook), auth method |
| Monthly cost | £ |
| Pain points | What's broken or frustrating about this tool |
| Overlap | Duplicates data or function with another tool |

**Then identify the patterns:**

- **Data silos** — Information trapped in one tool that other people or processes need
- **Data gaps** — Metrics, records, or tracking that should exist but doesn't
- **Manual bridges** — Where someone manually copies data between systems (the #1 automation signal)
- **Single points of failure** — Tools only one person knows how to use or administer

**Write output to:** `clients/[client-name]/mapping/data-map.md`
(Use the template at `clients/Example/mapping/data-map.md`)

---

### 3. Process Deep-Dive → Automation Layer

Map every repeating business process. This is the most important phase — it directly produces the list of automation opportunities.

**For every process, capture:**

| Field | What to record |
|-------|---------------|
| Process name | Clear, descriptive name |
| Owner | Who is responsible for this process |
| Frequency | Daily / Weekly / Monthly / Ad hoc / Event-triggered |
| Time per occurrence | Hours or minutes each time it runs |
| Monthly time cost | Frequency × time per occurrence |
| Steps | Numbered list of what actually happens, step by step |
| Tools involved | Which tools from Phase 2 |
| Inputs | What triggers it / what data goes in |
| Outputs | What it produces / who receives it |
| Current state | Manual / Semi-automated / Fully automated |
| Failure modes | What goes wrong, what gets missed, what breaks |
| Dependencies | What must happen before or after this process |
| Value if automated | Time saved + error reduction + speed improvement |
| Complexity | Simple (1-2 steps, existing APIs) / Moderate (multi-step, some custom logic) / Complex (custom builds, multiple integrations, edge cases) |

**Group processes by business function:**

1. **Sales & Lead Generation** — How do they find and close customers?
2. **Client/Customer Onboarding** — What happens when someone buys?
3. **Service Delivery / Fulfilment** — How do they deliver what they sell?
4. **Communication** — Internal comms, client-facing comms, reporting
5. **Finance & Invoicing** — Billing, payments, chasing, reconciliation
6. **Reporting & Analytics** — What numbers do they track? How?
7. **Content & Marketing** — Social, email marketing, brand presence
8. **Admin & Operations** — Everything else that keeps the lights on

**Dig deeper on the high-value processes:**
- "Walk me through exactly what happens, step by step"
- "What happens when this goes wrong?"
- "How long does this take you each time?"
- "If you could wave a magic wand, what would change about this process?"

**Write output to:** `clients/[client-name]/mapping/process-map.md`
(Use the template at `clients/Example/mapping/process-map.md`)

---

### 4. Integration Architecture → Integration Layer

*Skip this phase for Essentials clients — their integrations are simple enough to handle inline during build.*

Based on Phase 2 (tools) and Phase 3 (processes), design the complete integration picture. What connects to what, what data flows where, and what credentials we need.

**For every required connection:**

| Field | What to record |
|-------|---------------|
| From → To | System A → System B |
| Data flowing | Specific fields/records that move |
| Direction | One-way / Bidirectional / Event-triggered |
| Trigger | Schedule (how often) / Event (what event) / On-demand |
| Method | API / Webhook / n8n flow / Manual bridge today |
| Auth required | OAuth2 / API key / Service account / None |
| Complexity | Low (standard connector exists) / Medium (custom field mapping) / High (custom build required) |
| Prerequisites | What needs to be set up first |

**Also produce:**

- **Credential checklist** — Every API key, OAuth token, and access grant we need. Use checkboxes so we can track what's been obtained.
- **Dependency graph** — Which integrations must be connected before others will work (e.g., CRM must be connected before lead routing workflow can run)
- **Risk flags** — Rate limits, API instability, auth expiry, vendor lock-in concerns

**Write output to:** `clients/[client-name]/mapping/integrations.md`
(Use the template at `clients/Example/mapping/integrations.md`)

---

### 5. Workflow Roadmap → Delivery Plan

The payoff. Every automation opportunity from Phase 3, scored, prioritised, and grouped into a buildable, timelockable roadmap.

**Score each opportunity:**

- **Impact** (1-5): How much time, money, or pain does this save?
  - 1 = Minor convenience
  - 3 = Meaningful time saving (hours/week)
  - 5 = Transformative (eliminates a major bottleneck or unlocks growth)
- **Effort** (1-5): How hard is it to build?
  - 1 = Simple automation, existing tools, < 2 hours
  - 3 = Multi-step, some custom logic, half a day
  - 5 = Complex build, multiple integrations, custom agents, 2+ days
- **ROI Score**: Impact × (6 − Effort) — simple formula that favours high-impact, low-effort wins
- **Dependencies**: What integrations or other workflows must exist first?

**Group into delivery tiers:**

| Tier | Timing | What goes here | Purpose |
|------|--------|---------------|---------|
| **Quick Wins** | Week 1 | High impact, low effort, no dependencies | Proves value fast — client sees results immediately |
| **Core System** | Weeks 2-3 | Backbone automations that define the daily operating rhythm | The system that runs every day |
| **Advanced Builds** | Weeks 3-4+ | Complex multi-step workflows, custom agents, advanced integrations | Growth and Partner tiers only |
| **Future Roadmap** | Month 2+ | Nice-to-haves, expansion ideas, things that surfaced during discovery | Feeds into monthly strategy calls |

**Build the delivery timeline:**

| Week | What Gets Built | Integrations Needed | Dependencies | Milestone |
|------|----------------|-------------------|--------------|-----------|
| 1 | [Quick win workflows] | [List] | None | Client sees first automation running |
| 2 | [Core workflows] | [List] | Week 1 complete | Daily operating rhythm established |
| 3 | [Remaining core + advanced] | [List] | Core integrations live | Full system operational |
| 4 | Testing, training, launch | All above | All above | Client handover complete |

**For each recommended workflow, document:**

- **Name** — What we're calling it
- **Problem it solves** — The pain point from discovery (use their words)
- **What it does** — Plain language, one paragraph
- **Trigger** — What starts it (schedule, event, manual)
- **Integrations needed** — From the Phase 4 integration list
- **Estimated build time** — Hours
- **Impact score** — X/5
- **Effort score** — X/5
- **ROI score** — Calculated
- **Tier** — Quick Win / Core / Advanced / Future

**Write output to:** `clients/[client-name]/mapping/roadmap.md`
(Use the template at `clients/Example/mapping/roadmap.md`)

---

### 6. Present for Review

Compile the five mapping documents into a summary and present to the client team.

**Present internally first ({{OWNER_NAMES}}):**
- Does the roadmap make sense given the package tier?
- Are the quick wins genuinely quick?
- Are there any integration risks we haven't flagged?
- Is the timeline realistic?

**Then present to client:**
- Walk through the business map (confirm we understood them correctly)
- Show the process map (confirm priorities)
- Present the roadmap (get sign-off on build order)
- Confirm the delivery timeline

Do not begin building until the client has signed off on the roadmap.

---

### 7. Update Memory and Logs

- Update `clients/[client-name]/profile.md` with any new information from discovery
- Update `clients/[client-name]/actions.md` — log mapping completion and next steps
- Update `memory/clients.md` — status change to "Mapping Complete — Build Starting"
- Log in `logs/actions.md`: "Client [name] — mapping complete — [X] workflows identified — build starting Week [X]"

---

## Expected Output

Five structured documents in `clients/[client-name]/mapping/`:

1. `business-map.md` — Business model, team, goals, rules
2. `data-map.md` — Tool stack, data sources, silos, gaps
3. `process-map.md` — Every process mapped with automation potential scored
4. `integrations.md` — Connection architecture, credential checklist, dependency graph
5. `roadmap.md` — Scored and tiered workflow recommendations with delivery timeline

Plus: client sign-off on the roadmap before build begins.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Client can't articulate their processes clearly | Walk them through their last working day. "What did you do first thing Monday? Then what? What tool did you open?" — reconstruct from behaviour, not theory. |
| Too many processes to map in one session | Prioritise by pain. Ask "What are the 3 things that eat most of your time?" Map those first. Schedule a follow-up for the rest. |
| Client wants to skip discovery and jump to building | Explain: "We build the wrong thing if we don't map first. This is how we make sure every hour of build time creates maximum value." |
| Client's tools have no API | Flag in the data map. Explore alternatives: can they switch tools? Can we use browser automation? Is there a Zapier/Make connector? Note the workaround in integrations.md. |
| Scope creep — client keeps adding "oh and also..." | Capture everything but tier it. Quick wins and core go in Weeks 1-3. Everything else goes in Future Roadmap. "Great idea — let's put that in Month 2." |
| Discovery reveals they need a different package | Flag to the team lead. If Essentials client clearly needs Growth-level work, have the conversation early before build starts. |
| Required data is missing | Flag to user before proceeding. Do not guess or generate synthetic data. |
| External tool is inaccessible | Note the gap in output. Produce what you can from available information. |
