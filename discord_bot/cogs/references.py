"""
Fortress Command — References Cog
Accept UI/UX reference images and links for app design inspiration.
Stores references per-project or globally for the OPENAGENT pipeline.
"""

import json
import logging
import re
from datetime import datetime, timezone
from pathlib import Path

import aiohttp
import discord
from discord.ext import commands

log = logging.getLogger("fortress.references")

URL_PATTERN = re.compile(r'https?://[^\s<>"\']+')


class ReferencesCog(commands.Cog, name="References"):
    """Accept UI/UX reference material for the app pipeline."""

    def __init__(self, bot):
        self.bot = bot
        self.openagent_dir = Path(bot.openagent_dir)
        self.references_dir = self.openagent_dir / "references"
        self.references_dir.mkdir(parents=True, exist_ok=True)
        (self.references_dir / "global" / "images").mkdir(parents=True, exist_ok=True)

    def _get_projects(self) -> list:
        """List known project names."""
        projects_dir = self.openagent_dir / "projects"
        if not projects_dir.exists():
            return []
        return [
            d.name for d in sorted(projects_dir.iterdir())
            if d.is_dir() and not d.name.startswith("_")
        ]

    def _ensure_ref_dir(self, project: str) -> Path:
        ref_dir = self.references_dir / project
        (ref_dir / "images").mkdir(parents=True, exist_ok=True)
        return ref_dir

    def _append_ref(self, project: str, entry: dict):
        ref_dir = self._ensure_ref_dir(project)
        jsonl = ref_dir / "references.jsonl"
        with open(jsonl, "a") as f:
            f.write(json.dumps(entry) + "\n")

    async def _download_attachment(self, attachment: discord.Attachment, project: str) -> str:
        """Download a Discord attachment and return the local filename."""
        ref_dir = self._ensure_ref_dir(project)
        ts = datetime.now(timezone.utc).strftime("%Y%m%d_%H%M%S")
        ext = Path(attachment.filename).suffix or ".png"
        filename = f"{ts}_{attachment.filename}"
        filepath = ref_dir / "images" / filename

        async with aiohttp.ClientSession() as session:
            async with session.get(attachment.url) as resp:
                if resp.status == 200:
                    filepath.write_bytes(await resp.read())
                    return filename
        return ""

    @commands.command(name="ref")
    async def add_reference(self, ctx, project: str = None, *, note: str = ""):
        """Add a UI/UX reference. Attach images or include URLs.
        Usage: !ref <project|global> [note about what you like]
        """
        if not project:
            projects = self._get_projects()
            proj_list = ", ".join(f"`{p}`" for p in projects) if projects else "none yet"
            await ctx.send(
                "**Usage:** `!ref <project|global> [note]`\n"
                f"**Projects:** {proj_list}, `global`\n"
                "Attach an image or include a URL in your message."
            )
            return

        # Normalize project name
        project = project.lower().replace(" ", "-")
        valid = self._get_projects() + ["global"]
        if project not in valid:
            await ctx.send(f"Unknown project `{project}`. Valid: {', '.join(f'`{p}`' for p in valid)}")
            return

        saved = []
        user = str(ctx.author)
        ts = datetime.now(timezone.utc).isoformat()

        # Handle image attachments
        for att in ctx.message.attachments:
            if att.content_type and att.content_type.startswith("image"):
                filename = await self._download_attachment(att, project)
                if filename:
                    self._append_ref(project, {
                        "type": "image",
                        "filename": filename,
                        "note": note,
                        "submitted_by": user,
                        "timestamp": ts,
                    })
                    saved.append(f"Image: `{filename}`")
                    log.info(f"Reference image saved for {project}: {filename}")

        # Handle URLs in message text
        full_text = note + " " + ctx.message.content
        urls = URL_PATTERN.findall(full_text)
        for url in urls:
            # Skip Discord CDN URLs (those are the attachments)
            if "cdn.discordapp.com" in url or "media.discordapp.net" in url:
                continue
            self._append_ref(project, {
                "type": "url",
                "url": url,
                "note": note,
                "submitted_by": user,
                "timestamp": ts,
            })
            saved.append(f"URL: {url}")
            log.info(f"Reference URL saved for {project}: {url}")

        if saved:
            items = "\n".join(f"  - {s}" for s in saved)
            await ctx.reply(
                f"Saved **{len(saved)}** reference(s) for **{project}**:\n{items}",
                mention_author=False,
            )
        else:
            await ctx.send(
                "No images or URLs found. Attach an image or include a URL in your message."
            )

    @commands.command(name="refs")
    async def list_references(self, ctx, project: str = None):
        """List saved references. Usage: !refs [project|global]"""
        if not project:
            # Show summary for all projects
            lines = []
            for d in sorted(self.references_dir.iterdir()):
                if d.is_dir():
                    jsonl = d / "references.jsonl"
                    if jsonl.exists():
                        count = sum(1 for _ in jsonl.read_text().strip().splitlines() if _.strip())
                        img_count = len(list((d / "images").glob("*"))) if (d / "images").exists() else 0
                        lines.append(f"  **{d.name}**: {count} refs ({img_count} images)")
            if lines:
                await ctx.send("**Saved References:**\n" + "\n".join(lines))
            else:
                await ctx.send("No references saved yet. Use `!ref <project> [note]` with an image or URL.")
            return

        project = project.lower().replace(" ", "-")
        ref_dir = self.references_dir / project
        jsonl = ref_dir / "references.jsonl"

        if not jsonl.exists():
            await ctx.send(f"No references for `{project}`. Use `!ref {project} [note]` to add some.")
            return

        entries = []
        for line in jsonl.read_text().strip().splitlines():
            if line.strip():
                entries.append(json.loads(line))

        if not entries:
            await ctx.send(f"No references for `{project}`.")
            return

        lines = [f"**References for {project}** ({len(entries)} total):"]
        for e in entries[-10:]:  # Show last 10
            if e["type"] == "image":
                lines.append(f"  - Image: `{e['filename']}` — {e.get('note', 'no note')}")
            else:
                lines.append(f"  - URL: {e['url']} — {e.get('note', 'no note')}")

        await ctx.send("\n".join(lines))

    @commands.command(name="ref-clear")
    async def clear_references(self, ctx, project: str = None):
        """Clear references for a project. Usage: !ref-clear <project>"""
        if not project:
            await ctx.send("Usage: `!ref-clear <project|global>`")
            return

        project = project.lower().replace(" ", "-")
        ref_dir = self.references_dir / project
        jsonl = ref_dir / "references.jsonl"

        if jsonl.exists():
            jsonl.unlink()
            await ctx.reply(f"Cleared references for **{project}**.", mention_author=False)
        else:
            await ctx.send(f"No references found for `{project}`.")

    @commands.Cog.listener()
    async def on_message(self, message):
        """Detect reference intent in natural language messages with attachments."""
        if message.author == self.bot.user:
            return
        if message.content.startswith("!"):
            return

        # Only process if there are image attachments
        has_images = any(
            att.content_type and att.content_type.startswith("image")
            for att in message.attachments
        )
        if not has_images:
            return

        # Check for reference-related keywords
        text = message.content.lower()
        ref_keywords = [
            "reference", "ref", "inspiration", "like this", "cool app",
            "use this", "design like", "ui like", "ux like", "similar to",
            "look like", "style like", "this ui", "this design", "this app"
        ]

        if not any(kw in text for kw in ref_keywords):
            return

        # Try to extract project name from text
        projects = self._get_projects()
        target_project = "global"
        for proj in projects:
            if proj.lower() in text:
                target_project = proj
                break

        # Save the reference
        user = str(message.author)
        ts = datetime.now(timezone.utc).isoformat()
        saved = 0

        for att in message.attachments:
            if att.content_type and att.content_type.startswith("image"):
                filename = await self._download_attachment(att, target_project)
                if filename:
                    self._append_ref(target_project, {
                        "type": "image",
                        "filename": filename,
                        "note": message.content[:200],
                        "submitted_by": user,
                        "timestamp": ts,
                    })
                    saved += 1

        # Also save any URLs
        urls = URL_PATTERN.findall(message.content)
        for url in urls:
            if "cdn.discordapp.com" not in url and "media.discordapp.net" not in url:
                self._append_ref(target_project, {
                    "type": "url",
                    "url": url,
                    "note": message.content[:200],
                    "submitted_by": user,
                    "timestamp": ts,
                })
                saved += 1

        if saved:
            await message.reply(
                f"Saved as reference for **{target_project}** ({saved} item{'s' if saved > 1 else ''}).",
                mention_author=False,
            )


async def setup(bot):
    await bot.add_cog(ReferencesCog(bot))
