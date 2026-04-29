#!/usr/bin/env bash
# init-client.sh — bootstrap a fresh AI OS deployment for a new client.
#
# Walks the operator through an interactive questionnaire, substitutes every
# {{PLACEHOLDER}} across the template, creates the runtime directory layout,
# and generates workflows/cold-outreach/config.py from config.example.py.
#
# Idempotent under --force: a clean re-run will re-prompt and re-write, but
# never silently overwrite a config.py that already exists without warning.
#
# Usage:
#   ./scripts/init-client.sh               # interactive (typical case)
#   ./scripts/init-client.sh --force       # re-run on an already-initialised repo
#   ./scripts/init-client.sh --non-interactive --from-json path/to/values.json
#   ./scripts/init-client.sh --help
#
# values.json shape (for --non-interactive):
#   {
#     "CLIENT_NAME":            "Acme Agency Ltd",
#     "CLIENT_SLUG":            "acme",
#     "INDUSTRY":               "B2B growth consultancy",
#     "OWNER_NAMES":            "Jane Doe (100%)",
#     "TIMEZONE":               "Europe/London",
#     "CURRENCY":               "GBP (£)",
#     "SENDER_NAME":            "Jane Doe",
#     "SENDER_FIRST_NAME":      "Jane",
#     "SENDER_TITLE":           "Director",
#     "SENDER_EMAIL":           "enquiries@acmeagency.com",
#     "SENDER_PHONE":           "+44 7000 000000",
#     "SENDER_PHONE_TEL_LINK":  "+447000000000",
#     "COMPANY_NAME":           "Acme Agency Ltd",
#     "COMPANY_SHORT_NAME":     "Acme",
#     "COMPANY_URL":            "https://www.acmeagency.com/",
#     "COMPANY_DOMAIN":         "acmeagency.com",
#     "COMPANY_TAGLINE":        "B2B Growth Consultancy",
#     "COMPANY_LOCATION":       "London, UK",
#     "COMPANY_FOUNDED_YEAR":   "2020",
#     "SUPABASE_URL":           "https://xxxx.supabase.co",
#     "OWNER_ALERT_EMAILS":     "luke@x.com,codie@x.com"
#   }

set -euo pipefail

# Cross-platform Python resolution. Linux VPSes ship python3; macOS dev boxes
# may only have python; Git-Bash / WSL on Windows may have py. Accept whichever
# actually runs cleanly — the Microsoft Store stub on Windows claims to be
# "python" but prints an install prompt when invoked, so we verify with
# --version before picking a winner.
PYTHON=""
for cand in python3 py python; do
    if command -v "$cand" >/dev/null 2>&1 && "$cand" --version >/dev/null 2>&1; then
        PYTHON="$cand"
        break
    fi
done
if [ -z "$PYTHON" ]; then
    echo "ERROR: no working Python interpreter found (tried python3, py, python)." >&2
    echo "Install Python 3.11+ and re-run." >&2
    exit 1
fi

# -----------------------------------------------------------------------------
# Arg parsing
# -----------------------------------------------------------------------------

FORCE=0
NON_INTERACTIVE=0
FROM_JSON=""

while [ $# -gt 0 ]; do
    case "$1" in
        --force)
            FORCE=1
            shift
            ;;
        --non-interactive)
            NON_INTERACTIVE=1
            shift
            ;;
        --from-json)
            FROM_JSON="${2:-}"
            shift 2 || true
            ;;
        -h|--help)
            sed -n '2,40p' "$0"
            exit 0
            ;;
        *)
            echo "Unknown arg: $1" >&2
            echo "See --help." >&2
            exit 2
            ;;
    esac
done

if [ "$NON_INTERACTIVE" -eq 1 ] && [ -z "$FROM_JSON" ]; then
    echo "ERROR: --non-interactive requires --from-json <path>" >&2
    exit 2
fi

# -----------------------------------------------------------------------------
# Preconditions
# -----------------------------------------------------------------------------

if [ ! -f "CLAUDE.md" ]; then
    echo "ERROR: run this from the repo root (where CLAUDE.md lives)." >&2
    exit 1
fi

