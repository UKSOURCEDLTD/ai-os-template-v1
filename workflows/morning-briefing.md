# Workflow: Morning Briefing

**Trigger:** Scheduled — Weekdays [TIME] ([TIMEZONE])
**Also triggered by:** User says "morning briefing" or "what's on today"

---

## Pre-flight

Before starting, read:
- `context/business.md` — business context
- `memory/leads.md` — active leads
- `memory/clients.md` — active clients

---

## Steps

### 1. Check Gmail — Overnight / Since Yesterday
Scan inbox for:
- New leads or enquiries (flag immediately)
- Client messages needing a response today
- Anything marked urgent or with a deadline
- Anything that came in after close of business yesterday

### 2. Check Today's Calendar
- List all meetings and calls for today
- Flag any that need prep
- Note gaps that could be used for focused work

### 3. Check Active Leads
From `memory/leads.md`:
- Any lead where next action is today or overdue?
- Any follow-ups that should happen today?

### 4. Check Client Priorities
From `memory/clients.md`:
- Any client deliverables due today or this week?
- Any client awaiting something from us?

### 5. Produce the Briefing

```
Good morning — [Day, Date]

EMAIL
[Summary of anything needing attention — or "Nothing urgent overnight"]

TODAY'S CALENDAR
- [Time] — [Event]

LEAD ACTIONS DUE TODAY
- [Lead name] — [what needs doing]

CLIENT PRIORITIES
- [Client] — [what's outstanding or due]

TOP 3 PRIORITIES FOR TODAY
1. [Most important thing]
2. [Second most important]
3. [Third most important]
```

---

## Expected Output
A concise morning briefing covering email, calendar, leads, and top 3 priorities.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| No meetings today | Note as open time; suggest using it for outreach or deep work |
| Urgent lead came in overnight | Flag at the top of the briefing in bold |
| Gmail inaccessible | Note the gap; produce the rest from local memory files |
| Calendar is empty | Flag — may indicate scheduling is behind |
