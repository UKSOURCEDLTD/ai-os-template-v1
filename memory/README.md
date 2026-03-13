# Memory

Persistent business intelligence that the AI updates as it operates. These files grow over time and are the AI's working memory across sessions.

---

## Files

| File | What it tracks | When to update |
|------|---------------|----------------|
| `leads.md` | Active lead pipeline | When a new lead is identified, status changes, or follow-up happens |
| `clients.md` | Active client status | When client health changes, onboarding completes, or status shifts |
| `metrics.md` | Key business numbers | During reviews, when new revenue data arrives, or pipeline changes |
| `learnings.md` | Insights that compound | When something works unexpectedly well, fails, or produces a reusable insight |

---

## Maintenance rules

- **Update promptly** — don't batch updates. Record changes as they happen.
- **Never delete entries from `learnings.md`** — it's append-only. Old insights remain valuable.
- **Archive, don't delete leads** — when a lead closes (won or lost), move them from `leads.md` to `data/historical/` with outcome noted. Keep `leads.md` focused on active pipeline only.
- **Client status changes** — when a client churns or pauses, update their status in `clients.md` but keep the entry. Only remove after archiving to `data/historical/`.
- **Metrics are snapshots** — `metrics.md` shows current state. Historical values go in `data/historical/`.
- **Cross-reference client files** — `clients.md` is a summary. Full details live in `clients/[client-name]/`.

---

## Data format

Use the field definitions in `data/schema.md` when adding or updating entries. This keeps data consistent and queryable.
