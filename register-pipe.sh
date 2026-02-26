#!/bin/bash
# ============================================================
# Register the pipe function in Open WebUI
# Run this ONCE after first startup + account creation
# ============================================================
set -e

BASE_DIR="$(cd "$(dirname "$0")" && pwd)"
OPEN_WEBUI_URL="${1:-http://localhost:8080}"

echo "========================================="
echo "  Register Pipe Function"
echo "========================================="
echo ""

# Step 1: Check if Open WebUI is running
if ! curl -s "$OPEN_WEBUI_URL" > /dev/null 2>&1; then
    echo "ERROR: Open WebUI not running at $OPEN_WEBUI_URL"
    echo "Run ./start.sh first"
    exit 1
fi

# Step 2: Get credentials
if [ -f "$BASE_DIR/.token" ]; then
    TOKEN=$(cat "$BASE_DIR/.token")
    echo "Using saved token."
else
    echo "No saved token found. Creating admin account..."
    echo ""
    read -p "  Admin email: " EMAIL
    read -s -p "  Admin password: " PASSWORD
    echo ""

    RESP=$(curl -s -X POST "$OPEN_WEBUI_URL/api/v1/auths/signup" \
        -H "Content-Type: application/json" \
        -d "{\"name\": \"Admin\", \"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")

    TOKEN=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)

    if [ -z "$TOKEN" ]; then
        echo "Signup failed. Trying login..."
        RESP=$(curl -s -X POST "$OPEN_WEBUI_URL/api/v1/auths/signin" \
            -H "Content-Type: application/json" \
            -d "{\"email\": \"$EMAIL\", \"password\": \"$PASSWORD\"}")
        TOKEN=$(echo "$RESP" | python3 -c "import json,sys; print(json.load(sys.stdin).get('token',''))" 2>/dev/null)
    fi

    if [ -z "$TOKEN" ]; then
        echo "ERROR: Could not authenticate. Response: $RESP"
        exit 1
    fi

    echo "$TOKEN" > "$BASE_DIR/.token"
    echo "  Authenticated and token saved."
fi

HEADERS="-H \"Authorization: Bearer $TOKEN\" -H \"Content-Type: application/json\""

# Step 3: Read pipe file
PIPE_FILE="$BASE_DIR/github_pipe.py"
if [ ! -f "$PIPE_FILE" ]; then
    echo "ERROR: Pipe file not found at $PIPE_FILE"
    exit 1
fi

# Step 4: Create or update the pipe
echo ""
echo "Registering pipe function..."

python3 << PYEOF
import requests, json

token = open("$BASE_DIR/.token").read().strip()
code = open("$PIPE_FILE").read()
headers = {"Authorization": f"Bearer {token}", "Content-Type": "application/json"}
base = "$OPEN_WEBUI_URL"

# Try create first
resp = requests.post(f"{base}/api/v1/functions/create", headers=headers, json={
    "id": "github_mcp_agent",
    "name": "GitHub MCP Agent",
    "type": "pipe",
    "content": code,
    "meta": {"description": "v0.4.0 — Direct GitHub API for table/chart, model+MCP for general queries"}
})

if resp.status_code == 200:
    print(f"  Created: {resp.json()['name']}")
elif "already exists" in resp.text.lower() or resp.status_code == 400:
    # Update existing
    resp = requests.post(f"{base}/api/v1/functions/id/github_mcp_agent/update", headers=headers, json={
        "id": "github_mcp_agent",
        "name": "GitHub MCP Agent",
        "type": "pipe",
        "content": code,
        "meta": {"description": "v0.4.0 — Direct GitHub API for table/chart, model+MCP for general queries"}
    })
    print(f"  Updated: {resp.status_code}")
else:
    print(f"  Error: {resp.status_code} {resp.text[:200]}")

# Activate
resp = requests.post(f"{base}/api/v1/functions/id/github_mcp_agent/toggle", headers=headers)
print(f"  Active: {resp.json().get('is_active')}")

# Set valves (GITHUB_TOKEN from mcpo config)
try:
    mcpo_cfg = json.load(open("$BASE_DIR/mcpo/config.json"))
    gh_token = mcpo_cfg["mcpServers"]["github"]["env"]["GITHUB_PERSONAL_ACCESS_TOKEN"]
    resp = requests.post(f"{base}/api/v1/functions/id/github_mcp_agent/valves/update",
        headers=headers, json={"GITHUB_TOKEN": gh_token})
    print(f"  Valves set: GITHUB_TOKEN (length={len(gh_token)})")
except Exception as e:
    print(f"  Warning: Could not set valves: {e}")
    print(f"  Set GITHUB_TOKEN manually in Open WebUI > Functions > GitHub MCP Agent > Valves")
PYEOF

echo ""
echo "Done! Open http://localhost:8080 and select 'GitHub MCP Agent' model."
echo ""
