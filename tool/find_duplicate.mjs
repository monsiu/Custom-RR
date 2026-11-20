// Given a newly opened request and a dump of currently open issues, decides
// whether the new issue duplicates an older open request for the same device,
// or names no device at all.
//
// Usage: node tool/find_duplicate.mjs <new-number> <open-issues.json>
//   where ISSUE_TITLE / ISSUE_BODY hold the new issue's title/body (via env, to
//   avoid shell-quoting the untrusted text), and open-issues.json is a
//   `gh issue list --state open --json number,title,body,labels,createdAt` dump
//   that includes the new issue.
//
// Prints JSON: { verdict, key, kind, canonical }
//   verdict 'duplicate' - canonical is the older open issue number to fold into
//   verdict 'empty'     - the issue names no identifiable device
//   verdict 'unique'    - first open request for this device; leave it alone
// Only codename/model keys produce a 'duplicate' verdict; fuzzy name matches
// are left for a human, so a marketing-name collision never auto-closes.

import { readFileSync } from 'node:fs';
import { requestKey } from './request_key.mjs';

const newNumber = Number(process.argv[2]);
const openPath = process.argv[3];
const title = process.env.ISSUE_TITLE ?? '';
const body = process.env.ISSUE_BODY ?? '';

if (!newNumber || !openPath) {
  console.error('usage: ISSUE_TITLE=.. ISSUE_BODY=.. node tool/find_duplicate.mjs <new-number> <open.json>');
  process.exit(2);
}

const { key, kind } = requestKey(title, body);

if (!key) {
  console.log(JSON.stringify({ verdict: 'empty', key: '', kind: '', canonical: null }));
  process.exit(0);
}

let canonical = null;
if (kind === 'codename') {
  const open = JSON.parse(readFileSync(openPath, 'utf8'));
  const REQUEST = /device request|rom request|recovery request|rom or recovery|root solution/i;
  const isRequest = (i) => {
    const labels = (i.labels ?? []).map((l) => l.name);
    return REQUEST.test(i.title ?? '') || labels.includes('device') || labels.includes('request');
  };
  // Fold only onto a request that is genuinely OLDER than this one, never onto
  // a newer issue or onto itself. Folding onto the oldest *other* sibling would
  // let two issues opened seconds apart close each other (A->B while B->A),
  // leaving nothing canonical open; "strictly older" keeps the earliest issue
  // as the canonical and makes it classify as unique.
  const subject = open.find((i) => i.number === newNumber);
  const subjectAt = subject?.createdAt ?? '';
  const olderThanSubject = (i) =>
    i.createdAt < subjectAt || (i.createdAt === subjectAt && i.number < newNumber);
  const siblings = open
    .filter((i) => i.number !== newNumber && isRequest(i))
    .filter((i) => requestKey(i.title ?? '', i.body ?? '').key === key)
    .filter(olderThanSubject)
    .sort((a, b) => (a.createdAt < b.createdAt ? -1 : a.createdAt > b.createdAt ? 1 : a.number - b.number));
  if (siblings.length > 0) canonical = siblings[0].number;
}

console.log(
  JSON.stringify({
    verdict: canonical ? 'duplicate' : 'unique',
    key,
    kind,
    canonical,
  }),
);
