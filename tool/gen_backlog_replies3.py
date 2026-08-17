#!/usr/bin/env python3
"""Backlog replies, built from issues read one by one rather than regex-guessed.

The earlier generator only understood the device_request template and treated
the rom_request template's free-text "Supported devices" field as empty, so
real requests (a covered Galaxy A21s, a locked bootloader, a Pixel 8a) were
filed as "no device info". Everything here is hand-verified against the issue
text and checked against assets/catalog.json.

Writes /tmp/crr-drafts3.txt and /tmp/crr-drafts3.json.
"""
import json, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
catalog = json.load(open(os.path.join(ROOT, 'assets', 'catalog.json'), encoding='utf-8'))

PLAY = 'https://play.google.com/store/apps/details?id=io.github.monsiu.custom_rr'
CTA = ('If Custom RR helped you out, a quick rating on Google Play goes a long '
       'way and helps other people find the app: ' + PLAY)

names = {}
for section in ('roms', 'recoveries', 'roots'):
    for entry in catalog.get(section) or []:
        names[entry['id']] = (section, entry['name'])


def covered(codename):
    """(roms, recoveries) names covering this codename."""
    roms, recs = [], []
    cn = codename.lower()
    for section in ('roms', 'recoveries'):
        for entry in catalog.get(section) or []:
            for d in entry.get('devices') or []:
                parts = str(d.get('codename', '')).lower().replace(',', '/').split('/')
                if cn in [p.strip() for p in parts]:
                    (roms if section == 'roms' else recs).append(entry['name'])
                    break
    return sorted(set(roms)), sorted(set(recs))


drafts = []


def add(number, action, lines):
    drafts.append({'n': number, 'action': action,
                   'text': '\n'.join(lines).strip() + '\n\n' + CTA})


def covered_reply(number, codename, device, note=''):
    roms, recs = covered(codename)
    lines = [
        f'Good news: your **{device}** (`{codename}`) is **already in the catalog**.',
        '',
    ]
    if roms:
        lines.append(f'- **ROMs:** {", ".join(roms)}')
    if recs:
        lines.append(f'- **Recoveries:** {", ".join(recs)}')
    lines += [
        '',
        f'Open **Find my phone** in the app and search `{codename}` (searching '
        'your model number works now too). Each card lists the devices it '
        'supports and links straight to the download.',
    ]
    if note:
        lines += ['', note]
    lines += ['', 'Closing as already covered. If your unit is a different '
                  'variant, reply and we will take another look. \U0001f44d']
    add(number, 'comment + close (already covered)', lines)


GSI_XDA = (
    'What works today, since your bootloader unlocks:\n\n'
    '- **A Treble GSI** is the practical route. The **Treble & GSI** tab in the '
    'app explains how to check your variant and pick the right image.\n'
    '- **XDA** is where unofficial builds and TWRP ports appear first. The '
    '**Search XDA** button on your device card runs that search for you.'
)

TRACKING = ('We refresh the catalog from each project every week, so if a '
            'maintained build appears for your device it shows up in the app '
            'on its own. Leaving this open as a tracked gap. \U0001f44d')


def gap_reply(number, device, codename, extra=''):
    who = f'your **{device}**' + (f' (`{codename}`)' if codename else '')
    lines = [
        f'Thanks for the request! \U0001f64f Honest status check: {who} has no '
        'maintained custom ROM or recovery that we can list yet. That is a real '
        'gap rather than something we are ignoring, and it is almost always '
        'about who is building, not about your phone.',
        '',
        GSI_XDA,
    ]
    if extra:
        lines += ['', extra]
    lines += ['', TRACKING]
    add(number, 'comment (stay open, tracked gap)', lines)


# ---------------------------------------------------------------- A: covered
covered_reply(209, 'a21s', 'Galaxy A21s',
              note='On Evolution X specifically: they do not build for the '
                   'A21s, but crDroid and LineageOS both do, and those are the '
                   'ones worth starting with.')
covered_reply(203, 'genevn', 'moto g stylus 5G (2023)',
              note='You asked for crDroid or Evolution X. Neither builds for '
                   'genevn, but LineageOS, Bliss, DerpFest, DotOS, RisingOS '
                   'and /e/OS all do, plus TWRP, OrangeFox and PitchBlack on '
                   'the recovery side.')
