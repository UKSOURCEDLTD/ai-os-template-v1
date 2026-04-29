# Workflow: Lead Response

**Trigger:** User says "respond to lead [name]", pastes a lead message, or a new lead is flagged from Gmail

---

## Pre-flight

Before starting, read:
- `context/business.md` — services, positioning, tone
- `context/rules.md` — never send without confirmation
- `memory/leads.md` — check if this lead already exists

---

## Steps

### 1. Read the Lead Message
Extract:
- Their name and company
- What they're asking about or what pain they mentioned
- How they found us (referral, web, social, cold?)
- What they do and how they operate
- Any urgency signals

### 2. Research Their Business
Use web search:
- Find their website and any relevant online presence
- Assess their current situation and obvious pain points
- Note any specific opportunities to mention in the response

**Note:** If no website found, still proceed — note the gap as an opportunity.

### 3. Draft the Response
Warm, direct, and personalised. Not a template. Structure:

```
Hi [Name],

[Acknowledge their message — 1 sentence that shows you read it]

[Show you know their business — 1-2 sentences referencing what you found]

[State what you can do for them — specific service, specific outcome]

[Soft CTA — suggest a quick call or ask a qualifying question]

Best,
[Owner name]
[Business name]
```

**Tone:** Confident, human, not salesy. Peers, not a vendor pitching.

### 4. Suggest Next Steps
After drafting the response, recommend:
- Follow-up cadence if no reply (e.g., 3 days, then 7 days)
- Whether to qualify further before proposing
- Whether to flag as hot or nurture

### 5. Present for Approval
Show the draft. Do not send. Ask:
- Any changes to tone or content?
- Who should sign off?
- Ready to send?

### 6. After Sending
- Add or update entry in `memory/leads.md` with status: Contacted
- Log in `logs/actions.md`: Lead response sent to [Name] / [Company]

---

## Expected Output
A ready-to-review email draft + recommended next steps. Lead updated in memory.

---

## Edge Cases

| Situation | Action |
|-----------|--------|
| Lead already exists in pipeline | Note their history; adjust tone for follow-up context |
| Lead is low quality or irrelevant | Flag to user before drafting; recommend decline or low-effort response |
| Lead came via referral | Always mention the referrer in the response |
| Lead has already been on a call | Skip intro research; focus on follow-up based on call notes |
| No name provided | Address as "Hi there" or use company name; flag the gap |
