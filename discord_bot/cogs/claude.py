"""
Fortress Command — Claude Cog
Provides Claude CLI passthrough for complex instructions and log viewing.
Works like Claude Code through Discord.
"""

import asyncio
import logging
from pathlib import Path
from datetime import datetime, timezone

import discord
from discord.ext import commands

log = logging.getLogger("fortress.claude")

MAX_DISCORD_MSG = 1900  # Leave room for code block markers


class ClaudeCog(commands.Cog, name="Claude"):
    """Claude CLI passthrough — like Claude Code through Discord."""

    def __init__(self, bot):
        self.bot = bot
        self.openagent_dir = Path(bot.openagent_dir)
        self.nfts_dir = Path(bot.nfts_dir)
        self._running_tasks = {}  # channel_id -> asyncio.Task

    @commands.command(name="ask")
    async def ask(self, ctx, *, question: str = None):
        """Ask Claude anything. Usage: !ask <question>"""
        if not question:
            await ctx.send('Usage: `!ask <your question or instruction>`\nExample: `!ask what is the current win rate across all trading bots?`')
            return

        # Send thinking indicator
        embed = discord.Embed(
            title="\U0001f9e0 Thinking...",
            description=f"**Q:** {question[:200]}",
            color=0xFFAA00,
        )
        thinking_msg = await ctx.send(embed=embed)

        # Determine working directory based on question content
        question_lower = question.lower()
        if any(kw in question_lower for kw in ["trade", "trading", "bot", "strategy", "pnl", "fortress", "nfts"]):
            work_dir = str(self.nfts_dir)
            context = "NFTS/Fortress Capital trading system"
        else:
            work_dir = str(self.openagent_dir)
            context = "OPENAGENT app factory"

        # Build Claude CLI command
        system_context = (
            f"You are answering a question from a Discord bot user about the {context}. "
            f"Working directory: {work_dir}. "
            "Be concise — your response will be shown in Discord (2000 char limit per message). "
            "Use markdown formatting."
        )

        full_prompt = f"{system_context}\n\nUser question: {question}"

        try:
            proc = await asyncio.create_subprocess_exec(
                "claude",
                "--print",
                "--dangerously-skip-permissions",
                "--model", "sonnet",
                "-p", full_prompt,
                stdout=asyncio.subprocess.PIPE,
                stderr=asyncio.subprocess.PIPE,
                cwd=work_dir,
            )

            stdout, stderr = await asyncio.wait_for(
                proc.communicate(), timeout=120
            )

            response = stdout.decode("utf-8", errors="replace").strip()

            if not response:
                error_text = stderr.decode("utf-8", errors="replace").strip()
                response = f"No response from Claude.\nStderr: {error_text[:500]}" if error_text else "No response from Claude."

        except asyncio.TimeoutError:
            response = "Claude took too long to respond (>120s timeout)."
        except FileNotFoundError:
            response = (
                "Claude CLI not found. Make sure `claude` is installed and in PATH.\n"
                "Install: `npm install -g @anthropic-ai/claude-code`"
            )
        except Exception as e:
            response = f"Error running Claude: {e}"

        # Delete thinking message
        try:
            await thinking_msg.delete()
        except discord.HTTPException:
            pass

        # Send response (chunked if needed)
        await self._send_chunked(ctx, question, response)

    async def _send_chunked(self, ctx, question: str, response: str):
        """Send a potentially long response in chunks."""
        # First message with question context
        header = f"**Q:** {question[:150]}\n\n"

        if len(header) + len(response) <= MAX_DISCORD_MSG:
            embed = discord.Embed(
                title="\U0001f9e0 Claude",
                color=0x00BFFF,
                timestamp=datetime.now(timezone.utc),
            )
            embed.add_field(name="Question", value=question[:250], inline=False)

            # If response fits in embed field
            if len(response) <= 1024:
                embed.add_field(name="Answer", value=response, inline=False)
                await ctx.send(embed=embed)
            else:
                embed.add_field(name="Answer", value="See below", inline=False)
                await ctx.send(embed=embed)
                await ctx.send(response[:MAX_DISCORD_MSG])
        else:
            embed = discord.Embed(
                title="\U0001f9e0 Claude",
                color=0x00BFFF,
                timestamp=datetime.now(timezone.utc),
            )
            embed.add_field(name="Question", value=question[:250], inline=False)
            embed.set_footer(text=f"Response: {len(response)} chars")
            await ctx.send(embed=embed)

            # Split response into chunks
            chunks = []
            while response:
                if len(response) <= MAX_DISCORD_MSG:
                    chunks.append(response)
                    break

                # Try to split at a newline
                split_at = response.rfind("\n", 0, MAX_DISCORD_MSG)
                if split_at < MAX_DISCORD_MSG // 2:
                    split_at = MAX_DISCORD_MSG

                chunks.append(response[:split_at])
                response = response[split_at:].lstrip("\n")

            for i, chunk in enumerate(chunks[:10]):  # Cap at 10 messages
                if i == 9 and len(chunks) > 10:
                    chunk += f"\n\n*... {len(chunks) - 10} more chunks truncated*"
                await ctx.send(chunk)
                await asyncio.sleep(0.5)  # Rate limit

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

        # System logs
        if target in ("system", "orchestrator", "cron"):
            log_path = self.openagent_dir / "logs" / "orchestrator.log"
            log_desc = "Orchestrator"
        elif target == "discord":
            log_path = self.openagent_dir / "logs" / "discord_bot.log"
            log_desc = "Discord Bot"
        else:
            # Check if it's a project
            proj_log = self.openagent_dir / "projects" / target / "agent.log"
            if proj_log.exists():
                log_path = proj_log
                log_desc = f"Project: {target}"
            else:
                # Check NFTS bot logs
                nfts_log_candidates = [
                    self.nfts_dir / "packages" / "engine" / "logs" / f"{target}.log",
                    self.nfts_dir / "logs" / f"{target}.log",
                    self.nfts_dir / "packages" / "engine" / "strategies" / target / "agent.log",
                ]
                for p in nfts_log_candidates:
                    if p.exists():
                        log_path = p
                        log_desc = f"Bot: {target}"
                        break

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
            title=f"\U0001f4dc Logs: {log_desc}",
            color=0x888888,
            timestamp=datetime.now(timezone.utc),
        )
        embed.set_footer(text=f"Last {len(tail)} lines from {log_path.name}")
        await ctx.send(embed=embed)

        # Send log content in code block
        if len(content) <= MAX_DISCORD_MSG - 10:
            await ctx.send(f"```\n{content}\n```")
        else:
            # Truncate from the beginning to fit
            truncated = content[-(MAX_DISCORD_MSG - 30):]
            await ctx.send(f"```\n...{truncated}\n```")


async def setup(bot):
    await bot.add_cog(ClaudeCog(bot))
