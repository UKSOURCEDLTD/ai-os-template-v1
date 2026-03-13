# Workflow: Client Monthly Report

**Trigger:** User says "generate report for [client]" or "monthly report [client]" — run at end of each month

---

## Pre-flight

Before starting, read:
- `clients/[client-name]/profile.md` — who they are, contract, contacts
- `clients/[client-name]/performance.md` — KPIs and monthly metrics
- `clients/[client-name]/actions.md` — what was done this month, open tasks

---

## Steps

### 1. Pull This Month's Metrics
From `performance.md`, extract for the current month:
- Revenue / key performance metrics
- Any spend or cost metrics
- Units, conversions, or volume metrics
- Any anomalies or standout weeks

**If metrics are missing:** Flag to user immediately. Do not generate a report without real data.

### 2. Review Actions Taken
From `actions.md`, list:
- What was completed this month
- What is still open and why
- Any decisions made or escalations

### 3. Assess Account Health
Rate each relevant dimension as: Strong / Needs Work / Critical

### 4. Draft the Report

```
[Client Name] — Monthly Report — [Month YYYY]

SUMMARY
[2-3 sentence executive summary — the headline story this month]

PERFORMANCE
| Metric     | This Month | Last Month | Change |
|------------|-----------|------------|--------|
| [Metric 1] |           |            |        |
| [Metric 2] |           |            |        |

KEY ACTIONS TAKEN
- [Action 1]
- [Action 2]

ACCOUNT HEALTH
- [Dimension]: [status]

NEXT MONTH PRIORITIES
1. [Priority 1]
2. [Priority 2]

OPEN ITEMS / NEEDS FROM CLIENT
- [Anything we need from them]
```

### 5. Present for Review
Show the draft. Do not send. Ask:
- Is all data accurate?
- Anything to add or remove?
- Format for email / doc?

### 6. After Sending
- Archive a snapshot in `data/historical/[client]/[YYYY-MM].md`
- Update `memory/clients.md` with current status
- Log in `logs/actions.md`: Monthly report sent to [Client Name]

---

## Expected Output
A formatted monthly report, ready for client delivery. One per client per month.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Performance data is missing | Stop. Ask user to pull data before proceeding |
| Client is new (first month) | Note this; skip last month comparison column |
| Results were poor | Be honest, specific, and solution-focused |
| Client hasn't responded to previous report | Note in covering email; flag to owner |
