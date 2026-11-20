import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/pages/device_model_page.dart';
import 'package:custom_rr/theme.dart';
import 'package:custom_rr/util/bootloader_lock.dart';
import 'package:custom_rr/widgets/bootloader_lock_banner.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  Widget wrap(Widget child) => MaterialApp(theme: AppTheme.light(), home: child);

  testWidgets('exact banner says the bootloader is locked', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Scaffold(
      body: BootloaderLockBanner(lock: BootloaderLock(model: 'SM-A015U', region: 'US')),
    )));
    expect(find.text('Bootloader locked'), findsOneWidget);
    expect(find.textContaining('SM-A015U'), findsOneWidget);
    expect(find.textContaining('cannot normally be unlocked'), findsOneWidget);
  });

  testWidgets('non-exact banner is the softer "some variants" note', (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Scaffold(
      body: BootloaderLockBanner(
        lock: BootloaderLock(model: 'SM-A135U', region: 'US'),
        exact: false,
      ),
    )));
    expect(find.text('Some variants are locked'), findsOneWidget);
    expect(find.textContaining('International variants unlock normally'), findsOneWidget);
    expect(find.text('Bootloader locked'), findsNothing);
  });

  group('on the real device page', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String json = File('assets/catalog.json').readAsStringSync();
      await CatalogRepository.instance.load(overrideJson: json);
    });

    testWidgets('a codename with a locked US variant shows the soft note',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(420, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // a13 bundles SM-A135U (locked US variant) in the bundled catalog.
      await tester.pumpWidget(wrap(const DeviceModelPage(brand: 'Samsung', codename: 'a13')));
      await tester.pump();

      expect(find.text('Some variants are locked'), findsOneWidget);
    });
  });
}
