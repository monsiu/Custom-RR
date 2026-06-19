import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/data/selected_device_controller.dart';
import 'package:custom_rr/models.dart';
import 'package:custom_rr/pages/roms_page.dart';
import 'package:custom_rr/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Widget tests for the selected-device filter banner on the ROMs list.
void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String json = File('assets/catalog.json').readAsStringSync();
    await CatalogRepository.instance.load(overrideJson: json);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await SelectedDeviceController.instance.clear();
  });

  /// First catalogued device that at least one ROM supports, so the filter
  /// has something real to match.
  DeviceRef firstSupportedDevice() {
    for (final CatalogEntry e in CatalogRepository.instance.roms) {
      for (final DeviceRef d in e.devices) {
        if (d.codename.isNotEmpty) return d;
      }
    }
    fail('catalog has no ROM with a device codename');
  }

  Widget wrap() => MaterialApp(
        theme: AppTheme.light(),
        home: const RomsPage(),
      );

  testWidgets('no banner when no device is selected',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.textContaining('Showing builds for'), findsNothing);
    expect(find.textContaining('Showing all builds'), findsNothing);
  });

  testWidgets('banner appears and Show all toggles the filter off',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(420, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    final DeviceRef dev = firstSupportedDevice();
    await SelectedDeviceController.instance.select(
      brand: dev.brand,
      codename: dev.codename,
      model: dev.model,
    );

    await tester.pumpWidget(wrap());
    await tester.pump();

    expect(find.textContaining('Showing builds for'), findsOneWidget);

    await tester.tap(find.text('Show all'));
    await tester.pump();

    expect(find.textContaining('Showing all builds'), findsOneWidget);

    // Re-applying the filter restores the active banner.
    await tester.tap(find.text('Filter'));
    await tester.pump();
    expect(find.textContaining('Showing builds for'), findsOneWidget);
  });
}
