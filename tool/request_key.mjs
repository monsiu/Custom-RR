// Extracts a canonical grouping key for a device/ROM/recovery request issue,
// so two requests for the same handset collapse onto one key.
//
// Usage (CLI): node tool/request_key.mjs <title> <body>   -> prints "<kind>\t<key>"
// Import:      import { requestKey } from './request_key.mjs'
//
// Returns { key, kind }:
//   kind 'codename' - the issue declares a codename (title parens / Codename
//                     field) or a retail model number; the strongest key, safe
//                     to dedup and close on automatically.
//   kind 'name'     - no codename, but the title/body names a device by its
//                     marketing name (e.g. "Moto G24"); good enough to group
//                     duplicates, too fuzzy to auto-close without review.
//   kind ''         - the issue names no device at all (key ''); an empty
//                     request.
// Normalization and the alias map mirror tool/catalog_match.mjs so the two
// agree on what a codename is.

import { readFileSync } from 'node:fs';

const norm = (s) => (s ?? '').toLowerCase().replace(/[\s\-_]+/g, '');

const nonCodenames = new Set(
  [
    'twrp', 'orangefox', 'ofox', 'pbrp', 'shrp', 'magisk', 'kernelsu', 'apatch',
    'recovery', 'root', 'rom', 'customrom', 'gsi', 'emulator',
    'none', 'unknown', 'idk', 'tbd', 'nil', 'any', 'other', 'os',
  ].map((w) => norm(w)),
);
const isCodenameLike = (t) => Boolean(t) && !nonCodenames.has(norm(t));

const aliases = (() => {
  const map = new Map();
  try {
    const src = readFileSync('lib/util/codename_aliases.dart', 'utf8');
    const block = src.match(/kCodenameAliases\s*=\s*<String,\s*String>\{([\s\S]*?)\n\};/);
    for (const [, k, v] of (block?.[1] ?? '').matchAll(/'([^']+)'\s*:\s*'([^']+)'/g)) {
      map.set(norm(k), norm(v));
    }
  } catch {
    /* aliases are a bonus; grouping still works without them */
  }
  return map;
})();

const resolve = (c) => aliases.get(c) ?? c;

function field(body, name) {
  const m = body.match(new RegExp(`###\\s*${name}\\s*\\n+([^\\n#]+)`, 'i'));
  const v = m ? m[1].trim() : '';
  return v === '_No response_' ? '' : v;
}

const clean = (t) =>
  t && t.trim().length >= 3 && !/^20\d\d$/.test(t.trim()) && !/^\d+$/.test(t.trim())
    ? t.trim()
    : '';

// Words that carry no device identity, stripped before building a name key.
const nameNoise = new Set([
  'device', 'request', 'rom', 'recovery', 'root', 'solution', 'fastboot',
  'custom', 'gsi', 'treble', 'please', 'need', 'needed', 'want', 'and', 'or',
  'for', 'the', 'my', 'version', 'retail', 'variant', 'us', 'model', 'that',
  'you', 'notes', 'data', 'support', 'add', 'new', 'phone', 'mobile',
]);

// Strips the "<type> request:" prefix the issue forms prepend to every title.
const stripPrefix = (t) =>
  t.replace(/^\s*(fastboot)?\s*(device|rom( or recovery)?|recovery|root solution|root)\s*request\s*:?/i, '').trim();

// Builds a fuzzy marketing-name key from free text: lowercase alphanumeric
// tokens, brand/filler words dropped, joined. Returns '' when nothing of
// substance remains.
function nameKey(text) {
  const tokens = text
    .toLowerCase()
    .split(/[^a-z0-9]+/)
    .filter((t) => t && !nameNoise.has(t));
  const joined = tokens.join('');
  // Require either a digit (model/series number) or a reasonably long run of
  // letters, so stray punctuation or a lone brand word is not treated as a key.
  if (/\d/.test(joined) ? joined.length >= 3 : joined.length >= 5) return joined;
  return '';
}

// Returns { key, kind }; see the file header for what each kind means.
export function requestKey(title = '', body = '') {
  // A declared codename wins: title parens first, then the Codename field.
  const titleParen = clean((title.match(/\(([^)]+)\)/) ?? [])[1]);
  if (isCodenameLike(titleParen) && norm(titleParen).length >= 3) {
    return { key: resolve(norm(titleParen)), kind: 'codename' };
  }
  const fieldCodename = clean(field(body, 'Codename'));
  if (isCodenameLike(fieldCodename) && norm(fieldCodename).length >= 3) {
    return { key: resolve(norm(fieldCodename)), kind: 'codename' };
  }
  // A parenthetical inside the ROM form's Supported devices field is usually
  // the codename spelled out in prose ("Redmi Note 9S (curtana)").
  const supportedParen = clean((field(body, 'Supported devices').match(/\(([^)]+)\)/) ?? [])[1]);
  if (isCodenameLike(supportedParen) && norm(supportedParen).length >= 3) {
    return { key: resolve(norm(supportedParen)), kind: 'codename' };
  }
  // Then a retail model number (SM-A556E, RMX3939, XT2531-2, KB2005).
  const haystack = `${title}\n${body}`;
  const model = (haystack.match(/\b[A-Za-z]{1,3}-?[A-Za-z]?\d{3,}[A-Za-z0-9-]*\b/) ?? [])[0];
  if (model && isCodenameLike(model) && norm(model).length >= 4) {
    return { key: resolve(norm(model)), kind: 'codename' };
  }
  // Finally the marketing name. Sources, in order: the title, the device form's
  // Model field, and the ROM form's "Supported devices" field (where reporters
  // often name the device in prose). "What should we add" and "Name" are the
  // ROM/recovery name, not the device, so they are deliberately not read here.
  const named = [stripPrefix(title), field(body, 'Model'), field(body, 'Supported devices')]
    .map((s) => nameKey(s ?? ''))
    .find((k) => k);
  if (named) return { key: named, kind: 'name' };
  return { key: '', kind: '' };
}

if (import.meta.url === `file://${process.argv[1]}`) {
  const title = process.argv[2] ?? process.env.ISSUE_TITLE ?? '';
  const body = process.argv[3] ?? process.env.ISSUE_BODY ?? '';
  const { key, kind } = requestKey(title, body);
  process.stdout.write(`${kind}\t${key}`);
}
