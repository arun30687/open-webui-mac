#!/bin/bash
# ============================================================
# One-time setup: Install all dependencies on macOS
# ============================================================
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "========================================="
echo "  Open WebUI + MCP Setup (macOS)"
echo "========================================="

# ── 1. Check prerequisites ────────────────────────────────
echo ""
echo "[1/5] Checking prerequisites..."

# Homebrew
if ! command -v brew &> /dev/null; then
    echo "  ERROR: Homebrew not found. Install from https://brew.sh"
    exit 1
fi
echo "  Homebrew: OK"

# ── 2. Install Python 3.11 ────────────────────────────────
echo ""
echo "[2/5] Installing Python 3.11..."
if command -v python3.11 &> /dev/null || [ -f /opt/homebrew/bin/python3.11 ]; then
    echo "  Python 3.11: Already installed"
else
    brew install python@3.11
fi
PYTHON=$(/opt/homebrew/bin/python3.11 --version 2>/dev/null && echo "/opt/homebrew/bin/python3.11" || echo "python3.11")
echo "  Using: $($PYTHON --version)"

# ── 3. Install Node.js ────────────────────────────────────
echo ""
echo "[3/5] Installing Node.js..."
if command -v node &> /dev/null; then
    echo "  Node.js: $(node --version)"
else
    brew install node@20
    brew link node@20 --force 2>/dev/null || true
fi

# ── 4. Install Ollama ─────────────────────────────────────
echo ""
echo "[4/5] Installing Ollama..."
if command -v ollama &> /dev/null; then
    echo "  Ollama: $(ollama --version 2>/dev/null || echo 'installed')"
else
    brew install ollama
fi

# Pull default model
echo "  Pulling qwen2.5:7b model (this may take a while)..."
ollama pull qwen2.5:7b 2>/dev/null || echo "  Model pull skipped (Ollama may not be running)"

# ── 5. Create Python venv and install packages ────────────
echo ""
echo "[5/5] Setting up Python environment..."

PYTHON_BIN="/opt/homebrew/bin/python3.11"
if [ ! -f "$PYTHON_BIN" ]; then
    PYTHON_BIN=$(which python3.11 2>/dev/null || which python3)
fi

if [ ! -d "$BASE_DIR/venv" ]; then
    echo "  Creating virtual environment..."
    $PYTHON_BIN -m venv "$BASE_DIR/venv"
fi

source "$BASE_DIR/venv/bin/activate"
echo "  Installing packages..."
pip install --quiet --upgrade pip
pip install --quiet open-webui mcpo
echo "  Installed: open-webui, mcpo"

# ── 6. Create config from example ─────────────────────────
echo ""
if [ ! -f "$BASE_DIR/mcpo/config.json" ]; then
    echo "========================================="
    echo "  IMPORTANT: Configure your MCP server"
    echo "========================================="
    echo ""
    echo "  Copy the example config and add your GitHub token:"
    echo ""
    echo "    cp mcpo/config.json.example mcpo/config.json"
    echo "    # Edit mcpo/config.json and replace <YOUR_GITHUB_PAT_HERE>"
    echo ""
else
    echo "  MCP config: mcpo/config.json exists"
fi

echo ""
echo "========================================="
echo "  Setup complete!"
echo "========================================="
echo ""
echo "  Next steps:"
echo "    1. cp mcpo/config.json.example mcpo/config.json  (if not done)"
echo "    2. Edit mcpo/config.json with your GitHub PAT"
echo "    3. ./start.sh                                    (start all services)"
echo "    4. Open http://localhost:8080                     (create account)"
echo "    5. ./register-pipe.sh                            (register the pipe)"
echo "    6. Select 'GitHub MCP Agent' model in Open WebUI"
echo ""
