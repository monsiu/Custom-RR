#!/usr/bin/env python3
"""Fetch brand logos for device-catalog cards from Wikimedia Commons.

Many manufacturer cards (especially the ones the TWRP roster introduced) fall
back to the generic ``images/branding.png`` placeholder because they have no
tailored asset. This tool searches Wikimedia Commons for each brand's logo,
picks the best candidate with a small scoring heuristic, and downloads a
512px-wide PNG render to ``images/device_<slug>.png``.

Why Commons logos: files on Commons carry a free/PD license (brand wordmarks
are typically uploaded as {{PD-textlogo}}), which is the most defensible
source to reuse, and the project already hot-links Commons for screenshots.

Run with:

    python3 tool/fetch_brand_logos.py            # fetch all
    python3 tool/fetch_brand_logos.py Tecno Vivo  # fetch a subset

This is a convenience helper, not a deterministic generator: re-running may
pick a slightly different file if Commons search results change. The committed
PNGs are the source of truth. After fetching, register each new asset in
``pubspec.yaml`` and ``tool/sync_catalog.dart``'s ``assetMap``, then regenerate
``assets/catalog.json``.
"""

import json
import sys
import urllib.parse
import urllib.request

API = "https://commons.wikimedia.org/w/api.php"
UA = "custom-rr-catalog/1.0 (https://github.com/monsiu/Custom-RR; contactmonsiu@gmail.com)"
THUMB_WIDTH = 512

# brand display name -> (slug, search query[, explicit tokens]). The display
# name must match the catalog's vendor name exactly. A title is only eligible
# if it contains one of the tokens (defaults to words from the display name);
# set explicit tokens when the best logo file is named after a sub-brand
# (e.g. Huami ships under "Amazfit", Cat phones under "Caterpillar").
#
# This script only covers brands whose logo lives on Wikimedia Commons. A few
# brands have NO usable Commons logo and were instead sourced by hand from
# their official site / web archive (see images/device_*.png): Elephone,
# Hyundai (Hyundai Technology), Minix, Mobvoi, Planet (Planet Computers), and
# Zinwa. TWRP is intentionally skipped (it lists its own test devices under
# /Devices/TWRP/ but is not a phone manufacturer). The remaining placeholders
# (Ergo, IUNI, Omate, Vanzo) have no cleanly-sourced logo anywhere.
BRANDS = {
    "Alcatel": ("alcatel", "Alcatel logo"),
    "Allview": ("allview", "Allview logo"),
    "Amazon": ("amazon", "Amazon logo"),
    "Amlogic": ("amlogic", "Amlogic logo"),
    "Archos": ("archos", "Archos logo"),
    "Barnes & Noble": ("barnes_noble", "Barnes Noble logo"),
    "Cat": ("cat", "Caterpillar Inc logo", ["caterpillar"]),
    "Dell": ("dell", "Dell logo"),
    "Elephone": ("elephone", "Elephone logo"),
    "Ergo": ("ergo", "Ergo phone logo"),
    "Gigaset": ("gigaset", "Gigaset logo"),
    "HP": ("hp", "HP logo"),
    "Huami": ("huami", "Amazfit logo", ["amazfit"]),
    "Infinix": ("infinix", "Infinix logo"),
    "Itel": ("itel", "Itel mobile logo"),
    "Kazam": ("kazam", "Kazam logo"),
    "Kyocera": ("kyocera", "Kyocera logo"),
    "Letv": ("letv", "Letv logo"),
    "Lyf": ("lyf", "Lyf logo"),
    "Marshall": ("marshall", "Marshall amplification logo"),
    "Mattel": ("mattel", "Mattel logo"),
    "Meizu": ("meizu", "Meizu logo"),
    "Micromax": ("micromax", "Micromax logo"),
    "Mobvoi": ("mobvoi", "Mobvoi logo"),
    "Omate": ("omate", "Omate logo"),
    "Oukitel": ("oukitel", "Oukitel logo"),
    "Pantech": ("pantech", "Pantech logo"),
    "Planet": ("planet", "Planet Computers logo", ["planet computers"]),
    "Qualcomm": ("qualcomm", "Qualcomm logo"),
    "Quanta": ("quanta", "Quanta Computer logo"),
    "Silentcircle": ("silentcircle", "Silent Circle logo", ["silent circle"]),
    "Tecno": ("tecno", "Tecno Mobile logo"),
    "Ulefone": ("ulefone", "Ulefone logo"),
    "Umidigi": ("umidigi", "Umidigi logo"),
    "Unihertz": ("unihertz", "Unihertz logo"),
    "Vanzo": ("vanzo", "Vanzo logo"),
    "Vestel": ("vestel", "Vestel logo"),
    "Vivo": ("vivo", "Vivo electronics logo"),
    "Zinwa": ("zinwa", "Zinwa logo"),
}

