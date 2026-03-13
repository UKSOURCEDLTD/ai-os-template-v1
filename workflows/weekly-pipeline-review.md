# Workflow: Weekly Pipeline Review

**Trigger:** Scheduled — [DAY] [TIME] ([TIMEZONE])
**Also triggered by:** User says "pipeline review" or "where are we with leads"

---

## Pre-flight

Before starting, read:
- `context/business.md` — revenue targets, services, positioning
- `memory/leads.md` — full lead pipeline
- `memory/clients.md` — active clients and status
- `memory/metrics.md` — current revenue and pipeline value

---

## Steps

### 1. Full Lead Funnel Review
For every lead in `memory/leads.md`, assess:
- What stage are they at? (New / Contacted / Discovery / Proposal / Negotiation / Closed / Lost)
- When was last contact?
- What is the next action — and is it overdue?
- What is the estimated deal value?
- What's the likelihood of closing in the next 30 days?

Flag:
- **Hot** — likely to close this month
- **Stalled** — no movement in 7+ days
- **Cold** — no response in 14+ days; needs decision (chase or close off)

### 2. Revenue vs Target
From `memory/metrics.md`:
- Revenue this month so far
- Revenue target for the month
- Gap to target
- Pipeline value that could close this month

If targets are not set, flag this and ask the owner to confirm.

### 3. Active Client Projects
From `memory/clients.md` + client folders:
- Which clients are active and in delivery?
- Any client at risk?
- Any client approaching renewal?
- Any upsell opportunity?

### 4. Priorities for the Week
- Top 3 revenue actions
- Top 3 client actions
- Any content or outreach for this week

### 5. Produce the Pipeline Report

```
Weekly Pipeline Review — [Date]

PIPELINE SUMMARY
| Lead | Stage | Last Contact | Est. Value | Likelihood | Next Action |
|------|-------|-------------|-----------|-----------|------------|

HOT THIS WEEK
- [Lead name] — [why / what needs to happen]

STALLED
- [Lead name] — [last contact / recommended action]

COLD
- [Lead name] — [chase or close off?]

REVENUE STATUS
- This month: [value]
- Target: [value]
- Gap: [value]
- Pipeline that could close: [value]

CLIENT STATUS
| Client | Health | Outstanding | Upsell Opp? |
|--------|--------|-------------|------------|

PRIORITIES THIS WEEK
1. [Revenue action]
2. [Revenue action]
3. [Client action]

OUTREACH TO DO
- [Target / channel / angle]
```

### 6. Update Memory and Logs
- Update `memory/leads.md` with any status changes
- Update `memory/metrics.md` with current pipeline value
- Log in `logs/tasks.md`: Weekly Pipeline Review — [date] — Completed

---

## Expected Output
A full pipeline report with lead status, revenue position, client health, and this week's priorities.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Pipeline is empty | Flag as critical — recommend outreach or content push |
| Revenue target not set | Flag and ask owner to confirm before proceeding |
| No metrics data | Produce the review from leads and clients only; flag the gap |
| A client is at risk | Escalate immediately — do not bury in a report |
| Multiple stalled leads | Suggest a batch follow-up day to clear the pipeline |
