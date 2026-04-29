# Workflow: Client Mapping (Claude-led, phased)

**Trigger:** Client signs / `"start mapping for [client-name]"`
**Also triggered by:** `"continue mapping for [client-name]"` (resume at next phase)

---

## How this workflow runs

**Claude leads the questions. You and the client drive together.** This is a three-way conversation, not an interview-by-proxy.

The mapping is split into **5 short sessions**, each producing one deliverable. Sessions are typically run on different days — the client digests between sessions and brings missing info to the next one.

| Session | Phase | Duration | Output | Client present? |
|---------|-------|----------|--------|----------------|
| 1 | Business & People Map | 45–60 min | `business-map.md` | Yes |
| 2 | Tool Stack & Data Audit | 60–90 min | `data-map.md` | Yes (screen-sharing tools) |
| 3 | Process Deep-Dive | 60–90 min (split if needed) | `process-map.md` | Yes |
| 4 | Integration Architecture | 30–45 min | `integrations.md` | No — internal design work |
| 5 | Workflow Roadmap (presentation) | 45–60 min | `roadmap.md` + sign-off | Yes |

**Total: ~4–5 hours of client time over 2–3 weeks. Internal design work is on top.**

### Setup — two valid arrangements

Pick the one that fits the situation:

**A. You're driving Claude, client is watching alongside** *(in your office, or you screen-share on Zoom)*
- Your laptop is the workstation — Claude open, mapping doc visible
- Client sees the conversation happening, can read along, jump in any time
- You speak the client's answers into Claude (paraphrasing or quoting)
- Best when: client is non-technical, or you want tight control of pace

**B. Client is driving Claude, you're watching over their shoulder** *(in their office, or they screen-share on Zoom)*
- Their laptop is the workstation
- Client interacts with Claude directly — types or voices answers
- You watch, interject when Claude misses something, steer when needed
- Best when: client is comfortable with AI tools, or you want them to feel ownership of the process

Either way: the client sees the screen. The mapping doc takes shape live. Nothing happens behind a curtain.

### Roles

- **Claude** — the interviewer. Asks the questions, probes when answers are vague, drafts the output doc at the end of each session. Should NOT just plough through a script — it adapts to what the client says.
- **You (the team lead running the session)** — the active co-pilot. You know things the client won't say (or doesn't know to say). Your job:
  - **Interrupt** when Claude goes off-track or misses something obvious
  - **Add context** — "[Client], you mentioned last week that the [other workstream] side does X — that's relevant here"
  - **Correct in real-time** — "Hold on, that's not quite right. Let me clarify..."
  - **Push for depth** — "Claude, dig into the invoicing process specifically — that's where I think the win is"
  - **Edit the draft doc** before moving on — fix anything Claude misread
- **Client** — the source of truth on their own business. Talks freely. Doesn't need to know which "phase" they're in — to them it's just a structured conversation.

### Setup before any session

- Open Claude Code in this repo (or the client's repo, if it's been forked)
- Have Claude read `clients/[client-name]/profile.md` and any prior mapping outputs at the start
- Have screen-sharing ready (essential for Sessions 2 and 3)
- Agree the arrangement (A or B above) with the client before the call
- Have a fresh page open for ad-hoc notes Claude won't see (sensitive remarks, side observations)

---

## Pre-flight (before Session 1)

Before kicking off, read:

- `clients/[client-name]/profile.md` — basic client info from kickoff
- `sales/packages.md` — confirm package tier (determines depth)
- `blueprint/architecture.md` — the 4-layer model we're mapping them onto
- `data/schema.md` — standard field definitions

**Package depth guidance:**

| Package | Depth |
|---------|-------|
| **Essentials** (£1.5K + £300/mo) | Sessions 1–3 + abbreviated Session 5. Skip Session 4. 2–3 workflows. |
| **Growth** (£3-5K + £750/mo) | All 5 sessions, full depth. 5–8 workflows. |
| **Partner** (£2K + £1K/mo) | All 5 sessions, max depth. Process map covers entire business. 90-day roadmap. |

Create the mapping folder: `clients/[client-name]/mapping/`

---

## Session 1 — Business & People Map (45–60 min)

**Goal:** Understand the business as a whole. This sets the lens for everything that follows.

**When to run:** As soon as possible after kickoff. Easiest session — sets the tone.

**Output:** `clients/[client-name]/mapping/business-map.md` (use template at `clients/Example/mapping/business-map.md`)

### How Claude opens the session

> "Hi [name], thanks for making the time. Today's session is about getting to know your business — what you sell, who you serve, who's on the team, where you want to be in 12 months. There's no right or wrong answers — I'm trying to build a complete picture so the AI OS we build actually fits how you work. We'll do this in five short sessions over the next couple of weeks; today is the easy one. Roughly 45 minutes. Sound good?"

### Conversation flow

Claude works through these areas, letting the client lead and probing where useful:

