"""
Fortress Command — Claude Cog
Natural language Claude integration — chat freely like Claude Code.
Monitors OPENAGENT pipeline and NFTS trading bots.
"""

import asyncio
import json
import logging
from pathlib import Path
from datetime import datetime, timezone

import discord
from discord.ext import commands

log = logging.getLogger("fortress.claude")

MAX_DISCORD_MSG = 1900


class ClaudeCog(commands.Cog, name="Claude"):
    """Natural language Claude — chat freely in any channel."""

    def __init__(self, bot):
        self.bot = bot
        self.openagent_dir = Path(bot.openagent_dir)
        self.nfts_dir = Path(bot.nfts_dir)
        self._running_tasks = {}

    def _build_system_context(self, channel_name: str) -> str:
        """Build system context based on channel and current state."""

        # Read pipeline state
        pipeline_summary = self._get_pipeline_summary()
        trading_summary = self._get_trading_summary()

        return f"""You are the Fortress Command AI assistant in a Discord server.
You help the user manage two systems:

1. **OPENAGENT** — Autonomous iOS app factory that researches, builds, and ships apps.
   Current pipeline status:
{pipeline_summary}

2. **Fortress Capital (NFTS)** — AI trading bot platform with multiple strategies.
   Current trading status:
{trading_summary}

You are chatting in the #{channel_name} channel.

Rules:
- Be concise — Discord has a 2000 char limit per message.
- Use markdown formatting (bold, code blocks, bullet points).
- If the user asks about app progress, read the state files for real data.
- If asked to do something (submit idea, trigger build, etc.), take action.
- Be proactive — if you notice issues, mention them.
- Keep a conversational tone, like texting a friend who's also a tech expert.
- NEVER say "I can't do that" — instead explain what you CAN do.
- Handle ALL types of questions — simple or complex, technical or casual.
- For in-depth questions, give thorough answers. Don't tell the user to simplify their question.
- You can discuss strategy, architecture, debugging, business planning, or anything else.
- Working directories: OPENAGENT={self.openagent_dir}, NFTS={self.nfts_dir}
"""

    def _get_pipeline_summary(self) -> str:
        """Read all project states for context."""
        try:
            projects_dir = self.openagent_dir / "projects"
            lines = []
            for state_file in sorted(projects_dir.glob("*/state.json")):
                try:
                    state = json.loads(state_file.read_text())
                    name = state.get("name", state_file.parent.name)
                    if not name:
                        continue
                    status = state.get("status", "unknown")
                    phase = state.get("phase", 0)
                    phase_name = state.get("phase_name", "unknown")
                    fails = state.get("fail_count", 0)
                    lines.append(f"   - {name}: {status} (phase {phase}: {phase_name}, fails: {fails})")
                except Exception:
                    continue
            return "\n".join(lines) if lines else "   No projects found."
        except Exception as e:
            return f"   Error reading pipeline: {e}"

    def _get_trading_summary(self) -> str:
        """Read trading bot status for context."""
        try:
            trade_log = self.nfts_dir / "packages" / "engine" / "trade_log.jsonl"
            if not trade_log.exists():
                return "   No trade log found. Trading engine may not be running."

            lines = trade_log.read_text().strip().split("\n")
            recent = lines[-5:] if len(lines) >= 5 else lines
            trades = []
            for line in recent:
                try:
                    t = json.loads(line)
                    trades.append(f"   - {t.get('symbol', '?')} {t.get('side', '?')} @ {t.get('price', '?')}")
                except Exception:
                    continue
            return "\n".join(trades) if trades else "   No recent trades."
        except Exception:
            return "   Trading data unavailable."

    @commands.Cog.listener()
    async def on_message(self, message):
        """Handle all messages as natural language — no commands needed."""
        # Ignore bot's own messages
        if message.author == self.bot.user:
            return

        # Ignore if message starts with ! (let command handler deal with it)
        if message.content.startswith("!"):
            return

        # Ignore messages in channels we don't monitor
        # Respond in: commands, openagent-status, nfts-trading, or DMs
        allowed_channels = {"commands", "openagent-status", "nfts-trading"}
        is_dm = isinstance(message.channel, discord.DMChannel)
        is_allowed = is_dm or (hasattr(message.channel, "name") and message.channel.name in allowed_channels)

        # Also respond if bot is mentioned
        is_mentioned = self.bot.user.mentioned_in(message)

        if not is_allowed and not is_mentioned:
            return

        # Don't respond to very short messages or just emojis
        text = message.content.strip()
        if len(text) < 3:
            return

        # Remove bot mention from text if present
        if is_mentioned:
            text = text.replace(f"<@{self.bot.user.id}>", "").strip()
            text = text.replace(f"<@!{self.bot.user.id}>", "").strip()

        if not text:
            return

        channel_name = "DM" if is_dm else message.channel.name
        log.info(f"Message from {message.author} in #{channel_name}: {text[:80]}...")

        # Show typing indicator
        async with message.channel.typing():
            response = await self._ask_claude(text, channel_name)

        log.info(f"Claude response ({len(response)} chars) for {message.author}")

        # Send response
        if len(response) <= MAX_DISCORD_MSG:
            await message.reply(response, mention_author=False)
        else:
            # Split into chunks
            chunks = self._split_response(response)
            for i, chunk in enumerate(chunks[:5]):
                if i == 0:
                    await message.reply(chunk, mention_author=False)
                else:
                    await message.channel.send(chunk)
                await asyncio.sleep(0.3)

    async def _ask_claude(self, question: str, channel_name: str) -> str:
        """Send question to Claude CLI and return response."""
        import time as _time
        t0 = _time.time()
        system_context = self._build_system_context(channel_name)

        # Determine working directory
        question_lower = question.lower()
        if any(kw in question_lower for kw in [
            "trade", "trading", "bot", "strategy", "pnl",
            "fortress", "nfts", "position", "portfolio"
        ]):
            work_dir = str(self.nfts_dir)
        else:
            work_dir = str(self.openagent_dir)

        # Validate working directory exists — fall back to home if not
        if not Path(work_dir).is_dir():
            log.warning(f"Work dir {work_dir} does not exist, falling back to OPENAGENT dir")
            work_dir = str(self.openagent_dir)
        if not Path(work_dir).is_dir():
            work_dir = str(Path.home())

        full_prompt = f"{system_context}\n\nUser message: {question}"

        try:
            # Load env vars for Claude auth
            import os as _os
            env = {**_os.environ}
            env_file = Path.home() / ".env.openagent"
            if env_file.exists():
                for line in env_file.read_text().splitlines():
                    line = line.strip()
                    if line and not line.startswith("#") and "=" in line:
                        k, v = line.split("=", 1)
                        env[k.strip()] = v.strip()

            proc = await asyncio.create_subprocess_exec(
                "/usr/bin/claude",
                "--print",
                "--dangerously-skip-permissions",
                "--model", "sonnet",
                "-p", full_prompt,
                stdin=asyncio.subprocess.DEVNULL,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_dir,
                env=env,
            )

            stdout, stderr = await asyncio.wait_for(
                proc.communicate(), timeout=300
            )

            response = stdout.decode("utf-8", errors="replace").strip()

            if not response:
                error_text = stderr.decode("utf-8", errors="replace").strip()
                if "Credit balance" in error_text:
                    response = "Claude API needs auth refresh. The OAuth token may have expired."
                elif error_text:
                    response = f"Claude returned no response. Error: {error_text[:300]}"
                else:
                    response = "Claude returned an empty response. Try rephrasing your question."

        except asyncio.TimeoutError:
            elapsed = _time.time() - t0
            log.error(f"Claude timeout after {elapsed:.0f}s")
            response = "Claude took too long (>5 min). The question may be too complex for a single query — try breaking it into parts."
        except FileNotFoundError as e:
            log.error(f"FileNotFoundError: {e}")
            response = f"Claude CLI error: {e}. Check that /usr/bin/claude exists."
        except Exception as e:
            log.error(f"Claude error: {e}")
            response = f"Error: {e}"

        elapsed = _time.time() - t0
        log.info(f"Claude call completed in {elapsed:.1f}s ({len(response)} chars)")
        return response

    def _split_response(self, response: str) -> list:
        """Split a long response into Discord-friendly chunks."""
        chunks = []
        while response:
            if len(response) <= MAX_DISCORD_MSG:
                chunks.append(response)
                break
            split_at = response.rfind("\n", 0, MAX_DISCORD_MSG)
            if split_at < MAX_DISCORD_MSG // 2:
                split_at = MAX_DISCORD_MSG
            chunks.append(response[:split_at])
            response = response[split_at:].lstrip("\n")
        return chunks

    # Keep the !ask command as fallback
    @commands.command(name="ask")
    async def ask(self, ctx, *, question: str = None):
        """Ask Claude anything. Usage: !ask <question>"""
        if not question:
            await ctx.send("Just type your question — no need for `!ask`. I respond to all messages in this channel.")
            return

        async with ctx.typing():
            channel_name = ctx.channel.name if hasattr(ctx.channel, "name") else "DM"
            response = await self._ask_claude(question, channel_name)

        if len(response) <= MAX_DISCORD_MSG:
            await ctx.reply(response, mention_author=False)
        else:
            chunks = self._split_response(response)
            for i, chunk in enumerate(chunks[:5]):
                if i == 0:
                    await ctx.reply(chunk, mention_author=False)
                else:
                    await ctx.send(chunk)
                await asyncio.sleep(0.3)

    @commands.command(name="logs")
    async def logs(self, ctx, target: str = None, lines: int = 20):
        """View recent logs. Usage: !logs <project|bot|system> [lines]"""
        if not target:
            await ctx.send(
                "Usage: `!logs <target> [lines]`\n"
                "Targets: `system`, `orchestrator`, `discord`, or any project/bot name"
            )
            return

        lines = min(lines, 50)
        log_path = None
        log_desc = target

        if target in ("system", "orchestrator", "cron"):
            log_path = self.openagent_dir / "logs" / "orchestrator_run.log"
            log_desc = "Orchestrator"
        elif target == "discord":
            log_path = self.openagent_dir / "logs" / "discord_bot.log"
            log_desc = "Discord Bot"
        else:
            proj_log = self.openagent_dir / "logs" / f"agent_03_build_{target}.log"
            if proj_log.exists():
                log_path = proj_log
                log_desc = f"Build: {target}"
            else:
                proj_dir = self.openagent_dir / "projects" / target
                if proj_dir.exists():
                    log_path = proj_dir / "build_log.txt"
                    log_desc = f"Project: {target}"

        if not log_path or not log_path.exists():
            await ctx.send(f"No log file found for `{target}`.")
            return

        try:
            all_lines = log_path.read_text().strip().split("\n")
            tail = all_lines[-lines:]
            content = "\n".join(tail)
        except OSError as e:
            await ctx.send(f"Failed to read log: {e}")
            return

        embed = discord.Embed(
            title=f"Logs: {log_desc}",
            color=0x888888,
            timestamp=datetime.now(timezone.utc),
        )
        embed.set_footer(text=f"Last {len(tail)} lines from {log_path.name}")
        await ctx.send(embed=embed)

        if len(content) <= MAX_DISCORD_MSG - 10:
            await ctx.send(f"```\n{content}\n```")
        else:
            truncated = content[-(MAX_DISCORD_MSG - 30):]
            await ctx.send(f"```\n...{truncated}\n```")


async def setup(bot):
    await bot.add_cog(ClaudeCog(bot))
