#!/usr/bin/env python3
"""Find closed issues whose answer may no longer be true.

Two failure modes worth catching:
  STALE   - closed as not-planned, but the device is in the catalog now.
  SILENT  - closed with no comment at all, so the requester got no answer.

Codenames come from the title's "(codename)" and the Codename/Supported devices
fields, then are checked against the catalog and the Play device dictionary.
"""
import json, re, subprocess, io, os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
catalog = json.load(open(os.path.join(ROOT, 'assets', 'catalog.json'), encoding='utf-8'))
index = json.load(open(os.path.join(ROOT, 'assets', 'device_index.json'), encoding='utf-8'))

covered = {}
for section in ('roms', 'recoveries'):
    for entry in catalog.get(section) or []:
        for d in entry.get('devices') or []:
            for part in str(d.get('codename', '')).lower().replace(',', '/').split('/'):
                if part.strip():
                    covered.setdefault(part.strip(), set()).add(entry['name'])

out = subprocess.run(
    ['gh', 'issue', 'list', '-R', 'monsiu/Custom-RR', '--state', 'closed', '-L', '300',
     '--json', 'number,title,body,stateReason,comments,labels'],
    capture_output=True, text=True)
issues = json.load(io.StringIO(out.stdout))


def field(body, name):
    m = re.search(r'###\s*' + name + r'\s*\n+([^\n#]+)', body or '', re.I)
    v = m.group(1).strip() if m else ''
    return '' if v == '_No response_' else v


def codenames(it):
    """Only high-confidence codenames: title parens, or a Codename field that
    the device dictionary recognises."""
    out = []
    for m in re.findall(r'\(([A-Za-z0-9_.-]{3,24})\)', it['title']):
        out.append(m.lower())
    cn = field(it.get('body') or '', 'Codename').lower()
    if cn and cn in index:
        out.append(cn)
    return [c for c in dict.fromkeys(out) if c]


stale, silent = [], []
for it in issues:
    reason = it.get('stateReason')
    ncomments = len(it['comments'])
    hits = {}
    for cn in codenames(it):
        if cn in covered:
            hits[cn] = sorted(covered[cn])
    if hits and reason == 'NOT_PLANNED':
        stale.append((it['number'], it['title'], hits))
    if ncomments == 0:
        silent.append((it['number'], reason, it['title']))

print(f'closed issues checked: {len(issues)}')
print()
print(f'=== STALE: closed "not planned" but the device is covered now ({len(stale)}) ===')
for number, title, hits in sorted(stale, reverse=True):
    for cn, entries in hits.items():
        print(f'  #{number:<5} {title[:46]:<48} {cn} -> {", ".join(entries[:6])}')
print()
print(f'=== SILENT: closed with no comment ({len(silent)}) ===')
for number, reason, title in sorted(silent, reverse=True):
    print(f'  #{number:<5} [{reason or "-":<12}] {title[:56]}')
