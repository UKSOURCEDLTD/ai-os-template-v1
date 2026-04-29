# Deployment Guide

*End-to-end walkthrough for spinning up an AI OS instance for a new client. Budget: 60–120 minutes. The OAuth dance plus first-run observation are the longest stretches; everything else is scripted.*

The 12 steps below mirror the order `scripts/doctor.sh` verifies. If you follow them in sequence, doctor should go fully green at step 9.

---

## Prerequisites

Before starting, have the following in hand:

- A **fork** of this template into a new private GitHub repo. The repo becomes the client's OS.
- A **Linux VPS** with Python 3.11+, `cron`, `flock`, and `tar`. 1 vCPU / 1 GB RAM is sufficient for the cold-outreach workflow alone.
- A **Gmail account** owned by the client (or by you on their behalf) that will be the sender. Must be a real Gmail / Google Workspace user — not a service account.
- A **Google Cloud project** with Gmail API enabled and an OAuth 2.0 Desktop client configured. See [`workflows/cold-outreach/oauth-setup.md`](./workflows/cold-outreach/oauth-setup.md).
- A **Supabase project** — mandatory. Used for daily state backups. Free tier is fine. See Step 4.
- **`claude` CLI** installed on the VPS and authenticated (`claude --version` must return cleanly). Required by `retry_bounces.py` and `triage_daily_replies.py`.
- The client's **services-overview PDF** (1–3 pages, ideally under 2 MB).
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

- **Identity** — client legal name, slug, industry, owner names + stakes, timezone, currency display.
- **Sender** — full name, first name, title, email (must match the Gmail OAuth account), phone (human-readable + E.164).
- **Company** — legal name, short name, URL, bare domain, tagline, location, founded year.
- **Supabase** — Project URL (Project Settings → API). The service-role key is NOT entered here — it goes in `.credentials/supabase.env` at Step 4.
- **Owner alert emails** — comma-separated.

It writes those values across every `{{PLACEHOLDER}}` in `CLAUDE.md`, `README.md`, `context/`, `memory/`, `data/`, and generates `workflows/cold-outreach/config.py` from `config.example.py` with the substitutions applied. Body templates are left with a `# TODO: rewrite` marker — you customise those at Step 5.

**Other flags:**

- `./scripts/init-client.sh --force` — re-run on an already-initialised repo. Prompts for confirmation. Backs up any existing `config.py` to `config.py.bak.<timestamp>`.
- `./scripts/init-client.sh --non-interactive --from-json values.json` — unattended mode. See the `values.json` shape in the script header (`./scripts/init-client.sh --help`). Useful for scripted provisioning.

Commit the generated markdown changes after the substitutions look right. `config.py` itself is gitignored.

---

## Step 2 — Python environment + pinned deps

On the VPS:

```bash
cd ~/<client-slug>-ai-os
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt
```

`requirements.txt` pins every dependency (google-api, openpyxl, supabase, pytest). Do not `pip install` ad hoc — anything you add should be committed to `requirements.txt` in a dedicated "bump pin" commit.

`.venv/` is gitignored — every deployment builds its own.

---

## Step 3 — Gmail OAuth

Two tokens are required: **compose** (draft create + modify + send) and **readonly** (reply + bounce scan).

Canonical walkthrough: [`workflows/cold-outreach/oauth-setup.md`](./workflows/cold-outreach/oauth-setup.md). Follow it end-to-end.

Short version:

1. In the client's Google Cloud project: **APIs & Services → Credentials → Create OAuth client ID → Desktop app**. Download JSON → save as `.credentials/gmail_oauth_client.json`.
2. Add the sender's Gmail address as a **test user** on the OAuth consent screen.
3. From a machine with a browser (not the VPS), run the one-shot scripts documented in `oauth-setup.md` to generate `gmail_token.json` (compose scope) and `gmail_token_readonly.json` (readonly scope).
4. `scp` all three files into `.credentials/` on the VPS.

All three files are gitignored. Losing them means redoing the OAuth flow — back them up somewhere safe (e.g. a password manager).

---

## Step 4 — Supabase setup (mandatory)

Daily state backups live in Supabase Storage. If the VPS is lost, `scripts/restore_from_supabase.py` pulls the latest snapshot back. Skipping this step leaves the deployment with no disaster-recovery story.

