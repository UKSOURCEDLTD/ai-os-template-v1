#!/usr/bin/env python3
"""backup_to_supabase.py — daily state snapshot to Supabase Storage.

Builds a tarball of config.BACKUP_PATHS (tracker, CRM, suppression list,
bounce review queue, last 7 logs) and uploads to:

    {SUPABASE_BACKUP_BUCKET}/backups/{CLIENT_SLUG}/{YYYY-MM-DD}/snapshot.tar.gz

Rotation: deletes snapshots older than 30 days.

Exit code:
    0 — upload succeeded
    non-zero — any failure (run_backup.sh then alerts the owner)
"""

import argparse
import io
import os
import sys
import tarfile
from datetime import datetime, timedelta

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPO_ROOT = os.path.dirname(SCRIPT_DIR)
sys.path.insert(0, os.path.join(REPO_ROOT, 'workflows', 'cold-outreach'))
import config  # noqa: E402


RETENTION_DAYS = 30


def parse_supabase_env(path):
    """Trivial KEY=VALUE parser. No python-dotenv dependency."""
    out = {}
    if not os.path.exists(path):
        raise FileNotFoundError(f"supabase.env missing: {path}")
    with open(path, 'r', encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            if '=' not in line:
                continue
            k, _, v = line.partition('=')
            v = v.strip().strip('"').strip("'")
            out[k.strip()] = v
    return out


def build_tarball(paths, repo_root):
    """Return (bytes, size, file_count) for a gzipped tar of the given paths.

    Paths stored relative to repo_root so restore is unambiguous.
    Missing paths are skipped with a warning (not fatal).
    """
    buf = io.BytesIO()
    file_count = 0
    skipped = []
    with tarfile.open(fileobj=buf, mode='w:gz') as tar:
        for p in paths:
            # Resolve to absolute. Accept absolute or repo-relative input.
            if os.path.isabs(p):
                src = p
            else:
                src = os.path.join(repo_root, p)
            if not os.path.exists(src):
                skipped.append(p)
                continue
            arcname = os.path.relpath(src, repo_root)
            tar.add(src, arcname=arcname, recursive=True)
            if os.path.isdir(src):
                for root, _, files in os.walk(src):
                    file_count += len(files)
            else:
                file_count += 1
    data = buf.getvalue()
    return data, len(data), file_count, skipped


def get_client(url, key):
    from supabase import create_client
    return create_client(url, key)


def upload(client, bucket, remote_path, data):
    # supabase-py v2: bucket().upload(path, file, file_options)
    # Use upsert=true in case same-day rerun.
    try:
        client.storage.from_(bucket).upload(
            path=remote_path,
            file=data,
            file_options={'content-type': 'application/gzip', 'upsert': 'true'},
        )
    except Exception as e:
        # Some SDK versions raise on 409 conflict even with upsert; try update as fallback.
        msg = str(e)
        if 'already exists' in msg.lower() or '409' in msg:
            client.storage.from_(bucket).update(
                path=remote_path,
                file=data,
                file_options={'content-type': 'application/gzip'},
            )
        else:
            raise


def list_snapshots(client, bucket, prefix):
    """List snapshot date folders under backups/{client_slug}/.

    Returns a list of (date_str, full_path_to_snapshot).
    """
    try:
        entries = client.storage.from_(bucket).list(prefix)
    except Exception:
        return []
    out = []
    for e in entries or []:
        name = e.get('name') if isinstance(e, dict) else getattr(e, 'name', None)
        if not name:
            continue
        # date folders look like 2026-04-24
        try:
            datetime.strptime(name, '%Y-%m-%d')
        except ValueError:
            continue
        out.append((name, f"{prefix}/{name}/snapshot.tar.gz"))
    return out


def rotate(client, bucket, prefix, retention_days):
    cutoff = datetime.utcnow().date() - timedelta(days=retention_days)
    snapshots = list_snapshots(client, bucket, prefix)
    to_delete = []
    for date_str, path in snapshots:
        d = datetime.strptime(date_str, '%Y-%m-%d').date()
        if d < cutoff:
            to_delete.append(path)
    if to_delete:
        try:
            client.storage.from_(bucket).remove(to_delete)
        except Exception as e:
            sys.stderr.write(f"warning: rotation cleanup partial — {e}\n")
    return len(to_delete)


def main():
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument('--dry-run', action='store_true', help="Build tarball but don't upload")
    args = parser.parse_args()

    # 1. Load supabase creds
    env_path = os.path.join(REPO_ROOT, '.credentials', 'supabase.env')
    env = parse_supabase_env(env_path)
    key = env.get('SUPABASE_SERVICE_ROLE_KEY')
    if not key:
        sys.stderr.write(f"error: SUPABASE_SERVICE_ROLE_KEY missing from {env_path}\n")
        return 2

    # 2. Config-required fields
    try:
        supabase_url = config.SUPABASE_URL
        bucket = config.SUPABASE_BACKUP_BUCKET
        client_slug = config.CLIENT_SLUG
        backup_paths = list(config.BACKUP_PATHS)
    except AttributeError as e:
        sys.stderr.write(f"error: config is missing a required backup field — {e}\n")
        return 2

    # 3. Build tarball
    data, size, file_count, skipped = build_tarball(backup_paths, REPO_ROOT)
    if file_count == 0:
        sys.stderr.write("error: tarball is empty — nothing to back up\n")
        return 3

    date_str = datetime.utcnow().strftime('%Y-%m-%d')
    prefix = f"backups/{client_slug}"
    remote_path = f"{prefix}/{date_str}/snapshot.tar.gz"

    print(f"Snapshot: {size:,} bytes, {file_count} file(s)")
    if skipped:
        print(f"Skipped missing paths: {skipped}")

    if args.dry_run:
        print(f"DRY RUN — would upload to {bucket}/{remote_path}")
        return 0

    # 4. Upload
    try:
        client = get_client(supabase_url, key)
        upload(client, bucket, remote_path, data)
    except Exception as e:
        sys.stderr.write(f"error: upload failed — {e}\n")
        return 4
    print(f"Uploaded: {bucket}/{remote_path}")

    # 5. Rotate
    try:
        deleted = rotate(client, bucket, prefix, RETENTION_DAYS)
        print(f"Rotation: deleted {deleted} snapshot(s) older than {RETENTION_DAYS} days")
    except Exception as e:
        sys.stderr.write(f"warning: rotation failed — {e}\n")

    return 0


if __name__ == "__main__":
    sys.exit(main())
