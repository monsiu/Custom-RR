#!/usr/bin/env python3
"""Collect real supported-device lists from every upstream project we list.

Writes /tmp/crr-sources.json: {source: [codename, ...]}.
Static/server-rendered sites are parsed here; JS-only sites are collected via
the Playwright browser separately and merged in by number.
"""
import json, re, subprocess, os

UA = ('Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/126 Safari/537.36')


def get(url, timeout=30):
    r = subprocess.run(['curl', '-sL', '--max-time', str(timeout), '-A', UA, url],
                       capture_output=True, text=True)
    return r.stdout or ''


def codes(text, pattern=r'\b([a-z][a-z0-9_+-]{2,19})\b'):
    return set(re.findall(pattern, text.lower()))


sources = {}

# --- LineageOS official API -------------------------------------------------
try:
    oems = json.loads(get('https://download.lineageos.org/api/v2/oems'))
    los = {d['model'].lower() for o in oems for d in o.get('devices', [])}
    sources['lineageos'] = sorted(los)
except Exception as e:
    print('lineage api failed:', e)

# --- GrapheneOS -------------------------------------------------------------
g = get('https://grapheneos.org/releases')
sources['grapheneos'] = sorted({m.lower() for m in re.findall(r'id="([a-z0-9]{4,12})-stable"', g)})

# --- CalyxOS ----------------------------------------------------------------
c = get('https://calyxos.org/docs/guide/device-support/')
sources['calyxos'] = sorted({m.lower() for m in re.findall(r'\(([a-z0-9]{4,12})\)', c)})

# --- /e/OS ------------------------------------------------------------------
e = get('https://doc.e.foundation/devices')
sources['eos'] = sorted({m.lower() for m in re.findall(r'/devices/([A-Za-z0-9_+-]{3,20})/', e)})

# --- AXP.OS -----------------------------------------------------------------
a = get('https://axpos.org/devices')
sources['axpos'] = sorted({m.lower() for m in re.findall(r'\b([a-z0-9_]{3,15})\b', a) if False} or set())

# --- iodeOS (GitLab OTA manifests) -----------------------------------------
try:
    tree = json.loads(get('https://gitlab.com/api/v4/projects/iode%2Fota/repository/tree?per_page=100'))
    sources['iodeos'] = sorted({t['path'][:-5].lower() for t in tree if t['path'].endswith('.json')})
except Exception as ex:
    print('iode failed:', ex)

# --- OrangeFox (embedded in the homepage payload) --------------------------
o = get('https://orangefox.download/')
sources['orangefox'] = sorted({m.lower() for m in re.findall(r'\\?"codename\\?":\\?"([^"\\\\]+)', o)})

# --- Local snapshots already in the repo -----------------------------------
root = os.path.expanduser('~/Custom-RR')
try:
    twrp = json.load(open(f'{root}/tool/data/twrp_devices.json'))
    sources['twrp_local'] = sorted({str(d.get('codename', d) if isinstance(d, dict) else d).lower()
                                    for d in twrp})
except Exception as ex:
    print('twrp local failed:', ex)

json.dump(sources, open('/tmp/crr-sources.json', 'w'), indent=1)
for k, v in sorted(sources.items()):
    print(f'{k:<14} {len(v):>5} devices   e.g. {v[:6]}')
