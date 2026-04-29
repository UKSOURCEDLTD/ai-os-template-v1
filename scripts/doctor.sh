#!/bin/bash
# doctor.sh — AI OS health check.
#
# Prints a checklist of 16 checks. Exit 0 iff every required check passes.
# Warnings (pause flag, halt flag) don't fail the check.
#
# Usage:
#   ./scripts/doctor.sh
#   ./scripts/doctor.sh --help

set -u

if [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    sed -n '2,10p' "$0" | sed 's/^# \{0,1\}//'
    exit 0
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
cd "$REPO_ROOT"

GREEN=$'\033[32m'
RED=$'\033[31m'
YELLOW=$'\033[33m'
DIM=$'\033[2m'
RESET=$'\033[0m'

PASS=0
FAIL=0
TOTAL=0

check() {
    # check <status> <name> <detail>
    TOTAL=$((TOTAL + 1))
    local status="$1" name="$2" detail="${3:-}"
    if [ "$status" = "ok" ]; then
        printf '  %s✓%s %s%s%s\n' "$GREEN" "$RESET" "$name" \
            "${detail:+ — $DIM$detail$RESET}" ""
        PASS=$((PASS + 1))
    elif [ "$status" = "warn" ]; then
        printf '  %s!%s %s%s\n' "$YELLOW" "$RESET" "$name" \
            "${detail:+ — $detail}"
        PASS=$((PASS + 1))  # warnings don't fail
    else
        printf '  %s✗%s %s%s\n' "$RED" "$RESET" "$name" \
            "${detail:+ — $detail}"
        FAIL=$((FAIL + 1))
    fi
}

echo "=============================================="
echo "AI OS doctor — $(date -u +'%Y-%m-%d %H:%M:%S UTC')"
echo "Repo: $REPO_ROOT"
echo "=============================================="

# -----------------------------------------------------------------------------
# 1. venv + deps
# -----------------------------------------------------------------------------
VENV_PY="$REPO_ROOT/.venv/bin/python3"
if [ ! -x "$VENV_PY" ]; then
    check fail "Python venv" ".venv/ missing — run scripts/bootstrap-vps.sh"
else
    # Compare installed vs pinned. Use pip freeze + requirements.txt.
    MISSING_PKGS="$("$VENV_PY" -m pip install --dry-run -r "$REPO_ROOT/requirements.txt" 2>&1 \
        | grep -iE 'would install|error' | head -3 || true)"
    if [ -z "$MISSING_PKGS" ]; then
        check ok "Python venv + requirements.txt" "all pinned deps installed"
    else
        check fail "Python venv + requirements.txt" "missing deps — run .venv/bin/pip install -r requirements.txt"
    fi
fi

# -----------------------------------------------------------------------------
# 2. config.py imports cleanly
# -----------------------------------------------------------------------------
CONFIG_PY="$REPO_ROOT/workflows/cold-outreach/config.py"
if [ ! -f "$CONFIG_PY" ]; then
    check fail "config.py exists" "cp workflows/cold-outreach/config.example.py workflows/cold-outreach/config.py"
else
    # Import by adding the workflow dir to sys.path (mirrors how other scripts do it).
    IMPORT_ERR="$("$VENV_PY" -c "
import sys, os
sys.path.insert(0, '$REPO_ROOT/workflows/cold-outreach')
import config
" 2>&1 || true)"
    if [ -z "$IMPORT_ERR" ]; then
        check ok "config.py imports" "workflows/cold-outreach/config.py"
    else
        check fail "config.py imports" "$(printf '%s' "$IMPORT_ERR" | tail -1)"
    fi
fi

# -----------------------------------------------------------------------------
# 3. No {{PLACEHOLDER}} tokens remain in context/, memory/, CLAUDE.md
# -----------------------------------------------------------------------------
PLACEHOLDER_HITS=""
for target in "$REPO_ROOT/context" "$REPO_ROOT/memory" "$REPO_ROOT/CLAUDE.md"; do
    if [ -e "$target" ]; then
        hits="$(grep -rlE '\{\{[A-Z_]+\}\}' "$target" 2>/dev/null || true)"
        [ -n "$hits" ] && PLACEHOLDER_HITS="$PLACEHOLDER_HITS $hits"
    fi
done
if [ -z "$PLACEHOLDER_HITS" ]; then
    check ok "no {{PLACEHOLDER}} tokens remain" "context/, memory/, CLAUDE.md clean"
else
    N="$(printf '%s\n' $PLACEHOLDER_HITS | wc -l | tr -d ' ')"
    check fail "no {{PLACEHOLDER}} tokens" "$N file(s) still have placeholders — run scripts/init-client.sh"
fi

# -----------------------------------------------------------------------------
# 4. Gmail OAuth client JSON
# -----------------------------------------------------------------------------
if [ -f "$REPO_ROOT/.credentials/gmail_oauth_client.json" ]; then
    check ok ".credentials/gmail_oauth_client.json"
else
    check fail ".credentials/gmail_oauth_client.json" "see DEPLOY.md step 3"
fi

# -----------------------------------------------------------------------------
# 5. Compose token — refresh + emailAddress matches config.SENDER_EMAIL
# -----------------------------------------------------------------------------
GMAIL_COMPOSE_CHECK="$("$VENV_PY" - <<'PY' 2>&1 || true
import sys, os
REPO_ROOT = os.environ.get('REPO_ROOT')
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
try:
    import config
except Exception as e:
    print(f'ERR config: {e}')
    sys.exit(1)
try:
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
except Exception as e:
    print(f'ERR deps: {e}')
    sys.exit(1)
SCOPES = ['https://www.googleapis.com/auth/gmail.compose']
if not os.path.exists(config.GMAIL_TOKEN):
    print('ERR missing: .credentials/gmail_token.json')
    sys.exit(1)
try:
    creds = Credentials.from_authorized_user_file(config.GMAIL_TOKEN, SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
    svc = build('gmail', 'v1', credentials=creds, cache_discovery=False)
    profile = svc.users().getProfile(userId='me').execute()
    actual = profile.get('emailAddress', '')
    expected = config.SENDER_EMAIL
    if actual.lower() == expected.lower():
        print(f'OK {actual}')
    else:
        print(f'ERR mismatch: token={actual} config.SENDER_EMAIL={expected}')
except Exception as e:
    print(f'ERR {type(e).__name__}: {e}')
PY
)"
REPO_ROOT="$REPO_ROOT" :  # (env already set)
if printf '%s' "$GMAIL_COMPOSE_CHECK" | grep -q '^OK '; then
    addr="$(printf '%s' "$GMAIL_COMPOSE_CHECK" | sed 's/^OK //')"
    check ok "gmail_token.json (compose)" "authorised as $addr"
else
    detail="$(printf '%s' "$GMAIL_COMPOSE_CHECK" | sed 's/^ERR //' | head -1)"
    check fail "gmail_token.json (compose)" "$detail"
fi

# -----------------------------------------------------------------------------
# 6. Readonly token — refresh + can list in:sent
# -----------------------------------------------------------------------------
GMAIL_RO_CHECK="$(REPO_ROOT="$REPO_ROOT" "$VENV_PY" - <<'PY' 2>&1 || true
import sys, os
REPO_ROOT = os.environ.get('REPO_ROOT')
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
try:
    import config
except Exception as e:
    print(f'ERR config: {e}')
    sys.exit(1)
try:
    from google.oauth2.credentials import Credentials
    from google.auth.transport.requests import Request
    from googleapiclient.discovery import build
except Exception as e:
    print(f'ERR deps: {e}')
    sys.exit(1)
SCOPES = ['https://www.googleapis.com/auth/gmail.readonly']
if not os.path.exists(config.GMAIL_TOKEN_READONLY):
    print('ERR missing: .credentials/gmail_token_readonly.json')
    sys.exit(1)
try:
    creds = Credentials.from_authorized_user_file(config.GMAIL_TOKEN_READONLY, SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
    svc = build('gmail', 'v1', credentials=creds, cache_discovery=False)
    svc.users().messages().list(userId='me', q='in:sent', maxResults=1).execute()
    print('OK list in:sent ok')
except Exception as e:
    print(f'ERR {type(e).__name__}: {e}')
PY
)"
if printf '%s' "$GMAIL_RO_CHECK" | grep -q '^OK '; then
    check ok "gmail_token_readonly.json" "in:sent query works"
else
    detail="$(printf '%s' "$GMAIL_RO_CHECK" | sed 's/^ERR //' | head -1)"
    check fail "gmail_token_readonly.json" "$detail"
fi

# -----------------------------------------------------------------------------
# 7. Supabase env
# -----------------------------------------------------------------------------
SUPA_ENV="$REPO_ROOT/.credentials/supabase.env"
if [ ! -f "$SUPA_ENV" ]; then
    check fail ".credentials/supabase.env" "create with SUPABASE_SERVICE_ROLE_KEY=..."
elif grep -q '^SUPABASE_SERVICE_ROLE_KEY=.\+$' "$SUPA_ENV"; then
    check ok ".credentials/supabase.env" "SUPABASE_SERVICE_ROLE_KEY present"
else
    check fail ".credentials/supabase.env" "SUPABASE_SERVICE_ROLE_KEY missing or empty"
fi

# -----------------------------------------------------------------------------
# 8. claude CLI
# -----------------------------------------------------------------------------
if command -v claude >/dev/null 2>&1; then
    ver="$(claude --version 2>/dev/null | head -1)"
    check ok "claude CLI" "${ver:-installed}"
else
    check fail "claude CLI" "not on PATH — install from https://docs.claude.com"
fi

# -----------------------------------------------------------------------------
# 9. PDF attachment exists
# -----------------------------------------------------------------------------
PDF_PATH="$(REPO_ROOT="$REPO_ROOT" "$VENV_PY" -c "
import sys, os
sys.path.insert(0, os.path.join(os.environ['REPO_ROOT'], 'workflows', 'cold-outreach'))
try:
    import config
    print(config.PDF_ATTACHMENT_PATH)
except Exception:
    pass
" 2>/dev/null)"
if [ -z "$PDF_PATH" ]; then
    check fail "PDF attachment" "config.py not importable — see check 2"
elif [ -f "$PDF_PATH" ]; then
    size="$(wc -c <"$PDF_PATH" | tr -d ' ')"
    check ok "PDF attachment" "$(basename "$PDF_PATH") (${size} bytes)"
else
    check fail "PDF attachment" "not found: $PDF_PATH"
fi

# -----------------------------------------------------------------------------
# 10. master-lead-list.json valid + has ≥1 lead with required fields
# -----------------------------------------------------------------------------
LEAD_CHECK="$(REPO_ROOT="$REPO_ROOT" "$VENV_PY" - <<'PY' 2>&1 || true
import os, sys, json
REPO_ROOT = os.environ['REPO_ROOT']
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
try:
    import config
    p = config.MASTER_LEAD_LIST_PATH
except Exception as e:
    print(f'ERR config: {e}'); sys.exit(1)
if not os.path.exists(p):
    print(f'ERR missing: {p}'); sys.exit(1)
try:
    data = json.load(open(p))
except Exception as e:
    print(f'ERR invalid JSON: {e}'); sys.exit(1)
if not isinstance(data, list) or not data:
    print('ERR lead list is empty'); sys.exit(1)
required = {'brand', 'email'}
for i, lead in enumerate(data):
    missing = required - set(lead.keys())
    if missing:
        print(f'ERR lead[{i}] missing fields: {sorted(missing)}'); sys.exit(1)
print(f'OK {len(data)} leads')
PY
)"
if printf '%s' "$LEAD_CHECK" | grep -q '^OK '; then
    check ok "master-lead-list.json" "$(printf '%s' "$LEAD_CHECK" | sed 's/^OK //')"
