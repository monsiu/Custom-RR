#!/usr/bin/env python3
"""Generate LIGHT-MODE branded TABLET screenshots for Custom RR (1440x2560).

Same showcase design as the phone set (green robot badge, mono eyebrow with a
green underline, serif headline, subtitle) but scaled up and framed in a
portrait TABLET body around the tablet-layout (side-rail) app capture.

Raw LIGHT tablet captures (side-rail layout) live in RAW_DIR. Output to OUT_DIR
(a preview/staging dir); rollout copies these into the sevenInch/tenInch sets.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1440, 2560
RAW_DIR = "/tmp/light-tablet-raw"
OUT_DIR = "/tmp/light-tablet-preview"
ROBOT = "/home/monsiu/Custom-RR/images/generated/launcher_full.png"

F = "/usr/share/fonts/TTF"
FONT_EYEBROW = f"{F}/JetBrainsMonoNerdFont-Bold.ttf"
FONT_HEAD = f"{F}/RobotoSlab-Bold.ttf"
FONT_SUB = f"{F}/DejaVuSans.ttf"
FONT_SB = f"{F}/DejaVuSans-Bold.ttf"

BG_TOP = (233, 246, 224)
BG_BOTTOM = (246, 251, 242)
GREEN = (126, 217, 87)
DEEP_GREEN = (53, 107, 35)
HEADLINE = (16, 36, 14)
SUBTITLE = (76, 94, 68)
STATUSBAR_BG = (246, 249, 243)
STATUSBAR_FG = (40, 52, 36)

COPY = [
    ("CUSTOM RR", "Your custom Android toolkit",
     "ROMs, recoveries, root, and device support in one place."),
    ("CUSTOM ROMS", "Track ROM freshness fast",
     "Browse active projects, check freshness, and jump to sources."),
    ("ROM DETAILS", "Open every project deeply",
     "Features, links, and supported devices at a glance."),
    ("RECOVERIES", "Recoveries made searchable",
     "TWRP, OrangeFox, PBRP, SHRP, and one-tap source links."),
    ("ROOT", "Root tools, clearly curated",
     "Magisk, KernelSU, APatch, and SukiSU with status badges."),
    ("DEVICES", "Find support by device",
     "Search by brand, model, or codename to match ROM support."),
]


def font(path, size):
    return ImageFont.truetype(path, size)


def text_w(draw, text, fnt, tracking=0.0):
    if tracking == 0:
        return draw.textlength(text, font=fnt)
    return sum(draw.textlength(c, font=fnt) + tracking for c in text) - tracking


def draw_centered(draw, cx, y, text, fnt, fill, tracking=0.0):
    total = text_w(draw, text, fnt, tracking)
    x = cx - total / 2
    if tracking == 0:
        draw.text((x, y), text, font=fnt, fill=fill)
        return
    for c in text:
        draw.text((x, y), c, font=fnt, fill=fill)
        x += draw.textlength(c, font=fnt) + tracking


def wrap(draw, text, fnt, max_w):
    words, lines, cur = text.split(), [], ""
    for wd in words:
        trial = f"{cur} {wd}".strip()
        if draw.textlength(trial, font=fnt) <= max_w:
            cur = trial
        else:
            if cur:
                lines.append(cur)
            cur = wd
    if cur:
        lines.append(cur)
    return lines


def gradient_bg():
    col = Image.new("RGB", (1, H))
    for y in range(H):
        t = y / (H - 1)
        col.putpixel((0, y), tuple(
            int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)))
    return col.resize((W, H)).convert("RGBA")


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def circle_badge(diameter=210):
    badge = Image.new("RGBA", (diameter, diameter), (0, 0, 0, 0))
    d = ImageDraw.Draw(badge)
    d.ellipse([0, 0, diameter - 1, diameter - 1], fill=GREEN + (255,))
    robot = Image.open(ROBOT).convert("RGBA")
    robot = robot.crop(robot.getbbox())
    target = int(diameter * 0.66)
    rh = int(robot.height * target / robot.width)
    robot = robot.resize((target, rh), Image.LANCZOS)
    bx = (diameter - target) // 2
    by = diameter - rh - int(diameter * 0.06)
    badge.alpha_composite(robot, (bx, max(by, int(diameter * 0.12))))
    badge.putalpha(Image.composite(badge.split()[3], Image.new("L", badge.size, 0),
                                   rounded_mask((diameter, diameter), diameter // 2)))
    return badge


def status_bar(width, height=58):
    bar = Image.new("RGBA", (width, height), STATUSBAR_BG + (255,))
    d = ImageDraw.Draw(bar)
    d.text((38, (height - 30) // 2 - 2), "9:41", font=font(FONT_SB, 30), fill=STATUSBAR_FG)
    x, cy = width - 190, height // 2
    for i in range(4):
        bh = 8 + i * 6
        d.rounded_rectangle([x + i * 15, cy + 10 - bh, x + i * 15 + 10, cy + 10], radius=2, fill=STATUSBAR_FG)
    d.pieslice([x + 78, cy - 12, x + 110, cy + 20], start=225, end=315, fill=STATUSBAR_FG)
    bx = width - 58
    d.rounded_rectangle([bx, cy - 11, bx + 38, cy + 11], radius=5, outline=STATUSBAR_FG, width=3)
    d.rectangle([bx + 4, cy - 6, bx + 30, cy + 6], fill=STATUSBAR_FG)
    d.rounded_rectangle([bx + 39, cy - 5, bx + 43, cy + 5], radius=2, fill=STATUSBAR_FG)
    return bar


def tablet_frame(shot_path):
    screen_w = 1044
    radius = 40
    sb_h = 58
    bezel = 20
    body_col = (22, 25, 29)
    edge_col = (58, 64, 70)
    shot = Image.open(shot_path).convert("RGB")
    sh = int(shot.height * screen_w / shot.width)
    shot = shot.resize((screen_w, sh), Image.LANCZOS)

    inner_h = sb_h + sh
    screen = Image.new("RGBA", (screen_w, inner_h), (0, 0, 0, 0))
    ImageDraw.Draw(screen).rounded_rectangle([0, 0, screen_w - 1, inner_h - 1], radius=radius, fill=(255, 255, 255, 255))
    screen.paste(status_bar(screen_w, sb_h), (0, 0))
    screen.paste(shot, (0, sb_h))
    screen.putalpha(rounded_mask((screen_w, inner_h), radius))

    body_w = screen_w + bezel * 2
    body_h = inner_h + bezel * 2
    body_r = radius + bezel
    m = 8
    cw = body_w + m * 2
    L, R = m, m + body_w
    body = Image.new("RGBA", (cw, body_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle([L, 0, R - 1, body_h - 1], radius=body_r, fill=body_col + (255,))
    bd.rounded_rectangle([L + 5, 5, R - 6, body_h - 6], radius=body_r - 5, outline=edge_col + (255,), width=2)
    # subtle tablet side buttons near the top-right edge (power + volume)
    btn_col, btn_hi = (44, 49, 55), (82, 90, 98)
    bd.rounded_rectangle([R - 3, int(body_h * 0.06), R + 5, int(body_h * 0.06) + 150], radius=3, fill=btn_col)
    bd.rectangle([R - 3, int(body_h * 0.06), R + 5, int(body_h * 0.06) + 3], fill=btn_hi)
    bd.rounded_rectangle([R - 3, int(body_h * 0.20), R + 5, int(body_h * 0.20) + 84], radius=3, fill=btn_col)
    body.alpha_composite(screen, (L + bezel, bezel))
    return body


def render(eyebrow, headline, subtitle, shot_path, out_path):
    canvas = gradient_bg()
    d = ImageDraw.Draw(canvas)
    cx = W // 2

    badge = circle_badge(210)
    canvas.alpha_composite(badge, (cx - badge.width // 2, 130))

    fe = font(FONT_EYEBROW, 36)
    ey_y = 388
    draw_centered(d, cx, ey_y, eyebrow, fe, DEEP_GREEN, tracking=9)
    uy = ey_y + 58
    d.rounded_rectangle([cx - 46, uy, cx + 46, uy + 8], radius=4, fill=GREEN)

    hsize = 100
    fh = font(FONT_HEAD, hsize)
    while max((text_w(d, ln, fh) for ln in wrap(d, headline, fh, W - 200)), default=0) > W - 200 and hsize > 60:
        hsize -= 3
        fh = font(FONT_HEAD, hsize)
    hy = 488
    for ln in wrap(d, headline, fh, W - 200)[:2]:
        draw_centered(d, cx, hy, ln, fh, HEADLINE)
        hy += int(hsize * 1.16)

    fs = font(FONT_SUB, 40)
    sy = hy + 22
    for ln in wrap(d, subtitle, fs, W - 300)[:2]:
        draw_centered(d, cx, sy, ln, fs, SUBTITLE)
        sy += 58

    frame = tablet_frame(shot_path)
    fx = (W - frame.width) // 2
    fy = 980
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    slayer = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    slayer.putalpha(frame.split()[3].point(lambda a: int(a * 0.30)))
    shadow.paste(Image.new("RGBA", frame.size, (14, 34, 10, 255)), (fx, fy + 30), slayer)
    shadow = shadow.filter(ImageFilter.GaussianBlur(38))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(frame, (fx, fy))

    canvas.convert("RGB").save(out_path)
    print("wrote", out_path)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for i, (eyebrow, headline, subtitle) in enumerate(COPY, start=1):
        render(eyebrow, headline, subtitle,
               os.path.join(RAW_DIR, f"{i:02d}.png"),
               os.path.join(OUT_DIR, f"{i:02d}.png"))


if __name__ == "__main__":
    main()
