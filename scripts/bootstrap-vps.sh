#!/bin/bash
# bootstrap-vps.sh — one-time VPS setup for an AI OS deployment.
#
# Idempotent. Safe to re-run.
#
# What it does:
#   1. Creates .venv/ and installs requirements.txt (if needed)
#   2. Verifies claude CLI is installed
#   3. Creates standard directories (logs, credentials, batches, backups)
#   4. Installs a logrotate config for logs/outreach/*.log (requires sudo)
#   5. Offers to install cron entries (daily outreach, evening triage,
#      weekly maintenance, daily backup)
#   6. Runs scripts/doctor.sh as the final sanity check
#
# Usage:
#   ./scripts/bootstrap-vps.sh              # normal install
#   ./scripts/bootstrap-vps.sh --dry-run    # preview cron changes only
#   ./scripts/bootstrap-vps.sh --help       # this help

set -e
set -o pipefail

DRY_RUN=0
while [ $# -gt 0 ]; do
    case "$1" in
        --dry-run) DRY_RUN=1 ;;
        -h|--help)
            sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'
            exit 0
            ;;
        *) echo "Unknown flag: $1" >&2; exit 2 ;;
    esac
    shift
done

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
REPO_BASENAME="$(basename "$REPO_ROOT")"

cd "$REPO_ROOT"

say() { printf '%s\n' "$*"; }
ok()  { printf '  \033[32m✓\033[0m %s\n' "$*"; }
warn(){ printf '  \033[33m!\033[0m %s\n' "$*"; }
err() { printf '  \033[31m✗\033[0m %s\n' "$*"; }

say "=============================================="
say "AI OS VPS bootstrap"
say "Repo: $REPO_ROOT"
[ "$DRY_RUN" = "1" ] && say "(DRY RUN — no changes will be applied)"
say "=============================================="

# -----------------------------------------------------------------------------
# 1. Python venv
# -----------------------------------------------------------------------------
say ""
say "[1/6] Python virtualenv"
if [ -d "$REPO_ROOT/.venv" ]; then
    ok ".venv/ already exists — skipping create"
else
    if [ "$DRY_RUN" = "1" ]; then
        warn "would run: python3 -m venv .venv"
    else
        python3 -m venv "$REPO_ROOT/.venv"
        ok "created .venv/"
    fi
fi

if [ "$DRY_RUN" = "1" ]; then
    warn "would run: .venv/bin/pip install -r requirements.txt"
else
    "$REPO_ROOT/.venv/bin/pip" install --quiet --upgrade pip
    "$REPO_ROOT/.venv/bin/pip" install --quiet -r "$REPO_ROOT/requirements.txt"
    ok "requirements.txt installed"
fi

# -----------------------------------------------------------------------------
# 2. Claude CLI
# -----------------------------------------------------------------------------
say ""
say "[2/6] Claude CLI"
if command -v claude >/dev/null 2>&1; then
    ok "claude installed: $(claude --version 2>/dev/null | head -1)"
else
    err "claude CLI not found on PATH"
    say "    Install instructions:"
    say "      curl -fsSL https://claude.ai/install.sh | bash"
    say "      (or see https://docs.claude.com/en/docs/claude-code)"
    say "    Required for: retry_bounces.py (alt-email research) and evening triage."
    exit 1
fi

# -----------------------------------------------------------------------------
# 3. Standard directories
# -----------------------------------------------------------------------------
say ""
say "[3/6] Standard directories"
DIRS=(
    "logs/outreach"
    ".credentials"
    "workflows/cold-outreach/data/batches"
    "workflows/cold-outreach/data/backups"
)
for d in "${DIRS[@]}"; do
    full="$REPO_ROOT/$d"
    if [ -d "$full" ]; then
        ok "exists: $d"
    else
        if [ "$DRY_RUN" = "1" ]; then
            warn "would create: $d"
        else
            mkdir -p "$full"
            ok "created: $d"
        fi
    fi
done

