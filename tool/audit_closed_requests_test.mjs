// Feeds audit_closed_requests.mjs a mix of fixture closures and asserts which
// ones it flags as a likely codename collision.
//
// Usage: node tool/audit_closed_requests_test.mjs

import { execFileSync } from 'node:child_process';
import { writeFileSync, mkdtempSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const dir = mkdtempSync(join(tmpdir(), 'audit-test-'));

function run(issues) {
  const path = join(dir, 'issues.json');
  writeFileSync(path, JSON.stringify(issues));
  return JSON.parse(execFileSync('node', ['tool/audit_closed_requests.mjs', path], { encoding: 'utf8' }));
}

const issues = [
  {
    // #80: a Xiaomi POCO closed as a Teracube 2e (both `emerald`). Must flag.
    number: 80,
    title: 'Device request: xiaomi 2312FPCA6G (emerald)',
    body: '### Brand\n\nXiaomi\n\n### Model\n\nPOCO M6 PRO\n\n### Codename\n\nemerald',
  },
  {
    // A correct closure: curtana really is the Redmi Note 9S. Must NOT flag.
    number: 1,
    title: 'Device request: Xiaomi Redmi Note 9S (curtana)',
    body: '### Brand\n\nXiaomi\n\n### Model\n\nRedmi Note 9S\n\n### Codename\n\ncurtana',
  },
];

const flagged = run(issues);
const numbers = flagged.map((f) => f.number).sort((a, b) => a - b);

let failed = 0;
function check(name, cond, detail) {
  if (cond) {
    console.log(`ok    ${name}`);
  } else {
    failed += 1;
    console.log(`FAIL  ${name}\n      ${detail}`);
  }
}

check('flags the cross-brand collision (#80)', numbers.includes(80), `flagged: ${numbers}`);
check('does not flag a correct closure', !numbers.includes(1), `flagged: ${numbers}`);
check(
  'the #80 finding explains the mismatch (brand conflict or reported-brand word)',
  (flagged.find((f) => f.number === 80)?.mismatch ?? []).some(
    (m) => m === 'xiaomi' || m.startsWith('conflict:'),
  ),
  JSON.stringify(flagged.find((f) => f.number === 80)),
);

console.log(`\n${3 - failed}/3 passed`);
process.exit(failed ? 1 : 0);
