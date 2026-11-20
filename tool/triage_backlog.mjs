// Analyzes a `gh issue list` dump of open requests and produces a triage plan:
// which issues are duplicates of an older open request for the same device,
// and which name no identifiable device at all. Prints the plan as JSON and a
// human summary. It never touches GitHub itself; a caller applies the plan.
//
// Usage: gh issue list -R <repo> --state open -L 500 \
//          --json number,title,body,labels,createdAt > open.json
//        node tool/triage_backlog.mjs open.json
//
// Plan shape:
//   {
//     duplicates: [{ number, key, kind, canonical, title }],  // close these
//     empty:      [{ number, title }],                        // close, ask info
//     canonical:  [{ key, kind, number, dupes: [n,...] }],    // keep, +1 them
//   }
// kind is 'codename' (strong, safe to auto-close) or 'name' (fuzzy marketing
// match, review before closing). Callers can gate on kind.

import { readFileSync } from 'node:fs';
import { requestKey } from './request_key.mjs';

const path = process.argv[2];
if (!path) {
  console.error('usage: node tool/triage_backlog.mjs <open-issues.json>');
  process.exit(2);
}

const issues = JSON.parse(readFileSync(path, 'utf8'));
const REQUEST = /device request|rom request|recovery request|rom or recovery|root solution/i;

const isRequest = (issue) => {
  const labels = (issue.labels ?? []).map((l) => l.name);
  return (
    REQUEST.test(issue.title ?? '') ||
    labels.includes('device') ||
    labels.includes('request')
  );
};

// Oldest first, so the earliest request for a device becomes the canonical one.
const requests = issues
  .filter(isRequest)
  .sort((a, b) => (a.createdAt < b.createdAt ? -1 : a.createdAt > b.createdAt ? 1 : a.number - b.number));

const byKey = new Map(); // key -> { number, title, kind, dupes: [] }
const duplicates = [];
const empty = [];

for (const issue of requests) {
  const { key, kind } = requestKey(issue.title ?? '', issue.body ?? '');
  if (!key) {
    empty.push({ number: issue.number, title: issue.title });
    continue;
  }
  const existing = byKey.get(key);
  if (existing) {
    existing.dupes.push(issue.number);
    duplicates.push({
      number: issue.number,
      key,
      kind,
      canonical: existing.number,
      title: issue.title,
    });
  } else {
    byKey.set(key, { key, kind, number: issue.number, title: issue.title, dupes: [] });
  }
}

const canonical = [...byKey.values()]
  .filter((c) => c.dupes.length > 0)
  .map((c) => ({ key: c.key, kind: c.kind, number: c.number, dupes: c.dupes }));

const plan = { duplicates, empty, canonical };

const dupLine = (c) =>
  `  #${c.number} (${c.key}, ${c.kind})  <- dupes: ${c.dupes.map((n) => '#' + n).join(', ')}`;
const strongGroups = canonical.filter((c) => c.kind === 'codename');
const nameGroups = canonical.filter((c) => c.kind === 'name');

const summary = [
  `Open requests analyzed: ${requests.length}`,
  `Distinct devices (keys): ${byKey.size}`,
  `Duplicate issues to close: ${duplicates.length} (${duplicates.filter((d) => d.kind === 'codename').length} codename, ${duplicates.filter((d) => d.kind === 'name').length} name)`,
  `Empty / unidentifiable issues: ${empty.length}`,
  '',
  'Strong duplicate groups (codename/model - safe to auto-close):',
  ...strongGroups.sort((a, b) => b.dupes.length - a.dupes.length).map(dupLine),
  '',
  'Name-only duplicate groups (marketing name - review before closing):',
  ...nameGroups.sort((a, b) => b.dupes.length - a.dupes.length).map(dupLine),
  '',
  'Empty / unidentifiable:',
  ...empty.map((e) => `  #${e.number}  ${e.title}`),
].join('\n');

console.error(summary);
console.log(JSON.stringify(plan, null, 2));
