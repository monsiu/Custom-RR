// Matches a device/ROM request issue against assets/catalog.json.
//
// Usage: node tool/catalog_match.mjs <title> <body>
// Prints JSON: { strength: "strong"|"weak"|"none", term, matches: [{kind,id,name,device}] }
//
// strong = a term from the issue equals a catalog device codename
//          (normalized: lowercase, spaces/dashes/underscores stripped).
// weak   = a term only appears inside a device label (brand+model+codename).
//          Weak matches are suggestions; they should never auto-close.

import { readFileSync } from 'node:fs';

// argv for local runs; env for CI (avoids shell-injection via issue text).
const title = process.argv[2] ?? process.env.ISSUE_TITLE ?? '';
const body = process.argv[3] ?? process.env.ISSUE_BODY ?? '';

const catalog = JSON.parse(readFileSync('assets/catalog.json', 'utf8'));

const norm = (s) => s.toLowerCase().replace(/[\s\-_]+/g, '');

const index = [];
for (const kind of ['roms', 'recoveries', 'roots']) {
  for (const entry of catalog[kind] ?? []) {
    for (const device of entry.devices ?? []) {
      const label =
        typeof device === 'string'
          ? device
          : [device.brand, device.model, device.codename && `(${device.codename})`]
              .filter(Boolean)
              .join(' ');
      const codename = typeof device === 'string' ? '' : (device.codename ?? '');
      index.push({
        kind,
        id: entry.id,
        name: entry.name ?? entry.id,
        device: label,
        labelNorm: norm(label),
        labelTokens: new Set(label.toLowerCase().split(/[^a-z0-9]+/).filter(Boolean)),
        codenameNorm: norm(codename),
      });
    }
  }
}

function field(name) {
  const m = body.match(new RegExp(`###\\s*${name}\\s*\\n+([^\\n#]+)`, 'i'));
  const v = m ? m[1].trim() : '';
  return v === '_No response_' ? '' : v;
}

// The issue-form example values people sometimes type in verbatim; only trust
// them when the title corroborates (i.e. it's really about a Galaxy A52).
const exampleValues = new Set(['a52xq', 'galaxya525g', 'galaxya52', 'samsungxiaomioneplus']);
const titleNorm = norm(title);
function trustworthy(value) {
  const v = norm(value);
  if (!exampleValues.has(v)) return true;
  return titleNorm.includes('a52');
}

// Candidate terms. Declared codenames (title parens / Codename field) can
// match strongly; model text can only ever match weakly.
const declared = [];
const modelTerms = [];
const clean = (t) =>
  t && t.trim().length >= 3 && !/^20\d\d$/.test(t.trim()) && !/^\d+$/.test(t.trim())
    ? t.trim()
    : '';
const titleParen = clean((title.match(/\(([^)]+)\)/) ?? [])[1]);
if (titleParen) declared.push(titleParen);
const fieldCodename = clean(field('Codename'));
if (fieldCodename && trustworthy(fieldCodename)) declared.push(fieldCodename);
const fieldModel = clean(field('Model'));
if (fieldModel && trustworthy(fieldModel)) modelTerms.push(fieldModel);
// Model-number-ish tokens in the title (SM-A556E, RMX3939, KB2005, xt2513v…).
for (const tok of title.match(/[A-Za-z]{1,3}[\d][\w-]{3,}/g) ?? []) {
  const c = clean(tok);
  if (c) modelTerms.push(c);
}

let best = null; // {strength, term, matches}
for (const term of declared) {
  const t = norm(term);
  const tok = term.toLowerCase().trim();
  if (t.length < 3) continue;
  const exact = index.filter(
    (e) => (e.codenameNorm && e.codenameNorm === t) || e.labelTokens.has(tok),
  );
  if (exact.length > 0) {
    best = { strength: 'strong', term, matches: exact };
    break;
  }
  if (!best && t.length >= 4) {
    const fuzzy = index.filter((e) => e.labelNorm.includes(t));
    if (fuzzy.length > 0) best = { strength: 'weak', term, matches: fuzzy };
  }
}
if (!best || best.strength !== 'strong') {
  for (const term of modelTerms) {
    const t = norm(term);
    if (t.length < 5) continue;
    const fuzzy = index.filter((e) => e.labelNorm.includes(t));
    if (fuzzy.length > 0) {
      best = best ?? { strength: 'weak', term, matches: fuzzy };
      break;
    }
  }
}

const result = best ?? { strength: 'none', term: '', matches: [] };
const seen = new Set();
result.matches = result.matches.filter((m) => {
  const k = `${m.kind}/${m.id}`;
  if (seen.has(k)) return false;
  seen.add(k);
  return true;
});

console.log(
  JSON.stringify(
    {
      strength: result.strength,
      term: result.term,
      matches: result.matches.map(({ kind, id, name, device }) => ({
        kind,
        id,
        name,
        device,
      })),
    },
    null,
    2,
  ),
);
