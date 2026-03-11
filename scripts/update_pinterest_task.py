"""
update_pinterest_task.py
Updates a single row in the Pinterest Pin task sheet after processing.

Usage:
  # Mark as done
  python3 scripts/update_pinterest_task.py <row> done "<board>" "<csv_link>" "<date>"

  # Mark as failed
  python3 scripts/update_pinterest_task.py <row> failed "" "" "<date>" "<reason>"

Arguments:
  row       — sheet row number (integer, e.g. 2)
  status    — "done" or "failed"
  board     — Pin board title that was used (written to column C)
  csv_link  — Google Drive link to the CSV file (written to column D)
  date      — ISO date string, e.g. 2026-03-11 (written to column E)
  reason    — failure reason (written to column F, only used when status=failed)
"""

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
    if len(sys.argv) < 6:
        print("Usage: update_pinterest_task.py <row> <status> <board> <csv_link> <date> [reason]")
        sys.exit(1)

    row        = int(sys.argv[1])
    status     = sys.argv[2].strip()    # "done" or "failed"
    board      = sys.argv[3].strip()
    csv_link   = sys.argv[4].strip()
    date       = sys.argv[5].strip()
    reason     = sys.argv[6].strip() if len(sys.argv) > 6 else ""

    status_cell = "done" if status == "done" else "failed"

    creds      = load_creds()
    sheets_svc = build("sheets", "v4", credentials=creds)

    data = [
        {"range": f"B{row}", "values": [[status_cell]]},
        {"range": f"C{row}", "values": [[board]]},
        {"range": f"D{row}", "values": [[csv_link]]},
        {"range": f"E{row}", "values": [[date]]},
        {"range": f"F{row}", "values": [[reason]]},
    ]

    sheets_svc.spreadsheets().values().batchUpdate(
        spreadsheetId=SHEET_ID,
        body={"valueInputOption": "RAW", "data": data}
    ).execute()

    print(f"✅ Row {row} updated: {status_cell}")


if __name__ == "__main__":
    main()
