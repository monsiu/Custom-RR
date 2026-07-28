#!/usr/bin/env python3
"""Generate Microsoft Store screenshots for Custom RR.

Same method as the Play-store showcase generator: a branded 1920x1080
landscape card with an eyebrow label, a headline, a subtitle, and the real
app screenshot framed in a native Windows window-chrome mockup.

Custom RR green scheme, LIGHT mode (per user preference: MS Store shots are
always light mode). Mirrors the ClauseShift msstore reference layout.

Raw light-mode app captures live in RAW_DIR (1920x1080 each). Outputs to
OUT_DIR as 01..06.png, 1920x1080, which is an accepted MS Store screenshot
size.
"""

from __future__ import annotations

import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

W, H = 1920, 1080
RAW_DIR = "/tmp/crr-light-shots"
OUT_DIR = "/home/monsiu/Custom-RR/screenshots/msstore"
ICON = "/home/monsiu/Custom-RR/images/generated/launcher_full.png"
ICON_FG = "/home/monsiu/Custom-RR/images/generated/launcher_adaptive_fg.png"

F = "/usr/share/fonts/TTF"
FONT_EYEBROW = f"{F}/JetBrainsMonoNerdFont-Bold.ttf"
FONT_HEAD = f"{F}/RobotoSlab-Bold.ttf"
FONT_SUB = f"{F}/DejaVuSans.ttf"
FONT_UI = f"{F}/DejaVuSans.ttf"

# Custom RR green light palette.
BG_TOP = (247, 251, 243)
BG_BOTTOM = (230, 244, 221)
ACCENT = (69, 119, 48)       # brand dark green
EYEBROW = (60, 104, 42)
HEADLINE = (12, 33, 16)      # onSeed-ish near-black green
SUBTITLE = (74, 92, 68)
TITLEBAR = (241, 244, 238)
TITLEBAR_LINE = (223, 228, 219)
WIN_TITLE = (58, 68, 54)
WIN_CTRL = (120, 130, 116)

# eyebrow, headline, subtitle
COPY = [
    ("ONE HOME FOR EVERY ROM",
     "Custom ROMs, recoveries & GSIs",
     "A single catalog of popular Android custom ROMs and recoveries, with links, screenshots and flashing guides."),
    ("BROWSE THE CATALOG",
     "Every major ROM in one place",
     "LineageOS, crDroid, Pixel Experience, Evolution X and more, each with freshness signals and download links."),
    ("KNOW BEFORE YOU FLASH",
     "Deep detail on every build",
     "Supported devices, key features, screenshots and direct downloads, plus the XDA threads for each project."),
    ("RECOVERIES, SORTED",
     "TWRP, OrangeFox & friends",
     "Find the right custom recovery for your device, from the projects that actually support it."),
    ("FIND YOUR PHONE",
     "Hundreds of devices & brands",
     "Search by brand, model or codename to see exactly what ROMs and recoveries your device can run."),
    ("TREBLE & GSIs",
     "Generic images, explained",
     "Check if your device is Treble-compatible and pick the right GSI variant, with a plain-English guide."),
]


def font(path: str, size: int) -> ImageFont.FreeTypeFont:
    return ImageFont.truetype(path, size)


def text_w(draw, text, fnt, tracking=0.0) -> float:
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
    words = text.split()
    lines, cur = [], ""
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


def gradient_bg() -> Image.Image:
    base = Image.new("RGB", (W, H), BG_TOP)
    top = Image.new("RGB", (1, H), 0)
    for y in range(H):
        t = y / (H - 1)
        top.putpixel((0, y), tuple(
            int(BG_TOP[i] + (BG_BOTTOM[i] - BG_TOP[i]) * t) for i in range(3)))
    base = top.resize((W, H))
    return base.convert("RGBA")


def add_watermark(canvas):
    mark = Image.open(ICON_FG).convert("RGBA")
    size = 760
    mark = mark.resize((size, size), Image.LANCZOS).rotate(-18, expand=True, resample=Image.BICUBIC)
    alpha = mark.split()[3].point(lambda a: int(a * 0.05))
    mark.putalpha(alpha)
    canvas.alpha_composite(mark, (W - int(size * 0.72), H - int(size * 0.62)))


def rounded_mask(size, radius):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rounded_rectangle([0, 0, size[0] - 1, size[1] - 1], radius=radius, fill=255)
    return m


