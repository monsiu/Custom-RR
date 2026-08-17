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

  hits.push({
    number: issue.number,
    title: issue.title,
    term: result.term,
    matches: result.matches.map(({ kind, id, name }) => ({ kind, id, name })),
  });
}

console.log(JSON.stringify(hits, null, 1));
