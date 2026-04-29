# Deployment Guide

*End-to-end walkthrough for spinning up an AI OS instance for a new client. Budget: 30–60 minutes for the core stack. Add-ons (Supabase backups, n8n event plumbing, Pinecone vector recall) are configured separately, per the mapping roadmap.*

The 8 steps below mirror the order `scripts/doctor.sh` verifies. If you follow them in sequence, doctor should go fully green at step 8.

---

## Prerequisites

Before starting, have the following in hand:

- A **fork** of this template into a new private GitHub repo. The repo becomes the client's OS.
- A **Linux VPS** with Python 3.11+, `cron`, `flock`, and `tar`. 1 vCPU / 1 GB RAM is sufficient for most setups.
- **`claude` CLI** installed on the VPS and authenticated (`claude --version` must return cleanly). This is the reasoning engine called from workflow scripts.
- The client's basic identity info (legal name, owner names, timezone, currency, sender email).
- A list of **owner alert email addresses** — typically the client's operator plus your ops lead. These are where failure alerts land.

---

## Step 1 — Fork and run `init-client.sh`

Clone the fork onto your local machine (the init script runs anywhere Python 3 is available):

```bash
git clone git@github.com:your-org/<client-slug>-ai-os.git
cd <client-slug>-ai-os

./scripts/init-client.sh
```

The interactive walkthrough collects:

- **Identity** — client legal name, slug, industry, owner names, timezone, currency display.
- **Sender** — full name, first name, title, email, phone (human-readable + E.164).
- **Company** — legal name, short name, URL, bare domain, tagline, location, founded year.
- **Owner alert emails** — comma-separated.

It writes those values across every `{{PLACEHOLDER}}` in `CLAUDE.md`, `README.md`, `context/`, `memory/`, and `data/`.

**Other flags:**

- `./scripts/init-client.sh --force` — re-run on an already-initialised repo. Prompts for confirmation.
- `./scripts/init-client.sh --non-interactive --from-json values.json` — unattended mode for scripted provisioning.

Commit the generated markdown changes after the substitutions look right.

---

## Step 2 — Python environment + pinned deps

On the VPS:

```bash
cd ~/<client-slug>-ai-os
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

`requirements.txt` pins the core dependency set. Anything you add should be committed in a dedicated "bump pin" commit.

`.venv/` is gitignored — every deployment builds its own.

---

## Step 3 — Run client mapping

Before configuring any workflows, run the discovery process:

```bash
# In Claude Code, from the client repo:
# Open workflows/client-mapping.md and work through Phases 1–5
```

This produces five mapping documents in `clients/<client-name>/mapping/` that drive everything that follows: which workflows to build, which integrations to wire, which schedules to configure.

---

## Step 4 — Connect required integrations

Per the integrations doc produced by mapping:

1. Gmail (or other email provider) OAuth tokens — drop into `.credentials/`
2. Calendar / Drive / Sheets OAuth — same pattern
3. Any tool-specific API keys — add to `.credentials/<tool>.env` (gitignored)

All credential files are gitignored. Losing them means redoing the OAuth flow — back them up somewhere safe (e.g. a password manager).

---

## Step 5 — Configure workflow schedules

Per the mapping roadmap, set up cron entries for each scheduled workflow:

```bash
crontab -e
```

Each workflow ships its own `cron-entries.txt` showing the recommended schedule. Copy the lines that match your roadmap, adjust times for the client's timezone, and save.

---

## Step 6 — Run `scripts/doctor.sh`

```bash
./scripts/doctor.sh
```

Doctor checks every step above and prints PASS / FAIL for each. Iterate until everything is green.

---

## Step 7 — Add optional add-ons (per client roadmap)

Only add these if the mapping roadmap calls for them:

- **Supabase backups** — for state backup / disaster recovery. Set up a Supabase project, drop `SUPABASE_SERVICE_ROLE_KEY` into `.credentials/supabase.env`, install `supabase` Python package, add backup scripts.
- **n8n** — for event-driven webhooks (Stripe events, form submissions, etc.). Self-host on the VPS or use n8n Cloud.
- **Pinecone** — for vector recall over a large document corpus. Create a project, get an API key, install `pinecone-client`.
- **MCP servers** — for deeper tool integration. Document each in `integrations/mcps/`.

Each add-on adds its own credentials to `.credentials/` and its own dependencies to `requirements.txt`.

---

## Step 8 — Hand-over

1. Confirm one workflow runs end-to-end on schedule
2. Verify owner alerts fire (force a failure to test)
3. Connect the client's chosen messaging channel
4. Send the handover doc — what was built, how to interact, who to contact

---

## Operational notes

- **Logs** live in `logs/<workflow>/run-YYYY-MM-DD.log`. Tail them when debugging.
- **State files** live in `workflows/<name>/data/`. JSON / CSV / markdown — inspect with any text editor.
- **Config** lives in `workflows/<name>/config.py` per workflow. One source of truth for all per-deployment values.
- **Updates** flow via git: engineer pushes, VPS pulls (manually or via a webhook), cron picks up on next run.
