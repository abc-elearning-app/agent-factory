# GEO Blog Post Optimizer — Complete Setup & Usage Manual

This tool automatically optimizes blog posts for AI search visibility (Google AI Overviews, ChatGPT, Perplexity). It reads a Google Sheet, rewrites each post using Gemini or Claude, creates a formatted Google Doc, and writes the result back to the sheet.

---

## Table of Contents

1. [What You Need Before Starting](#1-what-you-need-before-starting)
2. [Step 1 — Install the Tool](#2-step-1--install-the-tool)
3. [Step 2 — Install Python Dependencies](#3-step-2--install-python-dependencies)
4. [Step 3 — Set Up Google Cloud (one-time)](#4-step-3--set-up-google-cloud-one-time)
5. [Step 4 — Authenticate with Google](#5-step-4--authenticate-with-google)
6. [Step 5 — Set Up Your AI Writer](#6-step-5--set-up-your-ai-writer)
7. [Step 6 — Get Access to the Google Sheet](#7-step-6--get-access-to-the-google-sheet)
8. [Step 7 — Build the Internal Link Cache](#8-step-7--build-the-internal-link-cache)
9. [Running the Optimizer](#9-running-the-optimizer)
10. [Understanding the Results](#10-understanding-the-results)
11. [Troubleshooting](#11-troubleshooting)

---

## 1. What You Need Before Starting

Make sure you have all of the following before starting:

| Requirement | How to check |
|-------------|-------------|
| A Mac or Linux computer | — |
| Python 3.9 or newer | Open Terminal, type `python3 --version` |
| Git | Open Terminal, type `git --version` |
| A Google account | — |
| Access to the team Google Sheet | Ask the team lead to share it with you |
| Either Gemini CLI **or** Claude CLI installed | See Step 5 |

> **Windows users:** These instructions assume Mac/Linux. On Windows, use [WSL](https://learn.microsoft.com/en-us/windows/wsl/install) (Windows Subsystem for Linux) and follow the same steps inside a WSL terminal.

---

## 2. Step 1 — Install the Tool

Open **Terminal** and run these commands one by one:

```bash
# Download the repository
git clone https://github.com/abc-elearning-app/agent-factory.git

# Go into the project folder
cd agent-factory

# Switch to the GEO optimizer branch
git checkout project/geo-blog-post-optimizer
```

You should now have a folder called `agent-factory` on your computer. All commands from this point on must be run from inside that folder.

---

## 3. Step 2 — Install Python Dependencies

Still in Terminal, run:

```bash
pip3 install google-auth google-auth-httplib2 google-api-python-client \
             google-auth-oauthlib
```

Wait for it to finish (usually under a minute). You should see a line like `Successfully installed ...` at the end.

---

## 4. Step 3 — Set Up Google Cloud (one-time)

This is the most involved step. You need to create your own Google Cloud project and OAuth credentials. This is free and takes about 10 minutes.

### 4a. Create a Google Cloud Project

1. Go to [https://console.cloud.google.com](https://console.cloud.google.com) and sign in with your Google account.
2. At the top of the page, click the project dropdown (it may say "Select a project").
3. Click **New Project**.
4. Give it any name (e.g. `geo-optimizer`) and click **Create**.
5. Make sure your new project is selected in the dropdown before continuing.

### 4b. Enable Required APIs

You need to enable three APIs. For each one, follow these steps:

1. In the left sidebar, go to **APIs & Services → Library**.
2. Search for the API name, click it, then click **Enable**.

Enable these three APIs:
- **Google Sheets API**
- **Google Docs API**
- **Google Drive API**

### 4c. Create OAuth Credentials

1. In the left sidebar, go to **APIs & Services → Credentials**.
2. Click **+ Create Credentials** → **OAuth client ID**.
3. If prompted to configure the OAuth consent screen first:
   - Click **Configure Consent Screen**
   - Choose **External** → click **Create**
   - Fill in **App name** (any name, e.g. "GEO Optimizer"), **User support email** (your email), **Developer contact** (your email)
   - Click **Save and Continue** through all the steps until done
   - Go back to **Credentials → + Create Credentials → OAuth client ID**
4. For **Application type**, choose **Desktop app**.
5. Give it any name and click **Create**.
6. A dialog will appear. Click **Download JSON**.
7. Rename the downloaded file to something simpler like `client_secret.json`.
8. Move this file into the `agent-factory` folder (the same folder where you cloned the repo).

---

## 5. Step 4 — Authenticate with Google

This step connects the tool to your Google account so it can read/write Sheets and Docs.

In Terminal (inside the `agent-factory` folder), run:

```bash
python3 - <<'EOF'
from google_auth_oauthlib.flow import InstalledAppFlow
import pickle, glob, os

# Find your client secret file
matches = glob.glob("client_secret*.json")
if not matches:
    print("ERROR: No client_secret*.json file found in this folder.")
    print("Make sure you downloaded and moved the file as described in Step 3.")
    exit(1)

secret_file = matches[0]
print(f"Using: {secret_file}")

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/drive"
]

flow = InstalledAppFlow.from_client_secrets_file(secret_file, SCOPES)
creds = flow.run_local_server(port=0)

with open("oauth_token.pickle", "wb") as f:
    pickle.dump(creds, f)

print("✅ Authentication successful! oauth_token.pickle saved.")
EOF
```

A browser window will open automatically. Sign in with your Google account and click **Allow**. When you see "The authentication flow has completed", return to Terminal.

You should see: `✅ Authentication successful! oauth_token.pickle saved.`

> **Note:** The `oauth_token.pickle` file contains your credentials. Never share this file with anyone.

---

## 6. Step 5 — Set Up Your AI Writer

The tool supports two AI writers: **Gemini** (free, uses your Google account) and **Claude** (requires Anthropic subscription). You only need one.

### Option A: Gemini CLI (recommended — free)

1. Install Gemini CLI by following the instructions at: [https://github.com/google-gemini/gemini-cli](https://github.com/google-gemini/gemini-cli)
2. After installing, run `gemini --version` in Terminal to confirm it works.
3. Run `gemini` once and sign in with your Google account when prompted.

### Option B: Claude CLI

1. Install Claude Code by following: [https://claude.ai/code](https://claude.ai/code)
2. Sign in with your Anthropic account.
3. Run `claude --version` in Terminal to confirm it works.

> **Which writer to use?** Check the **Writer** column in the Google Sheet for each row — it will say either `Gemini` or `Claude`. Set up whichever one is assigned to the rows you'll be processing.

---

## 7. Step 6 — Get Access to the Google Sheet

Ask the team lead to share the Google Sheet with your Google account (the same account you used in Step 4) with **Editor** access.

Also ask them to share the **"GEO Optimized Posts"** Google Drive folder with your account so the tool can save the output Docs there.

---

## 8. Step 7 — Build the Internal Link Cache

This is a one-time step that downloads all URLs from worksheetzone.org so the tool can add real, verified internal links to each post.

```bash
python3 scripts/build_sitemap_cache.py
```

This takes about 60 seconds and will print progress as it runs. At the end you should see something like:

```
✅  Cache saved → scripts/wzorg_link_cache.json
   Total URLs : 24681
   blog       : 616
   worksheet  : 23169
   ...
```

> **Re-run this command** whenever new content is published on worksheetzone.org to keep the cache up to date.

---

## 9. Running the Optimizer

Once all setup steps are complete, you're ready to run.

### Basic usage

```bash
# Process the next 10 rows (default)
python3 scripts/run_batch.py
```

### Process a specific number of rows

```bash
# Process 50 rows
python3 scripts/run_batch.py --limit 50
```

### Process a specific range of rows

```bash
# Only process rows 72 to 150 in the sheet
python3 scripts/run_batch.py --start-row 72 --end-row 150
```

### Test run without writing anything

```bash
# Dry run — optimizes posts but does NOT create Docs or update the sheet
python3 scripts/run_batch.py --limit 3 --dry-run
```

> **Recommended pace:** Process 50–80 rows per week to avoid triggering Google's spam filters.

### What you'll see while it runs

```
============================================================
GEO Batch Optimizer
  Limit     : 10 rows
============================================================
Reading sheet ...
Found 528 rows with status='optimize'
Processing 10 rows this run

── Row 71  [1/10]  https://worksheetzone.org/blog/adjectives-that-start-with-n
  [1/4] Fetching https://worksheetzone.org/blog/adjectives-that-start-with-n
  [1/4] ✅ 8,432 chars — "Adjectives That Start With N"
  [2/4] Optimizing via Gemini ...
  [2/4] ✅ Optimized (11,204 chars)
  [3/4] Creating Google Doc ...
  [3/4] ✅ https://docs.google.com/document/d/...
  [4/4] Updating sheet row 71 ...
  [4/4] ✅ Sheet updated
  ⏳ Waiting 5s before next row ...
```

---

## 10. Understanding the Results

After the tool runs, open the Google Sheet. Each processed row will be updated:

| Column | What it shows |
|--------|--------------|
| **Status** | `Done ✅` if successful, `Failed ❌` if something went wrong |
| **Optimized Doc** | Link to the Google Doc with the optimized post |
| **Fail Reason** | If status is `Failed ❌`, this explains what went wrong |
| **Processed Date** | The date the row was processed |

### What the optimized post contains

Each optimized post is formatted as a ready-to-copy Google Doc with:
- Original title preserved exactly
- Rewritten opening paragraph (sapo) — 40–60 words
- All headings improved to be specific and descriptive
- Definitions for key terms
- Bullet/numbered lists where appropriate
- A comparison table (if the post covers multiple categories)
- Exactly 4 FAQ pairs at the end
- 3–4 verified internal links to worksheetzone.org pages
- Proper heading styles (H1/H2/H3) and table borders — ready to paste into WordPress

---

## 11. Troubleshooting

| Error message | Cause | Fix |
|---------------|-------|-----|
| `oauth_token.pickle not found` | Authentication not completed | Re-run Step 4 |
| `Token expired` | OAuth token older than ~1 week | Re-run Step 4 |
| `No client_secret*.json found` | Credentials file missing or misnamed | Re-download from Google Cloud Console, rename to `client_secret.json`, put in project folder |
| `Gemini error` | Gemini CLI not logged in | Run `gemini` in Terminal and sign in |
| `Claude error` | Claude CLI not authenticated | Run `claude` in Terminal and sign in |
| `Fetch failed` | Blog post URL blocked or offline | Row is skipped automatically; check the URL manually |
| `wzorg_link_cache.json not found` | Cache not built | Run Step 7: `python3 scripts/build_sitemap_cache.py` |
| `Doc creator failed` | Docs/Drive API issue | Check [Google Cloud Console](https://console.cloud.google.com) — all three APIs must be enabled |
| `403 The caller does not have permission` | Drive folder not shared with your account | Ask team lead to share the "GEO Optimized Posts" folder with your Google account |

### Refreshing expired credentials

OAuth tokens expire after about a week. If you see a `Token expired` error, re-run the authentication command from Step 4:

```bash
python3 - <<'EOF'
from google_auth_oauthlib.flow import InstalledAppFlow
import pickle, glob

matches = glob.glob("client_secret*.json")
secret_file = matches[0]
SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/documents",
    "https://www.googleapis.com/auth/drive"
]
flow = InstalledAppFlow.from_client_secrets_file(secret_file, SCOPES)
creds = flow.run_local_server(port=0)
with open("oauth_token.pickle", "wb") as f:
    pickle.dump(creds, f)
print("✅ Token refreshed.")
EOF
```

---

## Quick Reference

```bash
# --- Setup (run once) ---
git clone https://github.com/abc-elearning-app/agent-factory.git
cd agent-factory
git checkout project/geo-blog-post-optimizer
pip3 install google-auth google-auth-httplib2 google-api-python-client google-auth-oauthlib
# → download client_secret.json from Google Cloud → place in this folder
# → run Step 4 authentication command
python3 scripts/build_sitemap_cache.py

# --- Daily use ---
python3 scripts/run_batch.py               # process next 10 rows
python3 scripts/run_batch.py --limit 50    # process 50 rows
python3 scripts/run_batch.py --dry-run     # test without writing
```

---

*Questions? Contact the team lead or refer to `agents/geo-blog-post-optimizer.md` in the repository for the full technical reference.*