1. Create a Supabase project at https://supabase.com/dashboard. Free tier is fine.
2. In the project, **Storage → New bucket**. Name it `backups`. Toggle **Private** — snapshots must not be publicly listable.
3. **Project Settings → API** — copy the `service_role` key. This is a high-privilege key; treat it like an admin password.
4. On the VPS, drop it into `.credentials/supabase.env` as a single line:
   ```
   SUPABASE_SERVICE_ROLE_KEY=eyJhbGciOi...
   ```
   (This file is gitignored.)
5. Confirm `SUPABASE_URL` is set correctly in `workflows/cold-outreach/config.py`. `init-client.sh` filled it in from your Step 1 answer; double-check it matches Project Settings → API → Project URL.

The default bucket name `backups` and the snapshot path layout (`backups/<CLIENT_SLUG>/<YYYY-MM-DD>/snapshot.tar.gz`) are driven by `SUPABASE_BACKUP_BUCKET` and `CLIENT_SLUG` in `config.py`.

---

## Step 5 — Customise `config.py`

Every per-deployment value lives in `workflows/cold-outreach/config.py`. Walk through each section using [`workflows/cold-outreach/CONFIG.md`](./workflows/cold-outreach/CONFIG.md) as your field-by-field reference.

The absolute must-touch items (init-client.sh prefilled identity, you fill the rest):

- **Body templates** — search for `TODO: rewrite`. `BODY_A`, `BODY_D`, `BODY_FOLLOWUP_1`, `BODY_FOLLOWUP_2`. These are the commercial heart of the workflow; don't ship the defaults.
- **Subject lines** — `SUBJECT_INITIAL`, `SUBJECT_FOLLOWUP_1`, `SUBJECT_FOLLOWUP_2`. F2 must stay distinctive (see CONFIG.md).
- **`SIGNATURE_HTML`** — confirm brand colours (`BRAND_*_COLOUR`) match the client's visual identity.
- **`BATCH_SIZE_RAMP_START_DATE`** — set this to the date of your first real send, in `YYYY-MM-DD` form. This activates the warm-up ramp (`[5, 5, 10, 10, 15, 15, 20, 20, 25, 25, 30]` by default). Leave as `None` only if the sender already has an established reputation.
- **`PDF_ATTACHMENT_FILENAME`** — matches the file you drop in Step 6.

Run a quick smoke test on the config itself:

```bash
.venv/bin/python3 -c "import sys; sys.path.insert(0, 'workflows/cold-outreach'); import config; print('OK')"
```

If that prints `OK`, the config imports cleanly.

---

## Step 6 — Seed leads, suppression list, and PDF

Drop three files into `workflows/cold-outreach/data/`:

1. **`<CLIENT_SLUG>-services-overview.pdf`** (filename must match `PDF_ATTACHMENT_FILENAME` in config).
2. **`master-lead-list.json`** — the scored lead queue. See [`data/master-lead-list.example.json`](./workflows/cold-outreach/data/master-lead-list.example.json) for the schema. Required per-lead fields: `brand`, `email`. Optional: `slug`, `contact_name`, `first_name`, `score`, `template` (`"A"` or `"D"`), `gaps`.
3. **`suppression-list.txt`** — one email address or domain per line. Seed it with:
   - The client's own domain (never email yourself).
   - Known competitor domains.
   - Any historic opt-outs carried over from a previous pipeline.

An empty suppression list is valid but risky — at least add the client's own domain.

---

## Step 7 — Dry run (READ-ONLY)

Do not skip this. The dry run catches placeholder leaks, signature typos, broken tel links, and wrong PDFs before anything goes over the wire.

