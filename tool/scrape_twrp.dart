// Scrapes the official TWRP device roster from https://twrp.me/Devices/ into a
// committed snapshot at tool/data/twrp_devices.json.
//
// Run with:
//
//   dart run tool/scrape_twrp.dart
//
// Why a snapshot instead of scraping live in sync_catalog.dart:
//   - twrp.me has no API or tarball, just ~70 per-OEM HTML pages. Scraping all
//     of them on every CI drift check would be slow and rude, and would make
//     the generated catalog non-deterministic (a device added upstream between
//     commit and CI run would fail the drift check).
//   - So this scraper is run by a human (or a scheduled job) to refresh the
//     snapshot; sync_catalog.dart reads the committed JSON. Refreshing the
//     TWRP list is then: run this, run sync_catalog.dart, commit, push. The
//     app picks the new list up via its remote catalog fetch, no app update.
//
// Output shape (sorted by brand then model):
//   [ { "brand": "Google", "model": "Pixel 5", "codename": "redfin" }, ... ]

import 'dart:convert';
import 'dart:io';

const String _indexUrl = 'https://twrp.me/Devices/';
const String _outputPath = 'tool/data/twrp_devices.json';

Future<void> main() async {
  final HttpClient client = HttpClient()
    ..userAgent = 'custom-rr-catalog-sync (+https://github.com/monsiu/Custom-RR)';
  try {
    stdout.writeln('[twrp] fetching OEM index...');
    final String indexHtml = await _get(client, _indexUrl);
    final List<_Oem> oems = _parseIndex(indexHtml);
    stdout.writeln('[twrp] ${oems.length} OEM pages found');

    final List<Map<String, String>> devices = <Map<String, String>>[];
    final Set<String> seen = <String>{};
    for (final _Oem oem in oems) {
      String html;
      try {
        html = await _get(client, oem.url);
      } on Object catch (e) {
        stderr.writeln('[twrp] WARN failed ${oem.brand} (${oem.url}): $e');
        continue;
      }
      int added = 0;
      for (final _Device d in _parseOemPage(html, oem.brand)) {
        final String key = '${d.brand}|${d.codename}'.toLowerCase();
        if (!seen.add(key)) continue;
        devices.add(<String, String>{
          'brand': d.brand,
          'model': d.model,
          'codename': d.codename,
        });
        added++;
      }
      stdout.writeln('[twrp] ${oem.brand}: $added devices');
    }

    devices.sort((Map<String, String> a, Map<String, String> b) {
      final int byBrand =
          a['brand']!.toLowerCase().compareTo(b['brand']!.toLowerCase());
      if (byBrand != 0) return byBrand;
      return a['model']!.toLowerCase().compareTo(b['model']!.toLowerCase());
    });

    final File out = File(_outputPath);
    out.parent.createSync(recursive: true);
    const JsonEncoder pretty = JsonEncoder.withIndent('  ');
    out.writeAsStringSync('${pretty.convert(devices)}\n');
    stdout.writeln('[twrp] wrote ${devices.length} devices to $_outputPath');
  } finally {
    client.close(force: true);
  }
}

Future<String> _get(HttpClient client, String url) async {
  final HttpClientRequest req = await client.getUrl(Uri.parse(url));
  final HttpClientResponse resp = await req.close();
  if (resp.statusCode != 200) {
    throw HttpException('HTTP ${resp.statusCode} for $url');
  }
  return resp.transform(utf8.decoder).join();
}

/// One manufacturer sub-page on twrp.me.
class _Oem {
  _Oem(this.brand, this.url);
  final String brand;
  final String url;
}

class _Device {
  _Device(this.brand, this.model, this.codename);
  final String brand;
  final String model;
  final String codename;
}

/// Parses the OEM index page. Anchors look like:
///   <a href="/Devices/Samsung/">Samsung</a>
/// (Some OEMs contain spaces / ampersands, e.g. "Barnes & Noble".)
List<_Oem> _parseIndex(String html) {
  final RegExp re = RegExp(
    r'href="/Devices/([^"]+?)/"\s*>\s*([^<]+?)\s*<',
    multiLine: true,
  );
  final List<_Oem> out = <_Oem>[];
  final Set<String> seen = <String>{};
  for (final RegExpMatch m in re.allMatches(html)) {
    final String pathSeg = m.group(1)!.trim();
    final String brand = _decodeEntities(m.group(2)!).trim();
    if (brand.isEmpty || pathSeg.isEmpty) continue;
    if (!seen.add(brand)) continue;
    final String url =
        'https://twrp.me/Devices/${Uri.encodeComponent(pathSeg)}/';
    out.add(_Oem(brand, url));
  }
  return out;
}

/// Parses a single OEM page. Device anchors look like:
///   <a href="/google/googlepixel5.html">Google Pixel 5 (redfin)</a>
/// The visible text is "Marketing Name (codename)"; the last parenthesised
/// group is the codename and everything before it is the model.
List<_Device> _parseOemPage(String html, String brand) {
  final RegExp anchor = RegExp(
    r'href="(/[^"]+?\.html)"\s*>\s*([^<]+?)\s*<',
    multiLine: true,
  );
  final RegExp nameCodename = RegExp(r'^(.*)\(([^()]+)\)\s*$');
  final List<_Device> out = <_Device>[];
  for (final RegExpMatch m in anchor.allMatches(html)) {
    final String href = m.group(1)!;
    // Skip non-device links (terms, faq, contact) that share the .html shape.
    if (href.startsWith('/terms/') ||
        href.startsWith('/about') ||
        href.startsWith('/FAQ') ||
        href.startsWith('/contactus')) {
      continue;
    }
    final String text = _decodeEntities(m.group(2)!).trim();
    if (text.isEmpty) continue;
    final RegExpMatch? nm = nameCodename.firstMatch(text);
    String model;
    String codename;
    if (nm != null) {
      model = nm.group(1)!.trim();
      codename = nm.group(2)!.trim();
    } else {
      // No parenthesised codename; fall back to the URL filename.
      model = text;
      codename = href.split('/').last.replaceAll('.html', '');
    }
    if (model.isEmpty) model = codename;
    if (codename.isEmpty) continue;
    out.add(_Device(brand, model, codename));
  }
  return out;
}

/// Minimal HTML entity decode for the handful that appear in device names.
String _decodeEntities(String s) {
  return s
      .replaceAll('&amp;', '&')
      .replaceAll('&#39;', "'")
      .replaceAll('&quot;', '"')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&nbsp;', ' ');
}
