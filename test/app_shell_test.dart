import 'dart:io';

import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/pages/home_page.dart';
import 'package:custom_rr/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Size size) {
  return MediaQuery(
    data: MediaQueryData(size: size),
    child: MaterialApp(
      theme: AppTheme.light(),
      home: const HomePage(),
    ),
  );
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String json = File('assets/catalog.json').readAsStringSync();
    await CatalogRepository.instance.load(overrideJson: json);
  });

  testWidgets('compact width uses a Drawer', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const Size(400, 800)));
    await tester.pump();

    expect(find.byType(NavigationRail), findsNothing);
    // Drawer is offscreen until opened; verify a hamburger menu is wired.
    expect(find.byTooltip('Open navigation menu'), findsOneWidget);
  });

  testWidgets('medium width shows a NavigationRail',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const Size(800, 900)));
    await tester.pump();

    expect(find.byType(NavigationRail), findsOneWidget);
  });

  testWidgets('expanded width shows a permanent navigation panel',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(_wrap(const Size(1400, 900)));
    await tester.pump();

    expect(find.byType(VerticalDivider), findsWidgets);
    expect(find.byType(NavigationRail), findsNothing);
  });
}
