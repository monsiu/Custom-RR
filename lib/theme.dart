import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand colour for Custom RR (Custom ROMs & Recoveries).
const Color kBrandSeed = Color(0xFF7ED957);

/// Theme extension that carries Custom RR's brand palette alongside the
/// Material You / dynamic colour scheme. Use this whenever a widget needs
/// to render in the app's signature green regardless of the user's
/// wallpaper-derived accent (e.g. the launcher splash, easter-egg
/// payoffs, marketing-style headers).
///
/// Read with `Theme.of(context).extension<BrandColors>()!` or via the
/// [BrandColorsX] context extension.
@immutable
class BrandColors extends ThemeExtension<BrandColors> {
  const BrandColors({
    required this.seed,
    required this.dark,
    required this.deep,
    required this.onSeed,
  });

  /// Anchor brand colour (Custom RR green). Use as a primary surface or
  /// accent that must read as "the brand".
  final Color seed;

  /// Darker variant of [seed], suitable for mid-stops in gradients or for
  /// pressed/active states on top of a [seed] surface.
  final Color dark;

  /// Deepest variant of [seed], suitable for the bottom of a brand
  /// gradient or for shadows / borders on brand surfaces.
  final Color deep;

  /// Foreground colour with sufficient contrast against [seed]. Currently
  /// fixed to black because the brand green is bright enough that white
  /// text would fail WCAG AA at body sizes.
  final Color onSeed;

  /// Standard Custom RR brand palette, derived from [kBrandSeed]. Pre-built
  /// so we don't recompute the lerps on every theme rebuild.
  static final BrandColors standard = BrandColors(
    seed: kBrandSeed,
    dark: Color.lerp(kBrandSeed, Colors.black, 0.45)!,
    deep: Color.lerp(kBrandSeed, Colors.black, 0.70)!,
    onSeed: const Color(0xFF0A1F0E),
  );

  @override
  BrandColors copyWith({
    Color? seed,
    Color? dark,
    Color? deep,
    Color? onSeed,
  }) {
    return BrandColors(
      seed: seed ?? this.seed,
      dark: dark ?? this.dark,
      deep: deep ?? this.deep,
      onSeed: onSeed ?? this.onSeed,
    );
  }

  @override
  BrandColors lerp(ThemeExtension<BrandColors>? other, double t) {
    if (other is! BrandColors) return this;
    return BrandColors(
      seed: Color.lerp(seed, other.seed, t)!,
      dark: Color.lerp(dark, other.dark, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      onSeed: Color.lerp(onSeed, other.onSeed, t)!,
    );
  }
}

/// Convenience accessor: `context.brand.seed` rather than the
/// verbose `Theme.of(context).extension<BrandColors>()!.seed`. Falls back
/// to [BrandColors.standard] if the extension was somehow not registered,
/// so widgets never need a nullable dance.
extension BrandColorsX on BuildContext {
  BrandColors get brand =>
      Theme.of(this).extension<BrandColors>() ?? BrandColors.standard;
}

class AppTheme {
  const AppTheme._();

  static ThemeData light({ColorScheme? dynamicScheme}) =>
      _build(Brightness.light, dynamicScheme, amoled: false);
  static ThemeData dark({ColorScheme? dynamicScheme, bool amoled = false}) =>
      _build(Brightness.dark, dynamicScheme, amoled: amoled);

