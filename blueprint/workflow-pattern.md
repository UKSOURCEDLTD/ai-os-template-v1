# Workflow Pattern

*The canonical shape every workflow in the AI OS must follow. Read this before proposing or building any workflow beyond the first one.*

The cold-outreach workflow (`_template/workflows/cold-outreach/`) is the reference implementation. This document generalises it — so workflow #2 (lead enrichment, inbox triage, monthly reporting, whatever comes next) slots in without the OS's plumbing needing any code changes.

---

## 1. Philosophy

A **workflow** is a self-contained capability that can run unattended on a schedule. It has its own config, its own state, its own scripts, its own docs, and its own tests. It cooperates with shared OS-level services (backup, doctor, alerts, logs, cron) but owns nothing of theirs.

Strict conventions matter because the OS is the common substrate. `bootstrap-vps.sh`, `doctor.sh`, `backup_to_supabase.py`, `send_owner_alert.py`, and the logrotate config all assume uniform shape. Break the shape in workflow #2 and you either fork the plumbing (bad) or the plumbing silently skips your workflow (worse).

Every workflow must preserve these five invariants:

1. **File-based state.** JSON + CSV + markdown on disk. No workflow-private database. Enables trivial backup and trivial inspection.
2. **Single config file.** Every per-deployment value lives in `config.py`. Zero strings hardcoded in scripts.
3. **Orchestrator script pattern.** One `run_daily_{name}.sh` (or weekly/monthly — the schedule varies, the pattern doesn't). Cron calls only this.
4. **Regression tests.** Every production bug becomes a test. No silent failures.
5. **Cooperative with OS plumbing.** Config exposes `BACKUP_PATHS`, `CLIENT_SLUG`, `ALERT_SUBJECT_PREFIX`, `OWNER_ALERT_EMAILS`. State goes under `data/`. Logs go under `logs/{workflow}/`. Alerts go through `scripts/send_owner_alert.py`.

If you catch yourself writing plumbing that duplicates an OS-level script, stop — either extend the OS script or use it as-is.

---

## 2. Folder layout (strict)

```
workflows/{workflow-name}/
├── README.md                   ← operator-facing: what this does, where state lives, daily operation
├── CONFIG.md                   ← every config.py field explained, rationale per field
├── config.example.py           ← single source of truth for every per-deployment value
├── oauth-setup.md              ← only if the workflow needs OAuth (omit otherwise)
├── scripts/
│   ├── run_daily_{name}.sh     ← cron entrypoint — even if it runs weekly/monthly
│   ├── _shared_helpers.py      ← module-private helpers (underscore prefix — do not import from outside)
│   ├── <step-1>.py             ← one module per pipeline step
│   ├── ...
│   ├── build_{name}_report.py  ← artefact rebuild (if the workflow produces a human-readable report)
│   └── cron-entries.txt        ← crontab lines this workflow owns (convention, see §6)
└── data/
    ├── {state-files}.json / .csv
    ├── suppression-list.txt    ← if applicable
    └── backups/.gitkeep
```

Hard rules:

- **No config values hardcoded in scripts.** Every per-deployment string lives in `config.py`. If you catch a literal brand name, email address, or directory path in a `.py` file, lift it to config.
- **State files live under `data/`.** Never under `scripts/` and never at the workflow root. Even temporary artefacts (`.completed-{DATE}` markers, lock-adjacent state) go under `data/`.
- **Scripts import config by prepending the workflow dir to `sys.path`:**
  ```python
  import os, sys
  WORKFLOW_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
  sys.path.insert(0, WORKFLOW_DIR)
  import config  # noqa: E402
  ```
  Every script in `scripts/` starts with this block. No relative imports, no `from ..config import` tricks — they break when cron runs the script from a different cwd.
- **Helper modules intended only for internal use start with `_`.** `_shared_helpers.py`, `_gmail_auth.py`. The underscore is the "don't import me from outside this workflow" signal.
- **No cross-workflow imports.** If workflow B needs code from workflow A, factor it into a top-level utility (rare) or duplicate it. Workflows are independent units.

---

## 3. The `config.py` contract

Every workflow's `config.py` must:

1. **Import cleanly with no side effects.** No network calls, no file writes, no interactive OAuth flow at import time. (An `if __name__ == "__main__":` block that triggers an OAuth refresh is fine — just not at module load.)
2. **Expose `CLIENT_SLUG`** — short lowercased identifier matching the rest of the deployment. Used by lock files, alert subject prefixes, and log paths.
3. **Expose `BACKUP_PATHS`** — a list of files and directories `backup_to_supabase.py` should snapshot for this workflow. The backup script reads this list and needs no code change when a new workflow is added.
4. **Expose `OWNER_ALERT_EMAILS`** — list of addresses to notify on critical failure. `send_owner_alert.py` reads this.
5. **Expose `ALERT_SUBJECT_PREFIX`** — e.g. `"[acme-outreach]"`. Prepended to every alert subject so routing rules in the owners' inboxes work.
6. **Define path constants at the bottom** — all paths computed from `WORKFLOW_DIR = os.path.dirname(os.path.abspath(__file__))`. Scripts never hardcode paths.

Minimum required block at the top of `config.py`:

```python
# OS-level fields (every workflow must define these)
CLIENT_SLUG = "acme"
ALERT_SUBJECT_PREFIX = f"[{CLIENT_SLUG}-{WORKFLOW_NAME}]"  # e.g. "[acme-outreach]"
OWNER_ALERT_EMAILS = [
    "ops@acmeagency.com",
]
```

Minimum required block at the bottom:

```python
import os

WORKFLOW_DIR = os.path.dirname(os.path.abspath(__file__))
DATA_DIR = os.path.join(WORKFLOW_DIR, "data")
SCRIPTS_DIR = os.path.join(WORKFLOW_DIR, "scripts")
REPO_ROOT = os.path.dirname(os.path.dirname(WORKFLOW_DIR))
LOG_DIR = os.path.join(REPO_ROOT, "logs", "{workflow-name}")
CREDS_DIR = os.path.join(REPO_ROOT, ".credentials")

# What backup_to_supabase.py should snapshot for this workflow.
# Include state files (not logs — logrotate owns those, not backup).
BACKUP_PATHS = [
    os.path.join(DATA_DIR, "master-lead-list.json"),
    os.path.join(DATA_DIR, "outreach-crm.csv"),
    os.path.join(DATA_DIR, "outreach-tracker.json"),
    os.path.join(DATA_DIR, "suppression-list.txt"),
]
```

**Validation is part of the contract.** `config.py` should include module-level `assert` statements on required fields so `import config` fails loudly if a deployment forgot to fill something in. `doctor.sh` imports every workflow's config as one of its checks — that's the enforcement loop.

```python
assert SENDER_EMAIL and "@" in SENDER_EMAIL, "config.SENDER_EMAIL must be set"
assert OWNER_ALERT_EMAILS, "config.OWNER_ALERT_EMAILS must have at least one address"
assert CLIENT_SLUG and CLIENT_SLUG.islower(), "CLIENT_SLUG must be lowercase"
```

---

## 4. The orchestrator pattern

Every workflow has one cron entrypoint: `scripts/run_daily_{name}.sh`. Even if the workflow runs weekly or monthly, the filename prefix stays `run_daily_` — the cron schedule alone determines frequency.

Required features, in order:

1. `set -e` + `set -o pipefail` — fail loud.
2. File lock via `flock` at `/tmp/{slug}-{workflow}.lock`. Prevents cron + manual collision.
3. Idempotency marker at `data/.completed-{DATE}`. Subsequent same-day invocations short-circuit.
4. Schedule guard (weekend skip, first-of-month-only, etc. — whatever the workflow's cadence requires).
5. Pause flag check: `if [ -f "$REPO_ROOT/.{workflow}-paused" ]; then exit 0; fi`.
6. Circuit-breaker flag check (optional but recommended): `if [ -f "$REPO_ROOT/.{workflow}-halted" ]; then exit 1 after alert; fi`. This is for "something broke yesterday, don't run again until a human checks".
7. Per-step `alert_owner` function that calls `scripts/send_owner_alert.py` on critical-step failure.
8. Logging via `{ ... } 2>&1 | tee -a "$LOG"` with one log per run at `logs/{workflow}/run-YYYY-MM-DD.log`.
9. Touch the idempotency marker at the end of a successful run.

Copy-paste skeleton:

```bash
#!/bin/bash
# {Workflow} daily orchestrator.
# Layout assumptions:
#   - This script lives at workflows/{workflow-name}/scripts/
#   - Repo root is 3 levels up
#   - Python venv is at <repo_root>/.venv

set -e
set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
WORKFLOW_DIR="$(dirname "$SCRIPT_DIR")"
REPO_ROOT="$(dirname "$(dirname "$WORKFLOW_DIR")")"
WORKFLOW_NAME="$(basename "$WORKFLOW_DIR")"

LOG_DIR="$REPO_ROOT/logs/$WORKFLOW_NAME"
DATE=$(date -u +%Y-%m-%d)
LOG="$LOG_DIR/run-$DATE.log"
LOCK="/tmp/$(basename "$REPO_ROOT")-$WORKFLOW_NAME.lock"

mkdir -p "$LOG_DIR"

# File lock
exec 9>"$LOCK"
if ! flock -n 9; then
    echo "[$(date)] Another $WORKFLOW_NAME run in progress — skipping." | tee -a "$LOG"
    exit 0
fi

# Idempotency
if [ -f "$WORKFLOW_DIR/data/.completed-$DATE" ]; then
    echo "[$(date)] $WORKFLOW_NAME already completed for $DATE — skipping." | tee -a "$LOG"
    exit 0
fi

# Venv
[ -f "$REPO_ROOT/.venv/bin/activate" ] && source "$REPO_ROOT/.venv/bin/activate"

cd "$REPO_ROOT"

alert_owner() {
    local subject="$1" body="$2"
    python3 "$REPO_ROOT/scripts/send_owner_alert.py" --subject "$subject" --body "$body" \
        || echo "WARN: alert dispatch failed for: $subject" | tee -a "$LOG"
}

{
    echo "============================================"
    echo "$WORKFLOW_NAME run — $(date -u)"
    echo "============================================"

    # Schedule guard (example: weekday-only)
    DOW=$(date -u +%u)
    if [ "$DOW" -ge 6 ]; then
        echo "Weekend ($DOW) — skipping."
        exit 0
    fi

    # Pause flag
    if [ -f "$REPO_ROOT/.$WORKFLOW_NAME-paused" ]; then
        echo "Pause flag (.$WORKFLOW_NAME-paused) found — skipping."
        exit 0
    fi

    echo ""
    echo "--- 1. <step description> ---"
    python3 -u "$SCRIPT_DIR/step_1.py" || {
        alert_owner "$WORKFLOW_NAME step 1 failed" "See $LOG"
        echo "Step 1 failed — continuing."
    }

    echo ""
    echo "--- 2. <step description> ---"
    python3 -u "$SCRIPT_DIR/step_2.py"   # critical — fail the whole run if this fails

    # Mark complete
    touch "$WORKFLOW_DIR/data/.completed-$DATE"
    echo ""
    echo "--- DONE at $(date -u) ---"
} 2>&1 | tee -a "$LOG"
```

Rules of thumb:

- **Non-critical steps** (detection, classification, cleanup) use `|| { alert_owner ...; echo "continuing."; }` so one failure doesn't abort the run.
- **Critical steps** (the step that actually does the thing) have no `||` — they fail the run loudly.
- **Never `rm -rf`** anything in the orchestrator. If you need to clear state, do it in a dedicated Python script with logging, not inline in bash.

---

## 5. Test contract

Every workflow has a `tests/{workflow-name}/` directory.

`pytest tests/` must pass before `doctor.sh` reports green. Tests mock every external API — no real Gmail token, no real Claude CLI call, no real network. A contributor with a clean checkout must be able to run the full test suite.

**The minimum test set every workflow ships with:**

1. **Config imports cleanly.** `import config` raises nothing. All required fields present.
2. **No dead config fields.** Every field in `config.py` is referenced by at least one script. (Walk the config module, grep the scripts dir — anything in config that no script reads is either dead code or a silent footgun.)
3. **Orchestrator exits cleanly when pause flag is present.** Create `.{workflow}-paused`, invoke the orchestrator with a mocked python, assert exit 0 and no side effects.
4. **Orchestrator short-circuits on `.completed-{DATE}`.** Touch the marker, invoke orchestrator, assert no steps ran.
5. **State file corruption is recoverable.** Feed the workflow a malformed JSON state file; assert it moves the bad file aside (`.corrupt-YYYY-MM-DD`), starts fresh, and calls `alert_owner`. Never silently overwrite a broken file — you lose the forensic trail.

**Plus: one test per lesson learned.** Every entry in `blueprint/{workflow}-system.md#lessons-learned` must have a matching test that would have caught the original bug. Cold-outreach's six lessons translate to six regression tests. Future workflows inherit the principle: production bug → blueprint entry → test → done. If you skip the test, you'll repeat the bug.

Test conventions:

- Use `pytest` (already in `requirements.txt`).
- Name tests after the behaviour, not the function: `test_empty_to_address_does_not_delete_draft`, not `test_send_drafts_5`.
- Mock the Google API client with a minimal fake (`class FakeGmail: ...`) — don't try to use `mock.patch` on a dozen chained method calls.
- Each test file imports config with a dedicated test config if the real config has required fields the test doesn't need (set env var `WORKFLOW_CONFIG_MODULE=tests.{workflow}.test_config` or similar; pattern TBD).

---

## 6. OS-level cooperation

A new workflow hooks into shared OS services by following conventions, not by modifying shared code.

### Backup

Add state paths to `config.BACKUP_PATHS`. That's it. `scripts/backup_to_supabase.py` discovers every workflow's `config.py`, unions their `BACKUP_PATHS` lists, and uploads a daily snapshot to Supabase Storage. No code change in the backup script.

(Note: at time of writing, `backup_to_supabase.py` does not yet exist in `scripts/` — a parallel effort is building it. When it lands, it must follow this contract. Until then, workflows should still declare `BACKUP_PATHS` so they're ready.)

### Doctor

`doctor.sh` discovers workflows by scanning `workflows/*/config.py` and doing `python3 -c "import config"` from each workflow dir. The `assert` statements in your config do the validation. Doctor needs no per-workflow code — just make sure your config asserts loudly.

If your workflow needs a doctor check that's not simply "does config import", add a module-level function `config.doctor_checks()` returning a list of `(name, status, detail)` tuples. Doctor will invoke it if present.

### Alerts

Use `scripts/send_owner_alert.py` via subprocess. Never send alert emails directly from workflow scripts — you'd need to re-plumb Gmail auth in every workflow.

```bash
python3 "$REPO_ROOT/scripts/send_owner_alert.py" \
    --subject "outreach bounce rate 7.3%" \
    --body "See logs/outreach/run-$(date +%F).log"
```

The alert script reads `OWNER_ALERT_EMAILS` and `ALERT_SUBJECT_PREFIX` from whichever workflow's config is importable. For multi-workflow deployments, pass `--workflow {name}` so the right config is loaded.

### Logs

Write to `logs/{workflow}/` — never to `logs/` directly. The logrotate config at the OS level is globbed `logs/**/*.log` — your logs get rotated automatically.

No custom log formats. Plain text, newline-separated, prefix each line with a timestamp if the script runs for more than a minute.

### Cron

Each workflow owns its cron entries. Convention: ship them as `scripts/cron-entries.txt`, one entry per line, comments allowed:

```
# {workflow-name} daily — runs Mon-Fri 10:00 UTC
0 10 * * 1-5 /home/<user>/<repo>/workflows/{workflow-name}/scripts/run_daily_{workflow-name}.sh
```

`bootstrap-vps.sh` reads every workflow's `cron-entries.txt`, unions them with the user's existing crontab (de-duping by content), and offers to install. No manual `crontab -e` needed on a fresh deployment.

(Status: `cron-entries.txt` does not yet exist for cold-outreach. It should be added. This is the target state — new workflows should ship it from day one; cold-outreach should backfill.)

---

## 7. Documentation contract

Every workflow ships three docs, no more, no less.

- **`README.md`** — operator view. What the workflow does, when it runs, where state lives, how to trigger manually, how to pause, how to debug. Written for the human who wakes up at 3 a.m. to a pager.
- **`CONFIG.md`** — every field in `config.py` explained. What it does, why it exists, when you'd change it, common mistake. Written for the human configuring a fresh deployment.
- **`blueprint/{workflow}-system.md`** — engineering spec. Data contracts, pipeline flow, OAuth setup, lessons learned. This is the canonical spec a future agent rebuilds from. The **"Lessons learned" section grows over time** as production bugs are found and fixed — add an entry for every incident, with enough detail that the fix isn't lost when the person who fixed it moves on.

The README and CONFIG live inside the workflow folder. The blueprint doc lives under top-level `blueprint/` so it's discoverable alongside the architecture and other specs.

---

## 8. Anti-patterns (things NOT to do)

✗ **Hardcoding paths, identities, or thresholds in scripts.** Everything configurable goes in `config.py`. If a script has `SENDER = "Jane"` at the top, lift it.

✗ **Using a service account instead of user OAuth** where the pipeline sends as a human. Service accounts can't send mail on personal Gmail without domain-wide delegation, and even with DWD the "From" headers look wrong. Use an interactive user OAuth flow for the sender's own account.

✗ **Silent failure handling.** Bare `except:` that continues without logging is forbidden. Either log the exception and alert the owner, or let it propagate. Never both log-and-swallow — that hides bugs for months.

✗ **Modifying state before the external action succeeds.** Cold-outreach currently marks leads as "sent" in the tracker before Gmail confirms delivery. This is an accepted trade-off with a CRM-based safety net, but future workflows should prefer post-confirm marking: write state only after the external system confirms the action. Two-phase: `pending → committed`.

✗ **Creating new top-level directories.** The existing folders (`blueprint/`, `context/`, `workflows/`, `memory/`, `data/`, `logs/`, `scripts/`, `clients/`, `integrations/`, plus `CLAUDE.md`) cover everything. If you need new state, it almost certainly goes under `workflows/{name}/data/`.

✗ **Depending on Supabase URL or service key via env vars in scripts.** Always go through `config` + `.credentials/supabase.env`. Env vars disappear when cron runs the script in a clean shell.

✗ **Long scripts.** If a step script exceeds ~300 lines, it's doing too much. Split it. Each script should have one obvious responsibility.

✗ **Cross-workflow imports.** Workflow B should not `from workflows.a.scripts import ...`. If the function is general, lift it to a top-level utility module. Usually the right answer is duplicate rather than couple.

---

## 9. How to propose a new workflow

1. **Write the blueprint first.** Open `blueprint/{workflow-name}-system.md` describing the problem, inputs, outputs, failure modes. Target 200-400 lines. No code yet. If you can't explain it cleanly in prose, don't implement it yet.
2. **Draft `config.example.py`.** Every tunable listed, every value documented inline. No defaults that hide real decisions.
3. **Write the smallest possible orchestrator + a single step's script.** Prove the loop end-to-end with one trivial step before fleshing out the rest.
4. **Add regression tests for every failure mode you anticipated** in the blueprint. A failure mode without a test is an incident waiting to happen.
5. **Add `scripts/cron-entries.txt`.** Even if you won't install the cron immediately, declare what schedule the workflow intends.
6. **Run `doctor.sh`.** Your new workflow must be discoverable and green. If doctor doesn't report your workflow, the convention was broken somewhere.
7. **Write `README.md` and `CONFIG.md`.** Only after the code works. Docs written before the code are aspirational; docs written after are true.

---

## 10. Example — adding an inbox-triage workflow

Pseudocode walkthrough of the minimum viable workflow — 20 lines of code, four files.

**`workflows/inbox-triage/config.example.py`:**
```python
import os
WORKFLOW_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(os.path.dirname(WORKFLOW_DIR))

CLIENT_SLUG = "acme"
ALERT_SUBJECT_PREFIX = f"[{CLIENT_SLUG}-triage]"
OWNER_ALERT_EMAILS = ["ops@acmeagency.com"]

TRIAGE_LOOKBACK_DAYS = 1
HIGH_PRIORITY_KEYWORDS = ["urgent", "asap", "invoice", "refund"]

DATA_DIR = os.path.join(WORKFLOW_DIR, "data")
TRIAGE_LOG = os.path.join(DATA_DIR, "triage-log.jsonl")
BACKUP_PATHS = [TRIAGE_LOG]

assert OWNER_ALERT_EMAILS, "OWNER_ALERT_EMAILS required"
```

**`workflows/inbox-triage/scripts/triage_inbox.py`:**
```python
import json, os, sys
from datetime import datetime
WORKFLOW_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
sys.path.insert(0, WORKFLOW_DIR)
import config

def main():
    # ...fetch inbox, classify, append to config.TRIAGE_LOG as jsonl...
    with open(config.TRIAGE_LOG, 'a') as f:
        f.write(json.dumps({"ts": datetime.utcnow().isoformat(), "count": 0}) + "\n")

if __name__ == "__main__":
    main()
```

**`workflows/inbox-triage/scripts/run_daily_triage.sh`:**
Copy the skeleton from §4, substitute `triage` for `{workflow-name}`, call `triage_inbox.py` as the single step.

**`workflows/inbox-triage/scripts/cron-entries.txt`:**
```
# inbox triage — hourly Mon-Fri business hours
0 9-18 * * 1-5 /home/<user>/<repo>/workflows/inbox-triage/scripts/run_daily_triage.sh
```

**`tests/inbox-triage/test_config_imports.py`:**
```python
import importlib, sys, os
sys.path.insert(0, os.path.join(os.path.dirname(__file__), '..', '..', 'workflows', 'inbox-triage'))
def test_config_imports():
    importlib.import_module("config")
```

That's the floor. Everything else — README, CONFIG.md, the blueprint doc, the full test matrix — gets added as the workflow matures.

---

## 11. Checklist for reviewers

A code review of a new workflow (or a substantial change to an existing one) verifies:

- [ ] `config.example.py` exists, imports cleanly, defines `CLIENT_SLUG`, `ALERT_SUBJECT_PREFIX`, `OWNER_ALERT_EMAILS`, `BACKUP_PATHS`, and path constants at the bottom
- [ ] Every per-deployment string is in `config.py`, not in a script
- [ ] `config.py` has `assert` statements on required fields
- [ ] Scripts use the `sys.path.insert(0, WORKFLOW_DIR); import config` pattern, not relative imports
- [ ] State lives under `data/`, logs under `logs/{workflow}/`, credentials under `.credentials/`
- [ ] `run_daily_{name}.sh` has: `set -e`, `set -o pipefail`, flock lock, completed-marker, pause flag check, log piping, `alert_owner` helper
- [ ] Non-critical steps guarded with `|| { alert_owner ...; echo continuing; }`; critical steps not guarded
- [ ] `scripts/cron-entries.txt` present and schedule matches the orchestrator's schedule guard
- [ ] `tests/{workflow-name}/` exists with at least the five minimum tests from §5 passing
- [ ] Every "lessons learned" entry in the blueprint has a matching regression test
- [ ] `README.md`, `CONFIG.md`, and `blueprint/{workflow}-system.md` all exist and are current
- [ ] `doctor.sh` reports the workflow as discovered and green
- [ ] No service-account auth, no bare `except:`, no cross-workflow imports, no new top-level directories
- [ ] Alert dispatch goes through `scripts/send_owner_alert.py`, not direct Gmail/SMTP calls
- [ ] Dry-run instructions included in the README (how to exercise the full pipeline without external side effects)

If any of these is missing, the workflow is not ready to ship. The OS's plumbing assumes uniform shape — deviation here breaks invisible things later.