# Substrings that signal a file is NOT a clean wordmark logo for this brand.
NOISE = (
    "deletion",
    "riaa",
    "guinea",
    "android 16",
    "screenshot",
    "building",
    "store",
    "splash",
    "assemblea",
    "poster",
    "advert",
    "box art",
    "packaging",
    "award",
    "stadium",
    "jersey",
    "wia",  # Hyundai Wia (auto parts), not Hyundai mobile
    "mobis",  # Hyundai Mobis (auto parts), not Hyundai mobile
    "oilbank",  # Hyundai Oilbank, not Hyundai mobile
    "libre",  # LibrePlanet (FSF), not Planet Computers
    "instituto",  # IUNIS university, not IUNI phones
    "university",
    "universitario",
    "minix3",  # the MINIX 3 OS, not the Minix device brand
    "operating system",
)


def _get(url):
    req = urllib.request.Request(url, headers={"User-Agent": UA})
    with urllib.request.urlopen(req, timeout=30) as resp:
        return resp.read()


def search_candidates(query):
    params = {
        "action": "query",
        "format": "json",
        "generator": "search",
        "gsrsearch": query,
        "gsrnamespace": "6",  # File:
        "gsrlimit": "12",
        "prop": "imageinfo",
        "iiprop": "url|extmetadata",
        "iiurlwidth": str(THUMB_WIDTH),
        "iiextmetadatafilter": "LicenseShortName",
    }
    url = API + "?" + urllib.parse.urlencode(params)
    data = json.loads(_get(url))
    return list(data.get("query", {}).get("pages", {}).values())


def score(title, tokens):
    t = title.lower()
    if not any(tok in t for tok in tokens):
        return -999
    if t.endswith(".svg"):
        s = 5
    elif t.endswith(".png"):
        s = 3
    elif t.endswith((".jpg", ".jpeg")):
        s = 1
    else:
        return -999  # gif/webp/pdf etc.
    if "logo" in t:
        s += 6
    for bad in NOISE:
        if bad in t:
            s -= 10
    s -= 0.03 * len(t)
    return s


def pick(pages, tokens):
    best = None
    best_score = -998
    for p in pages:
        ii = p.get("imageinfo")
        if not ii:
            continue
        sc = score(p["title"], tokens)
        if sc > best_score:
            best_score = sc
            best = p
    return best if best_score > 0 else None


def main(argv):
    wanted = set(argv[1:])
    report = []
    for display, spec in BRANDS.items():
        slug, query = spec[0], spec[1]
        explicit = spec[2] if len(spec) > 2 else None
        if wanted and display not in wanted and slug not in wanted:
            continue
        if explicit:
            tokens = [t.lower() for t in explicit]
        else:
            tokens = [
                w
                for w in display.lower().replace("&", " ").split()
                if len(w) > 2
            ]
            if not tokens:
                tokens = [display.lower()]
        try:
            pages = search_candidates(query)
        except Exception as e:  # noqa: BLE001
            report.append((display, "SEARCH-FAIL", str(e)))
            continue
        chosen = pick(pages, tokens)
        if not chosen:
            report.append((display, "NO-MATCH", query))
            continue
        ii = chosen["imageinfo"][0]
        thumb = ii.get("thumburl") or ii.get("url")
        lic = (
            ii.get("extmetadata", {})
            .get("LicenseShortName", {})
            .get("value", "?")
        )
        out = f"images/device_{slug}.png"
        try:
            data = _get(thumb)
            with open(out, "wb") as fh:
                fh.write(data)
            report.append(
                (display, "OK", f"{chosen['title']} [{lic}] -> {out}")
            )
        except Exception as e:  # noqa: BLE001
            report.append((display, "DL-FAIL", str(e)))

    print("\n=== brand logo fetch report ===")
    ok = 0
    for display, status, detail in report:
        if status == "OK":
            ok += 1
        print(f"  [{status:9}] {display:16} {detail}")
    print(f"\n{ok}/{len(report)} fetched")


if __name__ == "__main__":
    main(sys.argv)
