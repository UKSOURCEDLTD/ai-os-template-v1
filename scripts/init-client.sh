#!/usr/bin/env bash
# init-client.sh — bootstrap a freshly-cloned AI OS template for a new client.
#
# Walks through the placeholder substitutions across CLAUDE.md, README.md,
# context/, memory/, data/, and creates runtime directories.
#
# Usage:
#     ./scripts/init-client.sh                              # interactive
#     ./scripts/init-client.sh --force                      # re-run on already-initialised repo
#     ./scripts/init-client.sh --non-interactive --from-json values.json
#
# values.json shape:
#   {
#     "CLIENT_NAME":            "Acme Agency",
#     "CLIENT_SLUG":            "acme-agency",
#     "INDUSTRY":               "B2B Marketing",
#     "OWNER_NAMES":            "Jane Smith and John Doe",
#     "TIMEZONE":               "GMT/BST (UK)",
#     "CURRENCY":               "£ (GBP)",
#     "SENDER_NAME":            "Jane Smith",
#     "SENDER_FIRST_NAME":      "Jane",
#     "SENDER_TITLE":           "Director",
#     "SENDER_EMAIL":           "jane@acme.com",
#     "SENDER_PHONE":           "+44 7700 900000",
#     "SENDER_PHONE_TEL_LINK":  "+447700900000",
#     "COMPANY_NAME":           "Acme Agency Ltd",
#     "COMPANY_SHORT_NAME":     "Acme",
#     "COMPANY_URL":            "https://www.acme.com/",
#     "COMPANY_DOMAIN":         "acme.com",
#     "COMPANY_TAGLINE":        "B2B Growth Consultancy",
#     "COMPANY_LOCATION":       "London, UK",
#     "COMPANY_FOUNDED_YEAR":   "2020",
#     "OWNER_ALERT_EMAILS":     "owner@x.com,ops@x.com"
#   }

set -euo pipefail

# -----------------------------------------------------------------------------
# Locate the repo root (parent of scripts/)
# -----------------------------------------------------------------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

# -----------------------------------------------------------------------------
# Args
# -----------------------------------------------------------------------------
FORCE=0
NON_INTERACTIVE=0
FROM_JSON=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --force) FORCE=1; shift ;;
        --non-interactive) NON_INTERACTIVE=1; shift ;;
        --from-json) FROM_JSON="$2"; shift 2 ;;
        --help|-h)
            head -n 35 "$0" | sed 's/^# //; s/^#//'
            exit 0
            ;;
        *) echo "Unknown arg: $1" >&2; exit 1 ;;
    esac
done

# -----------------------------------------------------------------------------
# Already-initialised guard
# -----------------------------------------------------------------------------
if grep -q "{{CLIENT_NAME}}" CLAUDE.md 2>/dev/null; then
    : # not yet initialised — proceed
elif [[ $FORCE -eq 0 ]]; then
    echo "ERROR: This repo appears already initialised (CLAUDE.md has no {{CLIENT_NAME}} placeholder)." >&2
    echo "       Re-run with --force if you really want to redo the substitutions." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------
PYTHON="$(command -v python3 || command -v python)"
if [[ -z "$PYTHON" ]]; then
    echo "ERROR: python3 not found on PATH." >&2
    exit 1
fi

prompt() {
    local msg="$1"
    local ans=""
    while [[ -z "$ans" ]]; do
        read -r -p "  $msg: " ans
    done
    echo "$ans"
}

json_get() {
    local file="$1" key="$2"
    "$PYTHON" -c "import json,sys; print(json.load(open(sys.argv[1])).get(sys.argv[2], ''))" "$file" "$key"
}

# Cross-platform sed -i
sed_inplace() {
    if sed --version >/dev/null 2>&1; then
        sed -i "$@"
    else
        sed -i '' "$@"
    fi
}

