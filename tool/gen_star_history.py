#!/usr/bin/env python3
"""Generate a self-hosted "stargazers over time" chart.

Third-party chart services (starchart.cc, star-history.com) go down or
rate-limit constantly, which leaves a broken image in the README. This
script renders the chart ourselves from the GitHub stargazers API and
writes a static SVG into the repo, so the README only ever points at our
own raw.githubusercontent.com content.

Usage:
    GITHUB_TOKEN=... python3 tool/gen_star_history.py [--repo owner/name]
                                                      [--out path.svg]

Exits 0 without touching the existing SVG when the API cannot be reached,
so a transient failure never lands a broken chart on main.
"""

from __future__ import annotations

import argparse
import json
import os
import sys
import urllib.error
import urllib.request
from datetime import datetime, timedelta, timezone

API = "https://api.github.com"
PER_PAGE = 100
MAX_PAGES = 40  # 4000 stars; GitHub itself caps the listing anyway.

WIDTH = 800
HEIGHT = 400
PAD_L = 64
PAD_R = 28
PAD_T = 34
PAD_B = 52

ACCENT = "#7ed957"  # brand green, readable on light and dark backgrounds


def fetch_star_dates(repo: str, token: str | None) -> list[datetime]:
    """Return starred_at timestamps, oldest first."""
    dates: list[datetime] = []
    for page in range(1, MAX_PAGES + 1):
        url = f"{API}/repos/{repo}/stargazers?per_page={PER_PAGE}&page={page}"
        req = urllib.request.Request(url)
        req.add_header("Accept", "application/vnd.github.star+json")
        req.add_header("User-Agent", "custom-rr-star-history")
        if token:
            req.add_header("Authorization", f"Bearer {token}")
        with urllib.request.urlopen(req, timeout=30) as resp:
            batch = json.load(resp)
        if not batch:
            break
        for item in batch:
            starred = item.get("starred_at")
            if starred:
                dates.append(
                    datetime.strptime(starred, "%Y-%m-%dT%H:%M:%SZ").replace(
                        tzinfo=timezone.utc
                    )
                )
        if len(batch) < PER_PAGE:
            break
    dates.sort()
    return dates


def nice_ticks(maximum: int, target: int = 5) -> list[int]:
    """Pick round y-axis ticks from 0 up to at least `maximum`."""
    if maximum <= 0:
        return [0, 1]
    raw = maximum / target
    magnitude = 10 ** max(0, len(str(int(raw))) - 1)
    for mult in (1, 2, 2.5, 5, 10):
        step = magnitude * mult
        if raw <= step:
            break
    step = max(1, int(step))
    ticks = list(range(0, maximum + step, step))
    return ticks


def esc(text: str) -> str:
    return (
        text.replace("&", "&amp;")
        .replace("<", "&lt;")
        .replace(">", "&gt;")
        .replace('"', "&quot;")
    )


