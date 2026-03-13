# Clients

One folder per active client. Always read the relevant client files before doing any work on that client.

---

## Folder structure

```
clients/
├── README.md              ← you are here
├── Example/               ← template showing expected file layout
│   ├── profile.md         ← who they are, contract, contacts
│   ├── performance.md     ← KPIs and monthly metrics
│   ├── actions.md         ← open tasks, decisions, meeting notes
│   └── ppc/               ← service-specific subfolder (optional)
│       ├── strategy.md
│       └── action-plan.md
└── [client-name]/         ← create one of these per real client
    ├── profile.md
    ├── performance.md
    ├── actions.md
    └── [service]/          ← optional, only if needed
```

---

## When to create a new client folder

After completing the onboarding discovery (`blueprint/onboarding.md`), create a folder with the files listed above. Use `clients/Example/` as your starting template — copy the files and replace the placeholders.

---

## Service subfolders

Create a service-specific subfolder (e.g., `ppc/`, `seo/`, `email-marketing/`) only when:
- The client has a distinct service area that needs its own strategy and action plan
- The main `actions.md` would get cluttered mixing service-specific and general work

Not every client needs one. Start with just `profile.md`, `performance.md`, and `actions.md`. Add subfolders as complexity grows.

---

## The Example folder

`clients/Example/` is a **template**, not a real client. It shows the expected file structure and placeholder format. Copy it when onboarding a new client, then replace all `[placeholders]` with real data.

---

## Client confidentiality

Never reference one client's data when working on another. When switching between clients, only read files for the client you are currently working on.
