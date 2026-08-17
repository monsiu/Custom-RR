#!/usr/bin/env python3
"""Refresh the device dictionary from Google's public Play device catalog.

Writes two files:
  tool/data/play_devices.json  - codename -> {brand, name, models} for every
                                 codename the catalog already lists, merged
                                 into assets/catalog.json by sync_catalog.dart.
  assets/device_index.json     - the full codename/model dictionary, bundled so
                                 the app can recognise a device even when no
                                 maintained build exists for it.

Source: https://storage.googleapis.com/play_public/supported_devices.csv
(UTF-16 CSV, refreshed by Google roughly monthly.)
"""
import csv, io, json, os, subprocess, sys

CSV_URL = 'https://storage.googleapis.com/play_public/supported_devices.csv'
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def fetch() -> str:
    cache = os.path.join(ROOT, 'tool', '.cache', 'play', 'supported_devices.csv')
    os.makedirs(os.path.dirname(cache), exist_ok=True)
    if '--refresh' in sys.argv or not os.path.exists(cache):
        r = subprocess.run(['curl', '-sSL', '--max-time', '120', CSV_URL, '-o', cache])
        if r.returncode != 0:
            sys.exit('could not download the Play device catalog')
    return open(cache, 'rb').read().decode('utf-16')


def build(raw: str):
    index = {}
    for row in csv.DictReader(io.StringIO(raw)):
        codename = (row.get('Device') or '').strip()
        if not codename:
            continue
        key = codename.lower()
        entry = index.setdefault(key, {'brand': '', 'name': '', 'models': []})
        brand = (row.get('Retail Branding') or '').strip()
        name = (row.get('Marketing Name') or '').strip()
        model = (row.get('Model') or '').strip()
        if brand and not entry['brand']:
            entry['brand'] = brand
        if name and not entry['name']:
            entry['name'] = name
        # The Model column repeats the marketing name for some OEMs; only keep
        # values that look like an actual retail model number.
        if model and model not in entry['models'] and model.lower() != name.lower():
            entry['models'].append(model)
    return index


def main():
    index = build(fetch())
    print(f'play catalog: {len(index)} codenames')

    catalog_path = os.path.join(ROOT, 'assets', 'catalog.json')
    listed = set()
    if os.path.exists(catalog_path):
        catalog = json.load(open(catalog_path, encoding='utf-8'))
        for section in ('roms', 'recoveries', 'roots'):
            for entry in catalog.get(section) or []:
                for d in entry.get('devices') or []:
                    cn = str(d.get('codename', '')).lower()
                    for part in cn.replace(',', '/').split('/'):
                        if part.strip():
                            listed.add(part.strip())

    subset = {k: v for k, v in index.items() if k in listed and v['models']}
    out_devices = os.path.join(ROOT, 'tool', 'data', 'play_devices.json')
    json.dump(subset, open(out_devices, 'w', encoding='utf-8'),
              indent=1, ensure_ascii=False, sort_keys=True)
    print(f'wrote {out_devices}: {len(subset)} listed codenames with model numbers')

    # Bundled dictionary: compact keys keep the asset small.
    slim = {
        k: {'b': v['brand'], 'n': v['name'], 'm': v['models']}
        for k, v in index.items()
    }
    out_index = os.path.join(ROOT, 'assets', 'device_index.json')
    json.dump(slim, open(out_index, 'w', encoding='utf-8'),
              separators=(',', ':'), ensure_ascii=False, sort_keys=True)
    size = os.path.getsize(out_index) / 1e6
    print(f'wrote {out_index}: {len(slim)} codenames, {size:.2f} MB')


if __name__ == '__main__':
    main()
