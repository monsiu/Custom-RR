// Reads a `gh issue list --json number,title,body,labels` dump and reports the
// open requests whose device is now present in assets/catalog.json.
//
// Usage: node tool/match_open_requests.mjs <issues.json>
// Prints a JSON array: [{ number, title, term, matches: [{kind,id,name}] }]
//
// Reuses tool/catalog_match.mjs so the weekly watch and the on-open triage bot
// agree on what counts as a match. Only strong matches are reported, since a
// weak one is a suggestion rather than proof the device is covered.

import { readFileSync } from 'node:fs';
import { execFileSync } from 'node:child_process';

const issuesPath = process.argv[2];
if (!issuesPath) {
  console.error('usage: node tool/match_open_requests.mjs <issues.json>');
  process.exit(2);
}

const issues = JSON.parse(readFileSync(issuesPath, 'utf8'));
const REQUEST = /device request|rom request|recovery request|rom or recovery/i;

const hits = [];
for (const issue of issues) {
  const labels = (issue.labels ?? []).map((l) => l.name);
  const looksLikeRequest =
    REQUEST.test(issue.title ?? '') ||
    labels.includes('device') ||
    labels.includes('request');
  if (!looksLikeRequest) continue;
  if (labels.includes('already-covered')) continue;

  let result;
  try {
    const out = execFileSync(
      'node',
      ['tool/catalog_match.mjs', issue.title ?? '', issue.body ?? ''],
      { encoding: 'utf8' },
    );
    result = JSON.parse(out);
  } catch {
    continue;
  }
  if (result.strength !== 'strong' || result.matches.length === 0) continue;

  // Mirror the guards the on-open triage applies before it closes anything.
  // Without these, the weekly watch re-closes issues that catalog-match-triage
  // deliberately left open, which is how the Moto G Power 5G 2023 (XT2311DL)
  // reports got shut as the moto g32 (devon) / moto g 5G 2021 (kiev).

  // A conflict means the codename and the model number point at different
  // hardware. Closing it would send someone to builds for a phone they do not
  // own, so leave it for the on-open triage's "which phone is this?" question.
  if (result.conflict) continue;

  // US-carrier units are owned by us-carrier-triage.yml; they usually ship a
  // locked bootloader, so "it's in the catalog" is not the answer they need.
  if ((issue.body ?? '').includes("Yes, it's a US model or bought from a US carrier")) continue;

  hits.push({
    number: issue.number,
    title: issue.title,
    term: result.term,
    models: (result.models ?? []).slice(0, 6),
    matches: result.matches.map(({ kind, id, name }) => ({ kind, id, name })),
  });
}

console.log(JSON.stringify(hits, null, 1));
