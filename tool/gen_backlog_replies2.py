#!/usr/bin/env python3
"""Draft replies for the remaining open Custom RR request backlog.

Reads /tmp/crr-open2.json (gh issue list dump), buckets the issues, and writes
per-issue drafts to /tmp/crr-drafts2.txt plus /tmp/crr-drafts2.json for the
poster. Nothing is published from here.
"""
import json, re

issues = {it['number']: it for it in json.load(open('/tmp/crr-open2.json'))}

# Codename -> friendly name, from the bundled Play device dictionary. Lets a
# reply name the requester's phone even when nothing builds for it.
try:
    _index = json.load(open('/home/monsiu/Custom-RR/assets/device_index.json'))
except Exception:
    _index = {}


def device_label(codename):
    e = _index.get((codename or '').lower())
    if not e:
        return ''
    label = ' '.join(x for x in (e.get('b', ''), e.get('n', '')) if x).strip()
    models = e.get('m') or []
    if label and models:
        return f"{label} ({models[0]})"
    return label

PLAY_URL = 'https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr'
REVIEW_CTA = (
    "If Custom RR helped you out, a quick rating on Google Play goes a long way "
    "and helps other people find the app: " + PLAY_URL
)


def field(body, name):
    m = re.search(r'###\s*' + name + r'\s*\n+([^\n#]+)', body or '', re.I)
    v = m.group(1).strip() if m else ''
    return '' if v == '_No response_' else v


def codename_of(it):
    """Best codename for an issue, preferring one the device dictionary knows.

    People often type something in the Codename field that disagrees with the
    codename in the title, so try both and keep whichever we can actually
    resolve to a real device.
    """
    m = re.search(r'\(([a-z0-9_.-]{3,})\)', it['title'], re.I)
    candidates = [
        field(it.get('body') or '', 'Codename').strip(),
        (m.group(1).strip() if m else ''),
    ]
    candidates = [c for c in candidates if c]
    for c in candidates:
        if c.lower() in _index:
            return c
    return candidates[0] if candidates else ''


drafts = []


def add(n, action, lines):
    drafts.append(dict(n=n, action=action, text='\n'.join(lines).strip()))


# ---------------------------------------------------------------- individual
# #198 (One UI 8 bootloader unlock) is handled: Martin answered it himself and
# it is closed not-planned, so no draft is generated for it.

add(184, 'comment + close (needs info)', [
    "Hey! This one came through with an empty form, so there is nothing here for us to act on.",
    "",
    "Root solutions are already in the app under the **Root** section: Magisk, KernelSU, KernelSU Next, APatch and SukiSU, each with what it is, how it differs, and where to download it. Whether any of them work for you depends entirely on your specific phone and whether its bootloader can be unlocked.",
    "",
    "If you were asking for something more specific, open a new issue and tell us your brand, model, and codename, plus what you have already tried. Closing this one for now. \U0001f44d",
])

add(224, 'comment (stay open, needs a real source)', [
    "Hey, thanks for the suggestion! To add a GSI to the catalog we need a real source we can point users at, and the link here came through as `httpsGitHub.com`, which does not resolve.",
    "",
    "Could you drop the actual link to the project, ideally the page where its releases are published? What we look for before listing anything:",
    "",
    "- A working download or releases page that is publicly reachable.",
    "- Builds that are actually maintained, not a single upload from a while back.",
    "- Some idea of which Android version and Treble variant (arm64 a/b, a-only, vndklite) the images target.",
    "",
    "With that we can take a proper look. In the meantime, the **Treble & GSI** tab in the app covers how to check which GSI variant your phone takes and where the established images live. Leaving this open until you can share the link. \U0001f44d",
])

# ------------------------------------------------------------------ bulk sets
EMPTY_NEEDS_INFO = [228, 215, 209, 203, 191, 180, 155, 231, 222, 218, 223, 227, 199, 165, 162]

for n in EMPTY_NEEDS_INFO:
    if n not in issues:
        continue
    title = issues[n]['title']
    add(n, 'comment + close (needs info)', [
        "Hey, thanks for reaching out! Unfortunately this came through without enough information for us to do anything with it: we need to know exactly which phone you have before we can tell you what exists for it.",
        "",
        "If you would like us to look into it, open a new issue using the request form and fill in at least:",
        "",
        "- **Brand and model**, for example Samsung Galaxy A52 5G.",
        "- **Codename** if you know it, for example `a52xq`. Settings, the LineageOS wiki, or a Treble info app will tell you.",
        "- Whether **OEM unlocking** is available on your device, since nothing can be flashed without it.",
        "",
        "One tip that solves a lot of these straight away: many phones are listed in the catalog under a family or sibling codename rather than the one your phone reports, so search the model name in **Find my phone** in the app first. Closing this for now, and no hard feelings, just open a fresh one with the details. \U0001f44d",
    ])

# Devices that have a codename but no maintained build in the catalog. The bot
# handles this automatically for new issues; these predate it.
# #188 a55x, #171 topaz, #169 duchamp and #168 dm3q used to be here. Reading
# real upstream rosters showed they ARE supported, so upstream-device-watch.yml
# answers those instead.
NO_BUILD = [229, 225, 221, 219, 216, 212, 211, 210, 206, 204, 202, 200, 197,
            192, 189, 187, 182, 181, 179, 177, 175, 173, 170, 164, 161, 154,
            151, 149]

for n in NO_BUILD:
    if n not in issues:
        continue
    cn = codename_of(issues[n])
    label = device_label(cn)
    if label and cn:
        who = f'your **{label}**, codename `{cn}`,'
    elif cn:
        who = f'your device (`{cn}`)'
    else:
        who = 'your device'
    add(n, 'comment (stay open, tracked gap)', [
        f"Hey, thanks for the request! \U0001f64f Honest status check: {who} does not have a maintained custom ROM or recovery that we can list yet, so there is nothing for us to add today rather than something we are ignoring.",
        "",
        "That is normal and it is usually about who is building, not about your phone being bad. Budget models, very recent releases, and phones outside the big enthusiast brands often never get a dedicated build because nobody has picked up maintaining one.",
        "",
        "What actually works in the meantime, assuming your bootloader can be unlocked:",
        "",
        "- **GSI (Treble generic system image).** Most phones shipping with Android 9 or newer support Treble, which lets you run a generic build of LineageOS, crDroid and others. The **Treble & GSI** tab in the app explains how to check your variant and pick the right image.",
        "- **XDA.** Unofficial builds, TWRP ports and per-device guides usually live there first. The **Search XDA** button on your device card runs that search for you.",
        "",
        "We refresh the catalog from upstream every week, so if a maintained build appears for your device it will show up in the app on its own. Leaving this open as a tracked gap. \U0001f44d",
    ])

# ------------------------------------------------------------------------ out
lines = []
for d in drafts:
    d['text'] = d['text'].rstrip() + '\n\n' + REVIEW_CTA
    assert '\u2014' not in d['text'] and '\u2013' not in d['text'], f"dash in #{d['n']}"
    lines.append(f"{'='*70}\nISSUE #{d['n']} | ACTION: {d['action']}\n{'-'*70}\n{d['text']}\n")

open('/tmp/crr-drafts2.txt', 'w').write('\n'.join(lines))
json.dump(drafts, open('/tmp/crr-drafts2.json', 'w'), ensure_ascii=False, indent=1)

buckets = {}
for d in drafts:
    buckets.setdefault(d['action'], []).append(d['n'])
print(f"{len(drafts)} drafts written to /tmp/crr-drafts2.txt")
for a, ns in buckets.items():
    print(f"  {len(ns):2d}  {a}")
    print(f"      {ns}")
