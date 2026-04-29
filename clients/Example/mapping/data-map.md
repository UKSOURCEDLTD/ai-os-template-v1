# [Client Name] — Data Map

*Completed: [DATE] | Package: [Essentials/Growth/Partner]*

---

## Tool Stack

| Tool | Purpose | Users | Data Held | Data In | Data Out | API? | Cost/mo | Pain Points |
|------|---------|-------|-----------|---------|----------|------|---------|-------------|
| [e.g., Google Sheets] | CRM / pipeline tracking | [Name, Role] | Leads: name, email, phone, status, value | Manual entry | Export CSV, Sheets API | Yes (Sheets API, OAuth2) | £0 (GWS) | Manual entry, no automation, duplicates |
| [e.g., Xero] | Invoicing + accounting | [Name, Role] | Invoices: client, amount, date, status, payments | Manual + bank feed | API, PDF export | Yes (REST, OAuth2) | £30 | Disconnected from CRM |
| [e.g., Gmail] | Client communication | Everyone | Emails, attachments, enquiries | Inbound + manual | Gmail API | Yes (Gmail API, OAuth2) | £0 (GWS) | Enquiries get lost, no tracking |
| [e.g., Mailchimp] | Email marketing | [Name] | Subscribers: email, tags, open rates | Signup forms, manual import | API, export | Yes (REST, API key) | £15 | Low engagement, no segmentation |

## Tool Overlap

| Tools | Overlapping Data | Notes |
|-------|-----------------|-------|
| [e.g., Sheets + Xero] | Client names, invoice amounts | Data entered twice — Sheets for tracking, Xero for billing |

## Data Silos

| Silo | What's Trapped | Impact |
|------|---------------|--------|
| [e.g., Gmail inbox] | Lead enquiries, client requests | No visibility — things get missed, no tracking of response time |
| [e.g., Owner's notebook] | Meeting notes, verbal agreements | Knowledge stuck in one person's head |

## Data Gaps

| What's Missing | Why It Matters | How to Fix |
|---------------|---------------|------------|
| [e.g., Lead source tracking] | Can't tell which marketing channel works | Add source field to CRM, track from first touch |
| [e.g., Time spent per client] | Can't assess profitability per client | Implement basic time logging |

## Manual Bridges

| From | To | What Gets Copied | How Often | Time Spent | Automation Signal |
|------|----|-----------------|-----------|------------|-------------------|
| [e.g., Gmail] | [e.g., Google Sheets] | New lead details | Daily | 15 min/day | HIGH — Gmail API → Sheets API, straightforward |
| [e.g., Xero] | [e.g., Spreadsheet] | Monthly revenue figures | Monthly | 1 hour | MEDIUM — Xero API pull, format, push to Sheets |

## Single Points of Failure

| Tool/Process | Person | Risk | Mitigation |
|-------------|--------|------|------------|
| [e.g., Xero admin] | [Name] | Only person with access | Add second admin, document process |
