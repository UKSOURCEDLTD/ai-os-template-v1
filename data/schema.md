# Data Schema

How data is normalised across all sources. Consistent field names regardless of origin.
When pulling data from any source, map it to these structures.

---

## Lead

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Full name of contact |
| `company` | string | Business name |
| `source` | string | Where the lead came from |
| `date_added` | date | When first captured (YYYY-MM-DD) |
| `status` | enum | `new`, `contacted`, `proposal_sent`, `negotiating`, `won`, `lost` |
| `value_estimate` | number | Estimated deal value |
| `next_action` | string | What happens next and when |
| `notes` | string | Any relevant context |

---

## Client

| Field | Type | Description |
|-------|------|-------------|
| `name` | string | Business / brand name |
| `contact` | string | Primary contact name and email |
| `start_date` | date | When they became a client (YYYY-MM-DD) |
| `retainer` | number | Monthly fee |
| `services` | list | Which services we provide |
| `status` | enum | `active`, `at_risk`, `churned`, `paused` |
| `health_score` | enum | `green`, `amber`, `red` |

---

## Performance Metric

| Field | Type | Description |
|-------|------|-------------|
| `client` | string | Client name |
| `period` | string | Month/week (YYYY-MM) |
| `leads_generated` | number | New leads captured this period |
| `proposals_sent` | number | Proposals sent to prospects |
| `deals_closed` | number | Deals won this period |
| `revenue` | number | Total revenue (£) this period |
| `mrr` | number | Monthly recurring revenue (£) at end of period |

---

## Revenue Record

| Field | Type | Description |
|-------|------|-------------|
| `period` | string | Month (YYYY-MM) |
| `client` | string | Client name (or "own") |
| `retainer` | number | Monthly retainer income |
| `bonus` | number | Performance bonus if applicable |
| `total` | number | Total revenue from this source that period |

---

## Action / Task

| Field | Type | Description |
|-------|------|-------------|
| `date` | date | Date of action (YYYY-MM-DD) |
| `client` | string | Client name (or "internal") |
| `type` | enum | `email`, `proposal`, `report`, `call`, `change`, `decision` |
| `description` | string | What was done |
| `outcome` | string | Result or next step |
| `confirmed_by` | string | Who approved it (if required) |

---

## Cold Outreach Schemas

*Used by `workflows/cold-outreach/`. Keep these aligned with the scripts that read/write them.*

### Master Lead (`workflows/cold-outreach/data/master-lead-list.json`)

```json
{
  "slug": "string, unique, lowercased, hyphenated — stable ID",
  "brand": "string, human-readable brand name",
  "email": "string, primary contact email",
  "contact_name": "string, full name of primary contact",
  "first_name": "string, first name for personalised templates",
  "score": "int 0-100, priority ranking",
  "template": "A | B | D — routes to body template variant",
  "gaps": "string, comma-separated opportunity tags (no_ppc, poor_listings, etc.)"
}
```

### Outreach CRM Row (`workflows/cold-outreach/data/outreach-crm.csv`)

| Column | Type | Notes |
|---|---|---|
| Date Sent | YYYY-MM-DD | Server-local date at send time |
| Time | HH:MM:SS | 24h |
| Brand | string | |
| Contact Email | string | Free-form; may include display name |
| Subject | string | Exact subject the recipient saw |
| Status | enum | Sent, Followup1, Followup2, Bounced, Skipped |
| Follow-up Due | YYYY-MM-DD \| '' | F1 trigger date; empty for non-initial sends |
| Response Received | 'Yes' \| '' | Set by detect_replies_and_bounces.py |
| Reply Category | enum \| '' | interested, not_interested, unsubscribe, auto_reply, wrong_person, referral, question, other |
| Reply Date | YYYY-MM-DD \| '' | When the reply landed |
| Reply Snippet | string | First ~200 chars of the reply body |
| Notes | string | Pipe-delimited event log: 'retried→x@y.com \| retry_skipped: reason' |
| Message ID | string | Gmail message ID returned at send time |

### Outreach Tracker (`workflows/cold-outreach/data/outreach-tracker.json`)

```json
{
  "sent": ["slug-1", "slug-2"],
  "batches": [
    {
      "date": "YYYY-MM-DD",
      "count": 30,
      "file": "email-batch-YYYY-MM-DD.md",
      "leads": ["slug-1", "slug-2"]
    }
  ]
}
```
