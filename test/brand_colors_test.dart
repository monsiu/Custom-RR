import 'package:custom_rr/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks in the contract for [BrandColors]: present on both light and dark
/// themes, anchored on [kBrandSeed], and reachable through the
/// [BrandColorsX] context extension.
void main() {
  test('light theme registers BrandColors anchored on kBrandSeed', () {
    final ThemeData theme = AppTheme.light();
    final BrandColors? brand = theme.extension<BrandColors>();
    expect(brand, isNotNull);
    expect(brand!.seed, kBrandSeed);
    expect(brand.dark, isNot(equals(brand.seed)));
    expect(brand.deep, isNot(equals(brand.dark)));
  });

  test('dark theme also registers BrandColors', () {
    final ThemeData theme = AppTheme.dark();
    final BrandColors? brand = theme.extension<BrandColors>();
    expect(brand, isNotNull);
    expect(brand!.seed, kBrandSeed);
  });

  test('amoled dark theme keeps BrandColors intact', () {
    final ThemeData theme = AppTheme.dark(amoled: true);
    final BrandColors? brand = theme.extension<BrandColors>();
    expect(brand, isNotNull);
    expect(brand!.seed, kBrandSeed);
  });

  testWidgets('context.brand resolves to the registered extension',
      (WidgetTester tester) async {
    late BrandColors captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Builder(
          builder: (BuildContext context) {
            captured = context.brand;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(captured.seed, kBrandSeed);
  });

  testWidgets('context.brand falls back to standard palette when extension missing',
      (WidgetTester tester) async {
    late BrandColors captured;
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(useMaterial3: true),
        home: Builder(
          builder: (BuildContext context) {
            captured = context.brand;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(captured.seed, kBrandSeed);
  });

  test('lerp produces an intermediate palette', () {
    final BrandColors a = BrandColors.standard;
    final BrandColors b = BrandColors(
      seed: const Color(0xFF000000),
      dark: const Color(0xFF000000),
      deep: const Color(0xFF000000),
      onSeed: const Color(0xFFFFFFFF),
    );
    final ThemeExtension<BrandColors> midExt = a.lerp(b, 0.5);
    final BrandColors mid = midExt as BrandColors;
    expect(mid.seed, isNot(equals(a.seed)));
    expect(mid.seed, isNot(equals(b.seed)));
  });

  test('copyWith overrides only specified fields', () {
    final BrandColors override = BrandColors.standard
        .copyWith(seed: const Color(0xFF112233));
    expect(override.seed, const Color(0xFF112233));
    expect(override.dark, BrandColors.standard.dark);
    expect(override.deep, BrandColors.standard.deep);
    expect(override.onSeed, BrandColors.standard.onSeed);
  });
}