1. **Business model** — What do you sell? To whom? How does money come in?
2. **Revenue streams** — What's your biggest revenue line? What's growing? What's tailing off?
3. **Team** — Who's on the team? What does each person do? Who's overloaded right now?
4. **Goals** — Where do you want the business to be in 3 months? 6 months? 12?
5. **Competitive landscape** — Who do you lose to? Who do you beat? Why?
6. **Seasonality** — Is there a busy period? A quiet one? Anything cyclical?
7. **Communication style** — How do you talk to your customers? Internal team comms — Slack, WhatsApp, email?
8. **Rules & constraints** — What must the AI never do? Compliance, brand voice, anything off-limits?

### Probing prompts Claude can use

- "Tell me more about that."
- "Walk me through what that looks like day-to-day."
- "If you could fix one thing about [X] tomorrow, what would it be?"
- "Who else gets pulled in when that happens?"

### Wrap-up

At the end, Claude:
1. Summarises what it heard (3–5 bullet points)
2. Confirms with the client: "Did I get that right?"
3. Drafts `business-map.md` from the conversation
4. Books Session 2 (or asks the facilitator to)

---

## Session 2 — Tool Stack & Data Audit (60–90 min)

**Goal:** Map every tool the client uses and where their data actually lives. This finds the data silos and the manual copy-paste bridges that scream "automate me."

**When to run:** 2–5 days after Session 1. Client should be ready to share their screen.

**Setup:** Client shares their screen and walks through their tools. Have them open each one as it comes up — don't let them describe from memory.

**Output:** `clients/[client-name]/mapping/data-map.md` (use template at `clients/Example/mapping/data-map.md`)

### How Claude opens the session

> "Today we're going through every tool you use to run the business. I want to see what data lives where — because that's how we figure out what to automate. Have a screen ready to share. We'll go tool by tool, and at every one I'll ask you the same handful of questions. Should take about 60 to 90 minutes."

### Conversation flow

For **each tool** the client uses, Claude works through:

| Question | Why it matters |
|----------|---------------|
| What's the tool called and what's it for? | Establishes purpose |
| Who uses it? | Single point of failure check |
| What data lives in it? *(client opens it on screen)* | Specificity — fields, not vague descriptions |
| How does data get in? | Manual entry vs API vs import |
| How does data get out? | Export options reveal API maturity |
| Does it have an API? *(if client unsure, Claude can web-search)* | Integration feasibility |
| What does it cost per month? | TCO picture |
| What's frustrating about it? | Pain signals |

After working through every tool, Claude probes for the **patterns**:

- "Where do you copy data manually between tools?" → manual bridges
- "Where is information you need that you can't easily get?" → data silos
- "What numbers do you wish you had but don't?" → data gaps
- "Is there a tool only one person knows how to use?" → SPOF

### Wrap-up

Claude:
1. Summarises the tool list and the top 3 manual bridges spotted
2. Drafts `data-map.md`
3. Flags any tool where API access is unclear — facilitator follows up async
4. Books Session 3

---

## Session 3 — Process Deep-Dive (60–90 min, split if needed)

**Goal:** Map every repeating business process. This is the most important session — it directly produces the automation opportunities.

**When to run:** 3–7 days after Session 2. If the business has 8+ distinct processes, split into two sessions (sales/ops in one, comms/finance in another).

**Output:** `clients/[client-name]/mapping/process-map.md`

### How Claude opens the session

> "Today's the big one. We're going to walk through every repeating process in your business — sales, onboarding, delivery, comms, finance, reporting. For each one I want to know: who does it, how often, how long it takes, what tools, and what breaks. It's the most important session because everything we automate comes out of this. If we run out of time we'll do a Part 2 — better than rushing."

### Conversation flow

Claude walks through processes **grouped by business function**:

1. Sales & Lead Generation
2. Client/Customer Onboarding
3. Service Delivery / Fulfilment
4. Communication (internal + external)
5. Finance & Invoicing
6. Reporting & Analytics
7. Content & Marketing
8. Admin & Operations

For **each process**, Claude asks:

