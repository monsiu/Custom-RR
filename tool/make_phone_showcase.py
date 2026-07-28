#!/usr/bin/env python3
"""Generate LIGHT-MODE branded phone screenshots for Custom RR.

Keeps the existing showcase design (green robot badge, mono eyebrow with a
green underline, serif headline, subtitle, and the app screenshot in a
rounded phone frame) but flips it to a LIGHT theme: a light green gradient
background, dark text, and light-mode app captures.

Raw LIGHT app captures live in RAW_DIR (portrait). Output is 1080x1920 PNGs
(the Play phone screenshot size), written to OUT_DIR. This writes to a PREVIEW
dir; rollout to fastlane/zapstore/etc. is a separate, deliberate step.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFilter, ImageFont

W, H = 1080, 1920
RAW_DIR = "/tmp/light-phone-raw"
OUT_DIR = "/tmp/light-phone-preview"
ROBOT = "/home/monsiu/Custom-RR/images/generated/launcher_full.png"

F = "/usr/share/fonts/TTF"
FONT_EYEBROW = f"{F}/JetBrainsMonoNerdFont-Bold.ttf"
FONT_HEAD = f"{F}/RobotoSlab-Bold.ttf"
FONT_SUB = f"{F}/DejaVuSans.ttf"
FONT_SB = f"{F}/DejaVuSans-Bold.ttf"

# Light Custom RR palette.
BG_TOP = (233, 246, 224)      # soft green
BG_BOTTOM = (246, 251, 242)   # near-white green
GREEN = (126, 217, 87)        # brand #7ED957
DEEP_GREEN = (53, 107, 35)    # eyebrow / underline
HEADLINE = (16, 36, 14)       # near-black green
SUBTITLE = (76, 94, 68)
FRAME_BEZEL = (255, 255, 255)
STATUSBAR_BG = (246, 249, 243)
STATUSBAR_FG = (40, 52, 36)

# eyebrow, headline, subtitle  (matches the current dark set verbatim)
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


def circle_badge(diameter=156):
    badge = Image.new("RGBA", (diameter, diameter), (0, 0, 0, 0))
    d = ImageDraw.Draw(badge)
    d.ellipse([0, 0, diameter - 1, diameter - 1], fill=GREEN + (255,))
    # robot (trim to the shape, fit inside the circle)
    robot = Image.open(ROBOT).convert("RGBA")
    bbox = robot.getbbox()
    robot = robot.crop(bbox)
    target = int(diameter * 0.66)
    rw = target
    rh = int(robot.height * target / robot.width)
    robot = robot.resize((rw, rh), Image.LANCZOS)
    # place centered horizontally, sitting a touch low (bust hugs bottom of circle)
    bx = (diameter - rw) // 2
    by = diameter - rh - int(diameter * 0.06)
    badge.alpha_composite(robot, (bx, max(by, int(diameter * 0.12))))
    # clip to circle so the bust does not spill past the badge
    badge.putalpha(Image.composite(badge.split()[3], Image.new("L", badge.size, 0),
                                   rounded_mask((diameter, diameter), diameter // 2)))
    return badge


def status_bar(width, height=46):
    bar = Image.new("RGBA", (width, height), STATUSBAR_BG + (255,))
    d = ImageDraw.Draw(bar)
    ft = font(FONT_SB, 24)
    d.text((28, (height - 24) // 2 - 2), "9:41", font=ft, fill=STATUSBAR_FG)
    # right cluster: signal bars, wifi dot, battery
    x = width - 150
    cy = height // 2
    for i in range(4):
        bh = 6 + i * 5
        d.rounded_rectangle([x + i * 12, cy + 8 - bh, x + i * 12 + 8, cy + 8], radius=2, fill=STATUSBAR_FG)
    # wifi (simple arc-ish triangle)
    wx = x + 62
    d.pieslice([wx, cy - 10, wx + 26, cy + 16], start=225, end=315, fill=STATUSBAR_FG)
    # battery
    bx = width - 46
    d.rounded_rectangle([bx, cy - 9, bx + 30, cy + 9], radius=4, outline=STATUSBAR_FG, width=2)
    d.rectangle([bx + 3, cy - 5, bx + 23, cy + 5], fill=STATUSBAR_FG)
    d.rounded_rectangle([bx + 31, cy - 4, bx + 34, cy + 4], radius=2, fill=STATUSBAR_FG)
    return bar


def phone_frame(shot_path):
    screen_w = 744
    radius = 42
    sb_h = 46
    bezel = 18            # phone-body thickness around the screen
    body_col = (22, 25, 29)     # charcoal phone body
    edge_col = (58, 64, 70)     # subtle inner rim highlight
    shot = Image.open(shot_path).convert("RGB")
    sh = int(shot.height * screen_w / shot.width)
    shot = shot.resize((screen_w, sh), Image.LANCZOS)

    inner_h = sb_h + sh
    # the screen: white rounded panel + status bar + app shot
    screen = Image.new("RGBA", (screen_w, inner_h), (0, 0, 0, 0))
    ImageDraw.Draw(screen).rounded_rectangle([0, 0, screen_w - 1, inner_h - 1], radius=radius, fill=(255, 255, 255, 255))
    screen.paste(status_bar(screen_w, sb_h), (0, 0))
    screen.paste(shot, (0, sb_h))
    screen.putalpha(rounded_mask((screen_w, inner_h), radius))

    # the phone body (bezel) around the screen; bottom bleeds off the canvas.
    # A small horizontal margin leaves room for protruding side buttons.
    body_w = screen_w + bezel * 2
    body_h = inner_h + bezel * 2
    body_r = radius + bezel
    m = 8
    cw = body_w + m * 2
    L, R = m, m + body_w
    body = Image.new("RGBA", (cw, body_h), (0, 0, 0, 0))
    bd = ImageDraw.Draw(body)
    bd.rounded_rectangle([L, 0, R - 1, body_h - 1], radius=body_r, fill=body_col + (255,))
    # thin lighter rim just inside the body edge for a metallic look
    bd.rounded_rectangle([L + 4, 4, R - 5, body_h - 5], radius=body_r - 4, outline=edge_col + (255,), width=2)
    # side buttons (raised metallic bars protruding from the body edges)
    btn_col = (44, 49, 55)
    btn_hi = (82, 90, 98)
    # right: power / lock button
    py, pl = int(body_h * 0.27), 84
    bd.rounded_rectangle([R - 3, py, R + 5, py + pl], radius=3, fill=btn_col)
    bd.rectangle([R - 3, py, R + 5, py + 3], fill=btn_hi)
    # left: volume rocker (long)
    vy, vl = int(body_h * 0.16), 224
    bd.rounded_rectangle([L - 5, vy, L + 3, vy + vl], radius=3, fill=btn_col)
    bd.rectangle([L - 5, vy, L + 3, vy + 3], fill=btn_hi)
    body.alpha_composite(screen, (L + bezel, bezel))
    return body


def render(idx, eyebrow, headline, subtitle, shot_path, out_path):
    canvas = gradient_bg()
    d = ImageDraw.Draw(canvas)
    cx = W // 2

    # green circle robot badge
    badge = circle_badge(156)
    # soft shadow under badge
    sh = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh.alpha_composite(Image.new("RGBA", badge.size, (30, 70, 20, 90)), (cx - badge.width // 2, 104))
    sh.putalpha(sh.split()[3])
    canvas.alpha_composite(canvas)  # no-op keep
    canvas.alpha_composite(badge, (cx - badge.width // 2, 92))

    # eyebrow + underline
    fe = font(FONT_EYEBROW, 27)
    ey_y = 286
    draw_centered(d, cx, ey_y, eyebrow, fe, DEEP_GREEN, tracking=7)
    ew = text_w(d, eyebrow, fe, 7)
    uy = ey_y + 44
    d.rounded_rectangle([cx - 34, uy, cx + 34, uy + 6], radius=3, fill=GREEN)

    # headline (auto-fit, wrap to 2 lines)
    hsize = 74
    fh = font(FONT_HEAD, hsize)
    while max((text_w(d, ln, fh) for ln in wrap(d, headline, fh, W - 150)), default=0) > W - 150 and hsize > 44:
        hsize -= 2
        fh = font(FONT_HEAD, hsize)
    hlines = wrap(d, headline, fh, W - 150)[:2]
    hy = 360
    for ln in hlines:
        draw_centered(d, cx, hy, ln, fh, HEADLINE)
        hy += int(hsize * 1.16)

    # subtitle
    fs = font(FONT_SUB, 30)
    sy = hy + 18
    for ln in wrap(d, subtitle, fs, W - 220)[:2]:
        draw_centered(d, cx, sy, ln, fs, SUBTITLE)
        sy += 44

    # phone frame with drop shadow
    frame = phone_frame(shot_path)
    fx = (W - frame.width) // 2
    fy = 726
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    slayer = Image.new("RGBA", frame.size, (0, 0, 0, 0))
    slayer.putalpha(frame.split()[3].point(lambda a: int(a * 0.30)))
    shadow.paste(Image.new("RGBA", frame.size, (14, 34, 10, 255)), (fx, fy + 22), slayer)
    shadow = shadow.filter(ImageFilter.GaussianBlur(30))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(frame, (fx, fy))

    canvas.convert("RGB").save(out_path)
    print("wrote", out_path)


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for i, (eyebrow, headline, subtitle) in enumerate(COPY, start=1):
        shot = os.path.join(RAW_DIR, f"{i:02d}.png")
        out = os.path.join(OUT_DIR, f"{i:02d}.png")
        render(i, eyebrow, headline, subtitle, shot, out)


if __name__ == "__main__":
    main()
