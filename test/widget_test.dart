import 'dart:io';

import 'package:custom_rr/app.dart';
import 'package:custom_rr/data/catalog_repository.dart';
import 'package:custom_rr/pages/roms_page.dart';
import 'package:custom_rr/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final String json = File('assets/catalog.json').readAsStringSync();
    await CatalogRepository.instance.load(overrideJson: json);
  });

  testWidgets('Custom RR smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const CustomRrApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    expect(find.text('Custom RR'), findsWidgets);
    expect(find.text('Welcome to Custom RR'), findsOneWidget);
  });

  testWidgets('static deep-link paths remain case-insensitive',
      (WidgetTester tester) async {
    final router = buildRouter();
    addTearDown(router.dispose);

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    router.go('/ROMS');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byType(RomsPage), findsOneWidget);
  });
}