def render(repo: str, dates: list[datetime]) -> str:
    total = len(dates)
    start = dates[0]
    last = dates[-1]

    # Round the trailing edge down to the most recent Monday so the chart
    # only changes when stars change (or weekly at worst) instead of every
    # single day, which would spam the commit history.
    today = datetime.now(timezone.utc)
    week_start = (today - timedelta(days=today.weekday())).replace(
        hour=0, minute=0, second=0, microsecond=0
    )
    end = max(last, week_start)

    span = max((end - start).total_seconds(), 1.0)
    y_ticks = nice_ticks(total)
    y_max = max(y_ticks[-1], 1)

    plot_w = WIDTH - PAD_L - PAD_R
    plot_h = HEIGHT - PAD_T - PAD_B

    def sx(when: datetime) -> float:
        return PAD_L + plot_w * ((when - start).total_seconds() / span)

    def sy(count: int) -> float:
        return PAD_T + plot_h * (1 - count / y_max)

    # Step path: the count holds flat until the next star arrives.
    pts: list[tuple[float, float]] = [(sx(start), sy(0))]
    step = max(1, total // 400)  # keep the path small on popular repos
    for i, when in enumerate(dates, start=1):
        if i % step and i != total:
            continue
        x = sx(when)
        pts.append((x, pts[-1][1]))
        pts.append((x, sy(i)))
    pts.append((sx(end), pts[-1][1]))

    line = "M " + " L ".join(f"{x:.1f} {y:.1f}" for x, y in pts)
    area = (
        line
        + f" L {pts[-1][0]:.1f} {sy(0):.1f} L {pts[0][0]:.1f} {sy(0):.1f} Z"
    )

    parts: list[str] = []
    # Horizontal grid + y labels
    for tick in y_ticks:
        y = sy(tick)
        parts.append(
            f'<line class="grid" x1="{PAD_L}" y1="{y:.1f}" '
            f'x2="{WIDTH - PAD_R}" y2="{y:.1f}"/>'
        )
        parts.append(
            f'<text class="tick" x="{PAD_L - 10}" y="{y + 4:.1f}" '
            f'text-anchor="end">{tick}</text>'
        )

    # X labels
    label_count = 5
    for i in range(label_count):
        when = start + timedelta(seconds=span * i / (label_count - 1))
        x = sx(when)
        anchor = "middle"
        if i == 0:
            anchor = "start"
        elif i == label_count - 1:
            anchor = "end"
        parts.append(
            f'<text class="tick" x="{x:.1f}" y="{HEIGHT - PAD_B + 22}" '
            f'text-anchor="{anchor}">{when.strftime("%b %Y")}</text>'
        )

    grid = "\n    ".join(parts)

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="{WIDTH}" height="{HEIGHT}" \
viewBox="0 0 {WIDTH} {HEIGHT}" role="img" \
aria-label="Stargazers over time for {esc(repo)}: {total} stars">
  <style>
    .bg {{ fill: none; }}
    .title {{ font: 600 15px -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; fill: #57606a; }}
    .tick  {{ font: 400 11px -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif; fill: #8b949e; }}
    .grid  {{ stroke: #8b949e; stroke-opacity: .25; stroke-width: 1; }}
    .axis  {{ stroke: #8b949e; stroke-opacity: .55; stroke-width: 1; }}
    @media (prefers-color-scheme: dark) {{
      .title {{ fill: #c9d1d9; }}
    }}
  </style>
  <defs>
    <linearGradient id="fade" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0%" stop-color="{ACCENT}" stop-opacity=".35"/>
      <stop offset="100%" stop-color="{ACCENT}" stop-opacity="0"/>
    </linearGradient>
  </defs>
  <rect class="bg" width="{WIDTH}" height="{HEIGHT}"/>
  <text class="title" x="{PAD_L}" y="22">{esc(repo)} &#183; {total} stars</text>
  {grid}
  <line class="axis" x1="{PAD_L}" y1="{PAD_T}" x2="{PAD_L}" y2="{HEIGHT - PAD_B}"/>
  <line class="axis" x1="{PAD_L}" y1="{HEIGHT - PAD_B}" x2="{WIDTH - PAD_R}" y2="{HEIGHT - PAD_B}"/>
  <path d="{area}" fill="url(#fade)"/>
  <path d="{line}" fill="none" stroke="{ACCENT}" stroke-width="2.5" \
stroke-linejoin="round" stroke-linecap="round"/>
</svg>
"""


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo", default="monsiu/Custom-RR")
    parser.add_argument("--out", default="images/generated/star-history.svg")
    args = parser.parse_args()

    token = os.environ.get("GITHUB_TOKEN") or os.environ.get("GH_TOKEN")

    try:
        dates = fetch_star_dates(args.repo, token)
    except (urllib.error.URLError, urllib.error.HTTPError, TimeoutError) as err:
        print(f"star-history: GitHub API unavailable ({err}); keeping existing SVG")
        return 0

    if not dates:
        print("star-history: no stargazers returned; keeping existing SVG")
        return 0

    svg = render(args.repo, dates)
    out = args.out
    os.makedirs(os.path.dirname(out), exist_ok=True)
    previous = None
    if os.path.exists(out):
        with open(out, encoding="utf-8") as handle:
            previous = handle.read()
    if previous == svg:
        print(f"star-history: {out} unchanged ({len(dates)} stars)")
        return 0
    with open(out, "w", encoding="utf-8") as handle:
        handle.write(svg)
    print(f"star-history: wrote {out} ({len(dates)} stars)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
