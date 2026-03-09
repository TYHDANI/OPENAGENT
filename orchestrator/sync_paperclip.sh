#!/bin/bash
# OPENAGENT → Paperclip Dashboard Sync
# Reads project state from VPS, pushes agents/projects/tasks to local Paperclip
# Usage: bash ~/OPENAGENT/orchestrator/sync_paperclip.sh

set -euo pipefail

PAPERCLIP_URL="http://localhost:3100/api"
VPS="deploy@46.225.233.219"
COMPANY_ID="1c38f787-8d1f-461e-a243-3f038adf4ead"

echo "[sync_paperclip] Fetching OPENAGENT state from VPS..."

# Pull all project states from VPS
STATE_JSON=$(ssh "$VPS" 'cd ~/OPENAGENT && python3 -c "
import json, glob, os
projects = []
for sf in sorted(glob.glob(\"projects/*/state.json\")):
    with open(sf) as f:
        state = json.load(f)
    name = state.get(\"name\", os.path.basename(os.path.dirname(sf)))
    if not name or state.get(\"status\") == \"template\" or state.get(\"status\") == \"scrapped\":
        continue
    projects.append({
        \"name\": name,
        \"phase\": state.get(\"phase\", 1),
        \"phase_name\": state.get(\"phase_name\", \"research\"),
        \"status\": state.get(\"status\", \"active\"),
        \"fail_count\": state.get(\"fail_count\", 0),
        \"created_at\": state.get(\"created_at\", \"\"),
        \"updated_at\": state.get(\"updated_at\", \"\")
    })
print(json.dumps(projects))
"')

echo "[sync_paperclip] Got $(echo "$STATE_JSON" | python3 -c "import sys,json; print(len(json.load(sys.stdin)))") projects"

# Run the sync via Python
python3 << PYEOF
import json, urllib.request, urllib.parse, sys, time

PAPERCLIP = "$PAPERCLIP_URL"
COMPANY = "$COMPANY_ID"
projects = json.loads('''$STATE_JSON''')

PHASE_NAMES = {
    1: "Research", 2: "Validation", 3: "Build", 4: "Code Review",
    5: "Quality", 6: "Monetization", 7: "App Store Prep", 8: "Onboarding",
    9: "Screenshots", 10: "Promo", 11: "Launch", 12: "Growth"
}

PHASE_AGENTS = {
    "research": "researcher", "validation": "researcher",
    "build": "engineer", "code_review": "qa",
    "quality": "qa", "monetization": "engineer",
    "appstore_prep": "pm", "onboarding": "designer",
    "screenshots": "designer", "promo": "cmo",
    "launch": "cmo", "growth": "researcher"
}

def api(method, path, data=None):
    url = f"{PAPERCLIP}{path}"
    body = json.dumps(data).encode() if data else None
    req = urllib.request.Request(url, data=body, method=method,
        headers={"Content-Type": "application/json"} if body else {})
    try:
        with urllib.request.urlopen(req) as resp:
            return json.loads(resp.read())
    except urllib.error.HTTPError as e:
        err = e.read().decode()
        print(f"  API {method} {path}: {e.code} {err[:200]}")
        return None
    except Exception as e:
        print(f"  API error: {e}")
        return None

# Step 1: Get existing agents and projects
existing_agents = api("GET", f"/companies/{COMPANY}/agents") or []
existing_projects = api("GET", f"/companies/{COMPANY}/projects") or []
existing_issues = api("GET", f"/companies/{COMPANY}/issues?limit=200") or []

agent_map = {a["name"]: a["id"] for a in existing_agents}
project_map = {p["name"]: p["id"] for p in existing_projects}
issue_map = {i["title"]: i["id"] for i in existing_issues}

print(f"[sync] Existing: {len(agent_map)} agents, {len(project_map)} projects, {len(issue_map)} issues")

# Step 2: Create phase agents (one per pipeline role)
AGENTS_TO_CREATE = [
    {"name": "Research Bot", "role": "researcher", "desc": "Deep research, market analysis, competitor scraping (Phases 1-2)"},
    {"name": "Build Bot", "role": "engineer", "desc": "Swift/SwiftUI code generation, Xcode builds (Phase 3)"},
    {"name": "Review Bot", "role": "qa", "desc": "Code review, security audit, quality gates (Phases 4-5)"},
    {"name": "Monetization Bot", "role": "engineer", "desc": "StoreKit 2 integration, pricing, paywall (Phase 6)"},
    {"name": "Design Bot", "role": "designer", "desc": "Onboarding flows, screenshots, UI polish (Phases 7-9)"},
    {"name": "Marketing Bot", "role": "cmo", "desc": "ASO, social media, promo, launch, growth (Phases 10-12)"},
]

for agent_def in AGENTS_TO_CREATE:
    if agent_def["name"] in agent_map:
        continue
    result = api("POST", f"/companies/{COMPANY}/agents", {
        "name": agent_def["name"],
        "role": agent_def["role"],
        "adapterType": "process",
        "status": "active",
        "metadata": {"description": agent_def["desc"], "source": "openagent"},
        "budgetMonthlyCents": 5000,
    })
    if result:
        agent_map[agent_def["name"]] = result["id"]
        print(f"  Created agent: {agent_def['name']}")

# Map phases to agent names
def get_agent_for_phase(phase):
    if phase <= 2: return "Research Bot"
    if phase == 3: return "Build Bot"
    if phase <= 5: return "Review Bot"
    if phase == 6: return "Monetization Bot"
    if phase <= 9: return "Design Bot"
    return "Marketing Bot"

# Step 3: Create projects for each OPENAGENT app
COLORS = ["#E74C3C", "#3498DB", "#2ECC71", "#F39C12", "#9B59B6",
          "#1ABC9C", "#E67E22", "#34495E", "#16A085", "#C0392B",
          "#2980B9", "#27AE60", "#D35400", "#8E44AD", "#2C3E50",
          "#F1C40F", "#7F8C8D", "#00BCD4", "#FF5722", "#795548"]

for i, proj in enumerate(projects):
    name = proj["name"]
    if name not in project_map:
        phase_agent = get_agent_for_phase(proj["phase"])
        lead_id = agent_map.get(phase_agent)
        result = api("POST", f"/companies/{COMPANY}/projects", {
            "name": name,
            "description": f"iOS app — Phase {proj['phase']}/12 ({proj['phase_name']})",
            "status": "in_progress" if proj["status"] == "active" else "planned",
            "leadAgentId": lead_id,
            "color": COLORS[i % len(COLORS)],
        })
        if result:
            project_map[name] = result["id"]
            print(f"  Created project: {name}")

# Step 4: Create/update issues (tasks) for each project's current phase
for proj in projects:
    name = proj["name"]
    phase = proj["phase"]
    phase_name = PHASE_NAMES.get(phase, f"Phase {phase}")
    project_id = project_map.get(name)
    if not project_id:
        continue

    # Current phase task
    title = f"{name}: {phase_name}"
    agent_name = get_agent_for_phase(phase)
    agent_id = agent_map.get(agent_name)

    status_map = {
        "active": "in_progress",
        "paused": "blocked",
        "shipped": "done",
    }
    task_status = status_map.get(proj["status"], "todo")

    if title in issue_map:
        # Update existing
        api("PATCH", f"/issues/{issue_map[title]}", {
            "status": task_status,
            "assigneeAgentId": agent_id,
        })
    else:
        # Create new
        result = api("POST", f"/companies/{COMPANY}/issues", {
            "title": title,
            "description": f"Pipeline phase {phase}/12 for {name}.\nPhase: {phase_name}\nStatus: {proj['status']}\nFail count: {proj['fail_count']}\nLast updated: {proj['updated_at']}",
            "status": task_status,
            "priority": "high" if phase >= 3 else "medium",
            "projectId": project_id,
            "assigneeAgentId": agent_id,
        })
        if result:
            issue_map[title] = result["id"]
            print(f"  Created task: {title}")

    # Also create completed tasks for previous phases
    for prev_phase in range(1, phase):
        prev_name = PHASE_NAMES.get(prev_phase, f"Phase {prev_phase}")
        prev_title = f"{name}: {prev_name}"
        if prev_title not in issue_map:
            prev_agent = get_agent_for_phase(prev_phase)
            result = api("POST", f"/companies/{COMPANY}/issues", {
                "title": prev_title,
                "description": f"Completed phase {prev_phase}/12 for {name}",
                "status": "done",
                "priority": "medium",
                "projectId": project_id,
                "assigneeAgentId": agent_map.get(prev_agent),
            })
            if result:
                issue_map[prev_title] = result["id"]

print(f"\n[sync_paperclip] Done! {len(agent_map)} agents, {len(project_map)} projects, {len(issue_map)} tasks")
print("[sync_paperclip] Open http://localhost:3100 to see the dashboard")
PYEOF