else
    detail="$(printf '%s' "$LEAD_CHECK" | sed 's/^ERR //' | head -1)"
    check fail "master-lead-list.json" "$detail"
fi

# -----------------------------------------------------------------------------
# 11. suppression-list.txt
# -----------------------------------------------------------------------------
SUPP_PATH="$REPO_ROOT/workflows/cold-outreach/data/suppression-list.txt"
if [ -f "$SUPP_PATH" ]; then
    lines="$(wc -l <"$SUPP_PATH" | tr -d ' ')"
    check ok "suppression-list.txt" "$lines entries"
else
    check fail "suppression-list.txt" "create empty file: touch $SUPP_PATH"
fi

# -----------------------------------------------------------------------------
# 12. Cron entries
# -----------------------------------------------------------------------------
EXPECTED_CRON=(
    "run_daily_outreach.sh"
    "run_evening_triage.sh"
    "run_crm_maintenance.sh"
    "run_backup.sh"
)
CRON_CONTENT="$(crontab -l 2>/dev/null || true)"
CRON_MISSING=()
for job in "${EXPECTED_CRON[@]}"; do
    printf '%s\n' "$CRON_CONTENT" | grep -Fq "$job" || CRON_MISSING+=("$job")
done
if [ "${#CRON_MISSING[@]}" -eq 0 ]; then
    check ok "cron entries" "all 4 jobs present"
