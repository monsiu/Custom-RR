// Executes the real reply script out of catalog-match-triage.yml against fixture
// issues and asserts what the bot would actually do to them.
//
// This exists because of #232: it was filed as SM-G991B (a Galaxy S21, o1s) under
// the codename r0s (a Galaxy S22). The bot believed the codename, auto-closed the
// issue and listed S22 builds. Flashing a ROM built for another device can leave
// someone with a phone that will not boot, so "never auto-close when the reported
// model number and codename disagree" has to be enforced, not just intended.
//
// Usage: node tool/triage_reply_test.mjs

import { execFileSync } from 'node:child_process';
import { readFileSync, writeFileSync } from 'node:fs';
import { createRequire } from 'node:module';

// The workflow script runs under actions/github-script (CommonJS) and calls
// require('fs'), which does not exist in an ES module.
const require = createRequire(import.meta.url);

const workflow = readFileSync('.github/workflows/catalog-match-triage.yml', 'utf8');

// Pull the `script: |` block out without taking on a YAML dependency: keep every
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

async function triage({ title, body }) {
  const out = execFileSync('node', ['tool/catalog_match.mjs'], {
    env: { ...process.env, ISSUE_TITLE: title, ISSUE_BODY: body },
    encoding: 'utf8',
  });
  writeFileSync('/tmp/match.json', out);
  const strength = JSON.parse(out).strength;

  const calls = { comments: [], labels: [], closed: false };
  // The step itself is gated on the match being something.
  if (strength === 'none') return { strength, ...calls };

  const github = {
    rest: {
      issues: {
        createComment: async ({ body }) => calls.comments.push(body),
        addLabels: async ({ labels }) => calls.labels.push(...labels),
        update: async ({ state }) => {
          if (state === 'closed') calls.closed = true;
        },
      },
    },
  };
  const context = { payload: { issue: { body } }, repo: { owner: 'o', repo: 'r' }, issue: { number: 1 } };
  const core = { info: () => {}, warning: () => {} };
  await run(github, context, core, require);
  return { strength, ...calls };
}

