// Keeps tool/bootloader_lock.mjs in sync with lib/util/bootloader_lock.dart,
// since the CI triage (us-carrier-triage.yml) closes issues based on it.
//
// Usage: node tool/bootloader_lock_test.mjs

import { bootloaderLockForModel, detectLockedModel } from './bootloader_lock.mjs';

let failures = 0;
function check(label, cond) {
  if (cond) { console.log(`ok   ${label}`); }
  else { failures += 1; console.error(`FAIL ${label}`); }
}

// Locked: US (U/U1), Canada (W), US prepaid (SM-S…DL).
for (const m of ['SM-A015U', 'SM-N981U', 'SM-S908U', 'SM-F711U', 'SM-G990U1', 'SM-A037U1']) {
  check(`${m} locked US`, bootloaderLockForModel(m)?.region === 'US');
}
check('SM-G988W locked Canada', bootloaderLockForModel('SM-G988W')?.region === 'Canada');
check('SM-S111DL locked prepaid', bootloaderLockForModel('SM-S111DL')?.region === 'US prepaid');
check('SAMSUNG- prefix tolerated', bootloaderLockForModel('SAMSUNG-SM-G930U') !== null);
check('casing/space tolerated', bootloaderLockForModel('  sm-a015u ') !== null);

// Not locked: international and non-Samsung.
for (const m of ['SM-A015F', 'SM-A013M', 'SM-G973F', 'SM-S908B', 'CPH2653', 'RMX3939', 'Pixel 6', '']) {
  check(`${m || '(empty)'} not locked`, bootloaderLockForModel(m) === null);
}
check('S23 US locked, intl not', bootloaderLockForModel('SM-S911U') !== null && bootloaderLockForModel('SM-S911B') === null);

// detectLockedModel pulls the model out of issue text.
check('detects model in title', detectLockedModel('Device request: samsung SM-N981U (c1q)', '')?.model === 'SM-N981U');
check('detects legacy prefix', detectLockedModel('Device request: SAMSUNG-SM-G930U', '')?.model === 'SM-G930U');
check('no locked model in intl request', detectLockedModel('Device request: Galaxy S21 (SM-G991B)', '') === null);
check('no model number at all', detectLockedModel('Device request: some phone (b0q)', '') === null);
check('finds model in body when title lacks it', detectLockedModel('ROM request', 'Model: SM-A546U') ?.model === 'SM-A546U');

if (failures > 0) {
  console.error(`\n${failures} test(s) failed`);
  process.exit(1);
}
console.log('\nall bootloader_lock.mjs tests passed');
