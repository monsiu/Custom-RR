// Runs the real comment/close script out of upstream-device-watch.yml against a
// mocked GitHub API and asserts what it does to each hit.
//
// The guard under test: once the watch has auto-closed an issue and a human
// reopens it, the earlier "now in the catalog" match was wrong (that is why it
// was reopened), so the watch must not close it again. This is the loop the
// Moto G Power 5G 2023 (XT2311DL) reports were stuck in.
//
// Usage: node tool/upstream_watch_test.mjs

import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const workflow = readFileSync('.github/workflows/upstream-device-watch.yml', 'utf8');

// Pull the `script: |` block out without a YAML dependency (same approach as
// triage_reply_test.mjs): keep following lines that are blank or indented
// deeper than the key, then dedent.
function extractScript(yaml) {
  const lines = yaml.split('\n');
  const start = lines.findIndex((l) => /^\s*script:\s*\|\s*$/.test(l));
  if (start === -1) throw new Error('no `script: |` block found in the workflow');
  const indent = lines[start].match(/^\s*/)[0].length;
  const body = [];
  for (const line of lines.slice(start + 1)) {
    if (line.trim() === '') {
      body.push('');
      continue;
    }
    if (line.match(/^\s*/)[0].length <= indent) break;
    body.push(line);
  }
  const pad = Math.min(...body.filter((l) => l.trim()).map((l) => l.match(/^\s*/)[0].length));
  return body.map((l) => l.slice(pad)).join('\n');
}

const AsyncFunction = Object.getPrototypeOf(async () => {}).constructor;
const run = new AsyncFunction('github', 'context', 'core', 'require', extractScript(workflow));

// `priorComments` stands in for whatever is already on the issue.
async function watch({ hit, priorComments = [] }) {
  writeFileSync('/tmp/hits.json', JSON.stringify([hit]));
  const calls = { comments: [], labels: [], closed: false };
  const github = {
    paginate: async () => priorComments,
    rest: {
      issues: {
        listComments: () => {},
        createComment: async ({ body }) => calls.comments.push(body),
        addLabels: async ({ labels }) => calls.labels.push(...labels),
        update: async ({ state }) => {
          if (state === 'closed') calls.closed = true;
        },
      },
    },
  };
  const context = { repo: { owner: 'o', repo: 'r' } };
  const core = { info: () => {}, warning: () => {} };
  await run(github, context, core, require);
  return calls;
}

const sampleHit = {
  number: 42,
  title: 'Device request: Xiaomi Redmi Note 9S (curtana)',
  term: 'curtana',
  models: ['curtana', 'Redmi Note 9 Pro'],
  matches: [{ kind: 'recoveries', id: 'orangefox', name: 'OrangeFox Recovery' }],
};

const cases = [
  {
    name: 'a fresh hit is answered and closed, with the model caveat',
    run: () => watch({ hit: sampleHit }),
    check: (r) => {
      if (!r.closed) return 'did not close a genuinely covered request';
      if (!r.labels.includes('already-covered')) return 'did not label already-covered';
      if (!r.comments[0]?.includes('do not flash any of these')) return 'dropped the model-number caveat';
      return null;
    },
  },
  {
    name: 'an issue it already closed and a human reopened is left alone',
    run: () =>
      watch({
        hit: sampleHit,
        priorComments: [
          { user: { type: 'Bot', login: 'github-actions[bot]' }, body: 'Good news, this one aged well. Your device is now in the catalog.' },
        ],
      }),
    check: (r) => {
      if (r.closed) return 're-closed an issue a human had reopened';
      if (r.comments.length) return 'posted another comment on a reopened issue';
      return null;
    },
  },
];

let failed = 0;
for (const c of cases) {
  let problem;
  try {
    problem = c.check(await c.run());
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