const cases = [
  {
    name: 'conflicting model number and codename is never auto-closed (#232)',
    title: 'Device request: samsung SM-G991B (r0s)',
    body: '',
    check: (r) => {
      if (r.closed) return 'closed an issue whose model number and codename disagree';
      if (r.labels.includes('already-covered')) return 'marked a conflicting request already-covered';
      const c = r.comments[0] ?? '';
      if (!c.includes('do not agree on which phone')) return 'did not explain the conflict';
      if (!c.includes('SM-G991B') || !c.includes('Galaxy S21')) return 'did not name the real device';
      if (!c.includes('o1s') || !c.includes('r0s')) return 'did not show both codenames';
      return null;
    },
  },
  {
    name: 'genuinely covered device is still answered and closed',
    title: 'Device request: samsung SM-S901B (r0s)',
    body: '',
    check: (r) => {
      if (!r.closed) return 'failed to close a device that really is covered';
      if (!r.labels.includes('already-covered')) return 'missing already-covered label';
      if (!(r.comments[0] ?? '').includes('already in the catalog')) return 'wrong message';
      return null;
    },
  },
  {
    name: 'unified-build alias resolves instead of matching nothing',
    title: 'Device request: Xiaomi Redmi 8 (olive)',
    body: '',
    check: (r) => (r.strength === 'strong' ? null : `olive should resolve to mi439, got ${r.strength}`),
  },
  {
    name: 'regional codename suffix is not mistaken for a conflict',
    title: 'Device request: realme 7 RMX2151 (rmx2151)',
    body: '',
    check: (r) => {
      const c = r.comments[0] ?? '';
      return c.includes('do not agree on which phone')
        ? 'flagged rmx2151 vs rmx2151l1 as different phones'
        : null;
    },
  },
  {
    name: 'uncovered device is left alone for a human',
    title: 'ROM request: crDroid for Motorola Moto G96 (cuscoi)',
    body: '',
    check: (r) => {
      if (r.strength !== 'none') return `expected no match, got ${r.strength}`;
      if (r.comments.length) return 'commented on a device we do not cover';
      return null;
    },
  },
  {
    name: 'confident reply states the model numbers it is claiming',
    title: 'Device request: samsung SM-S901B (r0s)',
    body: '',
    check: (r) => {
      const c = r.comments[0] ?? '';
      if (!c.includes('SM-S901B')) return 'did not state the model number it is answering for';
      if (!c.includes('do not flash')) return 'did not warn what to do if the model number differs';
      return null;
    },
  },
  {
    name: 'brand that belongs to another manufacturer is not auto-closed',
    title: 'Device request: motorola something (r0s)',
    body: '### Brand\n\nmotorola\n\n### Codename\n\nr0s\n',
    check: (r) => {
      if (r.closed) return 'closed a request whose brand contradicts the codename';
      const c = r.comments[0] ?? '';
      if (!c.includes('motorola')) return 'did not quote the stated brand';
      return null;
    },
  },
  {
    name: 'sub-brand is not mistaken for a different manufacturer',
    title: 'Device request: Redmi Redmi 8 (olive)',
    body: '### Brand\n\nRedmi\n\n### Codename\n\nolive\n',
    check: (r) => {
      const c = r.comments[0] ?? '';
      if (c.includes('do not agree on which phone')) return 'flagged Redmi against Xiaomi as a brand conflict';
      if (!r.closed) return 'failed to close a genuinely covered Redmi device';
      return null;
    },
  },
  {
    name: 'OnePlus stock codename in the dictionary is not a conflict (#201)',
    title: 'Device request: OnePlus CPH2655 (op5d55l1)',
    body: '### Brand\n\nOnePlus\n\n### Model\n\nCPH2655\n\n### Codename\n\ndodge\n',
    check: (r) => {
      const c = r.comments[0] ?? '';
      return c.includes('do not agree on which phone')
        ? 'flagged the OnePlus 13 against its own ROM codename'
        : null;
    },
  },
  {
    name: 'codename that collides across manufacturers is not a conflict (#166)',
    title: 'Device request: OnePlus CPH2613 (op5d3fl1)',
    body: '### Brand\n\nOnePlus\n\n### Model\n\nCPH2613\n\n### Codename\n\nbenz\n',
    check: (r) => {
      const c = r.comments[0] ?? '';
      return c.includes('do not agree on which phone')
        ? 'trusted the dictionary calling benz an Alcatel over our own catalog'
        : null;
    },
  },
  {
    name: 'US carrier requests are left to the carrier workflow',
    title: 'Device request: samsung SM-S901B (r0s)',
    body: "Yes, it's a US model or bought from a US carrier",
    check: (r) => (r.comments.length || r.closed ? 'stepped on the US carrier flow' : null),
  },
  {
    name: 'a recovery name typed as the codename is never a match (#239)',
    title: 'Device request: OPPO CPH1901 (cph1901)',
    body: '### Brand\n\noppo\n\n### Model\n\nCPH1901\n\n### Codename\n\ntwrp\n',
    check: (r) => {
      if (r.strength !== 'none') return `matched a recovery name as a codename, got ${r.strength}`;
      if (r.closed) return 'auto-closed a real device against the TWRP emulator placeholder';
      if (r.labels.includes('already-covered')) return 'marked an uncovered device already-covered';
      return null;
    },
  },
  {
    name: 'the TWRP Android Emulator placeholder is never matched (#194)',
    title: 'Device request: vegas',
    body: '### Brand\n\nMotorola\n\n### Model\n\nG power 2025\n\n### Codename\n\nVegas\n',
    check: () => {
      const out = JSON.parse(readFileSync('/tmp/match.json', 'utf8'));
      return out.matches.some((m) => m.id === 'twrp')
        ? 'matched the TWRP Android Emulator placeholder entry'
        : null;
    },
  },
];

let failed = 0;
for (const c of cases) {
  let problem;
  try {
    problem = c.check(await triage(c));
  } catch (e) {
    problem = `threw: ${e.message}`;
  }
  if (problem) failed++;
  console.log(`${problem ? 'FAIL' : 'ok  '}  ${c.name}${problem ? `\n        ${problem}` : ''}`);
}

console.log(`\n${cases.length - failed}/${cases.length} passed`);
process.exit(failed ? 1 : 0);
