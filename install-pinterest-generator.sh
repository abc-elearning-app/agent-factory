#!/usr/bin/env bash
# =============================================================================
# Pinterest Pin CSV Generator — One-Command Installer
# =============================================================================
#
# Mac / Linux:
#   curl -fsSL https://raw.githubusercontent.com/abc-elearning-app/agent-factory/project/pinterest-pin-csv-generator/install-pinterest-generator.sh | bash
#
# Windows — run this same command inside either:
#   • Git Bash  (bundled with https://git-scm.com/download/win)
#   • WSL       (Windows Subsystem for Linux — enable in Windows Features)
#
# =============================================================================

set -euo pipefail

# ── Re-exec when piped (curl | bash loses stdin for read prompts) ──────────────
if [ ! -t 0 ]; then
    SELF=$(mktemp /tmp/install-pinterest-XXXX.sh)
    cat > "$SELF"
    exec bash "$SELF" "$@"
fi

# ── Colors ─────────────────────────────────────────────────────────────────────
BOLD='\033[1m'
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
DIM='\033[2m'
RESET='\033[0m'

REPO_URL="https://github.com/abc-elearning-app/agent-factory.git"
BRANCH="project/pinterest-pin-csv-generator"
DEFAULT_DIR="$HOME/pinterest-generator"

# ── Helpers ────────────────────────────────────────────────────────────────────
info()    { echo -e "${CYAN}→${RESET} $*"; }
success() { echo -e "${GREEN}✅${RESET} $*"; }
warn()    { echo -e "${YELLOW}⚠️  $*${RESET}"; }
error()   { echo -e "${RED}❌ $*${RESET}"; exit 1; }
step()    { echo -e "\n${BOLD}${CYAN}$*${RESET}"; echo -e "${DIM}$(printf '─%.0s' {1..60})${RESET}"; }
ask()     { echo -e "${YELLOW}?${RESET} $*"; }

pause() {
    echo ""
    read -rp "$(echo -e "${YELLOW}Press Enter to continue...${RESET}")" _
}

# ── Detect OS ──────────────────────────────────────────────────────────────────
OS="linux"
case "$(uname -s)" in
    Darwin) OS="mac" ;;
    Linux)
        if grep -qi microsoft /proc/version 2>/dev/null; then
            OS="wsl"
        fi
        ;;
    CYGWIN*|MINGW*|MSYS_NT*) OS="gitbash" ;;
esac

# ── Banner ─────────────────────────────────────────────────────────────────────
clear
echo -e "${BOLD}${CYAN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║     Pinterest Pin CSV Generator — Installer             ║"
echo "  ║     Worksheetzone.org  ·  Pinterest Bulk Pins           ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo "  This installer sets up everything you need to:"
echo "  • Fetch worksheet items from Worksheetzone listing pages"
echo "  • Generate Pinterest-optimized titles, descriptions & keywords"
echo "  • Create bulk-upload CSVs for Pinterest Business (200 pins/file)"
echo "  • Upload CSVs to your Google Drive automatically"
echo "  • Track and update tasks from your Google Sheet"
echo ""

case "$OS" in
    wsl)     echo -e "  ${CYAN}Detected: Windows (WSL)${RESET}\n" ;;
    gitbash) echo -e "  ${CYAN}Detected: Windows (Git Bash)${RESET}\n" ;;
    mac)     echo -e "  ${CYAN}Detected: macOS${RESET}\n" ;;
    *)       echo -e "  ${CYAN}Detected: Linux${RESET}\n" ;;
esac

echo -e "${DIM}  Estimated time: 5–15 minutes (most steps are automatic)${RESET}"
echo ""

# ── Step 1: Prerequisites ──────────────────────────────────────────────────────
step "Step 1/7 — Checking prerequisites"

PREREQ_OK=true

# Python 3.9+
if command -v python3 &>/dev/null; then
    PY_VER=$(python3 -c 'import sys; print(f"{sys.version_info.major}.{sys.version_info.minor}")')
    PY_MAJ=$(echo "$PY_VER" | cut -d. -f1)
    PY_MIN=$(echo "$PY_VER" | cut -d. -f2)
    if [ "$PY_MAJ" -ge 3 ] && [ "$PY_MIN" -ge 9 ]; then
        success "Python $PY_VER"
    else
        echo -e "${RED}❌ Python $PY_VER found — need 3.9 or newer${RESET}"
        case "$OS" in
            mac)             echo "  Upgrade: brew install python3   OR   https://python.org/downloads" ;;
            linux|wsl)       echo "  Upgrade: sudo apt install python3.11  (or newer)" ;;
            gitbash)         echo "  Download: https://python.org/downloads  (check 'Add to PATH')" ;;
        esac
        PREREQ_OK=false
    fi
