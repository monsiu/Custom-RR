#!/usr/bin/env python3
"""Post the generated backlog replies to GitHub.

Reads /tmp/crr-drafts.json (from gen_backlog_replies.py) and applies the
comment / label / close action recorded on each draft.

Dry run by default; pass --post to actually write to GitHub.
"""
import json, subprocess, sys, time

REPO = 'monsiu/Custom-RR'
POST = '--post' in sys.argv

# issue -> (close?, state_reason, labels)
ACTIONS = {
    201: (True, 'completed', ['already-covered']),
    178: (True, 'completed', ['already-covered']),
    167: (True, 'completed', ['already-covered']),
    157: (True, 'completed', ['already-covered']),
    166: (True, 'completed', ['already-covered']),
    129: (True, 'completed', ['already-covered']),
    174: (True, 'completed', ['already-covered', 'duplicate']),
    158: (True, 'completed', []),
    156: (True, 'not planned', ['duplicate']),
    163: (True, 'not planned', ['duplicate']),
    195: (True, 'not planned', ['duplicate']),
    208: (False, None, []),
    150: (False, None, []),
    196: (False, None, []),
}


def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        return False, (r.stderr or r.stdout).strip().splitlines()[-1][:160]
    return True, (r.stdout or '').strip()[:120]


def ensure_labels():
    for name, color, desc in (
        ('already-covered', '0e8a16', 'Device or ROM is already in the catalog'),
        ('duplicate', 'cfd3d7', 'This issue already exists'),
    ):
        run(['gh', 'label', 'create', name, '-R', REPO, '--color', color,
             '--description', desc, '--force'])


drafts = {d['n']: d for d in json.load(open('/tmp/crr-drafts.json'))}
if POST:
    ensure_labels()

for n in sorted(drafts, reverse=True):
    d = drafts[n]
    close, reason, labels = ACTIONS[n]
    if not POST:
        print(f"DRY #{n}: comment ({len(d['text'])} chars), labels={labels}, "
              f"close={close}{'/' + reason if reason else ''}")
        continue

    ok, msg = run(['gh', 'issue', 'comment', str(n), '-R', REPO, '--body', d['text']])
    print(f"#{n} comment: {'OK' if ok else 'FAIL ' + msg}")
    if not ok:
        continue
    if labels:
        ok, msg = run(['gh', 'issue', 'edit', str(n), '-R', REPO,
                       *sum([['--add-label', l] for l in labels], [])])
        print(f"#{n} labels {labels}: {'OK' if ok else 'FAIL ' + msg}")
    if close:
        args = ['gh', 'issue', 'close', str(n), '-R', REPO]
        if reason:
            args += ['--reason', reason]
        ok, msg = run(args)
        print(f"#{n} close({reason}): {'OK' if ok else 'FAIL ' + msg}")
    time.sleep(2)  # stay clear of the secondary-rate limiter

print('DONE' if POST else 'DRY RUN ONLY (pass --post to publish)')