if ! grep -q '{{CLIENT_NAME}}' CLAUDE.md 2>/dev/null; then
    if [ "$FORCE" -ne 1 ]; then
        echo ""
        echo "This repo has already been initialised — CLAUDE.md has no {{placeholders}} left."
        echo "Re-running would replace already-substituted values with new ones, which is"
        echo "usually not what you want."
        echo ""
        echo "If you genuinely want to re-run (e.g. you just reset the template files):"
        echo "    ./scripts/init-client.sh --force"
        exit 1
    else
        echo ""
        echo "WARNING: --force supplied. CLAUDE.md has no placeholder tokens — re-running"
        echo "will substitute across whatever strings currently match."
        if [ "$NON_INTERACTIVE" -ne 1 ]; then
            read -rp "Proceed with --force? [y/N] " CONFIRM_FORCE
            if [ "$CONFIRM_FORCE" != "y" ] && [ "$CONFIRM_FORCE" != "Y" ]; then
                echo "Aborted."
                exit 0
            fi
        fi
    fi
fi

# -----------------------------------------------------------------------------
# Helpers
# -----------------------------------------------------------------------------

# Escape a value for use on the RIGHT-hand side of sed's `s/LHS/RHS/` command.
# Handles: backslash, forward slash, ampersand. Newlines are stripped (values
# must be single-line).
sed_escape_rhs() {
    printf '%s' "$1" | sed -e 's/[\/&]/\\&/g' -e 's/|/\\|/g'
}

# Escape a Python string literal value for use inside "..." double quotes.
# Handles: backslash, double quote.
py_escape_dq() {
    printf '%s' "$1" | sed -e 's/\\/\\\\/g' -e 's/"/\\"/g'
}

# Portable in-place sed that works on both macOS (BSD) and Linux (GNU).
sed_inplace() {
    local expr="$1"
    local file="$2"
    if [ ! -f "$file" ]; then
        return 0
    fi
    # Use a temp-file approach that works identically on both seds.
    local tmp
    tmp=$(mktemp)
    sed "$expr" "$file" > "$tmp"
    mv "$tmp" "$file"
}

replace_token() {
    local token="$1"
    local value="$2"
    local file="$3"
    local escaped
    escaped=$(sed_escape_rhs "$value")
    # Using | as the delimiter to reduce the need for escaping slashes,
    # and piping through sed_escape_rhs to guarantee any | in the value is
    # escaped too.
    sed_inplace "s|{{${token}}}|${escaped}|g" "$file"
}

prompt() {
    local label="$1"
    local default="${2:-}"
    local value
    if [ -n "$default" ]; then
        read -rp "$label [$default]: " value
        echo "${value:-$default}"
    else
        while true; do
            read -rp "$label: " value
            if [ -n "$value" ]; then
                echo "$value"
                return
            fi
            echo "(required — please enter a value)" >&2
        done
    fi
}

# Parse a value out of a JSON file using python3. Returns empty string if
# the key is missing or null.
json_get() {
    local path="$1"
    local key="$2"
    "$PYTHON" - "$path" "$key" <<'PY'
import json, sys
try:
    with open(sys.argv[1]) as f:
        data = json.load(f)
    v = data.get(sys.argv[2], "")
    if v is None:
        v = ""
    print(v)
except Exception as e:
    print(f"ERROR: {e}", file=sys.stderr)
    sys.exit(1)
PY
}

# -----------------------------------------------------------------------------
# Gather values
# -----------------------------------------------------------------------------

CLIENT_NAME=""
CLIENT_SLUG=""
INDUSTRY=""
OWNER_NAMES=""
TIMEZONE=""
CURRENCY=""
SENDER_NAME=""
SENDER_FIRST_NAME=""
SENDER_TITLE=""
SENDER_EMAIL=""
SENDER_PHONE=""
SENDER_PHONE_TEL_LINK=""
COMPANY_NAME=""
COMPANY_SHORT_NAME=""
COMPANY_URL=""
COMPANY_DOMAIN=""
COMPANY_TAGLINE=""
COMPANY_LOCATION=""
COMPANY_FOUNDED_YEAR=""
SUPABASE_URL=""
OWNER_ALERT_EMAILS_RAW=""

