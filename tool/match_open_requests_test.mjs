// Runs the weekly watch matcher (match_open_requests.mjs) against fixture issues
// and asserts which ones it would auto-close.
//
// This exists because of the Moto G Power 5G 2023 (XT2311DL) reports (#508, #522):
// the on-open triage left them open on purpose (a US/carrier unit, and a codename
// that collides with the moto g32 `devon` / moto g 5G 2021 `kiev`), but the weekly
// watch re-matched the bare codename and closed them anyway. The watch has to apply
// the same guards the on-open triage does, or it keeps reopening that failure.
//
// Usage: node tool/match_open_requests_test.mjs

import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const dir = mkdtempSync(join(tmpdir(), 'watch-test-'));

function run(issues) {
  const path = join(dir, 'issues.json');
  writeFileSync(path, JSON.stringify(issues));
  return JSON.parse(execFileSync('node', ['tool/match_open_requests.mjs', path], { encoding: 'utf8' }));
}

const cases = [
  {
    name: 'US/carrier unit is left for the carrier workflow, not auto-closed',
    issues: [
      {
        number: 522,
        title: "Moto g power 5g 2023 (XT2311DL) TracFone",
        body: "### Codename\n\nDevon\n\n### Is this a US model or carrier variant?\n\nYes, it's a US model or bought from a US carrier",
        labels: [],
      },
    ],
    check: (hits) => (hits.length ? 'closed a US/carrier request' : null),
  },
  {
    name: 'already-covered issues are skipped',
    issues: [
      {
        number: 1,
        title: 'Device request: Xiaomi Redmi Note 9S (curtana)',
        body: '### Codename\n\ncurtana',
        labels: [{ name: 'already-covered' }],
      },
    ],
    check: (hits) => (hits.length ? 're-closed an already-covered issue' : null),
  },
  {
    name: 'a genuinely covered device is still matched and carries the model caveat',
    issues: [
      {
        number: 2,
        title: 'Device request: Xiaomi Redmi Note 9S (curtana)',
        body: '### Codename\n\ncurtana\n\n### Is this a US model or carrier variant?\n\nNot sure',
        labels: [],
      },
    ],
    check: (hits) => {
      if (hits.length !== 1) return 'did not match the covered device';
      if (!hits[0].matches.length) return 'reported no builds';
      if (!Array.isArray(hits[0].models)) return 'did not pass through model numbers for the caveat';
      return null;
    },
  },
];

let failed = 0;
for (const c of cases) {
  let problem;
  try {
    problem = c.check(run(c.issues));
  } catch (e) {
    problem = `threw: ${e.message}`;
  }
  if (problem) {
    failed += 1;
    console.log(`FAIL  ${c.name}\n      ${problem}`);
  } else {
    console.log(`ok    ${c.name}`);
  }
}

console.log(`\n${cases.length - failed}/${cases.length} passed`);
process.exit(failed ? 1 : 0);
