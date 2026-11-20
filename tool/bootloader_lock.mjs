// Mirrors lib/util/bootloader_lock.dart for CI triage: decides whether a
// Samsung model number is one whose bootloader cannot normally be unlocked
// (US U/U1, Canada W, US prepaid/Tracfone SM-S…DL). Kept in sync with the Dart
// rule by tool/bootloader_lock_test.mjs.
//
// Usage (CLI): ISSUE_TITLE=.. ISSUE_BODY=.. node tool/bootloader_lock.mjs
//   prints JSON { locked, model, region } for the first locked model found in
//   the title/body, or { locked: false } when none is present.

const US = /^SM-[A-Z]?\d+U1?$/;
const CANADA = /^SM-[A-Z]?\d+W$/;
const PREPAID = /^SM-S\d+DL$/;

// Lock info for a single model number, or null when it unlocks normally / is
// not a model we have a rule for.
export function bootloaderLockForModel(model) {
  const m = String(model ?? '').trim().toUpperCase().replace(/^SAMSUNG-/, '');
  if (!m) return null;
  if (US.test(m)) return { model: m, region: 'US' };
  if (CANADA.test(m)) return { model: m, region: 'Canada' };
  if (PREPAID.test(m)) return { model: m, region: 'US prepaid' };
  return null;
}

// Scans free text for Samsung model numbers and returns the first locked one,
// or null. Catches both `SM-A015U` and the legacy `SAMSUNG-SM-G930A` spelling.
export function detectLockedModel(title = '', body = '') {
  const text = `${title}\n${body}`;
  const candidates = text.match(/\b(?:SAMSUNG-)?SM-[A-Za-z]?\d+[A-Za-z0-9]*\b/gi) ?? [];
  for (const candidate of candidates) {
    const lock = bootloaderLockForModel(candidate);
    if (lock) return lock;
  }
  return null;
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const title = process.env.ISSUE_TITLE ?? process.argv[2] ?? '';
  const body = process.env.ISSUE_BODY ?? process.argv[3] ?? '';
  const lock = detectLockedModel(title, body);
  console.log(JSON.stringify(lock ? { locked: true, ...lock } : { locked: false }));
}