if [ "$NON_INTERACTIVE" -eq 1 ]; then
    if [ ! -f "$FROM_JSON" ]; then
        echo "ERROR: values JSON not found at $FROM_JSON" >&2
        exit 2
    fi
    CLIENT_NAME=$(json_get "$FROM_JSON" CLIENT_NAME)
    CLIENT_SLUG=$(json_get "$FROM_JSON" CLIENT_SLUG)
    INDUSTRY=$(json_get "$FROM_JSON" INDUSTRY)
    OWNER_NAMES=$(json_get "$FROM_JSON" OWNER_NAMES)
    TIMEZONE=$(json_get "$FROM_JSON" TIMEZONE); TIMEZONE=${TIMEZONE:-Europe/London}
    CURRENCY=$(json_get "$FROM_JSON" CURRENCY);  CURRENCY=${CURRENCY:-'GBP (£)'}
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
    SUPABASE_URL=$(json_get "$FROM_JSON" SUPABASE_URL)
    OWNER_ALERT_EMAILS_RAW=$(json_get "$FROM_JSON" OWNER_ALERT_EMAILS)
else
    echo ""
    echo "=========================================="
    echo "  AI OS — Client Initialisation"
    echo "=========================================="
    echo ""
    echo "I'll ask for the deployment's details and fill them across the template."
    echo "Press enter to accept defaults in brackets [like this]."
    echo "Required fields will re-prompt until you enter a value."
    echo ""

    echo "--- IDENTITY ---"
    CLIENT_NAME=$(prompt "Client legal name (e.g. 'Acme Agency Ltd')")
    CLIENT_SLUG=$(prompt "Short slug, lowercased + hyphenated (e.g. 'acme')")
    INDUSTRY=$(prompt "Industry / positioning (e.g. 'B2B growth consultancy')")
    OWNER_NAMES=$(prompt "Owner names + stakes (e.g. 'Jane Doe (100%)')")
    TIMEZONE=$(prompt "Timezone" "Europe/London")
    CURRENCY=$(prompt "Currency display" "GBP (£)")
    echo ""

    echo "--- SENDER (the human outreach appears to come from) ---"
    SENDER_NAME=$(prompt "Sender full name (e.g. 'Jane Doe')")
    SENDER_FIRST_NAME=$(prompt "Sender first name (e.g. 'Jane')")
    SENDER_TITLE=$(prompt "Sender title (e.g. 'Director')")
    SENDER_EMAIL=$(prompt "Sender email — must match Gmail OAuth account (e.g. 'enquiries@acme.com')")
    SENDER_PHONE=$(prompt "Sender phone, human-readable (e.g. '+44 7000 000000')")
    SENDER_PHONE_TEL_LINK=$(prompt "Sender phone in E.164, no spaces (e.g. '+447000000000')")
    echo ""

    echo "--- COMPANY ---"
    COMPANY_NAME=$(prompt "Company legal name (e.g. 'Acme Agency Ltd')")
    COMPANY_SHORT_NAME=$(prompt "Company casual/short name (e.g. 'Acme')")
    COMPANY_URL=$(prompt "Company URL (e.g. 'https://www.acme.com/')")
    COMPANY_DOMAIN=$(prompt "Company bare domain (e.g. 'acme.com')")
    COMPANY_TAGLINE=$(prompt "Company tagline (e.g. 'B2B Growth Consultancy')")
    COMPANY_LOCATION=$(prompt "Company location (e.g. 'London, UK')")
    COMPANY_FOUNDED_YEAR=$(prompt "Company founded year (e.g. '2020')")
    echo ""

    echo "--- SUPABASE (for state backup) ---"
    echo "You need a Supabase project for this deployment's state backups."
    echo "Create one here if you haven't: https://supabase.com/dashboard/projects"
    echo "Then copy the Project URL from Project Settings → API."
    SUPABASE_URL=$(prompt "Supabase Project URL (e.g. 'https://xxxx.supabase.co')")
    echo ""

    echo "--- OWNER ALERTING ---"
    echo "These addresses receive bounce-review, rate-limit, and failure alerts."
    OWNER_ALERT_EMAILS_RAW=$(prompt "Owner alert emails, comma-separated (e.g. 'luke@x.com,codie@x.com')")
    echo ""
