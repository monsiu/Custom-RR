// Sweeps every screenshot URL referenced in assets/catalog.json with an
// HTTP HEAD (falling back to a Range:bytes=0-0 GET when HEAD is unsupported)
// and reports any URL that:
//   - returns a non-2xx status code,
//   - returns a non-image Content-Type, or
//   - times out.
//
// Catches link rot before users do. Not wired into CI by default because
// it makes ~50 outbound requests per run; invoke it manually or from a
// scheduled workflow:
//
//   dart run tool/check_screenshot_urls.dart
//
// Exit codes:
//   0  all URLs OK
//   1  at least one URL failed
//   2  catalog.json missing or unparseable

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const Duration _timeout = Duration(seconds: 15);
const int _concurrency = 8;

Future<void> main(List<String> args) async {
  final File catalog = File('assets/catalog.json');
  if (!catalog.existsSync()) {
    stderr.writeln('assets/catalog.json missing');
    exit(2);
  }
  Map<String, dynamic> root;
  try {
    root = jsonDecode(catalog.readAsStringSync()) as Map<String, dynamic>;
  } on FormatException catch (e) {
    stderr.writeln('catalog.json parse error: $e');
    exit(2);
  }

  final List<_Job> jobs = <_Job>[];
  for (final String section in <String>['roms', 'recoveries']) {
    final List<dynamic>? entries = root[section] as List<dynamic>?;
    if (entries == null) continue;
    for (final dynamic e in entries) {
      if (e is! Map) continue;
      final String id = (e['id'] ?? '?').toString();
      final List<dynamic>? shots = e['screenshots'] as List<dynamic>?;
      if (shots == null) continue;
      for (final dynamic s in shots) {
        if (s is String && s.isNotEmpty) {
          jobs.add(_Job(section: section, id: id, url: s));
        }
      }
    }
  }

  stdout.writeln('Checking ${jobs.length} screenshot URLs '
      '(concurrency=$_concurrency)...');

  final HttpClient client = HttpClient()
    ..connectionTimeout = _timeout
    ..userAgent = 'CustomRR-link-check/1.0';

  final List<_Result> results = <_Result>[];
  int idx = 0;
  Future<void> worker() async {
    while (true) {
      final int i = idx++;
      if (i >= jobs.length) return;
      results.add(await _check(client, jobs[i]));
    }
  }

  await Future.wait(<Future<void>>[
    for (int i = 0; i < _concurrency; i++) worker(),
  ]);
  client.close(force: true);

  final List<_Result> failures =
      results.where((_Result r) => !r.ok).toList(growable: false);

  stdout.writeln('');
  stdout.writeln(
    'OK: ${results.length - failures.length} / ${results.length}',
  );
  if (failures.isEmpty) {
    return;
  }
  stdout.writeln('Failures (${failures.length}):');
  for (final _Result f in failures) {
    stdout.writeln('  [${f.job.section}/${f.job.id}] ${f.job.url}');
    stdout.writeln('    ${f.reason}');
  }
  exit(1);
}

Future<_Result> _check(HttpClient client, _Job job) async {
  try {
    final Uri uri = Uri.parse(job.url);
    HttpClientRequest req = await client.headUrl(uri).timeout(_timeout);
    HttpClientResponse res = await req.close().timeout(_timeout);
    // Some CDNs / Wayback return 405 on HEAD; retry with a tiny Range GET.
    if (res.statusCode == 405 || res.statusCode == 501) {
      await res.drain<void>();
      req = await client.getUrl(uri).timeout(_timeout);
      req.headers.set(HttpHeaders.rangeHeader, 'bytes=0-0');
      res = await req.close().timeout(_timeout);
    }
    final int code = res.statusCode;
    final String? ctype = res.headers.value(HttpHeaders.contentTypeHeader);
    await res.drain<void>();
    if (code < 200 || code >= 400) {
      return _Result(job, false, 'HTTP $code');
    }
    if (ctype != null && !ctype.toLowerCase().startsWith('image/')) {
      return _Result(job, false, 'non-image content-type: $ctype');
    }
    return _Result(job, true, 'HTTP $code ${ctype ?? '(no type)'}');
  } on TimeoutException {
    return _Result(job, false, 'timeout');
  } on Object catch (e) {
    return _Result(job, false, '$e');
  }
}

class _Job {
  _Job({required this.section, required this.id, required this.url});
  final String section;
  final String id;
  final String url;
}

class _Result {
  _Result(this.job, this.ok, this.reason);
  final _Job job;
  final bool ok;
  final String reason;
}
