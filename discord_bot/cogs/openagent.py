"""
Fortress Command — OPENAGENT Cog
Monitors the app factory pipeline and provides commands for project management.
"""

import json
import asyncio
import logging
from pathlib import Path
from datetime import datetime, timezone

import discord
from discord.ext import commands, tasks

log = logging.getLogger("fortress.openagent")

PHASE_NAMES = {
    "01_research": "Research",
    "02_validation": "Validation",
    "03_build": "Build",
    "04_quality": "Quality",
    "05_monetization": "Monetization",
    "06_appstore_prep": "App Store Prep",
    "07_onboarding": "Onboarding",
    "08_screenshots": "Screenshots",
    "09_promo": "Promo",
}

PHASE_EMOJI = {
    "research": "\U0001f50d",
    "validation": "\u2705",
    "build": "\U0001f528",
    "quality": "\U0001f9ea",
    "monetization": "\U0001f4b0",
    "appstore_prep": "\U0001f4e6",
    "onboarding": "\U0001f680",
    "screenshots": "\U0001f4f8",
    "promo": "\U0001f4e3",
}

STATUS_COLORS = {
    "active": 0x00FF88,
    "completed": 0x00BFFF,
    "failed": 0xFF4444,
    "pending": 0xFFAA00,
}


class OpenAgentCog(commands.Cog, name="OPENAGENT"):
    """Monitor and control the OPENAGENT app factory."""

    def __init__(self, bot):
        self.bot = bot
        self.openagent_dir = Path(bot.openagent_dir)
        self.projects_dir = self.openagent_dir / "projects"
        self.ideas_dir = self.openagent_dir / "ideas"
        self._last_states = {}  # project -> state dict (for change detection)
        self._status_channel = None

    async def cog_load(self):
        self._snapshot_states()
        self.watch_pipeline.start()

    async def cog_unload(self):
        self.watch_pipeline.cancel()

    def _get_status_channel(self):
        """Find the #openagent-status channel."""
        for guild in self.bot.guilds:
            for ch in guild.text_channels:
                if ch.name == "openagent-status":
                    return ch
        return None

    def _read_state(self, project_dir: Path) -> dict:
        """Read a project's state.json."""
        state_file = project_dir / "state.json"
        if not state_file.exists():
            return {}
        try:
            return json.loads(state_file.read_text())
        except (json.JSONDecodeError, OSError):
            return {}

    def _snapshot_states(self):
        """Take a snapshot of all project states."""
        if not self.projects_dir.exists():
            return
        for proj in self.projects_dir.iterdir():
            if proj.is_dir():
                state = self._read_state(proj)
                if state:
                    self._last_states[proj.name] = state

    def _get_all_projects(self) -> list[tuple[str, dict]]:
        """Return list of (project_name, state_dict) for all projects."""
        projects = []
        if not self.projects_dir.exists():
            return projects
        for proj in sorted(self.projects_dir.iterdir()):
            if proj.is_dir():
                state = self._read_state(proj)
                projects.append((proj.name, state))
        return projects

    @tasks.loop(seconds=60)
    async def watch_pipeline(self):
        """Watch for phase changes and post updates to #openagent-status."""
        channel = self._get_status_channel()
        if not channel:
            return

        if not self.projects_dir.exists():
            return

        for proj in self.projects_dir.iterdir():
            if not proj.is_dir():
                continue

            state = self._read_state(proj)
            if not state:
                continue

            old_state = self._last_states.get(proj.name, {})
            old_phase = old_state.get("phase_name", "")
            new_phase = state.get("phase_name", "")
            old_status = old_state.get("status", "")
            new_status = state.get("status", "")

            # Detect phase change
            if new_phase and (new_phase != old_phase or new_status != old_status):
                emoji = PHASE_EMOJI.get(new_phase, "\U0001f504")
                color = STATUS_COLORS.get(new_status, 0x888888)

                embed = discord.Embed(
                    title=f"{emoji} {proj.name}",
                    description=f"Phase changed: **{old_phase or 'none'}** → **{new_phase}**",
                    color=color,
                    timestamp=datetime.now(timezone.utc),
                )
                embed.add_field(name="Status", value=new_status.upper(), inline=True)
                embed.add_field(name="Phase", value=new_phase, inline=True)

                if state.get("error"):
                    embed.add_field(
                        name="Error", value=state["error"][:200], inline=False
                    )

                try:
                    await channel.send(embed=embed)
                except discord.HTTPException as e:
                    log.error(f"Failed to post phase change: {e}")

            self._last_states[proj.name] = state

    @watch_pipeline.before_loop
    async def before_watch(self):
        await self.bot.wait_until_ready()

    @commands.command(name="status")
    async def status(self, ctx):
        """Show all OPENAGENT project phases and status."""
        projects = self._get_all_projects()

        if not projects:
            await ctx.send("No projects found in the pipeline.")
            return

        embed = discord.Embed(
            title="OPENAGENT Pipeline Status",
            color=0x00FF88,
            timestamp=datetime.now(timezone.utc),
        )

        active = []
        completed = []
        failed = []

        for name, state in projects:
            phase = state.get("phase_name", "unknown")
            status = state.get("status", "unknown")
            emoji = PHASE_EMOJI.get(phase, "\u2753")
            line = f"{emoji} **{name}** — {phase} ({status})"

            if status == "completed":
                completed.append(line)
            elif status == "failed":
                failed.append(line)
            else:
                active.append(line)

        if active:
            embed.add_field(
                name=f"Active ({len(active)})",
                value="\n".join(active[:10]) or "None",
                inline=False,
            )
        if completed:
            embed.add_field(
                name=f"Completed ({len(completed)})",
                value="\n".join(completed[:10]) or "None",
                inline=False,
            )
        if failed:
            embed.add_field(
                name=f"Failed ({len(failed)})",
                value="\n".join(failed[:5]) or "None",
                inline=False,
            )

        embed.set_footer(text=f"Total: {len(projects)} projects")
        await ctx.send(embed=embed)

    @commands.command(name="phase")
    async def phase(self, ctx, project: str = None):
        """Show detailed phase info for a project. Usage: !phase <project>"""
        if not project:
            await ctx.send("Usage: `!phase <project_name>`")
            return

        proj_dir = self.projects_dir / project
        if not proj_dir.exists():
            # Try fuzzy match
            matches = [
                p.name
                for p in self.projects_dir.iterdir()
                if p.is_dir() and project.lower() in p.name.lower()
            ]
            if matches:
                proj_dir = self.projects_dir / matches[0]
                project = matches[0]
            else:
                await ctx.send(f"Project `{project}` not found.")
                return

        state = self._read_state(proj_dir)
        if not state:
            await ctx.send(f"No state.json found for `{project}`.")
            return

        phase = state.get("phase_name", "unknown")
        status = state.get("status", "unknown")
        emoji = PHASE_EMOJI.get(phase, "\u2753")
        color = STATUS_COLORS.get(status, 0x888888)

        embed = discord.Embed(
            title=f"{emoji} {project}",
            color=color,
            timestamp=datetime.now(timezone.utc),
        )
        embed.add_field(name="Phase", value=phase, inline=True)
        embed.add_field(name="Status", value=status.upper(), inline=True)

        if state.get("app_name"):
            embed.add_field(name="App Name", value=state["app_name"], inline=True)
        if state.get("category"):
            embed.add_field(name="Category", value=state["category"], inline=True)
        if state.get("error"):
            embed.add_field(
                name="Last Error", value=state["error"][:500], inline=False
            )
        if state.get("updated_at"):
            embed.add_field(name="Last Updated", value=state["updated_at"], inline=True)

        # Show phase history if available
        history = state.get("phase_history", [])
        if history:
            hist_text = "\n".join(
                f"- {h.get('phase', '?')} ({h.get('status', '?')})"
                for h in history[-5:]
            )
            embed.add_field(
                name="Recent History", value=hist_text[:500], inline=False
            )

        await ctx.send(embed=embed)

    @commands.command(name="idea")
    async def idea(self, ctx, *, description: str = None):
        """Submit an app idea to the pipeline. Usage: !idea "description" """
        if not description:
            await ctx.send('Usage: `!idea "Your app idea description here"`')
            return

        # Create ideas directory if needed
        self.ideas_dir.mkdir(parents=True, exist_ok=True)

        # Generate filename
        ts = datetime.now().strftime("%Y%m%d_%H%M%S")
        safe_name = "".join(c if c.isalnum() or c in "-_ " else "" for c in description[:30])
        safe_name = safe_name.strip().replace(" ", "_").lower()
        filename = f"{ts}_{safe_name}.md"

        idea_path = self.ideas_dir / filename
        idea_content = f"""# App Idea
**Submitted by:** {ctx.author.name} via Discord
**Date:** {datetime.now().strftime("%Y-%m-%d %H:%M:%S")}

## Description
{description}

## Source
Discord bot submission
"""
        idea_path.write_text(idea_content)
        log.info(f"New idea submitted: {filename}")

        embed = discord.Embed(
            title="\U0001f4a1 Idea Submitted",
            description=description[:500],
            color=0xFFAA00,
        )
        embed.add_field(name="File", value=filename, inline=False)
        embed.set_footer(
            text="The research agent will pick this up on its next run."
        )
        await ctx.send(embed=embed)

    @commands.command(name="build")
    async def build(self, ctx, project: str = None):
        """Force-trigger build phase for a project. Usage: !build <project>"""
        if not project:
            await ctx.send("Usage: `!build <project_name>`")
            return

        proj_dir = self.projects_dir / project
        if not proj_dir.exists():
            matches = [
                p.name
                for p in self.projects_dir.iterdir()
                if p.is_dir() and project.lower() in p.name.lower()
            ]
            if matches:
                proj_dir = self.projects_dir / matches[0]
                project = matches[0]
            else:
                await ctx.send(f"Project `{project}` not found.")
                return

        state_file = proj_dir / "state.json"
        state = self._read_state(proj_dir)

        # Update state to trigger build
        state["phase_name"] = "build"
        state["status"] = "pending"
        state["updated_at"] = datetime.now(timezone.utc).isoformat()
        state["triggered_by"] = f"discord:{ctx.author.name}"

        try:
            state_file.write_text(json.dumps(state, indent=2))
            embed = discord.Embed(
                title="\U0001f528 Build Triggered",
                description=f"Project **{project}** set to build phase.",
                color=0x00FF88,
            )
            embed.set_footer(
                text="The orchestrator will start the build on its next cycle."
            )
            await ctx.send(embed=embed)
        except OSError as e:
            await ctx.send(f"Failed to trigger build: {e}")

    @commands.command(name="costs")
    async def costs(self, ctx):
        """Show estimated API spending."""
        cost_log = self.openagent_dir / "logs" / "cost_tracker.jsonl"

        if not cost_log.exists():
            # Estimate from project count
            projects = self._get_all_projects()
            embed = discord.Embed(
                title="\U0001f4b0 API Cost Estimate",
                color=0xFFAA00,
            )
            embed.add_field(
                name="Projects",
                value=str(len(projects)),
                inline=True,
            )
            embed.add_field(
                name="Estimated Cost",
                value=f"~${len(projects) * 1.5:.2f} (standard)\n~${len(projects) * 12:.2f} (premium)",
                inline=True,
            )
            embed.set_footer(
                text="No cost_tracker.jsonl found — showing estimates based on model routing tiers."
            )
            await ctx.send(embed=embed)
            return

        # Parse cost log
        total = 0.0
        today_total = 0.0
        today = datetime.now().strftime("%Y-%m-%d")
        entries = []

        try:
            with open(cost_log) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    entry = json.loads(line)
                    cost = entry.get("cost_usd", 0)
                    total += cost
                    if entry.get("timestamp", "").startswith(today):
                        today_total += cost
                    entries.append(entry)
        except (json.JSONDecodeError, OSError):
            pass

        embed = discord.Embed(
            title="\U0001f4b0 API Spending",
            color=0x00FF88,
        )
        embed.add_field(name="Today", value=f"${today_total:.4f}", inline=True)
        embed.add_field(name="All Time", value=f"${total:.4f}", inline=True)
        embed.add_field(name="Log Entries", value=str(len(entries)), inline=True)
        await ctx.send(embed=embed)


async def setup(bot):
    await bot.add_cog(OpenAgentCog(bot))
