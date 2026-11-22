// Re-checks issues that were auto-closed as `already-covered` and flags any
// where the reporter's own Model text disagrees with the device the matcher
// picked. This is the net for the codename-collision failures we hit: #80 (a
// POCO M6 Pro closed as a Teracube 2e, both `emerald`) and the Moto G Power 5G
// 2023 reports (#508/#522, closed as moto g32 / moto g 5G 2021).
//
// Usage: node tool/audit_closed_requests.mjs <issues.json>
//   where <issues.json> is a `gh issue list --json number,title,body` dump of
//   the closed `already-covered` issues.
//
// Prints a JSON array of suspicious closures:
//   [{ number, term, matchedDevice, modelText, mismatch: [words] }]
// Exit code is always 0; the caller decides what to do with the findings.

import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const issuesPath = process.argv[2];
if (!issuesPath) {
  console.error('usage: node tool/audit_closed_requests.mjs <issues.json>');
  process.exit(2);
}

// Pure issue-template boilerplate and filler that never names a device. Kept
// deliberately small: brand and model words (xiaomi, poco, power, pro …) are
// exactly the evidence of a mismatch when they are absent from the device the
// matcher chose, so they must NOT be filtered out.
const STOP = new Set([
  'device', 'request', 'requesting', 'rom', 'recovery', 'roms', 'recoveries', 'root',
  'the', 'and', 'for', 'with', 'phone', 'smartphone', 'variant', 'variants', 'model',
  'models', 'global', 'international', 'factory', 'unlocked', 'carrier', 'edition',
  'version', 'android', 'newest', 'latest', 'please', 'help', 'running', 'want', 'need',
]);

const norm = (s) => (s || '').toLowerCase().replace(/[^a-z0-9]+/g, '');

function field(body, name) {
  const m = (body || '').match(new RegExp(`###\\s*${name}\\s*\\n+([^\\n#]+)`, 'i'));
  return m ? m[1].trim() : '';
}

const issues = JSON.parse(readFileSync(issuesPath, 'utf8'));
const flagged = [];

for (const issue of issues) {
  let result;
  try {
    result = JSON.parse(
      execFileSync('node', ['tool/catalog_match.mjs', issue.title ?? '', issue.body ?? ''], {
        encoding: 'utf8',
      }),
    );
  } catch {
    continue;
  }
  if (result.strength !== 'strong' || !result.matches?.length) continue;

  const matched = result.matches[0].device || '';
  const matchedNorm = norm(matched);
  // The reporter's own words for their phone: the Brand and Model fields, plus
  // the title with the "… request:" prefix stripped so boilerplate does not
  // count as device identity. A reported brand (e.g. Xiaomi) absent from the
  // matched device (e.g. Teracube 2e) is the strongest mismatch signal.
  const brandText = field(issue.body, 'Brand');
  const modelText = field(issue.body, 'Model');
  const titleText = (issue.title ?? '').replace(/^[^:]*request:?/i, '').trim();
  const reported = `${brandText} ${modelText} ${titleText}`;

  const words = [...new Set((reported.toLowerCase().match(/[a-z]{4,}/g) ?? []))].filter(
    (w) => !STOP.has(w),
  );
  const mismatch = words.filter((w) => !matchedNorm.includes(norm(w)));

  if (mismatch.length) {
    flagged.push({
      number: issue.number,
      term: result.term,
      matchedDevice: matched,
      reported: reported.trim(),
      mismatch,
    });
  }
}

console.log(JSON.stringify(flagged, null, 1));