else
    echo -e "${RED}❌ Python 3 not found${RESET}"
    case "$OS" in
        mac)             echo "  Install: brew install python3   OR   https://python.org/downloads" ;;
        linux|wsl)       echo "  Install: sudo apt install python3 python3-pip" ;;
        gitbash)         echo "  Install: https://python.org/downloads  (check 'Add to PATH')" ;;
    esac
    PREREQ_OK=false
fi

# pip3
if command -v pip3 &>/dev/null; then
    success "pip3 found"
else
    warn "pip3 not found — attempting to bootstrap..."
    python3 -m ensurepip --upgrade 2>/dev/null && success "pip3 installed" || {
        warn "Could not auto-install pip3."
        case "$OS" in
            linux|wsl) echo "  Try: sudo apt install python3-pip" ;;
            mac)       echo "  Try: python3 -m ensurepip --upgrade" ;;
        esac
        PREREQ_OK=false
    }
fi

# Git
if command -v git &>/dev/null; then
    success "Git $(git --version | awk '{print $3}')"
else
    echo -e "${RED}❌ Git not found${RESET}"
    case "$OS" in
        mac)       echo "  Install: brew install git   OR   xcode-select --install" ;;
        linux|wsl) echo "  Install: sudo apt install git" ;;
        gitbash)   echo "  Git Bash requires Git — reinstall from https://git-scm.com/download/win" ;;
    esac
    PREREQ_OK=false
fi

# Gemini CLI
if command -v gemini &>/dev/null; then
    success "Gemini CLI found"
else
    echo -e "${YELLOW}⚠️  Gemini CLI not found${RESET}"
    echo ""
    echo "  The agent uses Gemini CLI to fetch pages and generate content."
    echo "  Install it now (requires Node.js / npm):"
    echo ""
    echo -e "    ${CYAN}npm install -g @google/gemini-cli${RESET}"
    echo ""
    echo "  No npm? Install Node.js first: https://nodejs.org"
    echo "  After installing, run ${BOLD}gemini${RESET} once to log in with your Google account."
    echo ""
    warn "Continuing — install Gemini CLI before running the agent."
fi

# Claude Code
if command -v claude &>/dev/null; then
    success "Claude Code found (agent runner)"
else
    echo -e "${YELLOW}⚠️  Claude Code not found${RESET}"
    echo "  Install from: https://claude.ai/code"
    echo -e "  ${DIM}Claude Code is needed to run the Pinterest agent.${RESET}"
    warn "Continuing — install Claude Code before first use."
fi

if [ "$PREREQ_OK" = false ]; then
    echo ""
    error "Some prerequisites are missing. Install them, then re-run this installer."
fi

# ── Step 2: Install location ───────────────────────────────────────────────────
step "Step 2/7 — Choose install location"

echo ""
ask "Where should the tool be installed?"
echo -e "  ${DIM}Press Enter for the default: $DEFAULT_DIR${RESET}"
echo ""
read -rp "  Install path: " INSTALL_DIR
INSTALL_DIR="${INSTALL_DIR:-$DEFAULT_DIR}"
INSTALL_DIR="${INSTALL_DIR/#\~/$HOME}"

if [ -d "$INSTALL_DIR/.git" ]; then
    warn "Directory already exists — will update instead of re-cloning."
    UPDATE_ONLY=true
else
    UPDATE_ONLY=false
fi

info "Install path: $INSTALL_DIR"

# ── Step 3: Clone / update repo ───────────────────────────────────────────────
step "Step 3/7 — Downloading the tool"

if [ "$UPDATE_ONLY" = true ]; then
    info "Pulling latest changes..."
    cd "$INSTALL_DIR"
    git fetch origin
    git checkout "$BRANCH" 2>/dev/null || true
    git pull origin "$BRANCH"
    success "Repository updated"
else
    info "Cloning repository (branch: $BRANCH)..."
    git clone --branch "$BRANCH" --single-branch "$REPO_URL" "$INSTALL_DIR"
    cd "$INSTALL_DIR"
    success "Downloaded to $INSTALL_DIR"
fi

# ── Step 4: Python dependencies ───────────────────────────────────────────────
step "Step 4/7 — Installing Python dependencies"

info "Installing packages (30–60 seconds)..."
pip3 install \
    google-auth \
    google-auth-httplib2 \
    google-api-python-client \
    google-auth-oauthlib \
    --quiet

success "Python packages installed"

# ── Step 5: Google Cloud credentials ──────────────────────────────────────────
step "Step 5/7 — Google Cloud credentials (one-time manual setup)"

EXISTING_SECRET=$(ls "$INSTALL_DIR"/client_secret*.json 2>/dev/null | head -1 || true)

