import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/update_checker.dart';
import '../data/update_installer.dart';

/// Shows the canonical update dialog. Used both by the "Check for updates"
/// button on the About page and by the persistent update banner so behaviour
/// is identical: release notes, an "Open release" link to GitHub, and on
/// Android a "Download & install" button that side-loads the matching APK.
Future<void> showUpdateDialog(
  BuildContext context,
  UpdateCheckResult result,
) {
  final ColorScheme scheme = Theme.of(context).colorScheme;
  final bool noReleases = result.latestVersion.isEmpty;
  final bool upToDate = !noReleases && !result.isUpdateAvailable;

  final String title = noReleases
      ? 'No releases yet'
      : upToDate
          ? "You're up to date"
          : 'Update available';

  final String message = noReleases
      ? 'This repository has no published releases yet. You can still '
          'browse the source on GitHub.'
      : upToDate
          ? 'You are running the latest version (v${result.currentVersion}).'
          : 'Custom RR v${result.latestVersion} is available. '
              'You are on v${result.currentVersion}.';

  final String notes = result.releaseNotes.trim();
  final String trimmedNotes =
      notes.length > 1200 ? '${notes.substring(0, 1200)}\u2026' : notes;

  return showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      return AlertDialog(
        icon: Icon(
          upToDate ? Icons.check_circle_outline : Icons.system_update_alt,
          color: scheme.primary,
        ),
        title: Text(title),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(message),
                if (!noReleases &&
                    !upToDate &&
                    result.releaseName.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 12),
                  Text(
                    result.releaseName,
                    style: Theme.of(ctx).textTheme.titleSmall,
                  ),
                ],
                if (!noReleases &&
                    !upToDate &&
                    trimmedNotes.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text(
                    trimmedNotes,
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(upToDate ? 'OK' : 'Later'),
          ),
          if (result.releaseUrl.isNotEmpty)
            TextButton(
              onPressed: () async {
                Navigator.of(ctx).pop();
                final Uri uri = Uri.parse(result.releaseUrl);
                final bool ok = await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
                if (!ok && context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Could not open ${uri.toString()}')),
                  );
                }
              },
              child: Text(noReleases ? 'Open repository' : 'Open release'),
            ),
          if (!noReleases &&
              !upToDate &&
              UpdateInstaller.isSupported &&
              result.assets.any((ReleaseAsset a) => a.isApk))
            FilledButton.icon(
              icon: const Icon(Icons.download),
              label: const Text('Download & install'),
              onPressed: () {
                Navigator.of(ctx).pop();
                _downloadAndInstall(context, result);
              },
            ),
        ],
      );
    },
  );
}

/// Turns an arbitrary error into a short, user-readable line.
/// Strips Dio's noisy stack-trace style toString and exposes the
/// underlying network/IO cause where useful.
String humanizeUpdateError(Object error) {
  if (error is NoMatchingApkException) {
    return 'No APK in this release matches your device '
        '(supported: ${error.supportedAbis.join(", ")}).';
  }
  if (error is InstallLaunchException) {
    return 'Could not open the system installer. '
        'Allow "Install unknown apps" for Custom RR in Settings, then retry.';
  }
  if (error is DioException) {
    if (CancelToken.isCancel(error)) return 'Download cancelled.';
    final int? code = error.response?.statusCode;
    final String host = error.requestOptions.uri.host;
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Network timed out contacting $host. Check your connection and retry.';
      case DioExceptionType.badCertificate:
        return 'TLS certificate from $host was rejected.';
      case DioExceptionType.connectionError:
        final Object? inner = error.error;
        if (inner is SocketException) {
          return 'Network unreachable: ${inner.osError?.message ?? inner.message}.';
        }
        return 'Could not reach $host. Check your connection.';
      case DioExceptionType.badResponse:
        return 'Server returned HTTP $code from $host.';
      case DioExceptionType.cancel:
        return 'Download cancelled.';
      case DioExceptionType.unknown:
        final Object? inner = error.error;
        if (inner is SocketException) {
          return 'Network error: ${inner.osError?.message ?? inner.message}.';
        }
        return 'Network error contacting $host.';
    }
  }
  if (error is SocketException) {
    return 'Network error: ${error.osError?.message ?? error.message}.';
  }
  if (error is HttpException) {
    return 'HTTP error: ${error.message}.';
  }
  if (error is FormatException) {
    return 'Could not parse server response: ${error.message}.';
  }
  if (error is FileSystemException) {
    final String detail = error.osError?.message ?? error.message;
    return 'File system error: $detail.';
  }
  final String s = error.toString();
  // Trim Dio's multi-line dump so SnackBars stay readable.
  final int nl = s.indexOf('\n');
  return nl > 0 ? s.substring(0, nl) : s;
}

