"""
Fortress Command — Trading Cog
Monitors NFTS trading bots and provides commands for trade management.
"""

import json
import asyncio
import logging
from pathlib import Path
from datetime import datetime, timezone

import discord
from discord.ext import commands, tasks

log = logging.getLogger("fortress.trading")

BOT_EMOJI = {
    "fab4": "\U0001f916",
    "ict": "\U0001f4ca",
    "mym": "\U0001f52e",
    "quant_ai": "\U0001f9e0",
}


class TradingCog(commands.Cog, name="Trading"):
    """Monitor and control Fortress Capital trading bots."""

    def __init__(self, bot):
        self.bot = bot
        self.nfts_dir = Path(bot.nfts_dir)
        self._last_trade_count = 0
        self._trading_channel = None

    async def cog_load(self):
        self._last_trade_count = self._count_trades()
        self.watch_trades.start()

    async def cog_unload(self):
        self.watch_trades.cancel()

    def _get_trading_channel(self):
        """Find the #nfts-trading channel."""
        for guild in self.bot.guilds:
            for ch in guild.text_channels:
                if ch.name == "nfts-trading":
                    return ch
        return None

    def _find_trade_log(self) -> Path | None:
        """Locate the trade log file."""
        candidates = [
            self.nfts_dir / "packages" / "engine" / "trade_log.jsonl",
            self.nfts_dir / "trade_log.jsonl",
            self.nfts_dir / "logs" / "trade_log.jsonl",
            self.nfts_dir / "packages" / "engine" / "logs" / "trades.jsonl",
        ]
        for p in candidates:
            if p.exists():
                return p
        return None

    def _count_trades(self) -> int:
        """Count total lines in trade log."""
        log_file = self._find_trade_log()
        if not log_file:
            return 0
        try:
            with open(log_file) as f:
                return sum(1 for _ in f)
        except OSError:
            return 0

    def _read_recent_trades(self, count: int = 10) -> list[dict]:
        """Read the most recent trades from the log."""
        log_file = self._find_trade_log()
        if not log_file:
            return []

        trades = []
        try:
            with open(log_file) as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        trades.append(json.loads(line))
                    except json.JSONDecodeError:
                        continue
        except OSError:
            return []

        return trades[-count:]

    def _read_bot_status(self) -> list[dict]:
        """Read status of all trading bots."""
        bots = []
        status_candidates = [
            self.nfts_dir / "packages" / "engine" / "bot_status.json",
            self.nfts_dir / "bot_status.json",
            self.nfts_dir / "packages" / "engine" / "status.json",
        ]

        for path in status_candidates:
            if path.exists():
                try:
                    data = json.loads(path.read_text())
                    if isinstance(data, list):
                        return data
                    elif isinstance(data, dict):
                        # Could be {bot_name: status_dict}
                        for name, info in data.items():
                            if isinstance(info, dict):
                                info["name"] = name
                                bots.append(info)
                        return bots
                except (json.JSONDecodeError, OSError):
                    pass

        # Fallback: check for individual strategy status files
        strategies_dir = self.nfts_dir / "packages" / "engine" / "strategies"
        if strategies_dir.exists():
            for strat_dir in strategies_dir.iterdir():
                if strat_dir.is_dir():
                    status_file = strat_dir / "status.json"
                    if status_file.exists():
                        try:
                            info = json.loads(status_file.read_text())
                            info["name"] = strat_dir.name
                            bots.append(info)
                        except (json.JSONDecodeError, OSError):
                            pass

        return bots

    @tasks.loop(seconds=30)
    async def watch_trades(self):
        """Watch for new trades and post alerts to #nfts-trading."""
        channel = self._get_trading_channel()
        if not channel:
            return

        current_count = self._count_trades()
        if current_count <= self._last_trade_count:
            self._last_trade_count = current_count
            return

        # New trades detected
        new_count = current_count - self._last_trade_count
        new_trades = self._read_recent_trades(new_count)
        self._last_trade_count = current_count

        for trade in new_trades[-5:]:  # Cap at 5 alerts per cycle
            side = trade.get("side", "?").upper()
            symbol = trade.get("symbol", "?")
            qty = trade.get("qty", trade.get("quantity", "?"))
            price = trade.get("price", "?")
            pnl = trade.get("pnl", trade.get("realized_pnl"))
            strategy = trade.get("strategy", trade.get("bot", "?"))

            color = 0x00FF88 if side == "BUY" else 0xFF6644
            emoji = "\U0001f7e2" if side == "BUY" else "\U0001f534"

            embed = discord.Embed(
                title=f"{emoji} {side} {symbol}",
                color=color,
                timestamp=datetime.now(timezone.utc),
            )
            embed.add_field(name="Qty", value=str(qty), inline=True)
            embed.add_field(name="Price", value=f"${price}" if price != "?" else "?", inline=True)
            embed.add_field(name="Strategy", value=strategy, inline=True)

            if pnl is not None:
                pnl_str = f"${float(pnl):+.2f}" if pnl else "$0.00"
                embed.add_field(name="P&L", value=pnl_str, inline=True)

            try:
                await channel.send(embed=embed)
            except discord.HTTPException as e:
                log.error(f"Failed to post trade alert: {e}")

    @watch_trades.before_loop
    async def before_watch_trades(self):
        await self.bot.wait_until_ready()

    @commands.command(name="trades")
    async def trades(self, ctx, count: int = 10):
        """Show recent trades and P&L. Usage: !trades [count]"""
        recent = self._read_recent_trades(min(count, 25))

        if not recent:
            await ctx.send(
                "No trades found. Check that the trade log exists and the NFTS engine is running."
            )
            return

        embed = discord.Embed(
            title="\U0001f4c8 Recent Trades",
            color=0x00FF88,
            timestamp=datetime.now(timezone.utc),
        )

        total_pnl = 0.0
        wins = 0
        losses = 0

        trade_lines = []
        for t in recent:
            side = t.get("side", "?").upper()
            symbol = t.get("symbol", "?")
            price = t.get("price", "?")
            pnl = t.get("pnl", t.get("realized_pnl"))
            strategy = t.get("strategy", t.get("bot", "?"))

            emoji = "\U0001f7e2" if side == "BUY" else "\U0001f534"

            line = f"{emoji} {side} **{symbol}** @ ${price}"
            if pnl is not None:
                pnl_val = float(pnl)
                total_pnl += pnl_val
                if pnl_val > 0:
                    wins += 1
                elif pnl_val < 0:
                    losses += 1
                line += f" | P&L: ${pnl_val:+.2f}"
            line += f" ({strategy})"
            trade_lines.append(line)

        # Split into chunks for embed fields (1024 char limit)
        chunk = ""
        chunk_idx = 1
        for line in trade_lines:
            if len(chunk) + len(line) + 1 > 1000:
                embed.add_field(
                    name=f"Trades (page {chunk_idx})", value=chunk, inline=False
                )
                chunk = ""
                chunk_idx += 1
            chunk += line + "\n"

        if chunk:
            label = "Trades" if chunk_idx == 1 else f"Trades (page {chunk_idx})"
            embed.add_field(name=label, value=chunk, inline=False)

        # Summary
        total_trades = wins + losses
        win_rate = (wins / total_trades * 100) if total_trades > 0 else 0
        embed.add_field(name="Total P&L", value=f"${total_pnl:+.2f}", inline=True)
        embed.add_field(
            name="Win Rate",
            value=f"{win_rate:.1f}% ({wins}W/{losses}L)",
            inline=True,
        )
        embed.set_footer(text=f"Showing last {len(recent)} trades")
        await ctx.send(embed=embed)

    @commands.command(name="bots")
    async def bots(self, ctx):
        """Show trading bot status."""
        bot_list = self._read_bot_status()

        embed = discord.Embed(
            title="\U0001f916 Trading Bots",
            color=0x00BFFF,
            timestamp=datetime.now(timezone.utc),
        )

        if not bot_list:
            # Fallback: show known bots with basic info
            known = ["FAB4", "ICT", "MYM", "Quant AI"]
            nfts_exists = self.nfts_dir.exists()
            embed.description = (
                "No bot status files found.\n"
                f"NFTS directory {'exists' if nfts_exists else 'NOT FOUND'}: `{self.nfts_dir}`\n\n"
                "Known strategies: " + ", ".join(known)
            )
            await ctx.send(embed=embed)
            return

        for bot_info in bot_list:
            name = bot_info.get("name", "Unknown")
            status = bot_info.get("status", "unknown")
            wr = bot_info.get("win_rate", bot_info.get("wr"))
            pnl = bot_info.get("pnl", bot_info.get("total_pnl"))
            pairs = bot_info.get("pairs", bot_info.get("symbols", []))

            emoji = BOT_EMOJI.get(name.lower().replace(" ", "_"), "\U0001f916")
            status_icon = "\U0001f7e2" if status in ("active", "running") else "\U0001f534"

            value = f"{status_icon} {status.upper()}"
            if wr is not None:
                value += f"\nWin Rate: {wr}%"
            if pnl is not None:
                value += f"\nP&L: ${float(pnl):+.2f}"
            if pairs:
                pair_str = ", ".join(pairs[:5]) if isinstance(pairs, list) else str(pairs)
                value += f"\nPairs: {pair_str}"

            embed.add_field(name=f"{emoji} {name}", value=value, inline=True)

        await ctx.send(embed=embed)

    @commands.command(name="strategy")
    async def strategy(self, ctx, bot_name: str = None, param: str = None, value: str = None):
        """Adjust a trading strategy parameter. Usage: !strategy <bot> <param> <value>"""
        if not all([bot_name, param, value]):
            await ctx.send("Usage: `!strategy <bot_name> <param> <value>`\nExample: `!strategy quant_ai risk_per_trade 0.02`")
            return

        # Only allow the server owner / bot deployer
        if not ctx.author.guild_permissions.administrator:
            await ctx.send("Only administrators can modify trading strategies.")
            return

        # Look for strategy config
        config_candidates = [
            self.nfts_dir / "packages" / "engine" / "strategies" / bot_name / "config.json",
            self.nfts_dir / "packages" / "engine" / f"{bot_name}_config.json",
            self.nfts_dir / "strategies" / bot_name / "config.json",
        ]

        config_path = None
        for p in config_candidates:
            if p.exists():
                config_path = p
                break

        if not config_path:
            await ctx.send(
                f"Config file not found for bot `{bot_name}`.\n"
                f"Searched: {', '.join(str(p) for p in config_candidates)}"
            )
            return

        try:
            config = json.loads(config_path.read_text())
        except (json.JSONDecodeError, OSError) as e:
            await ctx.send(f"Failed to read config: {e}")
            return

        old_value = config.get(param, "NOT SET")

        # Try to parse value as number
        try:
            parsed = float(value)
            if parsed == int(parsed):
                parsed = int(parsed)
            config[param] = parsed
        except ValueError:
            if value.lower() in ("true", "false"):
                config[param] = value.lower() == "true"
            else:
                config[param] = value

        try:
            config_path.write_text(json.dumps(config, indent=2))
        except OSError as e:
            await ctx.send(f"Failed to write config: {e}")
            return

        embed = discord.Embed(
            title="\u2699\ufe0f Strategy Updated",
            color=0x00FF88,
        )
        embed.add_field(name="Bot", value=bot_name, inline=True)
        embed.add_field(name="Parameter", value=param, inline=True)
        embed.add_field(name="Old Value", value=str(old_value), inline=True)
        embed.add_field(name="New Value", value=str(config[param]), inline=True)
        embed.set_footer(text="Restart the bot for changes to take effect.")
        await ctx.send(embed=embed)

    @commands.command(name="deploy")
    async def deploy(self, ctx, strategy: str = None):
        """Deploy a trading bot. Usage: !deploy <strategy>"""
        if not strategy:
            await ctx.send("Usage: `!deploy <strategy_name>`")
            return

        if not ctx.author.guild_permissions.administrator:
            await ctx.send("Only administrators can deploy trading bots.")
            return

        embed = discord.Embed(
            title="\U0001f680 Deploying Bot",
            description=f"Strategy: **{strategy}**",
            color=0xFFAA00,
        )
        embed.set_footer(text="This will be handled by the Fortress engine API.")
        msg = await ctx.send(embed=embed)

        # Try to hit the Fortress engine API
        try:
            import aiohttp

            async with aiohttp.ClientSession() as session:
                async with session.post(
                    "http://localhost:8080/api/deploy",
                    json={"strategy": strategy},
                    timeout=aiohttp.ClientTimeout(total=10),
                ) as resp:
                    if resp.status == 200:
                        result = await resp.json()
                        embed.color = 0x00FF88
                        embed.title = "\u2705 Bot Deployed"
                        embed.description = f"Strategy **{strategy}** is now running."
                        if result.get("message"):
                            embed.add_field(
                                name="Response", value=result["message"], inline=False
                            )
                    else:
                        embed.color = 0xFF4444
                        embed.title = "\u274c Deploy Failed"
                        embed.description = f"Engine returned status {resp.status}"
        except Exception as e:
            embed.color = 0xFF4444
            embed.title = "\u274c Deploy Failed"
            embed.description = f"Could not reach Fortress engine: {e}"

        await msg.edit(embed=embed)


async def setup(bot):
    await bot.add_cog(TradingCog(bot))
