#!/usr/bin/env python3
"""Cross-check every device mentioned in every issue against real upstream lists.

Reports, for open and closed issues alike:
  MISSED  - upstream supports the device but our catalog does not list it
  OK      - our catalog already lists it
  NONE    - no upstream source we can query supports it
"""
import json, re, subprocess, io, sys

REPO = 'monsiu/Custom-RR'
sources = json.load(open('/tmp/crr-sources.json'))
sources = {k: set(v) for k, v in sources.items() if v}

catalog = json.load(open('/home/monsiu/Custom-RR/assets/catalog.json'))
cat = {}
for kind in ('roms', 'recoveries', 'roots'):
    for e in catalog.get(kind) or []:
        for d in e.get('devices') or []:
            cn = str(d.get('codename', '')).lower().strip()
            if cn:
                cat.setdefault(cn, set()).add(f"{kind[:3]}/{e['id']}")

out = subprocess.run(
    ['gh', 'issue', 'list', '-R', REPO, '--state', 'all', '-L', '400',
     '--json', 'number,title,body,state,stateReason,labels'],
    capture_output=True, text=True)
issues = json.load(io.StringIO(out.stdout))
print(f'issues fetched: {len(issues)}\n')

# Form example values people paste in verbatim; ignore unless the title agrees.
EXAMPLES = {'a52xq', 'a52q', 'oriole', 'alioth'}
NOISE = {'yes', 'not', 'and', 'the', 'for', 'rom', 'roms', 'android', 'custom',
         'recovery', 'response', 'model', 'brand', 'none', 'other', 'twrp'}


def fields(body):
    """Every '### Heading\\n value' pair in an issue form."""
    d = {}
    for m in re.finditer(r'###\s*([^\n]+)\n+([^\n#]*)', body or ''):
        k = m.group(1).strip().lower()
        v = m.group(2).strip()
        if v and v != '_No response_':
            d[k] = v
    return d


def candidates(it):
    """Codename-ish tokens from the title and every relevant field."""
    got = set()
    t = it['title']
    for m in re.findall(r'\(([A-Za-z0-9_+-]{3,20})\)', t):
        got.add(m.lower())
    f = fields(it.get('body') or '')
    for k, v in f.items():
        if not re.search(r'codename|model|device|support', k):
            continue
        for tok in re.findall(r'[A-Za-z0-9_+-]{3,20}', v):
            got.add(tok.lower())
    for tok in re.findall(r'[A-Za-z]{1,3}[\d][A-Za-z0-9_-]{2,}', t):
        got.add(tok.lower())
    got -= NOISE
    title_l = t.lower()
    return {g for g in got if g not in EXAMPLES or g in title_l}


missed, ok, none = [], [], []
for it in issues:
    labels = {l['name'] for l in it['labels']}
    if not (labels & {'device', 'request', 'gsi-candidate'}) and \
       not re.search(r'device request|rom request|recovery request|rom or recovery', it['title'], re.I):
        continue
    cands = candidates(it)
    up = {}
    for c in cands:
        for src, devs in sources.items():
            if c in devs:
                up.setdefault(c, set()).add(src)
    incat = {c: cat[c] for c in cands if c in cat}
    rec = (it['number'], it['state'], it['title'][:44], up, incat)
    if up and not incat:
        missed.append(rec)
    elif incat:
        ok.append(rec)
    else:
        none.append(rec)

print(f'=== MISSED: upstream HAS it, our catalog does NOT ({len(missed)}) ===')
for n, st, t, up, _ in sorted(missed, reverse=True):
    for cn, srcs in up.items():
        print(f'  #{n:<4} [{st:<6}] {cn:<16} -> {", ".join(sorted(srcs))}   | {t}')
print(f'\n=== already covered ({len(ok)}) ===')
print('  ' + ', '.join(f'#{n}' for n, *_ in sorted(ok, reverse=True)))
print(f'\n=== no upstream support found ({len(none)}) ===')
print('  ' + ', '.join(f'#{n}' for n, *_ in sorted(none, reverse=True)))

json.dump({'missed': [[n, st, t, {k: sorted(v) for k, v in up.items()}] for n, st, t, up, _ in missed]},
          open('/tmp/crr-missed.json', 'w'), indent=1)
