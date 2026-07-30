/// Codename normalization and alias fallbacks for on-device detection.
///
/// Android devices frequently report a `ro.product.device` that does not
/// match the codename a ROM or recovery project publishes builds under:
///
///  * Transsion brands prefix the vendor: `Infinix-X6833B` vs `x6833b`.
///  * realme appends regional suffixes: `rmx2151l1` vs `rmx2151`.
///  * OnePlus stock OxygenOS reports marketing names: `OnePlus6T` while every
///    project ships builds for `fajita`.
///  * Xiaomi projects often ship one unified build for a board family:
///    a Redmi 8 reports `olive` but the builds live under `mi439`.
///  * TWRP publishes some combined pages: `rmx2001/rmx2151` covers both the
///    realme 6 and 7.
///
/// [codenameCandidates] turns a raw detected codename into an ordered list of
/// increasingly-loose candidates, and [catalogCodenameMatches] additionally
/// matches the components of combined catalog codenames. Aliases are only
/// consulted after the direct spellings fail, so an exact catalog entry
/// always wins over an alias.
library;

/// Unified-build and stock-name aliases, applied as a last resort.
/// Keys and values are lowercase.
const Map<String, String> kCodenameAliases = <String, String>{
  // Xiaomi mi439 board family: one unified build covers all of these.
  'olive': 'mi439', // Redmi 8
  'olivelite': 'mi439', // Redmi 8A
  'olivewood': 'mi439', // Redmi 8A Dual
  'pine': 'mi439', // Redmi 7A
  // OnePlus stock OxygenOS reports the marketing name, projects use the
  // internal codename.
  'oneplus5': 'cheeseburger',
  'oneplus5t': 'dumpling',
  'oneplus6': 'enchilada',
  'oneplus6t': 'fajita',
  'oneplus7': 'guacamoleb',
  'oneplus7pro': 'guacamole',
  'oneplus7t': 'hotdogb',
  'oneplus7tpro': 'hotdog',
};

final RegExp _vendorPrefix = RegExp(r'^(infinix|tecno|itel)[-_](.+)$');
final RegExp _realmeRegional = RegExp(r'^(rmx\d{4})[a-z0-9]+$');
final RegExp _combinedSeparators = RegExp(r'[/,\s]+');

/// Ordered, de-duplicated candidate codenames for [raw], loosest last.
List<String> codenameCandidates(String raw) {
  final String norm = raw.trim().toLowerCase();
  if (norm.isEmpty) return const <String>[];

  final List<String> direct = <String>[norm];
  final Match? prefixed = _vendorPrefix.firstMatch(norm);
  if (prefixed != null) direct.add(prefixed.group(2)!);
  final Match? regional = _realmeRegional.firstMatch(norm);
  if (regional != null) direct.add(regional.group(1)!);

  final List<String> out = <String>[];
  for (final String c in direct) {
    if (!out.contains(c)) out.add(c);
  }
  for (final String c in direct) {
    final String? alias = kCodenameAliases[c];
    if (alias != null && !out.contains(alias)) out.add(alias);
  }
  return out;
}

/// Whether a catalog codename matches [candidate] (already lowercase),
/// either exactly or as a component of a combined codename such as
/// `rmx2001/rmx2151` or `cheeseburger/dumpling`.
bool catalogCodenameMatches(String catalogCodename, String candidate) {
  final String cat = catalogCodename.trim().toLowerCase();
  if (cat == candidate) return true;
  if (!cat.contains(_combinedSeparators)) return false;
  return cat.split(_combinedSeparators).any((String p) => p == candidate);
}
