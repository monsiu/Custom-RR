#!/usr/bin/env python3
"""Generate reply drafts for the already-covered / near-miss backlog issues."""
import json, subprocess, textwrap

issues = {it['number']: it for it in json.load(open('/tmp/crr-issues.json'))}

def match(n):
    it = issues[n]
    out = subprocess.run(['node', 'tool/catalog_match.mjs', it['title'], it.get('body') or ''],
                         capture_output=True, text=True, cwd='/home/monsiu/Custom-RR')
    return json.loads(out.stdout)

def entry_lists(m):
    roms = [x['name'] for x in m['matches'] if x['kind'] == 'roms']
    recs = [x['name'] for x in m['matches'] if x['kind'] == 'recoveries']
    lines = []
    if roms: lines.append(f"**ROMs:** {', '.join(roms)}")
    if recs: lines.append(f"**Recoveries:** {', '.join(recs)}")
    return lines

def covered(n, codename, note=''):
    m = match(n)
    dev = m['matches'][0]['device'] if m['matches'] else codename
    body = [
        "Hey, thanks for the request! 🙏 Good news: this device is **already in the catalog** — it is listed as `" + dev + "`.",
        "",
        "It is covered by:",
    ] + ['- ' + l for l in entry_lists(m)] + [
        "",
        f"In the app, open **Find my phone** and search for the codename `{codename}` (device lists use the codename, so marketing-name searches sometimes miss it). Each ROM/recovery card shows its supported-device list.",
    ]
    if note: body += ["", note]
    body += ["", "Closing as already covered — if you meant a different variant that reports another codename, reply here and we will take another look. 👍"]
    return dict(n=n, action='comment+label already-covered+close (completed)', text='\n'.join(body))

def manual(n, text, action):
    return dict(n=n, action=action, text=textwrap.dedent(text).strip())

drafts = []

# ---- truly covered (strong codename match) ----
drafts.append(covered(201, 'dodge'))
drafts.append(covered(178, 'lisa'))
drafts.append(covered(167, 'kebab'))
drafts.append(covered(157, 'lemonade'))
drafts.append(covered(166, 'benz'))
drafts.append(covered(129, 'frankel',
    note="Note GrapheneOS installs on Pixels via their official web installer — no custom recovery needed."))

# #174 duplicate of #167 (OnePlus 8T, no codename given)
m167 = match(167)
drafts.append(dict(n=174, action='comment+label already-covered+close (completed)', text='\n'.join([
    "Hey, thanks for the request! \U0001f64f Good news: the OnePlus 8T is **already in the catalog** under its codename `kebab` \u2014 listed as `" + m167['matches'][0]['device'] + "`.",
    "",
    "It is covered by:",
] + ['- ' + l for l in entry_lists(m167)] + [
    "",
    "In the app, open **Find my phone** and search `kebab`. Closing as already covered (same device as #167). \U0001f44d",
])))

# ---- honest "not covered" with nearest sibling / guidance ----
drafts.append(manual(208, """
    Hey, thanks for the detailed request! 🙏 An honest status check: the **Redmi Note 14 5G (`tanzanite`)** has no dedicated entry in the catalog yet. The closest match we list is the **POCO X7 / Redmi Note 14 Pro 5G (`malachite`)** under LineageOS — that is a *different* model, so please don't flash malachite builds on tanzanite.

    What you can do today: tanzanite has an active unofficial scene on XDA (the **Search XDA** button on your device card runs that search), and as a Treble device it can run a **GSI** — see the **Treble & GSI** tab in the app for how to pick the right image.

    We'll keep an eye on tanzanite and add it once a maintained build lands. Leaving this open as a catalog gap. 👍
    """, 'comment (stay open, catalog gap)'))

drafts.append(manual(156, """
    Duplicate of #208 (same device, `tanzanite`) — tracking it there. Short version: no dedicated build in the catalog yet; the malachite entry you may find is the Note 14 **Pro**, a different model. See #208 for the GSI/XDA route in the meantime. 👍
    """, 'comment+close (duplicate of #208)'))

for n in (150, 163, 195):
    lines = [
        "Hey, thanks for the request! \U0001f64f An honest status check: the **moto g stylus 5G 2024 (`boston`)** has no dedicated entry in the catalog yet. We do list its 2023 sibling (`genevn`), but those builds are **not** compatible with boston.",
        "",
    ]
    if n != 150:
        lines += ["Also tracked in #150 for the same device.", ""]
    lines += [
        "What you can do today: check XDA for early boston work (the **Search XDA** button on your device card runs that search), and since it's a Treble device a **GSI** will run \u2014 the **Treble & GSI** tab in the app walks you through picking the right image.",
        "",
        "We'll add boston once a maintained build lands. \U0001f44d",
    ]
    action = 'comment (stay open, catalog gap)' if n == 150 else 'comment+close (duplicate of #150)'
    drafts.append(dict(n=n, action=action, text='\n'.join(lines)))

drafts.append(manual(196, """
    Hey, thanks for the request! 🙏 Careful one: the catalog lists `cancunf` (moto g54/g64) — that is **not** the Moto G14 (`cancun`), despite the similar codename, so don't flash cancunf builds.

    For the G14 itself there is no dedicated maintained ROM in the catalog yet. It's a Treble device, so a **GSI** is the practical route today — see the **Treble & GSI** tab, and the **Search XDA** button on your device card for unofficial builds.

    We'll add cancun once a maintained build lands. 👍
    """, 'comment (stay open, catalog gap)'))

drafts.append(manual(158, """
    Hey! The Pixel 6 Pro (`raven`) is well covered in the catalog on the ROM side (LineageOS, crDroid, GrapheneOS, CalyxOS and more — search `raven` in **Find my phone**).

    On the PitchBlack question specifically: PBRP does not ship a raven build, and modern Pixels generally don't use custom recoveries at all — ROMs install via `fastboot` or the ROM's own web installer, and that is the supported path for every raven ROM we list. So there is nothing missing to add here.

    Closing as answered — the ROMs you can flash are already in the app. 👍
    """, 'comment+close (answered)'))

out = []
for d in drafts:
    out.append(f"{'='*70}\nISSUE #{d['n']} — ACTION: {d['action']}\n{'-'*70}\n{d['text']}\n")
open('/tmp/crr-drafts.txt', 'w').write('\n'.join(out))
print(f"wrote {len(drafts)} drafts to /tmp/crr-drafts.txt")
