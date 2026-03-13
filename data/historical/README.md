# Historical Data

Flat file snapshots of business data over time.
Used for trend analysis, reporting, and training the Learning Layer.

---

## Folder structure

Organise by client when data is client-specific, or at the root for business-wide data:

```
data/historical/
├── README.md                          ← you are here
├── revenue-2026-01.md                 ← business-wide monthly revenue
├── revenue-2026-02.md
├── [client-name]/                     ← one subfolder per client
│   ├── performance-2026-01.md         ← monthly performance snapshot
│   ├── performance-2026-02.md
│   └── report-2026-02.md             ← archived monthly report
└── closed-leads-2026-Q1.md           ← quarterly closed lead outcomes
```

## Naming conventions

- File naming: `[type]-[YYYY-MM].md` (e.g., `performance-2026-02.md`, `revenue-2026-Q1.md`)
- Client subfolders: use the same name as the folder in `clients/`
- Always use the field names defined in `data/schema.md`

## What goes here

- Monthly performance snapshots (per client, in client subfolder)
- Monthly revenue records (business-wide, at root)
- Closed lead outcomes — won/lost + reason (quarterly or monthly)
- Archived monthly reports (per client, in client subfolder)
- Past proposals (reference copies)

## What does NOT go here

- Live/current data — that lives in `memory/` or your CRM/spreadsheet
- Client profiles — those live in `clients/`
- Logs — those live in `logs/`