  static ThemeData _build(
    Brightness brightness,
    ColorScheme? override, {
    required bool amoled,
  }) {
    // Material You: when a wallpaper-derived scheme is available
    // (Android 12+, some macOS builds) use it directly so every role in
    // the palette tracks the user's accent. Harmonizing the dynamic
    // primary against the brand seed clamps everything back to green and
    // defeats Material You, so we only fall back to a brand-seeded scheme
    // when no dynamic scheme is provided by the platform.
    ColorScheme scheme = override ??
        ColorScheme.fromSeed(
          seedColor: kBrandSeed,
          brightness: brightness,
        );
    final bool isDark = brightness == Brightness.dark;
    // AMOLED variant: collapse the dark surface tones to pure black so
    // OLED pixels switch off. Keep container tones as very-dark neutrals
    // so cards and chips stay distinguishable from the background.
    if (isDark && amoled) {
      const Color black = Color(0xFF000000);
      scheme = scheme.copyWith(
        surface: black,
        surfaceDim: black,
        surfaceBright: const Color(0xFF1A1A1A),
        surfaceContainerLowest: black,
        surfaceContainerLow: const Color(0xFF0A0A0A),
        surfaceContainer: const Color(0xFF111111),
        surfaceContainerHigh: const Color(0xFF161616),
        surfaceContainerHighest: const Color(0xFF1C1C1C),
        surfaceTint: scheme.primary,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,

      // Register Custom RR's brand palette as a ThemeExtension so any
      // widget can opt back into the signature green even when the
      // dynamic-colour scheme resolves to something else (blue / purple
      // wallpaper accents on Android 12+, GTK accents on Linux, etc).
      extensions: <ThemeExtension<dynamic>>[
        BrandColors.standard,
      ],

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: scheme.surfaceTint,
      ),

      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        elevation: 1,
        margin: const EdgeInsets.all(8),
        color: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),

      listTileTheme: ListTileThemeData(
        iconColor: scheme.onSurfaceVariant,
        textColor: scheme.onSurface,
        selectedTileColor: scheme.secondaryContainer,
        selectedColor: scheme.onSecondaryContainer,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),

      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant,
        thickness: 1,
        space: 16,
      ),

      chipTheme: ChipThemeData(
        // Bind every chip slot explicitly to the active scheme. Without this
        // Flutter's M3 chip defaults pin the leading-icon color to
        // scheme.primary, which makes Assist/Action chips render their icon
        // in a saturated wallpaper accent (often reading as bright blue on
        // stock Android) while the body stays neutral. Forcing each slot to
        // an on-surface neutral keeps chips coherent across the dynamic
        // palette while still tracking Material You.
        backgroundColor: scheme.surfaceContainerHigh,
        selectedColor: scheme.secondaryContainer,
        disabledColor: scheme.onSurface.withValues(alpha: 0.08),
        secondarySelectedColor: scheme.secondaryContainer,
        checkmarkColor: scheme.onSecondaryContainer,
        side: BorderSide(color: scheme.outlineVariant),
        iconTheme: IconThemeData(
          color: scheme.onSurfaceVariant,
          size: 18,
        ),
        labelStyle: TextStyle(
          color: scheme.onSurfaceVariant,
          fontWeight: FontWeight.w500,
        ),
        secondaryLabelStyle: TextStyle(
          color: scheme.onSecondaryContainer,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),

      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: scheme.inverseSurface,
        contentTextStyle: TextStyle(color: scheme.onInverseSurface),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      dialogTheme: DialogThemeData(
        backgroundColor: scheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),

      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: scheme.surfaceContainerLow,
        surfaceTintColor: scheme.surfaceTint,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
      ),

      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
      ),

      // Material 3 page transitions. Android gets predictive back support
      // (Android 14+), iOS / macOS use Cupertino. On desktop the default
      // zoom / fade-forwards transitions feel jarring, so we use a plain
      // cross-fade for a smooth, distraction-free page swap.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: _FadeThroughPageTransitionsBuilder(),
          TargetPlatform.windows: _FadeThroughPageTransitionsBuilder(),
        },
      ),

      // Tiny readability bumps for body text in dark mode.
      textTheme: isDark
          ? Typography.material2021().white.apply(
                bodyColor: scheme.onSurface,
                displayColor: scheme.onSurface,
              )
          : null,
    );
  }
}

/// A minimal page transition: just a cross-fade with no scale or slide.
/// Used on Linux / Windows where the default zoom transition reads as a
/// jarring pop-out. Short, smooth, distraction-free.
class _FadeThroughPageTransitionsBuilder extends PageTransitionsBuilder {
  const _FadeThroughPageTransitionsBuilder();

  @override
  Duration get transitionDuration => const Duration(milliseconds: 180);

  @override
  Duration get reverseTransitionDuration => const Duration(milliseconds: 140);

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final CurvedAnimation fade = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    return FadeTransition(opacity: fade, child: child);
  }
}
