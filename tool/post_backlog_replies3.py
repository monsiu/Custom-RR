#!/usr/bin/env python3
"""Post the hand-verified backlog replies from /tmp/crr-drafts3.json.

The action recorded on each draft decides what happens:
  "comment + close (already covered)"   comment, label already-covered, close completed
  "comment + close (answered)"          comment, close completed
  "comment + close (...)"               comment, close not planned
  "comment on CLOSED issue (...)"       comment only, plus already-covered label
  "comment (stay open, ...)"            comment only

Dry run unless --post is passed.
"""
import json, subprocess, sys, time

REPO = 'monsiu/Custom-RR'
POST = '--post' in sys.argv
drafts = json.load(open('/tmp/crr-drafts3.json'))


def plan(action):
    """(close?, reason, labels) for an action string."""
    if action.startswith('comment on CLOSED'):
        return False, None, ['already-covered']
    if 'close' not in action:
        return False, None, []
    if 'already covered' in action:
        return True, 'completed', ['already-covered']
    if 'answered' in action:
        return True, 'completed', []
    return True, 'not planned', []


def run(args):
    r = subprocess.run(args, capture_output=True, text=True)
    if r.returncode != 0:
        return False, (r.stderr or r.stdout).strip().splitlines()[-1][:150]
    return True, ''


if POST:
    run(['gh', 'label', 'create', 'already-covered', '-R', REPO, '--color', '0e8a16',
         '--description', 'Device or ROM is already in the catalog', '--force'])

ok = fail = 0
for d in sorted(drafts, key=lambda x: -x['n']):
    number, action, body = d['n'], d['action'], d['text']
    close, reason, labels = plan(action)
    if not POST:
        print(f"DRY #{number:<5} comment({len(body)} ch) labels={labels or '-'} "
              f"close={close}{'/' + reason if reason else ''}   [{action}]")
        continue

    good, msg = run(['gh', 'issue', 'comment', str(number), '-R', REPO, '--body', body])
    print(f'#{number} comment: {"OK" if good else "FAIL " + msg}')
    if not good:
        fail += 1
        continue
    ok += 1
    if labels:
        good, msg = run(['gh', 'issue', 'edit', str(number), '-R', REPO,
                         *sum([['--add-label', l] for l in labels], [])])
        if not good:
            print(f'  #{number} labels: FAIL {msg}')
    if close:
        args = ['gh', 'issue', 'close', str(number), '-R', REPO]
        if reason:
            args += ['--reason', reason]
        good, msg = run(args)
        print(f'  #{number} close({reason}): {"OK" if good else "FAIL " + msg}')
    time.sleep(2)  # stay under the secondary rate limiter

print(f'\n{"DONE" if POST else "DRY RUN"}  posted={ok} failed={fail} total={len(drafts)}')
