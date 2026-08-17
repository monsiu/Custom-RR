#!/usr/bin/env python3
"""Probe every ROM/recovery/root project we list for a machine-readable device roster.

Most AOSP ROMs publish an OTA repo on GitHub with one JSON per codename, which
is the authoritative list. This walks candidate orgs/repos and reports what is
usable, so sync_catalog.dart can stop guessing.
"""
import json, subprocess, sys
from concurrent.futures import ThreadPoolExecutor

UA = 'Mozilla/5.0 (X11; Linux x86_64) AppleWebKit/537.36 Chrome/126 Safari/537.36'


def gh(path):
    r = subprocess.run(['gh', 'api', path, '--paginate', '--slurp'],
                       capture_output=True, text=True, timeout=90)
    if r.returncode != 0:
        return None
    try:
        data = json.loads(r.stdout)
    except Exception:
        return None
    # --slurp wraps paginated pages in an outer list; flatten one level.
    out = []
    for page in data if isinstance(data, list) else [data]:
        if isinstance(page, list):
            out.extend(page)
        else:
            out.append(page)
    return out


def head(url):
    r = subprocess.run(['curl', '-sIL', '--max-time', '15', '-A', UA, '-o', '/dev/null',
                        '-w', '%{http_code}', url], capture_output=True, text=True)
    return r.stdout.strip()


# project -> candidate GitHub orgs to search for an OTA/devices repo
ORGS = {
    'pixelexperience': ['PixelExperience'],
    'derpfest': ['DerpFest-AOSP', 'DerpFest'],
    'bliss': ['BlissRoms-Devices', 'BlissRoms'],
    'risingosrevived': ['RisingOS-Revived', 'RisingTechOSS'],
    'voltage': ['VoltageOS'],
    'projectelixir': ['ProjectElixirOS', 'Project-Elixir'],
    'dotos': ['DotOS', 'DroidOnTime'],
    'paranoidandroid': ['AOSPA'],
    'potatoaosp': ['PotatoProject'],
    'un1ca': ['salvogiangri'],
    'pitchblack': ['PitchBlackRecoveryProject'],
    'shrp': ['SHRP'],
    'calyxos': ['CalyxOS'],
    'axpos': ['AXPOS', 'Divested-Mobile'],
    'grapheneos': ['GrapheneOS'],
}

KEYWORDS = ('ota', 'official_devices', 'devices', 'device_list', 'releases')

print('=== searching GitHub orgs for OTA / device-list repos ===\n')
found = {}


def scan(item):
    proj, orgs = item
    hits = []
    for org in orgs:
        repos = gh(f'/orgs/{org}/repos?per_page=100') or gh(f'/users/{org}/repos?per_page=100')
        if not repos:
            continue
        for r in repos:
            name = r.get('name', '').lower()
            if any(k in name for k in KEYWORDS):
                hits.append((f"{r['full_name']}", r.get('default_branch'), r.get('size'), r.get('pushed_at', '')[:10]))
    return proj, hits


with ThreadPoolExecutor(max_workers=6) as ex:
    for proj, hits in ex.map(scan, ORGS.items()):
        found[proj] = hits
        if hits:
            print(f'{proj}:')
            for full, br, size, pushed in sorted(hits, key=lambda x: -(x[2] or 0))[:5]:
                print(f'    {full:<52} branch={br:<12} pushed={pushed}')
        else:
            print(f'{proj}: (no obvious OTA repo found)')

json.dump({k: [list(x) for x in v] for k, v in found.items()},
          open('/tmp/crr-ota-repos.json', 'w'), indent=1)
print('\nsaved -> /tmp/crr-ota-repos.json')
