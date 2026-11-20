import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/models.dart';
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

  testWidgets('non-exact with an unlockable sibling is the softer "some variants" note',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Scaffold(
      body: BootloaderLockBanner(
        lock: BootloaderLock(model: 'SM-A135U', region: 'US'),
        exact: false,
        hasUnlockableVariant: true,
      ),
    )));
    expect(find.text('Some variants are locked'), findsOneWidget);
    expect(find.textContaining('International variants unlock normally'), findsOneWidget);
    expect(find.text('Bootloader locked'), findsNothing);
  });

  testWidgets('non-exact with no unlockable sibling is a hard all-variants-locked note',
      (WidgetTester tester) async {
    await tester.pumpWidget(wrap(const Scaffold(
      body: BootloaderLockBanner(
        lock: BootloaderLock(model: 'SM-A135U', region: 'US'),
        exact: false,
        hasUnlockableVariant: false,
      ),
    )));
    expect(find.text('Bootloader locked'), findsOneWidget);
    expect(find.textContaining('Every known variant'), findsOneWidget);
    expect(find.textContaining('International variants unlock normally'), findsNothing);
  });

  group('on the real device page', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      final String json = File('assets/catalog.json').readAsStringSync();
      await CatalogRepository.instance.load(overrideJson: json);
    });

    testWidgets('a codename with a locked variant shows a lock banner',
        (WidgetTester tester) async {
      // Discover a real (brand, codename) that has a locked model, rather than
      // hardcoding one, so a nightly catalog refresh cannot break this test.
      final CatalogRepository repo = CatalogRepository.instance;
      ({String brand, String codename})? target;
      for (final CatalogEntry e in <CatalogEntry>[...repo.roms, ...repo.recoveries]) {
        for (final DeviceRef d in e.devices) {
          if (d.codename.isNotEmpty && bootloaderLockForModels(d.models) != null) {
            target = (brand: d.brand, codename: d.codename);
            break;
          }
        }
        if (target != null) break;
      }
      if (target == null) {
        markTestSkipped('no catalogued device currently carries a locked model');
        return;
      }

      tester.view.physicalSize = const Size(420, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrap(DeviceModelPage(brand: target.brand, codename: target.codename)),
      );
      await tester.pump();

      // Either wording is acceptable depending on whether an unlockable
      // sibling exists; both render through BootloaderLockBanner.
      expect(find.byType(BootloaderLockBanner), findsOneWidget);
    });
  });
}
