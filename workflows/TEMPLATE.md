# Workflow: [Workflow Name]

**Trigger:** [What starts this workflow — scheduled time, user command, or event]
**Also triggered by:** [Alternative triggers, if any]

---

## Pre-flight

Before starting, read:
- `context/business.md` — [why this file is needed for this workflow]
- `context/rules.md` — [if this workflow takes actions requiring confirmation]
- `memory/[relevant-file].md` — [which memory files to check]
- `clients/[client-name]/[file].md` — [if client-specific]

---

## Steps

### 1. [First Step Name]
[What to do, what to check, what data to gather]

### 2. [Second Step Name]
[What to do with the data from step 1]

### 3. [Third Step Name]
[Continue the process]

### 4. Produce Output
[Format the result — include a template if the output is structured]

```
[Output template here]
```

### 5. Present for Review
Show the output. Do not send or publish without explicit confirmation.

### 6. Update Memory and Logs
- Update relevant memory files (`memory/leads.md`, `memory/clients.md`, etc.)
- Log in `logs/tasks.md`: [Workflow Name] — [date] — Completed
- Log in `logs/actions.md` if a significant action was taken

---

## Expected Output
[One sentence describing what the completed workflow produces]

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| [Scenario 1] | [What to do] |
| [Scenario 2] | [What to do] |
| [Scenario 3] | [What to do] |
| Required data is missing | Flag to user before proceeding. Do not guess or generate synthetic data. |
| External tool is inaccessible | Note the gap in output. Produce what you can from local files. |