# -----------------------------------------------------------------------------
# Collect values
# -----------------------------------------------------------------------------
if [[ $NON_INTERACTIVE -eq 1 ]]; then
    if [[ -z "$FROM_JSON" || ! -f "$FROM_JSON" ]]; then
        echo "ERROR: --non-interactive requires --from-json <file>." >&2
        exit 1
    fi
    CLIENT_NAME=$(json_get "$FROM_JSON" CLIENT_NAME)
    CLIENT_SLUG=$(json_get "$FROM_JSON" CLIENT_SLUG)
    INDUSTRY=$(json_get "$FROM_JSON" INDUSTRY)
    OWNER_NAMES=$(json_get "$FROM_JSON" OWNER_NAMES)
    TIMEZONE=$(json_get "$FROM_JSON" TIMEZONE)
    CURRENCY=$(json_get "$FROM_JSON" CURRENCY)
    SENDER_NAME=$(json_get "$FROM_JSON" SENDER_NAME)
    SENDER_FIRST_NAME=$(json_get "$FROM_JSON" SENDER_FIRST_NAME)
    SENDER_TITLE=$(json_get "$FROM_JSON" SENDER_TITLE)
    SENDER_EMAIL=$(json_get "$FROM_JSON" SENDER_EMAIL)
    SENDER_PHONE=$(json_get "$FROM_JSON" SENDER_PHONE)
    SENDER_PHONE_TEL_LINK=$(json_get "$FROM_JSON" SENDER_PHONE_TEL_LINK)
    COMPANY_NAME=$(json_get "$FROM_JSON" COMPANY_NAME)
    COMPANY_SHORT_NAME=$(json_get "$FROM_JSON" COMPANY_SHORT_NAME)
    COMPANY_URL=$(json_get "$FROM_JSON" COMPANY_URL)
    COMPANY_DOMAIN=$(json_get "$FROM_JSON" COMPANY_DOMAIN)
    COMPANY_TAGLINE=$(json_get "$FROM_JSON" COMPANY_TAGLINE)
    COMPANY_LOCATION=$(json_get "$FROM_JSON" COMPANY_LOCATION)
    COMPANY_FOUNDED_YEAR=$(json_get "$FROM_JSON" COMPANY_FOUNDED_YEAR)
    OWNER_ALERT_EMAILS_RAW=$(json_get "$FROM_JSON" OWNER_ALERT_EMAILS)
else
    echo ""
    echo "============================================================"
    echo "  AI OS — Client Bootstrap"
    echo "============================================================"
    echo ""
    echo "This walks through the placeholder substitutions for a new"
    echo "client deployment. Press Ctrl-C at any time to abort."
    echo ""

    echo "--- IDENTITY ---"
    CLIENT_NAME=$(prompt "Client name (display, e.g. 'Acme Agency')")
    CLIENT_SLUG=$(prompt "Client slug (lowercased, hyphenated, e.g. 'acme-agency')")
    INDUSTRY=$(prompt "Industry (e.g. 'B2B Marketing')")
    OWNER_NAMES=$(prompt "Owner names (e.g. 'Jane Smith and John Doe')")
    TIMEZONE=$(prompt "Timezone (e.g. 'GMT/BST (UK)')")
    CURRENCY=$(prompt "Currency (e.g. '£ (GBP)')")
    echo ""

    echo "--- SENDER ---"
    SENDER_NAME=$(prompt "Sender full name (e.g. 'Jane Smith')")
    SENDER_FIRST_NAME=$(prompt "Sender first name (e.g. 'Jane')")
    SENDER_TITLE=$(prompt "Sender title (e.g. 'Director')")
    SENDER_EMAIL=$(prompt "Sender email")
    SENDER_PHONE=$(prompt "Sender phone (human-readable, e.g. '+44 7700 900000')")
    SENDER_PHONE_TEL_LINK=$(prompt "Sender phone (E.164 for tel: links, e.g. '+447700900000')")
    echo ""

    echo "--- COMPANY ---"
    COMPANY_NAME=$(prompt "Company legal name (e.g. 'Acme Agency Ltd')")
    COMPANY_SHORT_NAME=$(prompt "Company short name (e.g. 'Acme')")
    COMPANY_URL=$(prompt "Company URL (e.g. 'https://www.acme.com/')")
    COMPANY_DOMAIN=$(prompt "Company bare domain (e.g. 'acme.com')")
    COMPANY_TAGLINE=$(prompt "Company tagline (e.g. 'B2B Growth Consultancy')")
    COMPANY_LOCATION=$(prompt "Company location (e.g. 'London, UK')")
    COMPANY_FOUNDED_YEAR=$(prompt "Company founded year (e.g. '2020')")
    echo ""

    echo "--- OWNER ALERTING ---"
    echo "These addresses receive failure alerts."
    OWNER_ALERT_EMAILS_RAW=$(prompt "Owner alert emails, comma-separated (e.g. 'owner@x.com,ops@x.com')")
    echo ""
fi

