# Skill — Google Workspace

## Overview
- **Provider:** Built-in Claude Code Google Workspace skills
- **Status:** Active
- **Purpose:** Full read/write access to the Google Workspace suite

## Services & what they do

### Gmail (`gws-gmail`)
- Read inbox, search emails, read threads
- Draft, send, reply, reply-all, and forward emails
- Apply labels, archive, and filter messages
- Watch for new emails in real time

### Google Calendar (`gws-calendar`)
- Read and create calendar events
- Check availability and find free time slots
- Schedule recurring events
- View upcoming agenda across all calendars

### Google Drive (`gws-drive`)
- Search, list, and download files
- Upload files and create folder structures
- Share files and manage permissions

### Google Sheets (`gws-sheets`)
- Read values from any spreadsheet
- Append rows and update cells

### Google Docs (`gws-docs`)
- Read and append to documents

### Google Tasks (`gws-tasks`)
- Create and manage task lists and tasks

## What we use it for
<!-- Customise for this business -->
- [Use case 1 — e.g. monitoring lead emails]
- [Use case 2 — e.g. scheduling meetings]
- [Use case 3 — e.g. storing proposals in Drive]

## Auth
- OAuth 2.0 via Claude Code built-in Google Workspace integration

## Notes
- Never send emails or create calendar events without explicit confirmation
- Always preview drafts before sending
