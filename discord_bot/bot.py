#!/usr/bin/env python3
"""
Fortress Command — Discord Bot
Unified command center for OPENAGENT (app factory) and NFTS (trading bots).
"""

import os
import sys
import asyncio
import logging
from pathlib import Path

import discord
from discord.ext import commands
from dotenv import load_dotenv

# Load env
load_dotenv(Path.home() / ".env.openagent")
load_dotenv()

TOKEN = os.getenv("DISCORD_BOT_TOKEN", "")
OPENAGENT_DIR = os.getenv("OPENAGENT_DIR", str(Path.home() / "OPENAGENT"))
NFTS_DIR = os.getenv("NFTS_DIR", str(Path.home() / "NFTS"))

if not TOKEN:
    print("ERROR: DISCORD_BOT_TOKEN not set in environment or .env.openagent")
    sys.exit(1)

# Logging
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(name)s] %(levelname)s: %(message)s",
    handlers=[
        logging.StreamHandler(),
        logging.FileHandler(Path(OPENAGENT_DIR) / "logs" / "discord_bot.log"),
    ],
)
log = logging.getLogger("fortress")

# Bot setup
intents = discord.Intents.default()
intents.message_content = True

bot = commands.Bot(command_prefix="!", intents=intents, help_command=None)

# Store config on bot for cogs to access
bot.openagent_dir = OPENAGENT_DIR
bot.nfts_dir = NFTS_DIR
bot.owner_set = False

# Channel name constants
CHANNEL_OPENAGENT = "openagent-status"
CHANNEL_TRADING = "nfts-trading"
CHANNEL_COMMANDS = "commands"
CHANNEL_LOGS = "logs"

REQUIRED_CHANNELS = [CHANNEL_OPENAGENT, CHANNEL_TRADING, CHANNEL_COMMANDS, CHANNEL_LOGS]


@bot.event
async def on_ready():
    log.info(f"Fortress Command online as {bot.user} (ID: {bot.user.id})")
    log.info(f"Connected to {len(bot.guilds)} server(s)")

    # Auto-create channels if missing
    for guild in bot.guilds:
        existing = [ch.name for ch in guild.text_channels]
        for ch_name in REQUIRED_CHANNELS:
            if ch_name not in existing:
                await guild.create_text_channel(ch_name)
                log.info(f"Created #{ch_name} in {guild.name}")

    # Load cogs
    cog_dir = Path(__file__).parent / "cogs"
    for cog_file in cog_dir.glob("*.py"):
        if cog_file.name.startswith("_"):
            continue
        cog_name = f"cogs.{cog_file.stem}"
        try:
            await bot.load_extension(cog_name)
            log.info(f"Loaded cog: {cog_name}")
        except Exception as e:
            log.error(f"Failed to load {cog_name}: {e}")

    # Set status
    await bot.change_presence(
        activity=discord.Activity(
            type=discord.ActivityType.watching,
            name="OPENAGENT + Fortress Capital",
        )
    )


@bot.command(name="help")
async def help_cmd(ctx):
    """Show all available commands."""
    embed = discord.Embed(
        title="Fortress Command",
        description="Unified command center for OPENAGENT & Fortress Capital",
        color=0x00FF88,
    )

    embed.add_field(
        name="OPENAGENT (App Factory)",
        value=(
            "`!status` — Pipeline overview\n"
            "`!phase <project>` — Project details\n"
            "`!idea \"description\"` — Submit app idea\n"
            "`!build <project>` — Trigger build\n"
            "`!costs` — API spending\n"
        ),
        inline=False,
    )

    embed.add_field(
        name="Fortress Capital (Trading)",
        value=(
            "`!trades` — Recent trades + P&L\n"
            "`!bots` — Trading bot status\n"
            "`!strategy <bot> <param> <val>` — Adjust strategy\n"
            "`!deploy <strategy>` — Deploy bot\n"
        ),
        inline=False,
    )

    embed.add_field(
        name="AI Assistant",
        value=(
            "`!ask <question>` — Ask Claude anything\n"
            "`!logs <project|bot>` — View recent logs\n"
        ),
        inline=False,
    )

    embed.set_footer(text="Fortress Command v1.0 | OPENAGENT + NFTS")
    await ctx.send(embed=embed)


@bot.command(name="ping")
async def ping(ctx):
    """Check bot latency."""
    await ctx.send(f"Pong! {round(bot.latency * 1000)}ms")


def main():
    bot.run(TOKEN, log_handler=None)


if __name__ == "__main__":
    main()