if [ -n "$EXISTING_SECRET" ]; then
    success "Credentials file found: $(basename "$EXISTING_SECRET")"
else
    echo ""
    echo -e "  ${BOLD}You need to create a Google Cloud OAuth credential.${RESET}"
    echo "  This is a one-time 5-minute setup — follow these steps:"
    echo ""
    echo -e "  ${CYAN} 1.${RESET} Open: ${BOLD}https://console.cloud.google.com${RESET}"
    echo -e "  ${CYAN} 2.${RESET} Create a new project (any name, e.g. ${BOLD}pinterest-generator${RESET})"
    echo -e "  ${CYAN} 3.${RESET} Go to ${BOLD}APIs & Services → Library${RESET} and enable:"
    echo "          • Google Sheets API"
    echo "          • Google Drive API"
    echo -e "  ${CYAN} 4.${RESET} Go to ${BOLD}APIs & Services → OAuth consent screen${RESET}"
    echo "          → User Type: External → fill in App name → Save"
    echo -e "  ${CYAN} 5.${RESET} Go to ${BOLD}APIs & Services → Credentials${RESET}"
    echo -e "          → ${BOLD}+ Create Credentials → OAuth client ID${RESET}"
    echo -e "  ${CYAN} 6.${RESET} Application type: ${BOLD}Desktop app${RESET} → Create"
    echo -e "  ${CYAN} 7.${RESET} Click ${BOLD}Download JSON${RESET}"
    echo -e "  ${CYAN} 8.${RESET} Rename the downloaded file to ${BOLD}client_secret.json${RESET}"
    echo -e "  ${CYAN} 9.${RESET} Move it into: ${BOLD}$INSTALL_DIR/${RESET}"
    echo ""
    echo -e "  ${DIM}Detailed guide with screenshots: $INSTALL_DIR/PINTEREST-GENERATOR-MANUAL.md${RESET}"
    echo ""

    while true; do
        pause
        EXISTING_SECRET=$(ls "$INSTALL_DIR"/client_secret*.json 2>/dev/null | head -1 || true)
        if [ -n "$EXISTING_SECRET" ]; then
            success "Found: $(basename "$EXISTING_SECRET")"
            break
        else
            warn "No client_secret*.json found in $INSTALL_DIR"
            echo "  Complete all 9 steps above, then press Enter to retry."
        fi
    done
fi

# ── Step 6: Google OAuth authentication ───────────────────────────────────────
step "Step 6/7 — Connecting to your Google account"

if [ -f "$INSTALL_DIR/oauth_token.pickle" ]; then
    success "Already authenticated (oauth_token.pickle exists)"
    echo -e "  ${DIM}To re-authenticate later: delete oauth_token.pickle and re-run this installer.${RESET}"
else
    info "A browser window will open — sign in and click Allow."
    echo -e "  ${DIM}Permissions requested: Google Sheets (read/write) + Google Drive (upload)${RESET}"
    echo ""

    python3 - <<'PYEOF'
import sys, glob, pickle

try:
    from google_auth_oauthlib.flow import InstalledAppFlow
except ImportError:
    print("ERROR: google-auth-oauthlib not installed.")
    sys.exit(1)

matches = glob.glob("client_secret*.json")
if not matches:
    print("ERROR: No client_secret*.json found in current directory.")
    sys.exit(1)

secret_file = sorted(matches)[0]
print(f"  Using: {secret_file}")

SCOPES = [
    "https://www.googleapis.com/auth/spreadsheets",
    "https://www.googleapis.com/auth/drive",
]

flow = InstalledAppFlow.from_client_secrets_file(secret_file, SCOPES)
creds = flow.run_local_server(port=0)

with open("oauth_token.pickle", "wb") as f:
    pickle.dump(creds, f)

print("  ✅ Authenticated. oauth_token.pickle saved.")
PYEOF

fi

# ── Step 7: Configure Sheet ID and Drive folder ────────────────────────────────
step "Step 7/7 — Configure your Google Sheet and Drive folder"

CFG="$INSTALL_DIR/pinterest_config.env"
SHEET_ID=""
FOLDER_ID=""

# Load existing values if re-running
if [ -f "$CFG" ]; then
    SHEET_ID=$(grep '^PINTEREST_SHEET_ID=' "$CFG" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || true)
    FOLDER_ID=$(grep '^PINTEREST_DRIVE_FOLDER_ID=' "$CFG" 2>/dev/null | cut -d'=' -f2- | tr -d '"' || true)
    [[ "$SHEET_ID" == "your_sheet_id_here" ]] && SHEET_ID=""
    [[ "$FOLDER_ID" == "your_drive_folder_id_here" ]] && FOLDER_ID=""
fi