covered_reply(191, 'akita', 'Pixel 8a',
              note='On OrangeFox specifically: the build you linked is an '
                   'unofficial XDA one, and OrangeFox does not ship akita on '
                   'its official download site, so we cannot list it. You do '
                   'not really need it either, since Pixels flash ROMs with '
                   '`fastboot` or the ROM\'s own web installer.')

# ------------------------------------------------------- B: locked bootloader
add(228, 'comment + close (hard blocker)', [
    'Thanks for the details, and sorry, this is the one answer that is a hard '
    'stop: you marked **OEM unlocking as unavailable** (greyed out, missing or '
    'locked) on your **Infinix Hot 30 (X6831)**.',
    '',
    'Nothing can be flashed to a phone whose bootloader will not unlock. No '
    'recovery, no ROM, no root. That lock is enforced by the bootloader itself, '
    'below Android, so no app or tool can work around it, and anyone selling '
    'you an unlock service for it is either scamming you or handing you malware.',
    '',
    'It is worth double-checking one thing first: OEM unlocking only appears in '
    'Developer options, and on some Infinix units it stays greyed out until the '
    'phone has been online for a few days. If it does eventually turn on, '
    'reopen this and we will look at what exists for the Hot 30.',
    '',
    'On the firmware request: we are a catalog of custom ROMs and recoveries, '
    'so we do not host or mirror stock firmware.',
    '',
    'Closing since there is nothing we can add while the bootloader is locked.',
])

# ------------------------------------------------------------- C: special cases
add(199, 'comment + close (not possible)', [
    'Thanks for the detailed writeup! \U0001f64f One important correction '
    'though: **GrapheneOS only supports Google Pixel devices**. It is not a '
    'GSI and it will never run on the TCL Smart M23 (T431P / 403 T431d), so '
    'that specific request is not something anyone can fulfil.',
    '',
    'More broadly, the M23 is an entry-level MediaTek device, and those very '
    'rarely get a dedicated custom ROM because the kernel sources and MediaTek '
    'bring-up work usually never land.',
    '',
    GSI_XDA,
    '',
    'Closing as not something we can add, but if a maintained build ever '
    'appears for the M23 it will show up in the app automatically. \U0001f44d',
])

add(224, 'comment + close (needs a real source)', [
    'Thanks for the suggestion! Two things here.',
    '',
    'On **Miku OS**: the source came through as `httpsGitHub.com`, which does '
    'not resolve, so there is nothing for us to verify or link to. Before we '
    'list a GSI we need a working releases page, builds that are actually '
    'maintained, and some idea of which Treble variant the images target. Drop '
    'a real link and we will take a proper look.',
    '',
    'On running it on your **Galaxy S21 5G**: that is a Treble device, so GSIs '
    'do run on it. The **Treble & GSI** tab in the app walks through checking '
    'your variant (arm64 a/b vs a-only) and flashing safely. Note Samsung '
    'wipes the device on unlock and trips Knox permanently, so back up first.',
    '',
    'Closing for now since there is no verifiable source to add. \U0001f44d',
])

add(226, 'comment (stay open, tracked gap)', [
    'Thanks, and good work getting this far already. \U0001f64f You have the '
    'bootloader unlocked, KernelSU root and your stock firmware, so you are '
    'past the hard part. The honest status: the **moto g power 2025 (`vegas`)** '
    'has no maintained custom ROM or recovery for us to list yet.',
    '',
    'You said you do not want a GSI, and that is fair, but right now that is '
    'genuinely the only way to run something other than stock on this device. '
    'A dedicated ROM needs a maintainer to do the device bring-up first, and '
    'nobody has published one for vegas.',
    '',
    'The one thing that would actually move this along: your unlocked, rooted '
    'unit plus full stock firmware is exactly what a maintainer needs. The '
    'moto g power XDA forum is where that conversation usually starts, and the '
    '**Search XDA** button on your device card takes you there.',
    '',
    TRACKING,
])

add(172, 'comment + close (answered)', [
    'This is genuinely useful, thank you for reporting back. \U0001f64f You '
    'flashed a **22.1 GAPPS EROFS GSI** on the **moto g 5G 2026 (`nevada`)** '
    'with working radio and data, on Metro by T-Mobile no less, which is the '
    'exact answer a lot of people with this phone are looking for.',
    '',
    'On listing it: the catalog only carries builds a project officially '
    'publishes for a specific device, and there is no dedicated nevada build to '
    'point at. A GSI running well is a property of the phone rather than '
    'something we can list as a nevada download, so there is nothing for us to '
    'add here.',
    '',
    'Leaving your report on the record though, since it is the best evidence '
    'anyone with a nevada will find. Closing as answered. \U0001f44d',
])

