#!/usr/bin/env python3
"""Re-read every issue properly: all form templates, all fields.

The first pass only understood the device_request template (Brand/Model/
Codename) and silently ignored the rom_request template, whose device lives in
a free-text "Supported devices" field. It also ignored the OEM-unlock answer,
which decides whether anything can be flashed at all.

Resolves device text against assets/device_index.json (36k codenames + retail
model numbers), so "infinix hot 30 x6831" resolves even with no codename given.

Usage: python3 tool/reaudit_issues.py [--state all|open]
"""
import json, re, subprocess, sys, io, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
STATE = 'all' if '--state' not in sys.argv else sys.argv[sys.argv.index('--state') + 1]

index = json.load(open(os.path.join(ROOT, 'assets', 'device_index.json'), encoding='utf-8'))
by_model = {}
for cn, e in index.items():
    for m in e.get('m') or []:
        by_model.setdefault(m.lower(), cn)

catalog = json.load(open(os.path.join(ROOT, 'assets', 'catalog.json'), encoding='utf-8'))
covered = {}
for section in ('roms', 'recoveries', 'roots'):
    for entry in catalog.get(section) or []:
        for d in entry.get('devices') or []:
            for part in str(d.get('codename', '')).lower().replace(',', '/').split('/'):
                if part.strip():
                    covered.setdefault(part.strip(), set()).add(
                        f"{section[:3]}/{entry['id']}")

out = subprocess.run(
    ['gh', 'issue', 'list', '-R', 'monsiu/Custom-RR', '--state', STATE, '-L', '400',
     '--json', 'number,title,body,state,stateReason,labels,comments'],
    capture_output=True, text=True)
issues = json.load(io.StringIO(out.stdout))

STOP = {
    'yes', 'no', 'not', 'sure', 'the', 'and', 'for', 'pls', 'please', 'make', 'me',
    'rom', 'roms', 'recovery', 'root', 'custom', 'android', 'device', 'phone',
    'response', 'other', 'want', 'need', 'my', 'this', 'that', 'with', 'have',
    'gsi', 'treble', 'twrp', 'orangefox', 'orange', 'fox', 'magisk', 'lineage',
    'lineageos', 'https', 'http', 'com', 'www', 'xdaforums', 'github', 'org',
}


def fields(body):
    """All '### Heading' blocks, keeping multi-line values."""
    out = {}
    parts = re.split(r'^###\s+', body or '', flags=re.M)
    for part in parts[1:]:
        lines = part.split('\n')
        key = lines[0].strip().lower()
        value = '\n'.join(lines[1:]).strip()
        if value and value != '_No response_':
            out[key] = value
    return out


def tokens(text):
    return [t for t in re.findall(r'[A-Za-z0-9_.-]{3,24}', text or '')
            if t.lower() not in STOP]


def resolve(issue):
    """Every device the issue plausibly refers to, best first."""
    f = fields(issue.get('body') or '')
    hay = [issue['title']]
    for key, value in f.items():
        if re.search(r'codename|model|brand|supported devices|anything else|name', key):
            hay.append(value)

    found = []
    seen = set()

    def add(codename, how):
        cn = codename.lower()
        if cn in seen:
            return
        seen.add(cn)
        e = index.get(cn)
        label = ''
        if e:
            label = ' '.join(x for x in (e.get('b', ''), e.get('n', '')) if x).strip()
        found.append({'codename': cn, 'label': label, 'how': how,
                      'covered': sorted(covered.get(cn, []))})

    # 1. explicit (codename) in the title
    for m in re.findall(r'\(([A-Za-z0-9_.-]{3,24})\)', issue['title']):
        if m.lower() in index:
            add(m, 'title-parens')
    # 2. any token from any relevant field that IS a known codename
    for text in hay:
        for t in tokens(text):
            if t.lower() in index:
                add(t, 'codename-token')
    # 3. any token that is a known retail model number
    for text in hay:
        for t in tokens(text):
            cn = by_model.get(t.lower())
            if cn:
                add(cn, f'model-number:{t}')
    return f, found


def oem_state(f):
    for key, value in f.items():
        if 'oem unlocking' in key or 'bootloader unlock' in key:
            v = value.lower()
            if v.startswith('no'):
                return 'LOCKED'
            if v.startswith('yes'):
                return 'unlockable'
            return 'unknown'
    return ''


rows = []
for it in issues:
    labels = {l['name'] for l in it['labels']}
    is_request = bool(labels & {'device', 'request', 'gsi-candidate'}) or re.search(
        r'device request|rom request|recovery request|rom or recovery|root solution', it['title'], re.I)
    if not is_request:
        continue
    f, found = resolve(it)
    rows.append({
        'number': it['number'], 'state': it['state'], 'title': it['title'],
        'oem': oem_state(f), 'devices': found,
        'ncomments': len(it['comments']),
        'fields': list(f.keys()),
    })

json.dump(rows, open('/tmp/crr-reaudit.json', 'w'), indent=1, ensure_ascii=False)

resolved = [r for r in rows if r['devices']]
unresolved = [r for r in rows if not r['devices']]
locked = [r for r in rows if r['oem'] == 'LOCKED']
now_covered = [r for r in rows if any(d['covered'] for d in r['devices'])]

print(f'request issues examined: {len(rows)}  (state={STATE})')
print(f'  device identified:      {len(resolved)}')
print(f'  nothing identifiable:   {len(unresolved)}')
print(f'  bootloader LOCKED:      {len(locked)}  <- cannot flash anything')
print(f'  device now in catalog:  {len(now_covered)}')
print()
print('=== OPEN issues where I previously said "no device info" but there IS ===')
for r in rows:
    if r['state'] != 'OPEN' or not r['devices']:
        continue
    d = r['devices'][0]
    if d['how'] in ('title-parens',):
        continue
    print(f"  #{r['number']:<5} {r['title'][:40]:<42} -> {d['label'] or d['codename']} "
          f"({d['codename']}, via {d['how']}) oem={r['oem'] or '?'}")
