"""
read_pinterest_tasks.py
Reads the Pinterest Pin task sheet and returns all rows with Status = "to do" as JSON.

Usage:
  python3 scripts/read_pinterest_tasks.py

Output (stdout): JSON array of pending tasks
  [{"row": 2, "source_url": "https://...", "board_override": ""}, ...]
"""

import json
import os
import pickle
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

from google.auth.transport.requests import Request
from googleapiclient.discovery import build

# ── Config ─────────────────────────────────────────────────────────────────────
TOKEN_FILE = Path(__file__).parent.parent / "oauth_token.pickle"

def _load_config():
    """Load pinterest_config.env into os.environ (only for keys not already set)."""
    cfg = Path(__file__).parent.parent / "pinterest_config.env"
    if not cfg.exists():
        return
    for line in cfg.read_text().splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, _, val = line.partition("=")
        key = key.strip()
        val = val.strip().strip('"').strip("'")
        if key and key not in os.environ:
            os.environ[key] = val

_load_config()

SHEET_ID = os.environ.get("PINTEREST_SHEET_ID", "")
if not SHEET_ID:
    print("ERROR: PINTEREST_SHEET_ID is not set. Copy pinterest_config.env.example to "
          "pinterest_config.env and fill in your Sheet ID.", file=sys.stderr)
    sys.exit(1)

# Column indices (0-based)
COL_SOURCE_URL  = 0   # A — Worksheetzone listing page URL
COL_STATUS      = 1   # B — "to do" | "done" | "failed"
COL_BOARD       = 2   # C — Pin board title (optional override)
COL_CSV         = 3   # D — Google Drive link to generated CSV
COL_DATE        = 4   # E — Created date
COL_FAIL_REASON = 5   # F — Failed reason

TODO_STATUS = "to do"


def load_creds():
    if not TOKEN_FILE.exists():
        print(f"ERROR: oauth_token.pickle not found at {TOKEN_FILE}", file=sys.stderr)
        sys.exit(1)
    with open(TOKEN_FILE, "rb") as f:
        creds = pickle.load(f)
    if creds.expired and creds.refresh_token:
        print("🔄 Refreshing OAuth token ...", file=sys.stderr)
        creds.refresh(Request())
        with open(TOKEN_FILE, "wb") as f:
            pickle.dump(creds, f)
    return creds


def main():
    creds      = load_creds()
    sheets_svc = build("sheets", "v4", credentials=creds)

    result = sheets_svc.spreadsheets().values().get(
        spreadsheetId=SHEET_ID, range="A:F"
    ).execute()
    rows = result.get("values", [])

    tasks = []
    for i, row in enumerate(rows[1:], start=2):   # row 1 is header
        status = row[COL_STATUS].strip().lower() if len(row) > COL_STATUS else ""
        if status == TODO_STATUS:
            source_url    = row[COL_SOURCE_URL].strip() if len(row) > COL_SOURCE_URL else ""
            board_override = row[COL_BOARD].strip()     if len(row) > COL_BOARD      else ""
            if source_url:
                tasks.append({
                    "row":            i,
                    "source_url":     source_url,
                    "board_override": board_override,
                })

    print(json.dumps(tasks, indent=2))


if __name__ == "__main__":
    main()
