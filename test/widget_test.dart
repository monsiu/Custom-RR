import 'dart:io';

import 'package:custom_rr/app.dart';
import 'package:custom_rr/data/catalog_repository.dart';
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
}
