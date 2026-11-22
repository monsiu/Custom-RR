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
    # Google reuses a codename across unrelated phones (e.g. `emerald` is both
    # the Teracube/Mint 2e and the Xiaomi POCO M6 Pro 4G). Grouping purely by
    # codename merged both devices' model numbers into one entry, which then let
    # the catalog list a Xiaomi model under the Teracube device (issue #80). So
    # we group by codename AND brand, keep the first-seen brand as the primary
    # entry, and record any other brands as `variants` so downstream can attach
    # model numbers to the right device instead of all of them to one.
    grouped = {}
    for row in csv.DictReader(io.StringIO(raw)):
        codename = (row.get('Device') or '').strip()
        if not codename:
            continue
        key = codename.lower()
        brand = (row.get('Retail Branding') or '').strip()
        name = (row.get('Marketing Name') or '').strip()
        model = (row.get('Model') or '').strip()
        g = grouped.setdefault(key, {'order': [], 'brands': {}})
        bkey = brand.lower()
        b = g['brands'].get(bkey)
        if b is None:
            b = {'brand': brand, 'name': '', 'models': []}
            g['brands'][bkey] = b
            g['order'].append(bkey)
        if name and not b['name']:
            b['name'] = name
        # The Model column repeats the marketing name for some OEMs; only keep
        # values that look like an actual retail model number.
        if model and model not in b['models'] and model.lower() != name.lower():
            b['models'].append(model)

    index = {}
    for key, g in grouped.items():
        # Brands that actually carry model numbers, in first-seen order. A row
        # with a blank Retail Branding becomes the '' bucket; fold it into the
        # primary rather than treating "no brand" as its own device.
        named = [bk for bk in g['order'] if bk and g['brands'][bk]['models']]
        blank = g['brands'].get('')
        if not named:
            # Single device (or brand-less rows only): keep the old flat shape.
            primary = g['brands'][g['order'][0]]
            models = list(primary['models'])
            if blank and blank is not primary:
                models += [m for m in blank['models'] if m not in models]
            index[key] = {'brand': primary['brand'], 'name': primary['name'], 'models': models}
            continue
        primary = g['brands'][named[0]]
        models = list(primary['models'])
        if blank:
            models += [m for m in blank['models'] if m not in models]
        entry = {'brand': primary['brand'], 'name': primary['name'], 'models': models}
        variants = [
            {'brand': g['brands'][bk]['brand'], 'name': g['brands'][bk]['name'], 'models': g['brands'][bk]['models']}
            for bk in named[1:]
        ]
        if variants:
            entry['variants'] = variants
        index[key] = entry
    return index


def all_models(entry):
    """Every model number for a codename, across its brand variants. Used for the
    bundled recognition dictionary, which only needs to know the number exists."""
    models = list(entry['models'])
    for v in entry.get('variants', ()):
        models += [m for m in v['models'] if m not in models]
    return models


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

    subset = {k: v for k, v in index.items() if k in listed and all_models(v)}
    out_devices = os.path.join(ROOT, 'tool', 'data', 'play_devices.json')
    json.dump(subset, open(out_devices, 'w', encoding='utf-8'),
              indent=1, ensure_ascii=False, sort_keys=True)
    collisions = sum(1 for v in subset.values() if v.get('variants'))
    print(f'wrote {out_devices}: {len(subset)} listed codenames with model '
          f'numbers ({collisions} shared across brands)')

    # Bundled dictionary: compact keys keep the asset small. The recognition
    # index only needs to know a model number exists, so it keeps every
    # variant's numbers under the codename.
    slim = {
        k: {'b': v['brand'], 'n': v['name'], 'm': all_models(v)}
        for k, v in index.items()
    }
    out_index = os.path.join(ROOT, 'assets', 'device_index.json')
    json.dump(slim, open(out_index, 'w', encoding='utf-8'),
              separators=(',', ':'), ensure_ascii=False, sort_keys=True)
    size = os.path.getsize(out_index) / 1e6
    print(f'wrote {out_index}: {len(slim)} codenames, {size:.2f} MB')


if __name__ == '__main__':
    main()