```bash
cd ~/<client-slug>-ai-os
source .venv/bin/activate

# Lower the batch size temporarily for the dry run
# (Edit config.py — BATCH_SIZE = 3 — or just use the ramp's Day-0 value of 5.)

# 1. Generate the batch (writes markdown; no Gmail calls)
python3 workflows/cold-outreach/scripts/generate_daily_email_batch.py
ls workflows/cold-outreach/data/batches/
head -80 workflows/cold-outreach/data/batches/email-batch-$(date +%Y-%m-%d).md

# 2. Create drafts (goes to Gmail Drafts — NOT sent)
python3 workflows/cold-outreach/scripts/create_gmail_drafts.py

# 3. Open Gmail → Drafts. For each draft, verify:
#    - Correct recipient (To: field)
#    - Correct subject
#    - Body has {brand} / {first_name} / {sender} correctly substituted
#    - PDF attached with the right filename
#    - Signature renders (logo mark, contact rows, no broken colours)
#    - tel: link dials correctly on mobile
#    - Company URL is linkified

# 4. If anything is wrong, fix config.py, delete the drafts in Gmail by hand,
#    reset the tracker, and re-run:
python3 -c "
import json
p = 'workflows/cold-outreach/data/outreach-tracker.json'
t = json.load(open(p))
t['sent'] = []; t['batches'] = []
json.dump(t, open(p, 'w'), indent=2)
print('Tracker wiped.')
"

# 5. When happy, delete all test drafts from Gmail and rewind the tracker
#    one final time before the first real cron run.
```

---

## Step 8 — `./scripts/bootstrap-vps.sh`

One-shot VPS provisioning. Idempotent — safe to re-run.

```bash
./scripts/bootstrap-vps.sh
```

It performs six steps:

1. **Python venv** — creates `.venv/` if missing, installs/updates `requirements.txt`.
2. **Claude CLI** — verifies `claude --version` works; aborts with install instructions if not.
3. **Directories** — creates `logs/outreach`, `.credentials`, `workflows/cold-outreach/data/batches`, `workflows/cold-outreach/data/backups`.
4. **Logrotate** — installs `/etc/logrotate.d/<repo>-outreach` (weekly, 8-week retention, compressed). Requires sudo; warns and continues if sudo unavailable.
5. **Cron** — offers to install the four cron entries (daily outreach, evening triage, CRM maintenance, daily backup). Prompts before modifying the user crontab.
6. **Doctor** — runs `scripts/doctor.sh` as the final sanity check.

Dry-run mode: `./scripts/bootstrap-vps.sh --dry-run` previews cron + logrotate changes without applying them.

---

## Step 9 — `./scripts/doctor.sh`

Sixteen-check health self-test. Must return all green before the first cron fires.

```bash
./scripts/doctor.sh
```

The checks (in order):

1. `.venv/` present and `requirements.txt` deps installed.
2. `config.py` imports cleanly.
3. No `{{PLACEHOLDER}}` tokens remain in `context/`, `memory/`, `CLAUDE.md`.
4. `.credentials/gmail_oauth_client.json` exists.
5. `gmail_token.json` (compose) — refreshes successfully + authorised email matches `config.SENDER_EMAIL`.
6. `gmail_token_readonly.json` — refreshes + can list `in:sent`.
7. `.credentials/supabase.env` exists and contains `SUPABASE_SERVICE_ROLE_KEY`.
8. `claude` CLI on `PATH`.
9. PDF attachment exists at the path `config.PDF_ATTACHMENT_PATH` resolves to.
10. `master-lead-list.json` is valid JSON, non-empty, every lead has `brand` + `email`.
11. `suppression-list.txt` exists.
12. All four cron entries installed.
13. `pytest` can collect tests in `tests/`.
14. `logs/outreach/` is writable.
15. `.outreach-paused` — warn (not fail) if present.
16. `.send-halted` — warn (not fail) if present.

Red Xs are fatal — fix and re-run. Yellow warnings (checks 15 + 16) only flag unusual state; they don't block deployment.

---

## Step 10 — First live run + observation

The first Mon–Fri after install, cron fires at 10:00 UTC. Watch it live:

```bash
tail -f logs/outreach/run-$(date +%Y-%m-%d).log
```

Healthy output:

```
============================================
Daily Outreach Run — Mon Apr 28 10:00:01 UTC 2026
============================================

--- 1. Detect replies + bounces ---
Checking 0 unique recipient(s) for replies and bounces
Replies found: 0
Bounces found: 0

--- 2. Retry bounced emails ---
New bounces eligible for retry: 0

--- 3. Generate initial batch ---
[warm-up ramp] day 0 → batch size 5
Batch generated: data/batches/email-batch-2026-04-28.md
Emails in batch: 5

--- 4. Create initial-batch Gmail drafts ---
Drafts created: 5
Failed:         0

--- 5. Create follow-up drafts ---
Candidates for follow-up today: 0

--- 6. Send all drafts (33s delay) ---
Found 5 drafts to send
  [1/5] SENT -> ...
  ...
Sent: 5, Skipped: 0, Failed: 0

--- 7. Refresh CRM xlsx ---
CRM saved to: data/outreach-crm.xlsx

--- DONE at Mon Apr 28 10:03:27 UTC 2026 ---
```

