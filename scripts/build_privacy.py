#!/usr/bin/env python3
"""Build the published privacy policy artifacts from the one canonical source.

Canonical:  AsteraDev/Resources/PrivacyPolicy.md
Generated:  docs/privacy/index.html   (the URL in App Store Connect)
            PRIVACY.md                (repo root, for people reading on GitHub)

The app does not get a generated copy: PrivacyPolicy.md ships in the app bundle
and PrivacyPolicy.swift reads it at runtime. So there is exactly one file a human
edits, and every published rendering comes from it.

Usage:
    python3 scripts/build_privacy.py           # write the artifacts
    python3 scripts/build_privacy.py --check   # fail if they are out of date
"""

import html
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CANONICAL = ROOT / "AsteraDev/Resources/PrivacyPolicy.md"
HTML_OUT = ROOT / "docs/privacy/index.html"
MD_OUT = ROOT / "PRIVACY.md"

PAGE_TITLE = "Astera privacy policy"
PAGE_DESCRIPTION = "What Astera collects. Spoiler: nothing."
REPO_URL = "https://github.com/anker-rasmussen/astera"

HTML_BANNER = "<!-- Generated from AsteraDev/Resources/PrivacyPolicy.md by scripts/build_privacy.py. Do not edit. -->"
MD_BANNER = "<!-- Generated from AsteraDev/Resources/PrivacyPolicy.md by scripts/build_privacy.py. Do not edit. -->"

LINK = re.compile(r"\[([^\]]+)\]\(([^)]+)\)")


def parse(text):
    """Returns (metadata, blocks). A block is ('h1'|'h2'|'p', markdown_text)."""
    if not text.startswith("---\n"):
        sys.exit("Canonical file must start with a --- frontmatter block")
    _, frontmatter, body = text.split("---\n", 2)

    meta = {}
    for line in frontmatter.strip().splitlines():
        key, _, value = line.partition(":")
        meta[key.strip()] = value.strip()
    for required in ("version", "updated"):
        if required not in meta:
            sys.exit(f"Frontmatter is missing '{required}'")

    blocks = []
    for chunk in (c.strip() for c in body.split("\n\n")):
        if not chunk:
            continue
        if chunk.startswith("## "):
            blocks.append(("h2", chunk[3:]))
        elif chunk.startswith("# "):
            blocks.append(("h1", chunk[2:]))
        else:
            blocks.append(("p", chunk))
    return meta, blocks


def to_html(markdown):
    """Escapes text, then turns [label](url) into an anchor."""
    parts, cursor = [], 0
    for match in LINK.finditer(markdown):
        parts.append(html.escape(markdown[cursor:match.start()], quote=False))
        label, url = html.escape(match.group(1), quote=False), html.escape(match.group(2), quote=True)
        parts.append(f'<a href="{url}">{label}</a>')
        cursor = match.end()
    parts.append(html.escape(markdown[cursor:], quote=False))
    return "".join(parts)


def render_html(meta, blocks, banner=True):
    """Layout rules, which are structure rather than content:
      - the first paragraph after the h1 is the standfirst, and a rule follows it
      - every h2 opens a new block, separated by a blank line
      - the closing paragraph is the meta note
    """
    lines = []
    if banner:
        lines.append(HTML_BANNER)
    lines += [
        "<!DOCTYPE html>",
        '<html lang="en">',
        "<head>",
        '<meta charset="utf-8">',
        '<meta name="viewport" content="width=device-width,initial-scale=1">',
        f"<title>{PAGE_TITLE}</title>",
        f'<meta name="description" content="{PAGE_DESCRIPTION}">',
        '<link rel="stylesheet" href="../style.css">',
        "</head>",
        "<body>",
        '<main class="page">',
        '  <a class="back" href="../">← Astera</a>',
        f'  <p class="caps">Privacy · v{meta["version"]} · {meta["updated"]}</p>',
    ]

    last_index = len(blocks) - 1
    seen_standfirst = False
    for index, (kind, text) in enumerate(blocks):
        body = to_html(text)
        if kind == "h1":
            lines.append(f"  <h1>{body}</h1>")
        elif kind == "h2":
            lines += ["", f"  <h2>{body}</h2>"]
        elif not seen_standfirst:
            seen_standfirst = True
            lines += [f'  <p class="italic">{body}</p>', "", "  <hr>"]
        elif index == last_index:
            lines += ["", f'  <p class="italic meta">{body}</p>']
        else:
            lines.append(f"  <p>{body}</p>")

    lines += [
        "",
        '  <div class="footer">',
        f'    Astera · <a href="{REPO_URL}">{REPO_URL.replace("https://", "")}</a>',
        "  </div>",
        "</main>",
        "</body>",
        "</html>",
    ]
    return "\n".join(lines) + "\n"


def render_markdown(meta, blocks):
    """Headings demote by one, because the file gets its own title."""
    lines = [
        MD_BANNER,
        "",
        "# Astera Privacy Policy",
        "",
        f'_Version {meta["version"]}, {meta["updated"]}._',
        "",
        "This is the same text that ships inside the app and that is published at "
        "[anker-rasmussen.github.io/astera/privacy](https://anker-rasmussen.github.io/astera/privacy/). "
        "All three come from one source file, so they cannot disagree.",
        "",
    ]
    for kind, text in blocks:
        prefix = {"h1": "## ", "h2": "### ", "p": ""}[kind]
        lines += [prefix + text, ""]
    return "\n".join(lines).rstrip() + "\n"


def main():
    check = "--check" in sys.argv
    meta, blocks = parse(CANONICAL.read_text())
    artifacts = {HTML_OUT: render_html(meta, blocks), MD_OUT: render_markdown(meta, blocks)}

    stale = [path for path, content in artifacts.items() if not path.exists() or path.read_text() != content]

    if check:
        if stale:
            for path in stale:
                print(f"out of date: {path.relative_to(ROOT)}")
            sys.exit("Privacy artifacts are stale. Run: python3 scripts/build_privacy.py")
        print(f"Privacy artifacts are up to date with {CANONICAL.relative_to(ROOT)} (v{meta['version']}).")
        return

    for path, content in artifacts.items():
        path.write_text(content)
        print(f"wrote {path.relative_to(ROOT)}")


if __name__ == "__main__":
    main()
