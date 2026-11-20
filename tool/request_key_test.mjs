// Asserts how tool/request_key.mjs keys requests, since the dedup workflow
// (request-dedup.yml) closes issues based on it: a wrong key either folds two
// different phones together or bounces a real request as empty.
//
// Usage: node tool/request_key_test.mjs

import { requestKey } from './request_key.mjs';

let failures = 0;
function check(label, got, want) {
  const ok = JSON.stringify(got) === JSON.stringify(want);
  if (!ok) {
    failures += 1;
    console.error(`FAIL ${label}\n  got:  ${JSON.stringify(got)}\n  want: ${JSON.stringify(want)}`);
  } else {
    console.log(`ok   ${label}`);
  }
}

const body = (fields) =>
  Object.entries(fields)
    .map(([k, v]) => `### ${k}\n\n${v}\n`)
    .join('\n');

// Codename in the title parens is the strongest signal.
check('title paren codename', requestKey('Device request: ZTE Blade A76 5G (p780f03)', ''), {
  key: 'p780f03',
  kind: 'codename',
});

// Codename field, device request form.
check('codename field', requestKey('Device request: Galaxy S23', body({ Codename: 'dm1q', Model: 'SM-S911B' })), {
  key: 'dm1q',
  kind: 'codename',
});

// A retail model number with no codename anywhere still keys strongly.
check('model number fallback', requestKey('Device request: SM-A556E', ''), {
  key: 'sma556e',
  kind: 'codename',
});

// Placeholder tool names people type into Codename must never become a key.
check('placeholder codename is not a key', requestKey('Recovery request: (twrp)', body({ Codename: 'twrp' })), {
  key: '',
  kind: '',
});

// Two spellings of the same marketing name key together (fuzzy, kind 'name').
const g24a = requestKey('Device request: Moto G24', '');
const g24b = requestKey('Device request: moto g24', body({ Model: 'Moto G24' }));
check('marketing name keys', g24a, { key: 'motog24', kind: 'name' });
check('marketing name groups same device', g24a.key === g24b.key && g24a.kind === 'name', true);

// Device named only in the ROM form's Supported devices prose is not "empty".
const prose = requestKey(
  'ROM or recovery request:',
  body({ 'What should we add': 'Custom ROM', Name: 'crDroid', 'Supported devices': "It's a Redmi Note 9S (curtana)" }),
);
check('prose device is not empty', prose.kind !== '', true);
check('prose device resolves codename', prose, { key: 'curtana', kind: 'codename' });

// Genuinely empty requests: no model, no codename, no device name.
check('empty rom request', requestKey('ROM request:', body({ 'What should we add': 'Custom ROM', Name: '', 'Supported devices': '_No response_' })), {
  key: '',
  kind: '',
});
check('empty recovery request', requestKey('Recovery request:', ''), { key: '', kind: '' });
check('noise-only title', requestKey('ROM request: os', ''), { key: '', kind: '' });

// A ROM/recovery name alone (no device) stays empty: Name field is not read.
check('rom name only stays empty', requestKey('Recovery request: Ayo', body({ Name: 'Orange fox', 'Supported devices': '_No response_' })), {
  key: '',
  kind: '',
});

if (failures > 0) {
  console.error(`\n${failures} test(s) failed`);
  process.exit(1);
}
console.log('\nall request_key tests passed');