# -----------------------------------------------------------------------------
# 4. Logrotate
# -----------------------------------------------------------------------------
say ""
say "[4/6] Logrotate"
LOGROTATE_PATH="/etc/logrotate.d/${REPO_BASENAME}-outreach"
LOGROTATE_CONF="$REPO_ROOT/logs/outreach/*.log {
    weekly
    rotate 8
    compress
    delaycompress
    missingok
    notifempty
    copytruncate
}"

if [ "$DRY_RUN" = "1" ]; then
    warn "would write: $LOGROTATE_PATH"
    say "    (weekly, keep 8 weeks, compressed)"
elif [ "$(id -u)" = "0" ]; then
    printf '%s\n' "$LOGROTATE_CONF" > "$LOGROTATE_PATH"
    ok "installed: $LOGROTATE_PATH"
elif command -v sudo >/dev/null 2>&1; then
    if printf '%s\n' "$LOGROTATE_CONF" | sudo tee "$LOGROTATE_PATH" >/dev/null 2>&1; then
        ok "installed (via sudo): $LOGROTATE_PATH"
    else
        warn "sudo required to write $LOGROTATE_PATH — skipped"
        say "    Re-run as root, or: echo '<config>' | sudo tee $LOGROTATE_PATH"
    fi
else
    warn "not root and sudo unavailable — logrotate not installed"
    say "    Manual install: place this in $LOGROTATE_PATH:"
    printf '%s\n' "$LOGROTATE_CONF" | sed 's/^/      /'
fi

# -----------------------------------------------------------------------------
# 5. Cron entries
# -----------------------------------------------------------------------------
say ""
say "[5/6] Cron entries"

WANTED_CRON=(
    "0 10 * * 1-5 $REPO_ROOT/workflows/cold-outreach/scripts/run_daily_outreach.sh"
    "0 17 * * 1-5 $REPO_ROOT/workflows/cold-outreach/scripts/run_evening_triage.sh"
    "0 18 * * 0 $REPO_ROOT/workflows/cold-outreach/scripts/run_crm_maintenance.sh"
    "30 3 * * * $REPO_ROOT/scripts/run_backup.sh"
)

EXISTING_CRON="$(crontab -l 2>/dev/null || true)"
MISSING=()
for entry in "${WANTED_CRON[@]}"; do
    # Match on the script path, not exact string, so minor time tweaks don't duplicate.
    path="$(printf '%s\n' "$entry" | awk '{print $NF}')"
    if printf '%s\n' "$EXISTING_CRON" | grep -Fq "$path"; then
        ok "already present: $(basename "$path")"
    else
        MISSING+=("$entry")
    fi
done

if [ "${#MISSING[@]}" -eq 0 ]; then
    ok "all 4 cron entries already installed"
elif [ "$DRY_RUN" = "1" ]; then
    warn "would add ${#MISSING[@]} cron entries:"
    for e in "${MISSING[@]}"; do say "      $e"; done
else
    say "  Missing ${#MISSING[@]} cron entries:"
    for e in "${MISSING[@]}"; do say "      $e"; done
    printf "  Install them now? [y/N] "
    read -r reply
    if [ "$reply" = "y" ] || [ "$reply" = "Y" ]; then
        NEW_CRON="$EXISTING_CRON"
        for e in "${MISSING[@]}"; do
            NEW_CRON="$(printf '%s\n%s\n' "$NEW_CRON" "$e")"
        done
        printf '%s\n' "$NEW_CRON" | crontab -
        ok "cron updated"
    else
        warn "cron install skipped — add manually with: crontab -e"
    fi
fi

# -----------------------------------------------------------------------------
# 6. Doctor
# -----------------------------------------------------------------------------
say ""
say "[6/6] Running doctor.sh"
say "=============================================="
if [ -x "$SCRIPT_DIR/doctor.sh" ]; then
    "$SCRIPT_DIR/doctor.sh"
    exit $?
else
    warn "doctor.sh not executable or missing — run: chmod +x scripts/doctor.sh"
    exit 1
fi
