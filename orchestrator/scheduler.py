#!/usr/bin/env python3
"""
OPENAGENT Scheduler — Project queue with priority sorting.

Reads all project state files and outputs a priority-sorted queue
of projects ready for their next pipeline phase.

Priority rules:
1. User-submitted ideas first (source == "user_idea")
2. Lower phase numbers first (earlier in pipeline)
3. Fewer failures first
4. Oldest updated_at first (longest waiting)

Output: One line per project: "project_name|phase_number"
"""

import json
import os
import sys
from datetime import datetime
from pathlib import Path


def load_project_states(projects_dir: str) -> list[dict]:
    """Load all project state.json files."""
    states = []
    projects_path = Path(projects_dir)

    for state_file in projects_path.glob("*/state.json"):
        if state_file.parent.name == "_template":
            continue
        try:
            with open(state_file) as f:
                state = json.load(f)
            state["_dir"] = state_file.parent.name
            states.append(state)
        except (json.JSONDecodeError, IOError) as e:
            print(f"[scheduler] Error reading {state_file}: {e}", file=sys.stderr)

    return states


def priority_sort(states: list[dict]) -> list[dict]:
    """Sort projects by priority for processing."""
    def sort_key(state):
        # User ideas get priority (0) over research (1)
        source_priority = 0 if state.get("source") == "user_idea" else 1
        # Lower phase = earlier in pipeline = higher priority
        phase = state.get("phase", 1)
        # Fewer failures = higher priority
        fail_count = state.get("fail_count", 0)
        # Oldest first
        updated = state.get("updated_at", "2099-01-01T00:00:00Z")
        return (source_priority, phase, fail_count, updated)

    return sorted(states, key=sort_key)


def filter_actionable(states: list[dict]) -> list[dict]:
    """Filter to only projects that can be worked on."""
    actionable = []
    for state in states:
        status = state.get("status", "unknown")
        phase = state.get("phase", 0)

        # Skip non-active projects
        if status != "active":
            continue

        # Skip completed projects (12-phase pipeline)
        if phase > 12:
            continue

        actionable.append(state)

    return actionable


def main():
    if len(sys.argv) < 2:
        print("Usage: scheduler.py <projects_dir>", file=sys.stderr)
        sys.exit(1)

    projects_dir = sys.argv[1]

    if not os.path.isdir(projects_dir):
        print(f"[scheduler] Projects directory not found: {projects_dir}", file=sys.stderr)
        sys.exit(1)

    states = load_project_states(projects_dir)
    actionable = filter_actionable(states)
    sorted_projects = priority_sort(actionable)

    # Output priority queue (max 5)
    for state in sorted_projects[:5]:
        project_name = state.get("_dir", state.get("name", "unknown"))
        phase = state.get("phase", 1)
        print(f"{project_name}|{phase}")


if __name__ == "__main__":
    main()
