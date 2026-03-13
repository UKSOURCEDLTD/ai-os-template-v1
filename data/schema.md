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
| `[metric_1]` | number | [Description of metric] |
| `[metric_2]` | number | [Description of metric] |
| `[metric_3]` | number | [Description of metric] |

<!-- Customise metric fields to match what this business tracks -->

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
