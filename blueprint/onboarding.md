# AI OS — Client Onboarding Blueprint

This is the structured discovery process for onboarding a new client.
Run this as a conversation — work through each section, capture everything,
then generate the context layer files into `clients/[client-name]/`.

---

## Phase 1: Business Identity

- Business name
- Owner / key decision maker
- Industry
- What does the business actually do? (in plain language)
- Website / social links
- Timezone, currency
- How long have they been running?
- Team size and structure

## Phase 2: Products & Services

- What do they sell? (products, services, subscriptions, retainers)
- Who are their customers? (B2B, B2C, market segment)
- What's their pricing model?
- What's their main revenue driver?
- Any seasonal patterns?

## Phase 3: Tool Stack Audit

Map every tool they use and what it's for:

| Tool | Purpose | Data it holds | API available? |
|------|---------|---------------|----------------|
| e.g. Stripe | Payments | Revenue, customers | Yes |
| e.g. Gmail | Email | Leads, client comms | Yes |
| e.g. Notion | Docs | SOPs, project notes | Yes |

Key questions:
- Where do leads come in?
- Where is customer data stored?
- Where is financial data?
- What do they use for project management?
- What do they use for communication (internal and external)?
- Any spreadsheets doing heavy lifting?

## Phase 4: Process Audit

For each core business process, map:
- What is the process?
- Who does it?
- How often?
- How long does it take?
- What tools are involved?
- Is it manual, semi-automated, or fully automated?
- What breaks or gets forgotten?

Key processes to ask about:
- Lead generation and sales pipeline
- Client onboarding
- Service delivery / fulfilment
- Invoicing and payments
- Reporting and reviews
- Content creation and marketing
- Customer support
- Team communication and coordination

## Phase 5: Data Audit

- What numbers do they check daily/weekly?
- Where does their most important data live?
- What reports do they currently run (or wish they had)?
- Any data trapped in spreadsheets or people's heads?
- What decisions would be better with more data?

## Phase 6: Pain Points & Priorities

- What takes too long?
- What gets forgotten or dropped?
- What do they wish "just happened" without them thinking about it?
- If they could automate 3 things tomorrow, what would they pick?
- What's the biggest bottleneck to growth right now?

## Phase 7: Automation Design

Based on everything above, design:

**Scheduled jobs** — things that should run on a clock:
- Morning briefing (what?)
- End of day summary (what?)
- Weekly/monthly reviews (what?)
- Regular checks (what needs monitoring?)

**Triggers** — things that should react to events:
- New lead comes in → what happens?
- Payment received → what happens?
- Payment failed → what happens?
- Task overdue → what happens?

**Workflows** — multi-step processes that can be triggered on demand:
- e.g. "Generate proposal for [prospect]"
- e.g. "Onboard new client [name]"
- e.g. "Weekly report"

## Phase 8: Access & Security

- Who will use the system? (list people + roles)
- What actions need human confirmation before executing?
- Any sensitive data that needs special handling?
- Any compliance requirements?

---

## Output

After discovery, generate these files into `clients/[client-name]/`:

```
clients/[client-name]/
├── profile.md               ← who they are, contacts, contract
├── performance.md           ← KPIs and monthly metrics
├── actions.md               ← open tasks, meeting notes, decisions
└── ppc/                     ← if managing Amazon PPC
    ├── strategy.md
    └── action-plan.md
```
