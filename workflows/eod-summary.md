# Workflow: End of Day Summary

**Trigger:** Scheduled — Weekdays [TIME] ([TIMEZONE])
**Also triggered by:** User says "end of day" or "EOD summary"

---

## Pre-flight

Before starting, read:
- `logs/actions.md` — what was logged today
- `memory/leads.md` — lead pipeline
- `memory/clients.md` — client status

---

## Steps

### 1. Review What Happened Today
From `logs/actions.md` and conversation context:
- What emails were sent or drafted?
- What tasks were completed?
- What decisions were made?
- Any calls or meetings held?

### 2. Check Gmail — Today's Activity
- Any new emails that haven't been dealt with?
- Any threads left open needing a reply tomorrow?
- Anything flagged as urgent for tomorrow?

### 3. Lead Pipeline Check
From `memory/leads.md`:
- Did any leads move forward today?
- Did any follow-ups get missed?
- Anyone that needs to be chased tomorrow?

### 4. Flag Follow-ups for Tomorrow
List anything that must happen tomorrow:
- Overdue responses
- Scheduled follow-ups
- Client deliverables
- Anything promised today

### 5. Produce the EOD Summary

```
End of Day — [Day, Date]

DONE TODAY
- [Task / action completed]

EMAILS TO ACTION TOMORROW
- [Sender] — [what's needed]

LEAD UPDATES
- [Lead name] — [status change or next action]

FOLLOW-UPS FOR TOMORROW
- [Action] — [who / what / deadline]

DECISIONS MADE
- [Decision and outcome]

MEMORY UPDATES
[Any new learnings or context worth noting]
```

### 6. Update Memory and Logs
- Log in `logs/tasks.md`: EOD Summary — [date] — Completed
- Update `memory/leads.md` if any status changes happened today
- Update `memory/learnings.md` if anything notable was learned

---

## Expected Output
A concise EOD summary covering the day's activity and tomorrow's priorities. Memory updated.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Very quiet day | Still produce the summary; suggest proactive outreach tomorrow |
| A lead came in late in the day | Flag prominently; ensure it's top of tomorrow's priorities |
| Urgent item needs action before tomorrow | Flag with [URGENT]; notify owner immediately |
| Logs are empty | Note the observability gap; prompt to log actions going forward |