Look for the `[warm-up ramp] day N → batch size M` line confirming the ramp is in effect. Any `FAILED`, `ERROR`, `Traceback`, or `SKIP-NO-METADATA` line is an alert — investigate before the next day's run. Owner-alert emails will land in the mailboxes configured in `OWNER_ALERT_EMAILS`.

---

## Step 11 — Emergency stop

Two independent kill switches:

**Pause flag** — operator-initiated, cancels all future runs until cleared:

```bash
touch ~/<client-slug>-ai-os/.outreach-paused
rm    ~/<client-slug>-ai-os/.outreach-paused   # resume
```

**Circuit breaker** — automatic. `send_drafts.py` drops `.send-halted` after `CONSECUTIVE_HTTPERROR_LIMIT` consecutive Gmail errors and alerts the owners. All three cron wrappers refuse to start while `.send-halted` exists.

Recovery:

```bash
# 1. Inspect the log that tripped the breaker
tail -80 logs/outreach/run-$(date +%Y-%m-%d).log

# 2. Fix the underlying cause (expired token, rate limit, bad draft)
./scripts/doctor.sh

# 3. Delete the sentinel to re-arm
rm ~/<client-slug>-ai-os/.send-halted
```

**Kill a run in flight:**

```bash
pkill -9 -f send_drafts.py
pkill -9 -f run_daily_outreach
```

---

## Step 12 — Backup + restore walkthrough

The daily backup at 03:30 UTC snapshots `BACKUP_PATHS` into `<SUPABASE_BACKUP_BUCKET>/backups/<CLIENT_SLUG>/<YYYY-MM-DD>/snapshot.tar.gz`. Retention is 30 days.

Verify backups are landing — on any day after the first backup has fired:

```bash
.venv/bin/python3 scripts/restore_from_supabase.py --list
```

You should see today's date. If the list is empty, check `logs/outreach/backup-<date>.log` for the failure.

**Restore drill** (run on a scratch VM, not production):

```bash
# Latest snapshot
.venv/bin/python3 scripts/restore_from_supabase.py

# Specific date
.venv/bin/python3 scripts/restore_from_supabase.py --from-date 2026-04-22

# Skip the "type RESTORE to confirm" prompt
.venv/bin/python3 scripts/restore_from_supabase.py --yes
```

The script lists every file in the snapshot with `(OVERWRITE)` or `(NEW)` tags, then gates extraction on typing the literal word `RESTORE`. Extraction writes files back to their original relative paths under the repo root.

Practice this once on a scratch machine before you need it under real pressure. A confirmed working restore is the last step of a live deployment.

---

## Deployment checklist

Copy into the first commit message of the new client's repo so the history documents the deployment:

```
[ ]  1. Template forked; init-client.sh run; no {{placeholders}} left
[ ]  2. Python venv created; requirements.txt installed on VPS
[ ]  3. Gmail OAuth: client JSON + compose token + readonly token in .credentials/
[ ]  4. Supabase project created; 'backups' bucket exists (private);
        SUPABASE_SERVICE_ROLE_KEY in .credentials/supabase.env
[ ]  5. config.py customised: bodies, subjects, signature, ramp start date
[ ]  6. services PDF + master-lead-list.json + suppression-list.txt in data/
[ ]  7. Dry run: 3-5 drafts reviewed in Gmail; drafts + tracker wiped
[ ]  8. bootstrap-vps.sh run; logrotate installed; 4 cron entries installed
[ ]  9. doctor.sh: 16/16 green
[ ] 10. First real cron observed; warm-up batch size logged; no errors
[ ] 11. .outreach-paused touch/remove tested; .send-halted recovery path rehearsed
[ ] 12. restore_from_supabase.py --list works; restore drill completed on a scratch VM
```
