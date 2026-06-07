import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

/// What the running hardware reports about itself, normalised for catalog
/// lookups. Only meaningful on Android; every other platform yields
/// [DetectedDevice.none].
class DetectedDevice {
  const DetectedDevice({
    required this.codename,
    required this.manufacturer,
    required this.model,
  });

  /// Empty sentinel used on non-Android platforms or when detection fails.
  static const DetectedDevice none =
      DetectedDevice(codename: '', manufacturer: '', model: '');

  /// `ro.product.device`, which for most phones matches the LineageOS-style
  /// codename the catalog keys on (e.g. `oriole`, `alioth`). Lower-cased.
  final String codename;

  /// `ro.product.manufacturer` (e.g. `Google`, `samsung`). Casing varies by
  /// OEM, so this is only a display/secondary hint, never a match key.
  final String manufacturer;

  /// Marketing model string (e.g. `Pixel 6`). Display only.
  final String model;

  bool get hasCodename => codename.isNotEmpty;
}

/// Reads the current device's codename on Android so the app can offer to
/// jump straight to its catalog page. Fully local: no network, no analytics,
/// no permissions. Returns [DetectedDevice.none] on iOS, desktop, and web.
class DeviceDetector {
  DeviceDetector({DeviceInfoPlugin? deviceInfo})
      : _deviceInfo = deviceInfo ?? DeviceInfoPlugin();

  static final DeviceDetector instance = DeviceDetector();

  final DeviceInfoPlugin _deviceInfo;

  /// True only where a codename maps onto the Android catalog. Other
  /// platforms (iOS machine ids, desktop) have nothing useful to detect.
  static bool get isSupported => !kIsWeb && Platform.isAndroid;

  DetectedDevice? _cached;

  /// Detects the device once and caches it. Never throws: any failure
  /// (plugin error, unexpected platform) resolves to [DetectedDevice.none].
  Future<DetectedDevice> detect() async {
    if (_cached != null) return _cached!;
    if (!isSupported) {
      return _cached = DetectedDevice.none;
    }
    try {
      final AndroidDeviceInfo info = await _deviceInfo.androidInfo;
      _cached = DetectedDevice(
        codename: info.device.trim().toLowerCase(),
        manufacturer: info.manufacturer.trim(),
        model: info.model.trim(),
      );
    } on Object {
      _cached = DetectedDevice.none;
    }
    return _cached!;
  }
}
