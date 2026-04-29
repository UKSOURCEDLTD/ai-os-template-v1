#!/usr/bin/env python3
"""restore_from_supabase.py — pull back a snapshot uploaded by
backup_to_supabase.py.

Usage:
    python3 scripts/restore_from_supabase.py                       # latest
    python3 scripts/restore_from_supabase.py --from-date 2026-04-22
    python3 scripts/restore_from_supabase.py --list
    python3 scripts/restore_from_supabase.py --yes                 # skip prompt

Extraction is destructive — files in BACKUP_PATHS will be overwritten.
A confirmation prompt requiring the literal word RESTORE gates the extract
unless --yes is passed.
"""

import argparse
import io
import os
import sys
import tarfile
from datetime import datetime

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
import config  # noqa: E402


def parse_supabase_env(path):
    out = {}
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#') or '=' not in line:
                continue
            k, _, v = line.partition('=')
            out[k.strip()] = v.strip().strip('"').strip("'")
    return out


def get_client():
    env = parse_supabase_env(os.path.join(REPO_ROOT, '.credentials', 'supabase.env'))
    key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    if not key:
        raise RuntimeError("SUPABASE_SERVICE_ROLE_KEY missing from .credentials/supabase.env")
    from supabase import create_client
    return create_client(config.SUPABASE_URL, key)


def list_snapshots(client, bucket, prefix):
    try:
        entries = client.storage.from_(bucket).list(prefix)
    except Exception as e:
        raise RuntimeError(f"list failed: {e}")
    dates = []
    for e in entries or []:
        name = e.get('name') if isinstance(e, dict) else getattr(e, 'name', None)
        if not name:
            continue
        try:
            datetime.strptime(name, '%Y-%m-%d')
        except ValueError:
            continue
        dates.append(name)
    return sorted(dates)


def download(client, bucket, remote_path):
    data = client.storage.from_(bucket).download(remote_path)
    return data


def preview_members(tar_bytes):
    files = []
    with tarfile.open(fileobj=io.BytesIO(tar_bytes), mode='r:gz') as tar:
        for m in tar.getmembers():
            if m.isfile():
                files.append(m.name)
    return files


def extract(tar_bytes, dest_root):
    with tarfile.open(fileobj=io.BytesIO(tar_bytes), mode='r:gz') as tar:
        tar.extractall(path=dest_root)


def main():
    p = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    p.add_argument('--from-date', dest='from_date', help='YYYY-MM-DD snapshot to restore')
    p.add_argument('--list', action='store_true', help='List available snapshots and exit')
    p.add_argument('--yes', action='store_true', help='Skip the RESTORE confirmation prompt')
    args = p.parse_args()

    try:
        bucket = config.SUPABASE_BACKUP_BUCKET
        client_slug = config.CLIENT_SLUG
    except AttributeError as e:
        sys.stderr.write(f"error: config missing field — {e}\n")
        return 2

    client = get_client()
    prefix = f"backups/{client_slug}"

    snapshots = list_snapshots(client, bucket, prefix)
    if not snapshots:
        sys.stderr.write(f"No snapshots found under {bucket}/{prefix}\n")
        return 3

    if args.list:
        print(f"Snapshots in {bucket}/{prefix}:")
        for d in snapshots:
            print(f"  {d}")
        print(f"({len(snapshots)} total, latest: {snapshots[-1]})")
        return 0

    # Pick target
    if args.from_date:
        if args.from_date not in snapshots:
            sys.stderr.write(f"error: no snapshot for {args.from_date}. Available: {snapshots}\n")
            return 3
        target = args.from_date
    else:
        target = snapshots[-1]

    remote_path = f"{prefix}/{target}/snapshot.tar.gz"
    print(f"Target snapshot: {target}")
    print(f"Downloading {bucket}/{remote_path}...")
    tar_bytes = download(client, bucket, remote_path)
    print(f"Downloaded: {len(tar_bytes):,} bytes")

    # Preview
    files = preview_members(tar_bytes)
    print(f"Snapshot contains {len(files)} file(s):")
    for f in files[:20]:
        exists_tag = " (OVERWRITE)" if os.path.exists(os.path.join(REPO_ROOT, f)) else " (NEW)"
        print(f"  {f}{exists_tag}")
    if len(files) > 20:
        print(f"  ... and {len(files) - 20} more")

    if not args.yes:
        print()
        print("This will overwrite existing files. Type RESTORE to proceed:")
        resp = input("> ").strip()
        if resp != "RESTORE":
            sys.stderr.write("Aborted.\n")
            return 1

    extract(tar_bytes, REPO_ROOT)
    print(f"Restored {len(files)} file(s) from snapshot {target}.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
