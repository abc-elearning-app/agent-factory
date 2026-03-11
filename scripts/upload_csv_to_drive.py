"""
upload_csv_to_drive.py
Uploads a local CSV file to the Pinterest Pins Google Drive folder
and returns the shareable link.

Usage:
  python3 scripts/upload_csv_to_drive.py <csv_file_path>

Output (stdout): shareable Google Drive link
  https://drive.google.com/file/d/XXXXX/view
"""

import os
import pickle
import sys
import warnings
from pathlib import Path

warnings.filterwarnings("ignore")

from google.auth.transport.requests import Request
from googleapiclient.discovery import build
from googleapiclient.http import MediaFileUpload

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

FOLDER_ID = os.environ.get("PINTEREST_DRIVE_FOLDER_ID", "")
if not FOLDER_ID:
    print("ERROR: PINTEREST_DRIVE_FOLDER_ID is not set. Copy pinterest_config.env.example to "
          "pinterest_config.env and fill in your Drive folder ID.", file=sys.stderr)
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
    if len(sys.argv) < 2:
        print("Usage: upload_csv_to_drive.py <csv_file_path>")
        sys.exit(1)

    csv_path = Path(sys.argv[1])
    if not csv_path.exists():
        print(f"ERROR: File not found: {csv_path}", file=sys.stderr)
        sys.exit(1)

    creds       = load_creds()
    drive_svc   = build("drive", "v3", credentials=creds)

    file_metadata = {
        "name":    csv_path.name,
        "parents": [FOLDER_ID],
    }
    media = MediaFileUpload(str(csv_path), mimetype="text/csv", resumable=False)

    uploaded = drive_svc.files().create(
        body=file_metadata,
        media_body=media,
        fields="id,name"
    ).execute()

    file_id = uploaded["id"]
    print(f"  Uploaded: {uploaded['name']} (id: {file_id})", file=sys.stderr)

    # Set "anyone with the link can view"
    drive_svc.permissions().create(
        fileId=file_id,
        body={"type": "anyone", "role": "reader"}
    ).execute()

    link = f"https://drive.google.com/file/d/{file_id}/view"
    print(link)   # stdout — captured by the agent


if __name__ == "__main__":
    main()