def window(shot_path):
    win_w = 1200
    radius = 18
    title_h = 58
    shot = Image.open(shot_path).convert("RGB")
    sh = int(win_w * shot.height / shot.width)
    shot = shot.resize((win_w, sh), Image.LANCZOS)
    win_h = title_h + sh

    win = Image.new("RGBA", (win_w, win_h), (0, 0, 0, 0))
    d = ImageDraw.Draw(win)
    # white body
    d.rounded_rectangle([0, 0, win_w - 1, win_h - 1], radius=radius, fill=(255, 255, 255, 255))
    # title bar (top corners rounded, bottom square)
    d.rounded_rectangle([0, 0, win_w - 1, title_h + radius], radius=radius, fill=TITLEBAR + (255,))
    d.rectangle([0, title_h - 1, win_w - 1, title_h + radius], fill=TITLEBAR + (255,))
    d.line([0, title_h, win_w - 1, title_h], fill=TITLEBAR_LINE + (255,), width=2)

    # app icon + title
    ic = Image.open(ICON).convert("RGBA").resize((32, 32), Image.LANCZOS)
    ic_mask = rounded_mask((32, 32), 8)
    win.paste(ic, (22, (title_h - 32) // 2), ic_mask)
    fui = font(FONT_UI, 22)
    d.text((66, (title_h - 26) // 2), "Custom RR", font=fui, fill=WIN_TITLE)

    # window controls: minimize, maximize, close
    cy = title_h // 2
    x_min = win_w - 150
    d.line([x_min, cy, x_min + 22, cy], fill=WIN_CTRL, width=2)
    x_max = win_w - 100
    d.rounded_rectangle([x_max, cy - 10, x_max + 20, cy + 10], radius=3, outline=WIN_CTRL, width=2)
    x_cl = win_w - 46
    d.line([x_cl, cy - 10, x_cl + 20, cy + 10], fill=WIN_CTRL, width=2)
    d.line([x_cl, cy + 10, x_cl + 20, cy - 10], fill=WIN_CTRL, width=2)

    # screenshot below title bar
    win.paste(shot, (0, title_h))

    # round the whole window
    win.putalpha(rounded_mask((win_w, win_h), radius))
    return win


def render(idx, eyebrow, headline, subtitle, shot_path, out_path):
    canvas = gradient_bg()
    add_watermark(canvas)
    d = ImageDraw.Draw(canvas)
    cx = W // 2

    # accent bar
    bar_w, bar_h, bar_y = 66, 6, 84
    d.rounded_rectangle([cx - bar_w // 2, bar_y, cx + bar_w // 2, bar_y + bar_h],
                        radius=3, fill=ACCENT)

    # eyebrow (letter-spaced mono)
    fe = font(FONT_EYEBROW, 30)
    draw_centered(d, cx, 108, eyebrow, fe, EYEBROW, tracking=8)

    # headline (auto-fit)
    hsize = 82
    fh = font(FONT_HEAD, hsize)
    while text_w(d, headline, fh) > W - 260 and hsize > 40:
        hsize -= 2
        fh = font(FONT_HEAD, hsize)
    hy = 152
    draw_centered(d, cx, hy, headline, fh, HEADLINE)
    hb = fh.getbbox(headline)
    head_bottom = hy + (hb[3] - hb[1]) + 8

    # subtitle (wrap, max 2 lines)
    fs = font(FONT_SUB, 33)
    lines = wrap(d, subtitle, fs, 1360)[:2]
    sy = head_bottom + 26
    for ln in lines:
        draw_centered(d, cx, sy, ln, fs, SUBTITLE)
        sy += 46

    # window mockup with drop shadow
    win = window(shot_path)
    win_x = (W - win.width) // 2
    win_y = 432

    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sh_layer = Image.new("RGBA", win.size, (0, 0, 0, 0))
    sh_mask = win.split()[3].point(lambda a: int(a * 0.28))
    sh_layer.putalpha(sh_mask)
    shadow.paste(Image.new("RGBA", win.size, (14, 30, 10, 255)), (win_x, win_y + 20), sh_layer)
    shadow = shadow.filter(ImageFilter.GaussianBlur(26))
    canvas.alpha_composite(shadow)
    canvas.alpha_composite(win, (win_x, win_y))

    canvas.convert("RGB").save(out_path)
    print(f"wrote {out_path}")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    for i, (eyebrow, headline, subtitle) in enumerate(COPY, start=1):
        shot = os.path.join(RAW_DIR, f"{i:02d}.png")
        out = os.path.join(OUT_DIR, f"{i:02d}.png")
        render(i, eyebrow, headline, subtitle, shot, out)


if __name__ == "__main__":
    main()