else
    check fail "cron entries" "missing: ${CRON_MISSING[*]} — run scripts/bootstrap-vps.sh"
fi

# -----------------------------------------------------------------------------
# 13. pytest can collect tests
# -----------------------------------------------------------------------------
TESTS_DIR="$REPO_ROOT/tests"
if [ ! -d "$TESTS_DIR" ]; then
    check warn "pytest collect" "tests/ dir not present (B1 writes these)"
else
    COLLECT="$("$VENV_PY" -m pytest --collect-only -q "$TESTS_DIR" 2>&1 | tail -3 || true)"
    if printf '%s' "$COLLECT" | grep -qiE 'error|no tests'; then
        check fail "pytest collect" "$(printf '%s' "$COLLECT" | tail -1)"
    else
        n="$(printf '%s' "$COLLECT" | grep -oE '[0-9]+ test' | head -1)"
        check ok "pytest collect" "${n:-tests collected}"
    fi
fi

# -----------------------------------------------------------------------------
# 14. Log dir writable
# -----------------------------------------------------------------------------
LOG_DIR="$REPO_ROOT/logs/outreach"
if [ ! -d "$LOG_DIR" ]; then
    check fail "logs/outreach writable" "dir missing — run bootstrap-vps.sh"
elif touch "$LOG_DIR/.doctor-write-test" 2>/dev/null; then
    rm -f "$LOG_DIR/.doctor-write-test"
    check ok "logs/outreach writable"
else
    check fail "logs/outreach writable" "permission denied as $(id -un)"
fi

# -----------------------------------------------------------------------------
# 15. .outreach-paused flag
# -----------------------------------------------------------------------------
if [ -f "$REPO_ROOT/.outreach-paused" ]; then
    check warn ".outreach-paused" "flag present — cron will skip sends (intentional?)"
else
    check ok ".outreach-paused" "not present"
fi

# -----------------------------------------------------------------------------
# 16. .send-halted flag
# -----------------------------------------------------------------------------
if [ -f "$REPO_ROOT/.send-halted" ]; then
    check warn ".send-halted" "circuit breaker tripped — investigate before resuming"
else
    check ok ".send-halted" "not present"
fi

# -----------------------------------------------------------------------------
# Summary
# -----------------------------------------------------------------------------
echo "=============================================="
printf '%d/%d checks passed\n' "$PASS" "$TOTAL"
if [ "$FAIL" -eq 0 ]; then
    printf '%sAll healthy.%s\n' "$GREEN" "$RESET"
    exit 0
else
    printf '%s%d check(s) failed.%s\n' "$RED" "$FAIL" "$RESET"
    exit 1
fi