void _showUpdateError(BuildContext context, String headline, Object error) {
  showDialog<void>(
    context: context,
    builder: (BuildContext ctx) {
      final ColorScheme scheme = Theme.of(ctx).colorScheme;
      return AlertDialog(
        icon: Icon(Icons.error_outline, color: scheme.error),
        title: Text(headline),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: SingleChildScrollView(
            child: Text(humanizeUpdateError(error)),
          ),
        ),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('OK'),
          ),
        ],
      );
    },
  );
}

Future<void> _downloadAndInstall(
  BuildContext context,
  UpdateCheckResult result,
) async {
  final UpdateInstaller installer = UpdateInstaller.instance;
  final ReleaseAsset? asset;
  try {
    asset = await installer.pickAssetForDevice(result.assets);
  } on Object catch (e) {
    if (!context.mounted) return;
    _showUpdateError(context, 'Cannot install update', e);
    return;
  }
  if (asset == null) {
    if (!context.mounted) return;
    _showUpdateError(
      context,
      'No installable asset',
      const FormatException('This release has no APK assets.'),
    );
    return;
  }

  final CancelToken cancelToken = CancelToken();
  final ({Stream<DownloadProgress> progress, Future<File> done}) job =
      installer.download(asset, cancelToken: cancelToken);

  if (!context.mounted) return;
  final bool? completed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext ctx) => _DownloadProgressDialog(
      asset: asset!,
      progress: job.progress,
      done: job.done,
      cancelToken: cancelToken,
    ),
  );

  if (completed != true || !context.mounted) return;
  try {
    final File apk = await job.done;
    await installer.install(apk);
  } on Object catch (e) {
    if (!context.mounted) return;
    _showUpdateError(context, 'Install failed', e);
  }
}

class _DownloadProgressDialog extends StatefulWidget {
  const _DownloadProgressDialog({
    required this.asset,
    required this.progress,
    required this.done,
    required this.cancelToken,
  });

  final ReleaseAsset asset;
  final Stream<DownloadProgress> progress;
  final Future<File> done;
  final CancelToken cancelToken;

  @override
  State<_DownloadProgressDialog> createState() =>
      _DownloadProgressDialogState();
}

class _DownloadProgressDialogState extends State<_DownloadProgressDialog> {
  DownloadProgress _latest = const DownloadProgress(0, -1);
  Object? _error;
  bool _finished = false;
  late final StreamSubscription<DownloadProgress> _sub;

  @override
  void initState() {
    super.initState();
    _sub = widget.progress.listen((DownloadProgress p) {
      if (!mounted) return;
      setState(() => _latest = p);
    });
    widget.done.then((_) {
      if (!mounted) return;
      setState(() => _finished = true);
      Navigator.of(context).pop(true);
    }).catchError((Object e) {
      if (!mounted) return;
      if (e is DioException && CancelToken.isCancel(e)) {
        Navigator.of(context).pop(false);
        return;
      }
      setState(() => _error = e);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  String _formatBytes(int b) {
    if (b <= 0) return '0 B';
    const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
    double v = b.toDouble();
    int i = 0;
    while (v >= 1024 && i < units.length - 1) {
      v /= 1024;
      i++;
    }
    return '${v.toStringAsFixed(v >= 10 || i == 0 ? 0 : 1)} ${units[i]}';
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final double? frac = _error != null ? 0 : _latest.fraction;
    final String sub = _error != null
        ? humanizeUpdateError(_error!)
        : _finished
            ? 'Download complete'
            : _latest.total > 0
                ? '${_formatBytes(_latest.received)} of ${_formatBytes(_latest.total)}'
                : 'Starting download...';
    final Color? subColor =
        _error != null ? theme.colorScheme.error : null;

    return AlertDialog(
      icon: Icon(
        _error != null ? Icons.error_outline : Icons.download,
        color:
            _error != null ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(_error != null ? 'Download failed' : 'Downloading update'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.asset.name,
            style: theme.textTheme.bodyMedium,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          if (_error == null) LinearProgressIndicator(value: frac),
          if (_error == null) const SizedBox(height: 8),
          Text(
            sub,
            style: theme.textTheme.bodySmall?.copyWith(color: subColor),
          ),
        ],
      ),
      actions: <Widget>[
        if (_error != null)
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Close'),
          )
        else
          TextButton(
            onPressed: () {
              if (!widget.cancelToken.isCancelled) {
                widget.cancelToken.cancel('user-cancelled');
              }
              Navigator.of(context).pop(false);
            },
            child: const Text('Cancel'),
          ),
      ],
    );
  }
}