fi

# -----------------------------------------------------------------------------
# Normalise + derive
# -----------------------------------------------------------------------------

# Lowercase + hyphenate slug defensively.
CLIENT_SLUG=$(printf '%s' "$CLIENT_SLUG" | tr '[:upper:]' '[:lower:]' | tr ' _' '--' | tr -cd 'a-z0-9-')
if [ -z "$CLIENT_SLUG" ]; then
    echo "ERROR: CLIENT_SLUG normalised to empty — please pick a value with [a-z0-9-] chars." >&2
    exit 2
fi

# Build Python list literal from comma-separated owner emails.
# e.g.  "a@x.com, b@y.com"  ->  "\"a@x.com\",\n    \"b@y.com\","
OWNER_ALERT_EMAILS_PY=$("$PYTHON" - "$OWNER_ALERT_EMAILS_RAW" <<'PY'
import sys
raw = sys.argv[1] if len(sys.argv) > 1 else ""
items = [x.strip() for x in raw.split(",") if x.strip()]
if not items:
    print('"you@example.com",')
else:
    parts = []
    for i in items:
        parts.append('    "' + i.replace('\\', '\\\\').replace('"', '\\"') + '",')
    # Strip the first 4 spaces — the template line already has leading indent
    # that we'll match against.
    print("\n".join(parts).lstrip())
PY
)

# -----------------------------------------------------------------------------
# Summary + confirmation
# -----------------------------------------------------------------------------

cat <<EOF

------------------------------------------
Summary
------------------------------------------
  CLIENT_NAME:             $CLIENT_NAME
  CLIENT_SLUG:             $CLIENT_SLUG
  INDUSTRY:                $INDUSTRY
  OWNER_NAMES:             $OWNER_NAMES
  TIMEZONE:                $TIMEZONE
  CURRENCY:                $CURRENCY

  SENDER_NAME:             $SENDER_NAME
  SENDER_FIRST_NAME:       $SENDER_FIRST_NAME
  SENDER_TITLE:            $SENDER_TITLE
  SENDER_EMAIL:            $SENDER_EMAIL
  SENDER_PHONE:            $SENDER_PHONE
  SENDER_PHONE_TEL_LINK:   $SENDER_PHONE_TEL_LINK

  COMPANY_NAME:            $COMPANY_NAME
  COMPANY_SHORT_NAME:      $COMPANY_SHORT_NAME
  COMPANY_URL:             $COMPANY_URL
  COMPANY_DOMAIN:          $COMPANY_DOMAIN
  COMPANY_TAGLINE:         $COMPANY_TAGLINE
  COMPANY_LOCATION:        $COMPANY_LOCATION
  COMPANY_FOUNDED_YEAR:    $COMPANY_FOUNDED_YEAR

  SUPABASE_URL:            $SUPABASE_URL
  OWNER_ALERT_EMAILS:      $OWNER_ALERT_EMAILS_RAW
------------------------------------------

EOF

if [ "$NON_INTERACTIVE" -ne 1 ]; then
    read -rp "Write these values across the repo? [y/N] " CONFIRM
    if [ "$CONFIRM" != "y" ] && [ "$CONFIRM" != "Y" ]; then
        echo "Aborted — no changes made."
        exit 0
    fi
fi

# -----------------------------------------------------------------------------
# Placeholder substitution in markdown / text files
# -----------------------------------------------------------------------------

MD_FILES=(
    "CLAUDE.md"
    "README.md"
    "DEPLOY.md"
    "context/business.md"
    "context/rules.md"
    "context/processes.md"
    "context/integrations.md"
    "memory/leads.md"
    "memory/clients.md"
    "memory/metrics.md"
    "memory/learnings.md"
    "data/schema.md"
    "data/sources.md"
)