echo ""

# ── Google Sheet ───────────────────────────────────────────────────────────────
if [ -n "$SHEET_ID" ]; then
    success "Sheet ID already set: $SHEET_ID"
else
    echo -e "  ${BOLD}Google Sheet ID${RESET}"
    echo "  Create a Google Sheet with these column headers in row 1:"
    echo -e "    ${CYAN}A: Source URL  │  B: Status  │  C: Pin board  │  D: CSV link  │  E: Date  │  F: Reason${RESET}"
    echo ""
    echo "  Set column B as a dropdown with values: to do, done, failed"
    echo ""
    echo "  Your sheet URL looks like:"
    echo -e "  ${DIM}  https://docs.google.com/spreadsheets/d/${BOLD}← SHEET_ID →${DIM}/edit${RESET}"
    echo ""
    while true; do
        read -rp "  Paste your Sheet ID: " SHEET_ID
        SHEET_ID=$(echo "$SHEET_ID" | tr -d ' ')
        [ -n "$SHEET_ID" ] && break
        warn "Sheet ID cannot be empty."
    done
fi

# ── Drive Folder ───────────────────────────────────────────────────────────────
if [ -n "$FOLDER_ID" ]; then
    success "Drive Folder ID already set: $FOLDER_ID"
else
    echo ""
    echo -e "  ${BOLD}Google Drive Folder ID${RESET}"
    echo "  Create a folder in your Google Drive for the CSV uploads."
    echo "  Open the folder — the URL looks like:"
    echo -e "  ${DIM}  https://drive.google.com/drive/folders/${BOLD}← FOLDER_ID →${RESET}"
    echo ""
    while true; do
        read -rp "  Paste your Drive Folder ID: " FOLDER_ID
        FOLDER_ID=$(echo "$FOLDER_ID" | tr -d ' ')
        [ -n "$FOLDER_ID" ] && break
        warn "Drive Folder ID cannot be empty."
    done
fi

# ── Write config file ──────────────────────────────────────────────────────────
cat > "$CFG" <<EOF
PINTEREST_SHEET_ID=$SHEET_ID
PINTEREST_DRIVE_FOLDER_ID=$FOLDER_ID
PINTEREST_SCRIPTS_DIR=$INSTALL_DIR/scripts
EOF

success "Config written to pinterest_config.env"

# ── Verify sheet connection ────────────────────────────────────────────────────
echo ""
info "Verifying connection to your Google Sheet..."
if python3 "$INSTALL_DIR/scripts/read_pinterest_tasks.py" 2>/dev/null \
    | python3 -c "import sys,json; d=json.load(sys.stdin); print(f'  Sheet connected — {len(d)} pending task(s) found')" 2>/dev/null; then
    success "Google Sheet connection verified"
else
    warn "Could not read the sheet."
    echo "  Make sure you:"
    echo "  1. Shared the sheet with the Google account you authenticated with"
    echo "  2. The Sheet ID is correct"
    echo ""
    echo -e "  ${DIM}The tool will still work — fix the sheet access and re-run if needed.${RESET}"
fi

# ── Done ───────────────────────────────────────────────────────────────────────
echo ""
echo -e "${BOLD}${GREEN}"
echo "  ╔══════════════════════════════════════════════════════════╗"
echo "  ║           ✅  Installation complete!                     ║"
echo "  ╚══════════════════════════════════════════════════════════╝"
echo -e "${RESET}"
echo -e "  ${BOLD}Installed to:${RESET} $INSTALL_DIR"
echo ""
echo -e "  ${BOLD}How to run:${RESET}"
echo ""
echo -e "  ${CYAN}1.${RESET} Open Claude Code from the install directory:"
echo -e "     ${CYAN}cd $INSTALL_DIR && claude${RESET}"
echo ""
echo -e "  ${CYAN}2.${RESET} The Pinterest agent will be available automatically."
echo -e "     Start it with:  ${CYAN}/pinterest-pin-csv-generator${RESET}"
echo -e "     ${DIM}(or pick it from the Agents panel with @)${RESET}"
echo ""
echo -e "  ${BOLD}Workflow:${RESET}"
echo "  1. Add worksheet listing URLs to your Google Sheet (Status = \"to do\")"
echo "  2. Run the agent — it reads the sheet, generates CSVs, uploads to Drive"
echo "  3. Download CSVs from Drive → upload to Pinterest Business → Bulk Create Pins"
echo ""
echo -e "  ${BOLD}Documentation:${RESET} $INSTALL_DIR/PINTEREST-GENERATOR-MANUAL.md"
echo ""
echo -e "  ${DIM}To re-run setup at any time:  bash $INSTALL_DIR/install-pinterest-generator.sh${RESET}"
echo ""
