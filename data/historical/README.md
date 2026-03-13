# Historical Data

Flat file snapshots of business data over time.
Used for trend analysis, reporting, and training the Learning Layer.

---

## Folder conventions

- One file per data type per time period where needed
- File naming: `[type]-[YYYY-MM].md` e.g. `performance-2026-02.md`, `revenue-2026-Q1.md`
- Always use the field names defined in `data/schema.md`

## What goes here

- Monthly performance snapshots (per client)
- Monthly revenue records
- Closed lead outcomes (won/lost + reason)
- Past proposals (reference copies)
- Monthly account health summaries

## What does NOT go here

- Live/current data — that lives in `memory/` or your CRM/spreadsheet
- Client profiles — those live in `clients/`
- Logs — those live in `logs/`
