// Covers tool/find_duplicate.mjs against crafted open-issue fixtures, including
// the race the live test caught: two requests for one device opened moments
// apart must not fold onto each other. The earliest stays canonical.
//
// Usage: node tool/find_duplicate_test.mjs

import { execFileSync } from 'node:child_process';
import { writeFileSync } from 'node:fs';

let failures = 0;
function run(number, title, body, open) {
  writeFileSync('/tmp/fd_open.json', JSON.stringify(open));
  const out = execFileSync('node', ['tool/find_duplicate.mjs', String(number), '/tmp/fd_open.json'], {
    encoding: 'utf8',
    env: { ...process.env, ISSUE_TITLE: title, ISSUE_BODY: body },
  }).trim();
  return JSON.parse(out);
}
function check(label, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (!ok) {
    failures += 1;
    console.error(`FAIL ${label}\n  got:  ${JSON.stringify(got)}\n  want: ${JSON.stringify(want)}`);
  } else {
    console.log(`ok   ${label}`);
  }
}

const dev = (number, codename, createdAt) => ({
  number,
  title: `Device request: Thing (${codename})`,
  body: '',
  labels: [{ name: 'device' }],
  createdAt,
});

// Two requests for the same device, #10 older than #11.
const open = [dev(10, 'curtana', '2026-01-01T00:00:00Z'), dev(11, 'curtana', '2026-01-02T00:00:00Z')];

// The newer one folds onto the older.
check('newer folds onto older', run(11, 'Device request: Thing (curtana)', '', open), {
  verdict: 'duplicate',
  key: 'curtana',
  kind: 'codename',
  canonical: 10,
});

// The older one is canonical: no strictly-older sibling, so it is unique.
check('oldest is unique (no mutual close)', run(10, 'Device request: Thing (curtana)', '', open), {
  verdict: 'unique',
  key: 'curtana',
  kind: 'codename',
  canonical: null,
});

// Same createdAt: tie-break on number so one still wins and they do not pair off.
const tied = [dev(20, 'tapas', '2026-03-01T00:00:00Z'), dev(21, 'tapas', '2026-03-01T00:00:00Z')];
check('tie on createdAt folds higher number onto lower', run(21, 'Device request: Thing (tapas)', '', tied), {
  verdict: 'duplicate',
  key: 'tapas',
  kind: 'codename',
  canonical: 20,
});
check('tie on createdAt leaves lower number unique', run(20, 'Device request: Thing (tapas)', '', tied), {
  verdict: 'unique',
  key: 'tapas',
  kind: 'codename',
  canonical: null,
});

// First request for a device is unique.
check('unique device', run(30, 'Device request: Other (newcodename)', '', [dev(30, 'newcodename', '2026-04-01T00:00:00Z'), ...open]), {
  verdict: 'unique',
  key: 'newcodename',
  kind: 'codename',
  canonical: null,
});

// Empty request names no device.
check('empty request', run(40, 'Recovery request:', '', [{ number: 40, title: 'Recovery request:', body: '', labels: [{ name: 'request' }], createdAt: '2026-05-01T00:00:00Z' }]), {
  verdict: 'empty',
  key: '',
  kind: '',
  canonical: null,
});

// A fuzzy name-only match never auto-folds (kind 'name' is review-only).
const named = [
  { number: 50, title: 'Device request: Moto G24', body: '', labels: [{ name: 'device' }], createdAt: '2026-06-01T00:00:00Z' },
  { number: 51, title: 'Device request: Moto G24', body: '', labels: [{ name: 'device' }], createdAt: '2026-06-02T00:00:00Z' },
];
check('name-only match is left unique for humans', run(51, 'Device request: Moto G24', '', named), {
  verdict: 'unique',
  key: 'motog24',
  kind: 'name',
  canonical: null,
});

if (failures > 0) {
  console.error(`\n${failures} test(s) failed`);
  process.exit(1);
}
console.log('\nall find_duplicate tests passed');
