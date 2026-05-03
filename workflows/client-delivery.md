# Client Delivery Workflow

*The end-to-end process from signed deal to running AI OS. Every client follows this path — scope varies by package.*

---

## Trigger

- Client signs contract / pays deposit
- "onboard [client name]"

## Owner

{{OWNER_NAMES}} — assign technical delivery and client communication roles during onboarding

---

## Pre-flight

- `sales/packages.md` — confirm which package they bought
- `workflows/client-mapping.md` — the 5-phase discovery & mapping process
- `blueprint/stack.md` — the runtime stack each client gets
- `blueprint/architecture.md` — the 4-layer architecture

---

## Delivery by Package

### AI OS Essentials (£1,500 setup + £300/mo)

**Timeline: 1-2 weeks**

| Week | What happens | Owner |
|------|-------------|-------|
| **Week 1** | Discovery + build | Both |
| **Week 2** | Testing + launch | Technical Lead |

### AI OS Growth (£3-5K setup + £750/mo)

**Timeline: 2-4 weeks**

| Week | What happens | Owner |
|------|-------------|-------|
| **Week 1** | Discovery + architecture design | Both |
| **Week 2** | Core build — context, first workflows, integrations | Technical Lead |
| **Week 3** | Extended build — remaining workflows, memory, testing | Technical Lead |
| **Week 4** | Launch + training + handover | Both |

### AI OS Partner (£5-10K setup + £1,500/mo)

**Timeline: 3-6 weeks**

| Week | What happens | Owner |
|------|-------------|-------|
| **Week 1** | Deep discovery + full architecture design | Both |
| **Week 2-3** | Core system build — context, workflows, integrations | Technical Lead |
| **Week 3-4** | Custom builds — bespoke agents, advanced integrations | Technical Lead |
| **Week 5** | Testing, refinement, internal review | Technical Lead |
| **Week 6** | Launch + training + strategy session | Both |

---

## Step-by-Step Process (All Packages)

### Stage 1: Kickoff (Day 1)

**Client Lead leads:**
1. Send welcome email with:
   - What to expect (timeline, milestones, communication cadence)
   - Access request list (see below)
   - Booking link for discovery session
2. Create client folder: `clients/[client-name]/`
3. Create client entry in `memory/clients.md`
4. Log in `logs/actions.md`: "Client [name] signed — [package] — £[value]"

**Access we need from them:**
- Google Workspace access (or equivalent email/calendar/drive)
- CRM / pipeline tool access (if they have one)
- Payment platform access (Stripe, etc.) — read-only for data
- Communication channel setup (invite us to Slack/Teams, or set up Telegram/WhatsApp group)
- Any other tools they use daily (list from discovery)

### Stage 2: Discovery & Mapping (Days 2-5)

**{{OWNER_NAMES}} — one leads the sessions, the other takes notes.**

Run the full client mapping process (`workflows/client-mapping.md`):

1. **Business & People Map** — business model, team, goals, seasonality, rules
2. **Tool Stack & Data Audit** — every tool, what data it holds, APIs, silos, gaps
3. **Process Deep-Dive** — every process mapped with steps, time cost, automation potential
4. **Integration Architecture** — connections needed, credential checklist, dependency graph (Growth/Partner)
5. **Workflow Roadmap** — scored and prioritised automations with delivery timeline

**Output (all in `clients/[client-name]/mapping/`):**
- `business-map.md` — business model, team, goals, rules → feeds Context Layer
- `data-map.md` — tool stack, data sources, silos, gaps → feeds Data Layer
- `process-map.md` — every process with automation potential → feeds Automation Layer
- `integrations.md` — connection architecture, credentials → feeds Integration Layer
- `roadmap.md` — tiered workflow recommendations with delivery timeline

**Plus:**
- Populate `clients/[client-name]/profile.md`
- Client sign-off on the roadmap before build begins

### Stage 3: Architecture Design (Days 3-7)

**Technical Lead leads:**
1. Using the mapping outputs from Stage 2, design the AI OS build:
   - Context layer — populate `context/` files from `business-map.md`
   - Data layer — configure data sources and schema from `data-map.md`
   - Integration layer — connect tools per `integrations.md` dependency graph
   - Automation layer — build workflows per `roadmap.md` tier order
2. Confirm build order matches the signed-off roadmap
3. Finalise delivery timeline with specific dates

**Client Lead:**
- Present the delivery plan to client for sign-off (if not already done in Stage 2)
- Set communication cadence (weekly update + async channel)

### Stage 4: Build (Varies by package)

**{{OWNER_NAMES}} — one builds, the other manages client comms.**

