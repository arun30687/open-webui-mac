# Open WebUI + MCP (Native macOS)

Run **Open WebUI** with **MCP tool integration** natively on macOS — no Docker required.

## Architecture

```
┌─────────────┐     ┌──────────┐     ┌────────────────┐
│  Open WebUI  │────▶│   MCPO   │────▶│  MCP Server    │
│  (port 8080) │     │ (port 8300)    │  (GitHub/EM/..) │
└──────┬───────┘     └──────────┘     └────────────────┘
       │
       ▼
┌─────────────┐
│   Ollama    │
│ (port 11434)│
└─────────────┘
```

- **Ollama** — LLM inference (runs natively with Apple Silicon GPU acceleration)
- **MCPO** — MCP-to-OpenAPI proxy (bridges MCP servers to HTTP)
- **Open WebUI** — Chat UI with pipe function for automated tool calling

## Quick Start

```bash
# 1. One-time setup (installs Python 3.11, Node.js, Ollama, pip packages)
./setup.sh

# 2. Configure MCP server
cp mcpo/config.json.example mcpo/config.json
# Edit mcpo/config.json — add your GitHub PAT (or EM credentials)

# 3. Start all services
./start.sh

# 4. Open browser → http://localhost:8080 → Create account

# 5. Register the pipe function (one-time)
./register-pipe.sh

# 6. Select "GitHub MCP Agent" model in the UI and start chatting!
```

## Stop Services

```bash
./stop.sh
```

## Sample Queries

| Query | Format |
|-------|--------|
| `What are the most popular Python repos?` | Bullet points (default) |
| `Show popular Docker repos in a table` | Markdown table |
| `Show Docker repos as a pie chart by language` | Mermaid pie chart |
| `Show top Python repos as a bar chart by stars` | Mermaid bar chart |

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | One-time install of all dependencies |
| `start.sh` | Start Ollama + MCPO + Open WebUI |
| `stop.sh` | Stop all services |
| `register-pipe.sh` | Register pipe function in Open WebUI |
| `github_pipe.py` | Pipe function — tool calling + formatting |
| `mcpo/config.json.example` | MCP server config template |

## Pipe Function (v0.4.0)

The pipe handles two paths:

- **Table/Chart requests** → Direct GitHub REST API call → Python formats the result → instant response (~1-2s)
- **General queries** → Ollama model + MCP tool calling loop → model generates response (~8-15s)

## Customization

### Change the LLM model

Edit `github_pipe.py` → `Valves` class:
```python
MODEL_ID: str = Field(default="qwen2.5:7b")   # or qwen2.5:3b for faster
NUM_CTX: int = Field(default=16384)            # increase for more tools
```

### Add a different MCP server

Edit `mcpo/config.json`:
```json
{
  "mcpServers": {
    "your-server": {
      "command": "/path/to/your-mcp-server",
      "args": ["--config", "config.json"],
      "env": { "API_KEY": "your-key" }
    }
  }
}
```

Then update `MCPO_BASE_URL` in the pipe's Valves to `http://localhost:8300/your-server`.

## Requirements

- macOS 12+ (Apple Silicon recommended)
- 8GB+ RAM (16GB+ recommended for 7b model)
- Python 3.11+
- Node.js 18+ (for MCP servers that use npx)
- Homebrew
