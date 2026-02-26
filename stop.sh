#!/bin/bash
# ============================================================
# Stop all services: Open WebUI + MCPO + Ollama
# ============================================================

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_DIR="$BASE_DIR/pids"

echo "========================================="
echo "  Stopping Open WebUI Stack"
echo "========================================="

# Stop Open WebUI
if [ -f "$PID_DIR/open-webui.pid" ]; then
    PID=$(cat "$PID_DIR/open-webui.pid")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping Open WebUI (PID $PID)..."
        kill "$PID"
        rm "$PID_DIR/open-webui.pid"
    fi
else
    # Find by process name
    pkill -f "open-webui serve" 2>/dev/null && echo "Stopped Open WebUI"
fi

# Stop MCPO
if [ -f "$PID_DIR/mcpo.pid" ]; then
    PID=$(cat "$PID_DIR/mcpo.pid")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping MCPO (PID $PID)..."
        kill "$PID"
        rm "$PID_DIR/mcpo.pid"
    fi
else
    pkill -f "mcpo --config" 2>/dev/null && echo "Stopped MCPO"
fi

# Stop Ollama (optional — only if we started it)
if [ -f "$PID_DIR/ollama.pid" ]; then
    PID=$(cat "$PID_DIR/ollama.pid")
    if kill -0 "$PID" 2>/dev/null; then
        echo "Stopping Ollama (PID $PID)..."
        kill "$PID"
        rm "$PID_DIR/ollama.pid"
    fi
else
    echo "Ollama: managed externally (not stopped)"
fi

echo ""
echo "All services stopped."