add(152, 'comment (stay open, community)', [
    'Thanks, and nice work building Nothing OS variants. \U0001f64f Status on '
    'the catalog side: the **Nothing Phone (3) (`metroid`)** has no maintained '
    'public build for us to list yet, so there is nothing to add today.',
    '',
    'On getting into development, the honest path: the Nothing Phone (3) XDA '
    'forum and the LineageOS device-bring-up docs are where this work actually '
    'happens, and Nothing publishes kernel sources on their GitHub, which is '
    'the starting point for a device tree.',
    '',
    'If you do get a build to a shippable state, open an issue with the '
    'releases link and we will look at listing it. That is exactly how devices '
    'get into the catalog. \U0001f44d',
])

add(231, 'comment (stay open, tracked gap)', [
    'Thanks, this is a more useful report than most. \U0001f64f Status: the '
    '**Alba 10" Pie tablet** has no maintained custom ROM or recovery for us to '
    'list, which is typical for own-brand MediaTek tablets. They are cheap and '
    'common, as you say, but they rarely get kernel sources or a maintainer.',
    '',
    'You are right that the unlock side is usually the easy part on MTK. The '
    'realistic route is a Treble GSI if the tablet ships with Android 9 or '
    'newer, see the **Treble & GSI** tab in the app.',
    '',
    'On the firmware dump: that would help whoever attempts the bring-up, but '
    'we are a catalog rather than a build project, so the right home for it is '
    'an XDA thread for the device where a maintainer can find it.',
    '',
    TRACKING,
])

# --------------------------------------------- D: real device, no build listed
GAPS = [
    (229, 'TECNO Spark 6 Go (KE5K)', 'tecno-ke5k', ''),
    (227, 'Blackview Shark 8', '', ''),
    (225, 'Ulefone RugKing', 'gq3103rh2', ''),
    (223, 'Motorola XT2513V', '', ''),
    (222, 'Galaxy A7 (2018)', 'a7y18lte', ''),
    (221, 'vivo S1', 'pd1913', ''),
    (219, 'realme RMX3939', 're6054', ''),
    (218, 'realme C63 (RMX3939)', '',
     'On unlocking: realme gates this behind their Deep Testing application, '
     'which has to be approved before the bootloader will unlock at all. That '
     'step comes before any ROM or recovery is possible.'),
    (216, 'Xiaomi 24115RA8EG', 'amethyst', ''),
    (212, 'vivo Y400 5G (V2506)', 'oriana', ''),
    (211, 'moto g 5G (2023)', 'pnangn', ''),
    (210, 'Infinix X682B', 'infinix-x682b',
     'Heads-up: the form fields came through with the template examples '
     '(Samsung / Galaxy a52 / A52xq) rather than your own device, so we went '
     'by the Infinix X682B in your title. If that is wrong, just say.'),
    (206, 'Xiaomi 23124RA7EO', 'sapphiren', ''),
    (204, 'Samsung Galaxy Tab A8 LTE (SM-X205)', 'gta8', ''),
    (202, 'Xiaomi M2006J10C', 'cezanne', ''),
    (200, 'moto g (2026)', 'utah', ''),
    (197, 'OPPO CPH2387', 'op571f', ''),
    (196, 'Motorola Moto G14', 'cancun',
     'Careful with one thing: the catalog lists `cancunf`, which is the moto '
     'g54/g64, not your G14. Do not flash cancunf builds. Your init_boot Magisk '
     'workaround for the vbmeta/dm-verity block is the right approach for GSIs '
     'on this device, and is worth posting on XDA where other G14 owners will '
     'find it.'),
    (194, 'moto g power 2025', 'vegas',
     'Same device as #226, tracked together. On rooting specifically: with the '
     'bootloader unlocked, Magisk or KernelSU patched onto your stock boot '
     'image is the standard route, and the **Root** section in the app covers '
     'the differences.'),
    (192, 'moto g (2025)', 'kansas', 'Same device as #175.'),
    (189, 'Lenovo Idea Tab Pro', 'tb373fu', ''),
    (187, 'Xiaomi 2201116SI', 'peux', ''),
    (182, 'Black Shark 5 Pro', 'katyusha',
     'Note the codename is spelled `katyusha` rather than Katysha, which is '
     'worth knowing when searching XDA.'),
    (181, 'Infinix GT 30 Pro 5G', 'infinix-x6873', ''),
    (179, 'Sony SOG01 (Xperia 1 III)', 'sog01', ''),
    (177, 'realme GT 6 (RMX3851)', 're5ca6l1', ''),
    (175, 'moto g (2025)', 'kansas', 'Same device as #192.'),
    (173, 'Nothing Phone (2a) Plus', 'pacmanpro', ''),
    (170, 'OPPO A38 4G', 'op5759l1',
     'You asked for Evolution X specifically: they do not build for this '
     'device, and no other project in the catalog does either.'),
    (165, 'Motorola moto g24', '', ''),
    (164, 'moto g(60)s', 'lisbon', ''),
    (162, 'Honor 200 Pro', '', ''),
    (161, 'Motorola Edge 60 Stylus', 'monai', ''),
    (159, 'moto g play (2023)', 'maui', ''),
    (156, 'Redmi Note 14 5G', 'tanzanite',
     'Tracked in #208 as well. Do not flash the `malachite` builds you may '
     'find: that is the Note 14 **Pro**, a different device.'),
    (155, 'Infinix Hot 20 5G', '', ''),
    (154, 'moto g(20)', 'java', ''),
    (151, 'ZTE Z2352N', 'p820f03', ''),
    (149, 'Meizu Note 22 4G (M513H)', 'meizu_note22', ''),
]
for number, device, codename, extra in GAPS:
    gap_reply(number, device, codename, extra)