echo ""
echo "Substituting placeholders in markdown files..."
for f in "${MD_FILES[@]}"; do
    if [ ! -f "$f" ]; then
        echo "  skip (missing): $f"
        continue
    fi
    replace_token CLIENT_NAME           "$CLIENT_NAME"           "$f"
    replace_token CLIENT_SLUG           "$CLIENT_SLUG"           "$f"
    replace_token INDUSTRY              "$INDUSTRY"              "$f"
    replace_token OWNER_NAMES           "$OWNER_NAMES"           "$f"
    replace_token TIMEZONE              "$TIMEZONE"              "$f"
    replace_token CURRENCY              "$CURRENCY"              "$f"
    replace_token SENDER_NAME           "$SENDER_NAME"           "$f"
    replace_token SENDER_FIRST_NAME     "$SENDER_FIRST_NAME"     "$f"
    replace_token SENDER_TITLE          "$SENDER_TITLE"          "$f"
    replace_token SENDER_EMAIL          "$SENDER_EMAIL"          "$f"
    replace_token SENDER_PHONE          "$SENDER_PHONE"          "$f"
    replace_token SENDER_PHONE_TEL_LINK "$SENDER_PHONE_TEL_LINK" "$f"
    replace_token COMPANY_NAME          "$COMPANY_NAME"          "$f"
    replace_token COMPANY_SHORT_NAME    "$COMPANY_SHORT_NAME"    "$f"
    replace_token COMPANY_URL           "$COMPANY_URL"           "$f"
    replace_token COMPANY_DOMAIN        "$COMPANY_DOMAIN"        "$f"
    replace_token COMPANY_TAGLINE       "$COMPANY_TAGLINE"       "$f"
    replace_token COMPANY_LOCATION      "$COMPANY_LOCATION"      "$f"
    replace_token COMPANY_FOUNDED_YEAR  "$COMPANY_FOUNDED_YEAR"  "$f"
    replace_token SUPABASE_URL          "$SUPABASE_URL"          "$f"
    echo "  updated: $f"
done

# -----------------------------------------------------------------------------
# Create runtime directories (idempotent)
# -----------------------------------------------------------------------------

echo ""
echo "Creating runtime directories..."
DIRS=(
    ".credentials"
    "logs/outreach"
    "workflows/cold-outreach/data/batches"
    "workflows/cold-outreach/data/backups"
)
for d in "${DIRS[@]}"; do
    mkdir -p "$d"
    if [ ! -f "$d/.gitkeep" ]; then
        : > "$d/.gitkeep"
    fi
    echo "  ok: $d"
done

# -----------------------------------------------------------------------------
# Generate workflows/cold-outreach/config.py from config.example.py
# -----------------------------------------------------------------------------

CONFIG_EXAMPLE="workflows/cold-outreach/config.example.py"
CONFIG_TARGET="workflows/cold-outreach/config.py"

if [ ! -f "$CONFIG_EXAMPLE" ]; then
    echo "WARNING: $CONFIG_EXAMPLE not found — skipping config.py generation." >&2
