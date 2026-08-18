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

// Reuse the app's alias map rather than duplicating it here, so a phone that
// reports `olive` is still recognised as the Redmi 8 that ships as `mi439`.
const aliases = (() => {
  const map = new Map();
  try {
    const src = readFileSync('lib/util/codename_aliases.dart', 'utf8');
    const block = src.match(/kCodenameAliases\s*=\s*<String,\s*String>\{([\s\S]*?)\n\};/);
    for (const [, k, v] of (block?.[1] ?? '').matchAll(/'([^']+)'\s*:\s*'([^']+)'/g)) {
      map.set(norm(k), norm(v));
    }
  } catch {
    /* aliases are a bonus; matching still works without them */
  }
  return map;
})();

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
        // Some projects publish one combined page, e.g. "rmx2001/rmx2151".
        codenameParts: new Set(
          codename
            .split(/[/,]/)
            .map(norm)
            .filter(Boolean),
        ),
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
  // Direct spellings always win; the alias is only a fallback.
  const spellings = [t];
  const alias = aliases.get(t);
  if (alias && alias !== t) spellings.push(alias);
  let exact = [];
  for (const spelling of spellings) {
    exact = index.filter(
      (e) =>
        (e.codenameNorm && e.codenameNorm === spelling) ||
        e.codenameParts.has(spelling) ||
        (spelling === t && e.labelTokens.has(tok)),
    );
    if (exact.length > 0) break;
  }
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

// Safety net: if the issue also carries a retail model number that resolves to
// a DIFFERENT device than the codename we matched on, the two disagree and we
// must not answer confidently. A Galaxy S21 (SM-G991B, o1s) filed with the
// codename r0s is a Galaxy S22, and pointing that owner at S22 builds is how
// phones get bricked. Downgrade to weak so nothing is auto-closed.
if (result.strength === 'strong') {
  const deviceIndex = (() => {
    try {
      return JSON.parse(readFileSync('assets/device_index.json', 'utf8'));
    } catch {
      return null;
    }
  })();
  if (deviceIndex) {
    const byModel = new Map();
    for (const [codename, entry] of Object.entries(deviceIndex)) {
      for (const m of entry.m ?? []) byModel.set(norm(m), codename);
    }
    // Retail model numbers keep their dashes (SM-G991B, XT2531-2), so they need
    // a looser pattern than the token scan above, then normalizing to compare.
    const haystack = `${title}\n${body}`;
    // Keep the original spelling (SM-G991B) alongside the normalized key so the
    // reply quotes the model number back the way the reporter wrote it.
    const candidates = new Map();
    for (const raw of haystack.match(/\b[A-Za-z]{1,3}-?[A-Za-z]?\d{3,}[A-Za-z0-9-]*\b/g) ?? []) {
      if (!candidates.has(norm(raw))) candidates.set(norm(raw), raw.trim());
    }
    for (const term of modelTerms) {
      if (!candidates.has(norm(term))) candidates.set(norm(term), term.trim());
    }
    const matchedCodename = norm(result.term);
    // Two spellings of the same phone are not a conflict: resolve both sides
    // through the alias map, and treat a regional suffix (rmx2151 vs
    // rmx2151l1) as the same device. Only a genuinely different phone counts.
    const resolve = (c) => aliases.get(c) ?? c;
    const sameDevice = (a, b) => {
      const [ra, rb] = [resolve(a), resolve(b)];
      return ra === rb || ra.startsWith(rb) || rb.startsWith(ra);
    };
    for (const [candidate, original] of candidates) {
      const viaModel = byModel.get(candidate);
      if (viaModel && !sameDevice(norm(viaModel), matchedCodename)) {
        result.strength = 'weak';
        result.conflict = {
          modelNumber: original,
          modelResolvesTo: viaModel,
          modelBrand: deviceIndex[viaModel]?.b ?? '',
          modelName: deviceIndex[viaModel]?.n ?? '',
          codenameGiven: result.term,
        };
        break;
      }
    }
  }
}

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
      conflict: result.conflict ?? null,
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
