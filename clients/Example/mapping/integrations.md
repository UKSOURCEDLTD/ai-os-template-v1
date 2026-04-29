# [Client Name] — Integration Architecture

*Completed: [DATE] | Package: [Growth/Partner]*

*Note: Essentials clients skip this document — integrations are simple enough to handle inline during build.*

---

## Required Connections

| # | From | To | Data Flow | Direction | Trigger | Method | Auth | Complexity | Priority |
|---|------|----|-----------|-----------|---------|--------|------|------------|----------|
| 1 | [e.g., Gmail] | AI OS | New enquiries | One-way | Event (new email) | Gmail API (push) | OAuth2 | Low | High |
| 2 | [e.g., Xero] | AI OS | Invoice data, revenue | One-way | Schedule (daily) | Xero API | OAuth2 | Medium | High |
| 3 | AI OS | [e.g., Google Sheets] | Updated CRM records | One-way | Event (lead processed) | Sheets API | OAuth2 | Low | High |
| 4 | AI OS | [e.g., Slack/Telegram] | Notifications, briefings | One-way | Schedule + event | Bot API | API key | Low | Medium |
| 5 | [e.g., Stripe] | AI OS | Payment confirmations | One-way | Event (webhook) | Stripe webhook | Webhook secret | Medium | Medium |

## Dependency Graph

Build integrations in this order — each tier depends on the one above it.

```
Tier 1 (No dependencies — connect first):
  └── Gmail API
  └── Google Sheets API
  └── Messaging channel (Telegram/Slack/WhatsApp)

Tier 2 (Depends on Tier 1):
  └── CRM sync (needs Sheets connected)
  └── Lead routing (needs Gmail + Sheets)

Tier 3 (Depends on Tier 2):
  └── Xero / accounting integration
  └── Stripe / payment integration

Tier 4 (Depends on Tier 3):
  └── Reporting workflows (needs all data flowing)
  └── Advanced automations
```

## Credential Checklist

**Google Workspace:**
- [ ] Gmail API — OAuth2 token (compose + readonly scopes)
- [ ] Google Sheets API — OAuth2 token
- [ ] Google Calendar API — OAuth2 token
- [ ] Google Drive API — OAuth2 token

**Accounting / Payments:**
- [ ] [e.g., Xero] — OAuth2 app registered + token
- [ ] [e.g., Stripe] — API key (restricted, read-only) + webhook secret

**Communication:**
- [ ] [e.g., Telegram Bot] — Bot token from BotFather
- [ ] [e.g., Slack] — Bot token + channel IDs

**Other:**
- [ ] [Tool] — [Auth type] — [Status]

## Risk Flags

| Integration | Risk | Impact | Mitigation |
|------------|------|--------|------------|
| [e.g., Gmail API] | OAuth token expires every 7 days without refresh | Outbound email stops | Implement token refresh in cron, alert on failure |
| [e.g., Xero API] | Rate limit: 60 calls/min | Bulk operations may throttle | Batch requests, implement backoff |
| [e.g., CRM Sheets] | Manual edits could break expected format | Automation errors | Add validation, alert on schema drift |

## Integration Notes

- [Any API limitations, undocumented behaviour, or gotchas discovered during discovery]
- [Vendor-specific quirks: e.g., "Xero sandbox requires separate app registration"]
- [Cost implications: e.g., "Stripe charges 1.4% + 20p per transaction — factor into ROI calculations"]