else
    if [ -f "$CONFIG_TARGET" ] && [ "$FORCE" -ne 1 ]; then
        echo ""
        echo "WARNING: $CONFIG_TARGET already exists. Not overwriting."
        echo "         Re-run with --force if you want to regenerate it."
    else
        echo ""
        echo "Generating $CONFIG_TARGET from $CONFIG_EXAMPLE..."

        # If force-overwriting, stash a backup.
        if [ -f "$CONFIG_TARGET" ]; then
            local_ts=$(date +%Y%m%d-%H%M%S)
            cp "$CONFIG_TARGET" "$CONFIG_TARGET.bak.$local_ts"
            echo "  existing config.py backed up to $CONFIG_TARGET.bak.$local_ts"
        fi

        cp "$CONFIG_EXAMPLE" "$CONFIG_TARGET"

        # Escape values for safe insertion as Python "..." string literals.
        ESC_CLIENT_SLUG=$(py_escape_dq "$CLIENT_SLUG")
        ESC_SENDER_NAME=$(py_escape_dq "$SENDER_NAME")
        ESC_SENDER_FIRST_NAME=$(py_escape_dq "$SENDER_FIRST_NAME")
        ESC_SENDER_TITLE=$(py_escape_dq "$SENDER_TITLE")
        ESC_SENDER_EMAIL=$(py_escape_dq "$SENDER_EMAIL")
        ESC_SENDER_PHONE=$(py_escape_dq "$SENDER_PHONE")
        ESC_SENDER_PHONE_TEL_LINK=$(py_escape_dq "$SENDER_PHONE_TEL_LINK")
        ESC_COMPANY_NAME=$(py_escape_dq "$COMPANY_NAME")
        ESC_COMPANY_SHORT_NAME=$(py_escape_dq "$COMPANY_SHORT_NAME")
        ESC_COMPANY_URL=$(py_escape_dq "$COMPANY_URL")
        ESC_COMPANY_DOMAIN=$(py_escape_dq "$COMPANY_DOMAIN")
        ESC_COMPANY_TAGLINE=$(py_escape_dq "$COMPANY_TAGLINE")
        ESC_COMPANY_LOCATION=$(py_escape_dq "$COMPANY_LOCATION")
        ESC_SUPABASE_URL=$(py_escape_dq "$SUPABASE_URL")
        PDF_FILENAME="${CLIENT_SLUG}-services-overview.pdf"
        ESC_PDF_FILENAME=$(py_escape_dq "$PDF_FILENAME")

        # All replacements use | as the sed delimiter. Values are already
        # py_escape_dq'd for the Python side; we additionally sed_escape_rhs
        # the full literal for the bash→sed handoff.
        rhs() { sed_escape_rhs "$1"; }

        sed_inplace "s|^CLIENT_SLUG = \"acme\".*$|CLIENT_SLUG = \"$(rhs "$ESC_CLIENT_SLUG")\"|" "$CONFIG_TARGET"

        sed_inplace "s|^SENDER_NAME = \"Jane Doe\".*$|SENDER_NAME = \"$(rhs "$ESC_SENDER_NAME")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^SENDER_FIRST_NAME = \"Jane\".*$|SENDER_FIRST_NAME = \"$(rhs "$ESC_SENDER_FIRST_NAME")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^SENDER_TITLE = \"Director\".*$|SENDER_TITLE = \"$(rhs "$ESC_SENDER_TITLE")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^SENDER_EMAIL = \"enquiries@acmeagency.com\".*$|SENDER_EMAIL = \"$(rhs "$ESC_SENDER_EMAIL")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^SENDER_PHONE = \"+44 7000 000000\".*$|SENDER_PHONE = \"$(rhs "$ESC_SENDER_PHONE")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^SENDER_PHONE_TEL_LINK = \"+447000000000\".*$|SENDER_PHONE_TEL_LINK = \"$(rhs "$ESC_SENDER_PHONE_TEL_LINK")\"|" "$CONFIG_TARGET"

        sed_inplace "s|^COMPANY_NAME = \"Acme Agency Ltd\".*$|COMPANY_NAME = \"$(rhs "$ESC_COMPANY_NAME")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_SHORT_NAME = \"Acme\".*$|COMPANY_SHORT_NAME = \"$(rhs "$ESC_COMPANY_SHORT_NAME")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_URL = \"https://www.acmeagency.com/\".*$|COMPANY_URL = \"$(rhs "$ESC_COMPANY_URL")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_DOMAIN = \"acmeagency.com\".*$|COMPANY_DOMAIN = \"$(rhs "$ESC_COMPANY_DOMAIN")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_TAGLINE = \"B2B Growth Consultancy\".*$|COMPANY_TAGLINE = \"$(rhs "$ESC_COMPANY_TAGLINE")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_LOCATION = \"London, UK\".*$|COMPANY_LOCATION = \"$(rhs "$ESC_COMPANY_LOCATION")\"|" "$CONFIG_TARGET"
        sed_inplace "s|^COMPANY_FOUNDED_YEAR = 2020.*$|COMPANY_FOUNDED_YEAR = ${COMPANY_FOUNDED_YEAR}|" "$CONFIG_TARGET"

        sed_inplace "s|^SUPABASE_URL = \"https://xxxxxxxxxxxxxxxxxxxx.supabase.co\".*$|SUPABASE_URL = \"$(rhs "$ESC_SUPABASE_URL")\"|" "$CONFIG_TARGET"

        sed_inplace "s|^PDF_ATTACHMENT_FILENAME = \"acme-services-overview.pdf\".*$|PDF_ATTACHMENT_FILENAME = \"$(rhs "$ESC_PDF_FILENAME")\"|" "$CONFIG_TARGET"

        # Replace the OWNER_ALERT_EMAILS single example line.
        # Use python to rewrite the list cleanly — sed gets ugly for multi-line.
        "$PYTHON" - "$CONFIG_TARGET" "$OWNER_ALERT_EMAILS_RAW" <<'PY'