# -----------------------------------------------------------------------------
# Normalise
# -----------------------------------------------------------------------------
CLIENT_SLUG=$(echo "$CLIENT_SLUG" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')

# Convert comma-separated alert emails into a Python-list literal.
OWNER_ALERT_EMAILS=$("$PYTHON" - "$OWNER_ALERT_EMAILS_RAW" <<'PY'
import sys
raw = sys.argv[1]
items = [x.strip() for x in raw.split(',') if x.strip()]
if not items:
    items = ["owner@example.com"]
quoted = ', '.join(f'"{i}"' for i in items)
print(f"[{quoted}]")
PY
)

echo ""
echo "Substituting placeholders with:"
cat <<EOF
  CLIENT_NAME:            $CLIENT_NAME
  CLIENT_SLUG:            $CLIENT_SLUG
  INDUSTRY:               $INDUSTRY
  OWNER_NAMES:            $OWNER_NAMES
  TIMEZONE:               $TIMEZONE
  CURRENCY:               $CURRENCY
  SENDER_NAME:            $SENDER_NAME
  SENDER_EMAIL:           $SENDER_EMAIL
  COMPANY_NAME:           $COMPANY_NAME
  OWNER_ALERT_EMAILS:     $OWNER_ALERT_EMAILS
EOF
echo ""

if [[ $NON_INTERACTIVE -eq 0 ]]; then
    read -r -p "Proceed? [y/N] " confirm
    if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
        echo "Aborted."
        exit 1
    fi
fi

# -----------------------------------------------------------------------------
# Apply substitutions across markdown files
# -----------------------------------------------------------------------------
MD_FILES=(
    "CLAUDE.md"
    "README.md"
    "DEPLOY.md"
    "agents.md"
    "gemini.md"
    "context/business.md"
    "context/rules.md"
    "context/processes.md"
    "context/integrations.md"
    "memory/leads.md"
    "memory/clients.md"
    "memory/metrics.md"
    "memory/learnings.md"
    "logs/tasks.md"
    "logs/actions.md"
    "data/sources.md"
)

# sed-safe escape (handles |, &, \)
escape_sed_replacement() {
    printf '%s' "$1" | sed -e 's/[\&|]/\\&/g'
}

replace_token() {
    local token="$1" value="$2" file="$3"
    local rep
    rep=$(escape_sed_replacement "$value")
    sed_inplace "s|{{${token}}}|${rep}|g" "$file"
}

for f in "${MD_FILES[@]}"; do
    [[ -f "$f" ]] || continue
    replace_token CLIENT_NAME            "$CLIENT_NAME"           "$f"
    replace_token CLIENT_SLUG            "$CLIENT_SLUG"           "$f"
    replace_token INDUSTRY               "$INDUSTRY"              "$f"
    replace_token OWNER_NAMES            "$OWNER_NAMES"           "$f"
    replace_token TIMEZONE               "$TIMEZONE"              "$f"
    replace_token CURRENCY               "$CURRENCY"              "$f"
    replace_token SENDER_NAME            "$SENDER_NAME"           "$f"
    replace_token SENDER_FIRST_NAME      "$SENDER_FIRST_NAME"     "$f"
    replace_token SENDER_TITLE           "$SENDER_TITLE"          "$f"
    replace_token SENDER_EMAIL           "$SENDER_EMAIL"          "$f"
    replace_token SENDER_PHONE           "$SENDER_PHONE"          "$f"
    replace_token SENDER_PHONE_TEL_LINK  "$SENDER_PHONE_TEL_LINK" "$f"
    replace_token COMPANY_NAME           "$COMPANY_NAME"          "$f"
    replace_token COMPANY_SHORT_NAME     "$COMPANY_SHORT_NAME"    "$f"
    replace_token COMPANY_URL            "$COMPANY_URL"           "$f"
    replace_token COMPANY_DOMAIN         "$COMPANY_DOMAIN"        "$f"
    replace_token COMPANY_TAGLINE        "$COMPANY_TAGLINE"       "$f"
    replace_token COMPANY_LOCATION       "$COMPANY_LOCATION"      "$f"
    replace_token COMPANY_FOUNDED_YEAR   "$COMPANY_FOUNDED_YEAR"  "$f"
done

# -----------------------------------------------------------------------------
# Create runtime directories
# -----------------------------------------------------------------------------
mkdir -p .credentials logs

cat > .credentials/.gitkeep <<EOF
# This directory is gitignored. Drop OAuth tokens, API keys, and env files here.
EOF

# -----------------------------------------------------------------------------
# Done
# -----------------------------------------------------------------------------
cat <<EOF

============================================================
  Bootstrap complete.
============================================================

Next steps:

  1. Review the substituted files (git diff). Adjust by hand if anything
     looks off.

  2. Run the client mapping process to discover the business and design
     the workflow roadmap:
         workflows/client-mapping.md

  3. Set up OAuth tokens for required integrations (Gmail, etc.) into:
         .credentials/

  4. Configure cron schedules per the mapping roadmap.

  5. Run scripts/doctor.sh to verify the deployment is healthy.

  6. Add optional add-ons (Supabase / n8n / MCP) per the roadmap.
     They are NOT included in the base template. Vector recall, if
     ever needed, is via pgvector inside the client's Supabase.

Commit when ready:
     git add -A && git commit -m "init: bootstrap for $CLIENT_NAME"

EOF
