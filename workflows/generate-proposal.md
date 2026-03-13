# Workflow: Generate Proposal

**Trigger:** User says "generate proposal for [prospect name]" or "write a proposal for [company]"

---

## Pre-flight

Before starting, read:
- `context/business.md` — our services, positioning, and pricing model
- `context/rules.md` — confirmation requirements before sending anything
- `memory/leads.md` — check if this prospect already exists in the pipeline

---

## Steps

### 1. Research the Prospect
Use web search to find:
- Company website and what they actually sell
- Their presence on any platforms relevant to our services
- Current quality of their digital presence — what's weak, what's missing?
- Any obvious gaps we could address

**Note:** If no website or presence found, flag this to the user before continuing.

### 2. Identify Service Fit
Based on research, decide which service(s) best fit the prospect's situation.
Reference `context/business.md` for the full service menu and when each applies.

If multiple services apply, lead with the most immediate value, mention others as next steps.

### 3. Draft the Proposal
Structure the proposal as follows:

```
[Business Name] — Proposal

YOUR SITUATION
[2-3 sentences on where they are now based on research]

THE OPPORTUNITY
[What's being left on the table — specific and evidence-based]

OUR RECOMMENDATION
[Specific service + why it fits their situation]

HOW IT WORKS
[3-5 step process overview — onboarding → delivery → results]

WHAT YOU GET
[Bullet list of deliverables]

INVESTMENT
[Pricing — use context/business.md for fee model]

NEXT STEP
[Single clear CTA — e.g., "Let's schedule a 30-minute call this week"]
```

### 4. Internal Review
Present the full draft to the user. Do not send. Ask:
- Is the pricing right?
- Any context I'm missing about this prospect?
- Happy for me to format this for email / doc?

### 5. After Approval
- Log the proposal in `memory/leads.md` with status: Proposal
- Log the action in `logs/actions.md`
- Format for sending only after explicit confirmation

---

## Expected Output
A tailored, ready-to-review proposal document. Named clearly: `[Prospect Name] Proposal — [Month YYYY]`

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| No online presence found | Note in proposal as an opportunity; adjust service recommendation |
| Multiple services could apply | Lead with one primary recommendation; note others as Phase 2 |
| Prospect already in leads.md | Update their record; note this is a follow-up proposal |
| Pricing is ambiguous | Leave as a range and ask user to confirm before sending |
