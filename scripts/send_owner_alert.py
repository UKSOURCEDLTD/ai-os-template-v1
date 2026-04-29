#!/usr/bin/env python3
"""send_owner_alert.py — fire a plain-text email to every address in
config.OWNER_ALERT_EMAILS via the Gmail compose token.

Each owner gets their own message (individual sends, not CC'd) so owner replies
don't spam the group.

Subject is prefixed with config.ALERT_SUBJECT_PREFIX.

Usage:
    python3 scripts/send_owner_alert.py "subject" < body.txt
    python3 scripts/send_owner_alert.py --subject "subject" --body "body text"
    python3 scripts/send_owner_alert.py --subject "s" --body-file path/to/body.txt

Fallback: if Gmail fails, writes the would-be alert to
logs/outreach/alerts-YYYY-MM-DD.log and exits 1.
"""

import argparse
import base64
import os
import sys
from datetime import datetime
from email.mime.text import MIMEText

# Reach into the cold-outreach workflow for config (only workflow for now).
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
import config  # noqa: E402


SCOPES = ['https://www.googleapis.com/auth/gmail.compose']


def parse_args():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('subject_positional', nargs='?', help='Subject (positional; body read from stdin)')
    p.add_argument('--subject', dest='subject', help='Subject line')
    p.add_argument('--body', dest='body', help='Body text inline')
    p.add_argument('--body-file', dest='body_file', help='Read body from this file')
    return p.parse_args()


def resolve_subject_body(args):
    subject = args.subject or args.subject_positional
    if not subject:
        sys.stderr.write("error: subject required\n")
        sys.exit(2)

    if args.body is not None:
        body = args.body
    elif args.body_file:
        with open(args.body_file, 'r', encoding='utf-8') as f:
            body = f.read()
    else:
        # stdin
        if sys.stdin.isatty():
            sys.stderr.write("error: no body provided — pipe via stdin or use --body/--body-file\n")
            sys.exit(2)
        body = sys.stdin.read()
    return subject, body


def fallback_log(subject, body, err):
    os.makedirs(config.LOG_DIR, exist_ok=True)
    path = os.path.join(config.LOG_DIR, f"alerts-{datetime.utcnow():%Y-%m-%d}.log")
    with open(path, 'a', encoding='utf-8') as f:
        f.write(f"\n----- {datetime.utcnow():%Y-%m-%d %H:%M:%S} UTC -----\n")
        f.write(f"Subject: {subject}\n")
        f.write(f"Gmail error: {err}\n\n")
        f.write(body)
        f.write("\n----- end -----\n")
    sys.stderr.write(f"Gmail send failed — fallback logged to {path}\n")


def send(subject, body):
    from google.auth.transport.requests import Request
    from google.oauth2.credentials import Credentials
    from googleapiclient.discovery import build

    creds = Credentials.from_authorized_user_file(config.GMAIL_TOKEN, SCOPES)
    if creds.expired and creds.refresh_token:
        creds.refresh(Request())
    svc = build('gmail', 'v1', credentials=creds, cache_discovery=False)

    prefix = getattr(config, 'ALERT_SUBJECT_PREFIX', f"[{config.COMPANY_SHORT_NAME} AI OS]")
    full_subject = f"{prefix} {subject}" if prefix else subject

    recipients = getattr(config, 'OWNER_ALERT_EMAILS', [])
    if not recipients:
        raise RuntimeError("config.OWNER_ALERT_EMAILS is empty")

    sent = 0
    last_err = None
    for addr in recipients:
        msg = MIMEText(body, _charset='utf-8')
        msg['To'] = addr
        msg['From'] = config.SENDER_EMAIL
        msg['Subject'] = full_subject
        raw = base64.urlsafe_b64encode(msg.as_bytes()).decode('ascii')
        try:
            svc.users().messages().send(userId='me', body={'raw': raw}).execute()
            sent += 1
        except Exception as e:
            last_err = e
    if sent == 0:
        raise RuntimeError(f"0/{len(recipients)} sent; last error: {last_err}")
    if sent < len(recipients):
        sys.stderr.write(f"warning: only {sent}/{len(recipients)} delivered; last error: {last_err}\n")
    return sent


def main():
    args = parse_args()
    subject, body = resolve_subject_body(args)
    try:
        sent = send(subject, body)
        print(f"Alert sent to {sent} owner(s): {subject}")
        return 0
    except Exception as e:
        fallback_log(subject, body, e)
        return 1


if __name__ == "__main__":
    sys.exit(main())
