#!/usr/bin/env bash
# run_schema_batch.sh
# Schema markup generator for worksheetzone.org blog posts.
#
# Reads rows with Schema Status = "Generate Schema" from the Google Sheet,
# scans each live post for existing JSON-LD, generates missing schema entities,
# creates a Google Doc per post, and writes the doc URL back to the sheet.
#
# Usage:
#   bash scripts/run_schema_batch.sh                        # process next 10 rows
#   bash scripts/run_schema_batch.sh --limit 5             # process 5 rows
#   bash scripts/run_schema_batch.sh --start-row 2 --end-row 20
#   bash scripts/run_schema_batch.sh --dry-run             # no sheet writes

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(dirname "$SCRIPT_DIR")"

exec python3 "$SCRIPT_DIR/run_batch.py" --schema "$@"
