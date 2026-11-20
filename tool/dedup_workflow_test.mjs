// Executes the real github-script block out of request-dedup.yml against mock
// GitHub state and asserts what the workflow would actually do. This covers the
// part unit tests on request_key.mjs cannot: the branching, the guards against
// double-triaging, and that duplicates fold (+1 the canonical) while empty
// requests close as invalid.
//
// Usage: node tool/dedup_workflow_test.mjs

import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const workflow = readFileSync('.github/workflows/request-dedup.yml', 'utf8');

// Pull the single `script: |` block out without a YAML dependency: keep every
// following line that is blank or indented deeper than the key, then dedent.
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

const script = extractScript(workflow);
const AsyncFunction = Object.getPrototypeOf(async () => {}).constructor;
const run = new AsyncFunction('github', 'context', 'core', 'require', script);

// Runs the workflow script with a given verdict file and issue state.
async function act({ verdict, issueState = 'open', issueLabels = [] }) {
  writeFileSync('/tmp/verdict.json', JSON.stringify(verdict));
  const calls = { comments: [], labels: [], closed: false, reactions: [] };
  const github = {
    rest: {
      issues: {
        get: async () => ({ data: { state: issueState, labels: issueLabels } }),
        createComment: async ({ issue_number, body }) => calls.comments.push({ issue_number, body }),
        addLabels: async ({ labels }) => calls.labels.push(...labels),
        update: async ({ state }) => {
          if (state === 'closed') calls.closed = true;
        },
      },
      reactions: {
        createForIssue: async ({ issue_number, content }) => calls.reactions.push({ issue_number, content }),
      },
    },
  };
  const context = { repo: { owner: 'o', repo: 'r' }, issue: { number: 99 } };
  const core = { info: () => {}, warning: () => {} };
  await run(github, context, core, require);
  return calls;
}

const cases = [
  {
    name: 'duplicate folds onto canonical and +1s it',
    input: { verdict: { verdict: 'duplicate', key: 'p780f03', kind: 'codename', canonical: 582 } },
    check: (r) => {
      if (r.closed !== true) return 'did not close the duplicate';
      if (!r.labels.includes('duplicate')) return 'missing duplicate label';
      const c = r.comments.find((x) => x.issue_number === 99)?.body ?? '';
      if (!c.includes('#582') || !c.includes('p780f03')) return 'comment did not reference canonical/key';
      if (!r.reactions.some((x) => x.issue_number === 582 && x.content === '+1')) return 'did not +1 the canonical';
      if (r.comments.some((x) => x.issue_number === 582)) return 'spammed the canonical with a comment';
      return null;
    },
  },
  {
    name: 'empty request closes as invalid with a details prompt',
    input: { verdict: { verdict: 'empty', key: '', kind: '', canonical: null } },
    check: (r) => {
      if (r.closed !== true) return 'did not close the empty request';
      if (!r.labels.includes('invalid')) return 'missing invalid label';
      const c = r.comments[0]?.body ?? '';
      if (!c.includes('model number') || !c.includes('codename')) return 'did not ask for model/codename';
      if (r.reactions.length) return 'reacted on an empty request';
      return null;
    },
  },
  {
    name: 'already-closed issue is left untouched',
    input: { verdict: { verdict: 'duplicate', key: 'x', kind: 'codename', canonical: 1 }, issueState: 'closed' },
    check: (r) => (r.comments.length || r.closed || r.labels.length ? 'acted on an already-closed issue' : null),
  },
  {
    name: 'already-labeled issue is not re-triaged',
    input: { verdict: { verdict: 'empty', key: '', kind: '', canonical: null }, issueLabels: [{ name: 'invalid' }] },
    check: (r) => (r.comments.length || r.closed ? 're-triaged an issue we already handled' : null),
  },
];

let failures = 0;
for (const c of cases) {
  const r = await act(c.input);
  const err = c.check(r);
  if (err) {
    failures += 1;
    console.error(`FAIL ${c.name}\n  ${err}`);
  } else {
    console.log(`ok   ${c.name}`);
  }
}

if (failures > 0) {
  console.error(`\n${failures} test(s) failed`);
  process.exit(1);
}
console.log('\nall dedup workflow tests passed');