import re, sys
path = sys.argv[1]
raw  = sys.argv[2]
items = [x.strip() for x in raw.split(",") if x.strip()]
if not items:
    items = ["you@example.com"]
body = open(path, encoding="utf-8").read()
new_block = "OWNER_ALERT_EMAILS = [\n"
for i in items:
    esc = i.replace("\\", "\\\\").replace('"', '\\"')
    new_block += f'    "{esc}",\n'
new_block += "    # add co-director / ops team if useful\n"
new_block += "]"
body, n = re.subn(
    r"OWNER_ALERT_EMAILS = \[[\s\S]*?\]",
    lambda m: new_block,
    body,
    count=1,
)
if n != 1:
    sys.stderr.write("ERROR: could not locate OWNER_ALERT_EMAILS block in config.py\n")
    sys.exit(1)
open(path, "w", encoding="utf-8").write(body)
PY

        # Annotate the body templates so the operator knows to rewrite them.
        # Prepend a TODO comment directly above each BODY_* assignment.
        "$PYTHON" - "$CONFIG_TARGET" "$CLIENT_NAME" <<'PY'
import re, sys
path = sys.argv[1]
client = sys.argv[2]
body = open(path, encoding="utf-8").read()
todo = f"# TODO: rewrite for {client}'s pitch\n"
for name in ("BODY_A", "BODY_D", "BODY_FOLLOWUP_1", "BODY_FOLLOWUP_2"):
    pattern = rf"(?m)^(?={re.escape(name)} = )"
    # Only insert if the TODO isn't already directly above.
    before_re = re.compile(rf"(?m)^# TODO: rewrite.*\n{re.escape(name)} = ")
    if before_re.search(body):
        continue
    body, n = re.subn(pattern, todo, body, count=1)
open(path, "w", encoding="utf-8").write(body)
PY

        # Validate the generated config — if it doesn't parse, roll back.
        if ! "$PYTHON" -c "import ast, sys; ast.parse(open('$CONFIG_TARGET', encoding='utf-8').read())" 2>/tmp/init-client-parse.err; then
            echo ""
            echo "ERROR: generated $CONFIG_TARGET failed to parse as Python." >&2
            cat /tmp/init-client-parse.err >&2 || true
            echo "Rolling back — removing $CONFIG_TARGET." >&2
            rm -f "$CONFIG_TARGET"
            exit 1
        fi

        echo "  ok: $CONFIG_TARGET (syntax-valid)"
    fi
fi

# -----------------------------------------------------------------------------
# Next steps
# -----------------------------------------------------------------------------

cat <<EOF

==========================================
  Init complete
==========================================

Next steps — in order:

  1. Edit the email body templates in:
         workflows/cold-outreach/config.py
     Search for "TODO: rewrite" — BODY_A, BODY_D, BODY_FOLLOWUP_1, BODY_FOLLOWUP_2.

  2. Generate Gmail OAuth tokens (compose + readonly scopes):
         workflows/cold-outreach/oauth-setup.md
     Both tokens land in .credentials/ on the VPS.

  3. Drop the Supabase service-role key into:
         .credentials/supabase.env
     Single line:
         SUPABASE_SERVICE_ROLE_KEY=eyJ...
     (Get it from Supabase dashboard → Project Settings → API → service_role.)

  4. Drop the services-overview PDF into:
         workflows/cold-outreach/data/${CLIENT_SLUG}-services-overview.pdf
     (Filename must match PDF_ATTACHMENT_FILENAME in config.py.)

  5. Populate the lead queue:
         workflows/cold-outreach/data/master-lead-list.json
     See master-lead-list.example.json for the schema.

  6. Provision the VPS:
         ./scripts/bootstrap-vps.sh

  7. Verify the deployment:
         ./scripts/doctor.sh

Full walkthrough: DEPLOY.md.

EOF
