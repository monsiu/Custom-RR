import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../util/build_flags.dart';
import 'update_checker.dart';

/// Snapshot of a download in flight. Emitted by [UpdateInstaller.download]
/// so the UI can render a progress bar.
class DownloadProgress {
  const DownloadProgress(this.received, this.total);

  /// Bytes received so far.
  final int received;

  /// Total bytes if known. -1 when the server did not report a length.
  final int total;

  bool get isIndeterminate => total <= 0;
  double? get fraction =>
      isIndeterminate ? null : (received / total).clamp(0.0, 1.0);
}

/// Thrown when none of the release assets match this device's ABIs.
class NoMatchingApkException implements Exception {
  NoMatchingApkException(this.supportedAbis, this.assetNames);
  final List<String> supportedAbis;
  final List<String> assetNames;
  @override
  String toString() =>
      'No APK in release matches device ABIs $supportedAbis '
      '(available: $assetNames)';
}

/// Thrown when the system installer refuses to launch the APK.
class InstallLaunchException implements Exception {
  InstallLaunchException(this.message);
  final String message;
  @override
  String toString() => 'Installer failed: $message';
}

/// Downloads the per-ABI APK that matches the current Android device from a
/// GitHub release and hands it to the system package installer. Android-only;
/// callers should gate UI on [isSupported].
class UpdateInstaller {
  UpdateInstaller({
    DeviceInfoPlugin? deviceInfo,
    Dio? dio,
  })  : _deviceInfo = deviceInfo ?? DeviceInfoPlugin(),
        _dio = dio ?? Dio();

  static final UpdateInstaller instance = UpdateInstaller();

  final DeviceInfoPlugin _deviceInfo;
  final Dio _dio;

  /// True on Android (the only platform where APK side-loading makes sense).
  /// Always false in F-Droid builds: that variant ships without the in-app
  /// installer because F-Droid updates the app itself.
  static bool get isSupported =>
      !kFdroidBuild && !kIsWeb && Platform.isAndroid;

  /// Picks the best-matching APK asset for this device, preferring earlier
  /// entries in [AndroidDeviceInfo.supportedAbis] (which Android orders by
  /// preference). Returns `null` if there are no APKs at all.
  Future<ReleaseAsset?> pickAssetForDevice(List<ReleaseAsset> assets) async {
    final List<ReleaseAsset> apks =
        assets.where((ReleaseAsset a) => a.isApk).toList();
    if (apks.isEmpty) return null;
    if (!isSupported) return apks.first;

    final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
    final List<String> abis = info.supportedAbis;
    for (final String abi in abis) {
      // Match on `-<abi>-` or `-<abi>.apk` so we do not accidentally pick
      // `armeabi-v7a` when looking for `arm`.
      for (final ReleaseAsset asset in apks) {
        final String lower = asset.name.toLowerCase();
        if (lower.contains('-$abi-') || lower.contains('-$abi.')) {
          return asset;
        }
      }
    }
    // No ABI match. Fall back to a "universal" APK if one was uploaded.
    for (final ReleaseAsset asset in apks) {
      final String lower = asset.name.toLowerCase();
      if (lower.contains('universal') || !lower.contains('-v')) {
        return asset;
      }
    }
    throw NoMatchingApkException(
      abis,
      apks.map((ReleaseAsset a) => a.name).toList(growable: false),
    );
  }

  /// Downloads [asset] into the app's temporary directory and emits
  /// progress events on the returned stream. The stream completes when
  /// the file is fully written; the future returned by [done] resolves to
  /// the local file path.
  ///
  /// Pass [cancelToken] to abort an in-flight download.
  ({Stream<DownloadProgress> progress, Future<File> done}) download(
    ReleaseAsset asset, {
    CancelToken? cancelToken,
  }) {
    final StreamController<DownloadProgress> controller =
        StreamController<DownloadProgress>.broadcast();
    final Future<File> file = _runDownload(asset, controller, cancelToken);
    return (progress: controller.stream, done: file);
  }

  Future<File> _runDownload(
    ReleaseAsset asset,
    StreamController<DownloadProgress> controller,
    CancelToken? cancelToken,
  ) async {
    try {
      final Directory dir = await getTemporaryDirectory();
      final String safeName = asset.name.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
      final File file = File('${dir.path}/$safeName');
      if (await file.exists()) {
        await file.delete();
      }
      await _dio.download(
        asset.downloadUrl,
        file.path,
        cancelToken: cancelToken,
        onReceiveProgress: (int received, int total) {
          if (!controller.isClosed) {
            controller.add(DownloadProgress(received, total));
          }
        },
        options: Options(
          followRedirects: true,
          headers: <String, String>{
            'Accept': 'application/octet-stream',
          },
        ),
      );
      return file;
    } finally {
      await controller.close();
    }
  }

  /// Launches the system package installer for [apk]. The user still has
  /// to confirm in Android's installer UI. Throws [InstallLaunchException]
  /// if the OS refuses (most commonly because "Install unknown apps" is
  /// disabled for this app).
  Future<void> install(File apk) async {
    final OpenResult result = await OpenFilex.open(
      apk.path,
      type: 'application/vnd.android.package-archive',
    );
    if (result.type != ResultType.done) {
      throw InstallLaunchException(result.message);
    }
  }
}