**Build order (always):**
1. **Context layer first** — populate business.md, processes.md, integrations.md, rules.md for the client. This is the foundation everything else depends on.
2. **First workflow (quick win)** — pick the highest-impact, easiest-to-deliver automation. Get it running fast so the client sees value immediately.
3. **Integrations** — connect their tools via direct API calls (email, calendar, CRM, payments, etc.). Add n8n only if event-driven webhooks are needed.
4. **Remaining workflows** — build out the full workflow suite per the architecture plan
5. **Memory layer** — set up `memory/` files. File-based recall is the default. Only consider vector recall (Supabase pgvector inside their existing Supabase) if the client has 50+ unstructured documents that genuinely need semantic search.
6. **Scheduled jobs** — morning briefing, EOD summary, weekly reviews (per client needs)
7. **Channel delivery** — connect their messaging channel (Telegram/WhatsApp/Slack)

**During build:**
- Test each workflow individually before connecting
- Document everything in the client's folder
- Send weekly progress update to client (Client Lead)
- Flag any blockers or scope changes immediately

### Stage 5: Testing & QA (2-3 days)

**Technical Lead:**
1. Run every workflow end-to-end
2. Test every integration (send test data, verify outputs)
3. Test scheduled jobs (run manually, verify output format)
4. Test edge cases (what happens when data is missing, API fails, etc.)
5. Internal review — Client Lead reviews outputs as if they were the client

**Checklist:**
- [ ] All workflows run without errors
- [ ] Scheduled jobs fire correctly
- [ ] Integrations read/write data correctly
- [ ] AI responses are accurate and on-brand for the client
- [ ] Memory/context is complete and correct
- [ ] Client-facing outputs (briefings, reports, messages) look professional

### Stage 6: Launch & Training (Day of handover)

**Both attend:**
1. **Launch call (45-60 min):**
   - Walk through the system — what it does, how it works
   - Show each workflow in action
   - Show them how to interact with their AI (messaging channel)
   - Explain what happens automatically vs what needs their input
   - Answer questions

2. **Handover docs:**
   - Summary of what was built
   - List of all active workflows and what they do
   - Communication channel guide
   - "How to get help" — who to contact and how

3. **Go live:**
   - Activate all scheduled jobs
   - Confirm messaging channel is connected
   - Send first briefing/output within 24 hours

### Stage 7: First 30 Days (Post-Launch)

**Both:**
1. **Week 1:** Daily check — is everything running? Any errors? Client feedback?
2. **Week 2:** First weekly review with client — what's working, what needs adjusting
3. **Week 3-4:** Optimise based on feedback, add any quick improvements
4. **End of Month 1:** Present 90-day roadmap (for Growth and Partner tiers)

**Client Lead sends:**
- Weekly async update every Friday
- Monthly performance summary at end of Month 1

**Log everything:**
- Update `clients/[client-name]/actions.md` with all decisions and changes
- Update `clients/[client-name]/performance.md` with initial metrics
- Update `memory/clients.md` with status

---

## Ongoing Management (Retainer Phase)

### Monthly rhythm (all AI OS tiers)

| Task | Frequency | Owner |
|------|-----------|-------|
| Monitor system health | Daily (automated alerts) | Technical Lead |
| Respond to client queries | Same business day | Both |
| Weekly async update | Every Friday | Client Lead |
| Optimise workflows | Ongoing | Technical Lead |
| Add new automations (Growth/Partner) | As identified | Technical Lead |
| Monthly performance review | End of month | Both |
| Strategy call (Partner only) | Monthly | Both |
| Quarterly business review (Partner only) | Quarterly | Both |

### When to expand scope

- Client asks for something outside current package → scope it, quote it, or suggest tier upgrade
- New pain point identified during reviews → add to roadmap
- Quick win spotted → just build it (if within current tier scope)

---

## Standalone Delivery (Websites & Workflow Builds)

### Website builds

1. Discovery call (30 min) — goals, brand, content, design preferences
2. Wireframe/mockup → client approval
3. Build → internal review
4. Client review → 1-2 rounds of revisions (per package)
5. Launch → DNS, hosting, analytics, SEO check
6. Handover + quick training on CMS (if applicable)
7. Pitch AI OS at handover: "Now that you're online, imagine an AI running your back office too."

### Workflow builds (single or bundle)

1. Discovery session (30-60 min) — map the process, identify tools, define success
2. Build the automation
3. Test end-to-end
4. Demo to client
5. Deploy + handover docs
6. Pitch AI OS at handover: "This is one workflow. Imagine your whole business running like this."

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Client is slow providing access | Follow up Day 2, Day 5, Day 10. Pause timeline if blocking. Communicate delay clearly. |
| Scope creep during discovery | Flag immediately. "That's a great idea — let's add it to the roadmap for Month 2" or quote as an add-on. |
| Technical blocker (API doesn't exist, tool limitations) | Identify workaround. If none, communicate to client with alternatives. Never promise what you can't deliver. |
| Client wants changes mid-build | If within scope: accommodate. If outside scope: quote and add to roadmap. |
| System error post-launch | Fix within 4 hours (Partner), same day (Growth), 48 hours (Essentials). Communicate proactively. |