- What's it called? Walk me through what actually happens, step by step.
- Who owns this? Anyone else involved?
- How often does it happen?
- How long does each occurrence take?
- What tools are involved? (Cross-reference Session 2's tool list)
- What goes in (the trigger/input)? What comes out?
- Where does this break? What gets missed? What gets done late?
- If you could wave a magic wand, what would change about this?

### Probing on the high-value ones

When the client mentions a process that takes hours/week or fails often, Claude digs in:
- "Walk me through the last time this happened."
- "What did you have open on your screen?"
- "What was the worst version of this in the last month?"

### Wrap-up

Claude:
1. Summarises: total processes mapped, top 3 by monthly time cost, top 3 by automation potential
2. Drafts `process-map.md`
3. Flags whether a Part 2 session is needed
4. Tells the client: "Next session is internal — we'll come back to you in a few days with a recommended roadmap."

---

## Session 4 — Integration Architecture (30–45 min, internal)

**Goal:** Design the integration picture from Sessions 2 + 3. **No client present.**

**Skip this session for Essentials clients** — their integrations are simple enough to handle inline during the build.

**When to run:** Within 2–3 days of Session 3, before Session 5.

**Who:** Facilitator + Claude. Optionally a second QF team member to pressure-test.

**Output:** `clients/[client-name]/mapping/integrations.md`

### Conversation flow

Claude works with the facilitator to design:

1. **For every required connection, capture:** From → To, data flowing, direction, trigger (schedule/event), method (API/webhook/manual today), auth required, complexity, prerequisites.

2. **Build the credential checklist** — every API key, OAuth token, access grant we need (with checkboxes).

3. **Build the dependency graph** — which integrations must connect before others work.

4. **Flag risks** — rate limits, API instability, auth expiry, vendor concerns.

This is design work, not discovery. Claude proposes, facilitator pushes back where they have signal Claude doesn't.

---

## Session 5 — Workflow Roadmap (45–60 min, presentation)

**Goal:** Present the recommended build plan to the client and get sign-off.

**When to run:** Within a week of Session 3 (or Session 4 if Growth/Partner). Internal prep before — Claude scores opportunities and tiers them.

**Output:** `clients/[client-name]/mapping/roadmap.md` + client sign-off

### Internal prep (before the call)

Claude reviews the process map and scores every automation opportunity:

- **Impact** (1-5): Time/money/pain saved
- **Effort** (1-5): Build complexity + dependencies
- **ROI Score**: Impact × (6 − Effort)
- **Dependencies**: What needs to exist first

Then groups into tiers:

| Tier | Timing | Criteria |
|------|--------|----------|
| **Quick Wins** | Week 1 | High impact, low effort, no dependencies |
| **Core System** | Weeks 2-3 | Backbone automations — daily operating rhythm |
| **Advanced Builds** | Weeks 3-4+ | Growth/Partner only — complex multi-step |
| **Future Roadmap** | Month 2+ | Expansion ideas, monthly strategy call topics |

Builds the delivery timeline table.

### How Claude opens the call

> "Right — we've finished mapping. We've found [X] processes worth automating, and I've ranked them by what'll save you the most time for the least build effort. Let me walk you through what I think we should build, in what order, and over what timeframe. Push back wherever it doesn't feel right — this is the plan we're going to execute, so it has to match what you actually need."

### Conversation flow

1. **Recap** — what we found: process count, time cost, top pain points (uses client's own words)
2. **The roadmap** — walk through each tier, each workflow inside it, why it's there
3. **The timeline** — week-by-week, what gets built, what dependencies, what milestone
4. **Push-back round** — "What's missing? What feels wrong? What's higher priority than I've ranked?"
5. **Sign-off** — explicit yes from the client before build starts. Document the sign-off date in `roadmap.md`.

### Wrap-up

Claude:
1. Updates `roadmap.md` with any changes from the discussion
2. Notes the sign-off date
3. Tells the client when build starts
4. Hands off to `workflows/client-delivery.md` Stage 3 (Architecture Design)

---

## After all sessions

Update memory and logs:

- Update `clients/[client-name]/profile.md` with anything new
- Update `clients/[client-name]/actions.md` — log mapping completion + next steps
- Update `memory/clients.md` — status change to "Mapping Complete — Build Starting"
- Log in `logs/actions.md`: "Client [name] — mapping complete — [X] workflows identified — sign-off [date]"

---

## Expected Output

Five structured documents in `clients/[client-name]/mapping/`:

1. `business-map.md` — Business model, team, goals, rules
2. `data-map.md` — Tool stack, data sources, silos, gaps
3. `process-map.md` — Every process with automation potential scored
4. `integrations.md` — Connection architecture, credential checklist, dependency graph
5. `roadmap.md` — Scored, tiered workflow recommendations with delivery timeline

Plus: explicit client sign-off on the roadmap before build begins.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Client can't articulate their processes | Walk them through their last working day. "What did you do first thing Monday? Then what?" — reconstruct from behaviour, not theory. |
| Client tries to skip ahead to "what we're building" | Hold the line: "We're going to build the wrong thing if we don't map first. This is how we make sure every hour creates max value." |
| Session running over | Stop on time. Schedule a Part 2 the same week. Don't let one session balloon to 3 hours. |
| Client cancels a session | Don't restart from scratch. Pick up where you left off using the partial output already drafted. |
| Client's tools have no API | Flag in the data map. Explore alternatives: switch tool? Browser automation? Zapier/Make connector? Document the workaround. |
| Scope creep mid-session | Capture everything but tier it. "Great idea — let's put that in Future Roadmap." Don't argue, just park it. |
| Discovery reveals they need a different package | Flag to the team lead between sessions. If Essentials clearly needs Growth, raise it before build starts — not after. |
| Required data is missing | Flag to the user before drafting the output doc. Don't synthesise. |
| External tool inaccessible mid-session | Note the gap. Move on. Follow up async. |
