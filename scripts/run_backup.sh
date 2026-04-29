#!/bin/bash
# run_backup.sh — cron wrapper around backup_to_supabase.py.
# Default schedule: 03:30 UTC daily (see scripts/bootstrap-vps.sh).
#
# On non-zero exit from the Python backup, fires send_owner_alert.py with the
# log file so the owner sees what went wrong.

set -o pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

LOG_DIR="$REPO_ROOT/logs/outreach"
DATE=$(date -u +%Y-%m-%d)
LOG="$LOG_DIR/backup-$DATE.log"
LOCK="/tmp/$(basename "$REPO_ROOT")-backup.lock"

mkdir -p "$LOG_DIR"

exec 9>"$LOCK"
if ! flock -n 9; then
    echo "[$(date -u)] Another backup in progress — skipping." | tee -a "$LOG"
    exit 0
fi

# venv if present
if [ -f "$REPO_ROOT/.venv/bin/activate" ]; then
    # shellcheck disable=SC1091
    source "$REPO_ROOT/.venv/bin/activate"
fi

{
    echo "============================================"
    echo "Backup — $(date -u)"
    echo "============================================"
    python3 -u "$SCRIPT_DIR/backup_to_supabase.py"
} 2>&1 | tee -a "$LOG"

EXIT=${PIPESTATUS[0]}

if [ "$EXIT" -ne 0 ]; then
    python3 -u "$SCRIPT_DIR/send_owner_alert.py" \
        --subject "Backup failed ($DATE)" \
        --body-file "$LOG" || true
fi

exit "$EXIT"