# ------------------------------------------ F: closed issues whose answer aged
# Both were answered correctly at the time and closed not-planned. An upstream
# project has started building for them since, so the requester deserves to know.
def now_covered_reply(number, codename, device, then):
    roms, recs = covered(codename)
    lines = [
        f'Following up on this one: your **{device}** (`{codename}`) **is in '
        'the catalog now**.',
        '',
        f'When you asked, {then} Since then we started reading each project\'s '
        'own published device list instead of inferring it, and this device '
        'turned up:',
        '',
    ]
    if roms:
        lines.append(f'- **ROMs:** {", ".join(roms)}')
    if recs:
        lines.append(f'- **Recoveries:** {", ".join(recs)}')
    lines += [
        '',
        f'Open **Find my phone** in the app and search `{codename}`, or your '
        'model number, and it will be there. Sorry for the earlier no. \U0001f44d',
    ]
    add(number, 'comment on CLOSED issue (now covered)', lines)


now_covered_reply(80, 'emerald', 'POCO M6 Pro 4G / Redmi Note 13 Pro 4G',
                  'we said there was no maintained ROM to list.')
now_covered_reply(74, 'a55x', 'Galaxy A55 5G',
                  'we said there was no maintained build to list.')

# ------------------------------------------------- E: genuinely nothing to act on
for number in (215, 180):
    add(number, 'comment + close (needs info)', [
        'Thanks for reaching out! Unfortunately there is not enough here for us '
        'to act on: we need to know which phone you have before we can tell you '
        'what exists for it.',
        '',
        'If you open a new issue, the two things that matter most are:',
        '',
        '- **Brand and model**, for example Samsung Galaxy A52 5G, or the model '
        'number printed on the box (SM-A525F).',
        '- Whether **OEM unlocking** is available on your device, since nothing '
        'can be flashed without it.',
        '',
        'One tip that solves a lot of these immediately: search your model '
        'number or codename in **Find my phone** in the app first, since many '
        'phones are listed under a family codename rather than the one your '
        'phone reports. Closing this one for now. \U0001f44d',
    ])

# ------------------------------------------------------------------------ out
lines = []
for d in drafts:
    assert '\u2014' not in d['text'] and '\u2013' not in d['text'], f"dash in #{d['n']}"
    lines.append(f"{'='*70}\nISSUE #{d['n']} | ACTION: {d['action']}\n{'-'*70}\n{d['text']}\n")
open('/tmp/crr-drafts3.txt', 'w').write('\n'.join(lines))
json.dump(drafts, open('/tmp/crr-drafts3.json', 'w'), ensure_ascii=False, indent=1)

buckets = {}
for d in drafts:
    buckets.setdefault(d['action'], []).append(d['n'])
print(f'{len(drafts)} drafts -> /tmp/crr-drafts3.txt')
for action, nums in sorted(buckets.items()):
    print(f'  {len(nums):>3}  {action}')
    print(f'       {sorted(nums)}')
