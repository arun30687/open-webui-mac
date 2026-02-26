#!/bin/bash
# ============================================================
# Start all services: Ollama + MCPO + Open WebUI
# ============================================================
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
VENV_DIR="$BASE_DIR/venv"
DATA_DIR="$BASE_DIR/data"
LOG_DIR="$BASE_DIR/logs"
PID_DIR="$BASE_DIR/pids"

mkdir -p "$LOG_DIR" "$PID_DIR" "$DATA_DIR"

echo "========================================="
echo "  Starting Open WebUI Stack (Native)"
echo "========================================="

# ── 1. Ollama ──────────────────────────────────────────────
echo ""
echo "[1/3] Ollama..."
if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
    echo "  Already running."
else
    echo "  Starting Ollama..."
    ollama serve > "$LOG_DIR/ollama.log" 2>&1 &
    echo $! > "$PID_DIR/ollama.pid"
    sleep 3
    if curl -s http://localhost:11434/api/tags > /dev/null 2>&1; then
        echo "  Started (PID $(cat $PID_DIR/ollama.pid))"
    else
        echo "  WARNING: Ollama may still be starting. Check $LOG_DIR/ollama.log"
    fi
fi

# ── 2. MCPO ────────────────────────────────────────────────
echo ""
echo "[2/3] MCPO..."
if curl -s http://localhost:8300/ > /dev/null 2>&1; then
    echo "  Already running."
else
    echo "  Starting MCPO on port 8300..."
    source "$VENV_DIR/bin/activate"
    cd "$BASE_DIR"
    nohup mcpo --config mcpo/config.json --host 0.0.0.0 --port 8300 \
        > "$LOG_DIR/mcpo.log" 2>&1 &
    echo $! > "$PID_DIR/mcpo.pid"

    # Wait for MCPO + MCP server init
    echo "  Waiting for MCP server initialization..."
    for i in $(seq 1 30); do
        if curl -s http://localhost:8300/ > /dev/null 2>&1; then
            TOOL_COUNT=$(curl -s http://localhost:8300/github/openapi.json 2>/dev/null | python3 -c "import json,sys; print(len(json.load(sys.stdin).get('paths',{})))" 2>/dev/null || echo "?")
            echo "  Started (PID $(cat $PID_DIR/mcpo.pid), $TOOL_COUNT tools)"
            break
        fi
        sleep 2
    done
fi

# ── 3. Open WebUI ──────────────────────────────────────────
echo ""
echo "[3/3] Open WebUI..."
if curl -s http://localhost:8080/ > /dev/null 2>&1; then
    echo "  Already running."
else
    echo "  Starting Open WebUI on port 8080..."
    source "$VENV_DIR/bin/activate"

    export DATA_DIR="$DATA_DIR"
    export OLLAMA_BASE_URL="http://localhost:11434"
    export WEBUI_AUTH=true
    export ENABLE_API_KEY=true

    cd "$BASE_DIR"
    nohup open-webui serve > "$LOG_DIR/open-webui.log" 2>&1 &
    echo $! > "$PID_DIR/open-webui.pid"

    echo "  Waiting for startup..."
    for i in $(seq 1 60); do
        if curl -s http://localhost:8080/ > /dev/null 2>&1; then
            echo "  Started (PID $(cat $PID_DIR/open-webui.pid))"
            break
        fi
        sleep 2
        if [ $i -eq 60 ]; then
            echo "  WARNING: Startup taking long. Check $LOG_DIR/open-webui.log"
        fi
    done
fi

echo ""
echo "========================================="
echo "  All services started!"
echo "========================================="
echo ""
echo "  Ollama:    http://localhost:11434"
echo "  MCPO:      http://localhost:8300"
echo "  Open WebUI: http://localhost:8080"
echo ""
echo "  Logs:      $LOG_DIR/"
echo "  Data:      $DATA_DIR/"
echo "========================================="
