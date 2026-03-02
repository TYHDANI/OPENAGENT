#!/usr/bin/env python3
"""
OPENAGENT Dashboard — FastAPI backend
Serves project status, costs, and logs for the monitoring dashboard.

Usage:
    pip install fastapi uvicorn
    cd /Users/beachbar/OPENAGENT
    python dashboard/server.py

Then open http://localhost:8420
"""

import json
import os
from datetime import datetime, timezone
from pathlib import Path

try:
    from fastapi import FastAPI
    from fastapi.responses import HTMLResponse, JSONResponse
    from fastapi.staticfiles import StaticFiles
    import uvicorn
except ImportError:
    print("Install dependencies: pip install fastapi uvicorn")
    raise

ROOT_DIR = Path(__file__).parent.parent
PROJECTS_DIR = ROOT_DIR / "projects"
LOGS_DIR = ROOT_DIR / "logs"
DASHBOARD_DIR = ROOT_DIR / "dashboard"

app = FastAPI(title="OPENAGENT Dashboard", version="1.0.0")


def read_jsonl(filepath: Path, limit: int = 100) -> list[dict]:
    """Read last N entries from a JSONL file."""
    entries = []
    if not filepath.exists():
        return entries
    try:
        with open(filepath) as f:
            for line in f:
                line = line.strip()
                if line:
                    try:
                        obj = json.loads(line)
                        if "_schema" in obj:
                            continue  # skip schema lines
                        entries.append(obj)
                    except json.JSONDecodeError:
                        continue
    except IOError:
        pass
    return entries[-limit:]


def load_project_states() -> list[dict]:
    """Load all project state.json files."""
    states = []
    for state_file in PROJECTS_DIR.glob("*/state.json"):
        if state_file.parent.name == "_template":
            continue
        try:
            with open(state_file) as f:
                state = json.load(f)
            state["_project_dir"] = state_file.parent.name
            states.append(state)
        except (json.JSONDecodeError, IOError):
            continue
    return sorted(states, key=lambda s: s.get("updated_at", ""), reverse=True)


@app.get("/", response_class=HTMLResponse)
async def dashboard():
    """Serve the dashboard HTML."""
    index_path = DASHBOARD_DIR / "index.html"
    if index_path.exists():
        return HTMLResponse(content=index_path.read_text())
    return HTMLResponse(content="<h1>Dashboard not found</h1>", status_code=404)


@app.get("/api/projects")
async def get_projects():
    """Get all project states."""
    return JSONResponse(content=load_project_states())


@app.get("/api/projects/{project_name}")
async def get_project(project_name: str):
    """Get a specific project state."""
    state_file = PROJECTS_DIR / project_name / "state.json"
    if not state_file.exists():
        return JSONResponse(content={"error": "Project not found"}, status_code=404)
    with open(state_file) as f:
        return JSONResponse(content=json.load(f))


@app.get("/api/logs/decisions")
async def get_decisions(limit: int = 50):
    """Get recent decisions."""
    return JSONResponse(content=read_jsonl(LOGS_DIR / "decisions.jsonl", limit))


@app.get("/api/logs/costs")
async def get_costs(limit: int = 100):
    """Get recent cost entries."""
    return JSONResponse(content=read_jsonl(LOGS_DIR / "costs.jsonl", limit))


@app.get("/api/logs/failures")
async def get_failures(limit: int = 50):
    """Get recent failures."""
    return JSONResponse(content=read_jsonl(LOGS_DIR / "failures.jsonl", limit))


@app.get("/api/summary")
async def get_summary():
    """Get overall system summary."""
    projects = load_project_states()
    costs = read_jsonl(LOGS_DIR / "costs.jsonl", 10000)

    # Calculate totals
    total_cost = sum(c.get("cost_usd", 0) for c in costs)
    today = datetime.now(timezone.utc).strftime("%Y-%m-%d")
    today_cost = sum(
        c.get("cost_usd", 0) for c in costs
        if c.get("timestamp", "").startswith(today)
    )

    active = sum(1 for p in projects if p.get("status") == "active")
    paused = sum(1 for p in projects if p.get("status") == "paused")
    shipped = sum(1 for p in projects if p.get("status") == "shipped")
    failed = sum(1 for p in projects if p.get("status") == "failed")

    return JSONResponse(content={
        "total_projects": len(projects),
        "active": active,
        "paused": paused,
        "shipped": shipped,
        "failed": failed,
        "total_cost_usd": round(total_cost, 2),
        "today_cost_usd": round(today_cost, 2),
        "daily_limit_usd": 50.00,
        "updated_at": datetime.now(timezone.utc).isoformat(),
    })


if __name__ == "__main__":
    uvicorn.run(app, host="0.0.0.0", port=8420)
