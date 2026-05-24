import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// Brand colour for Custom RR (Custom ROMs & Recoveries).
const Color kBrandSeed = Color(0xFF7ED957);

class AppTheme {
  const AppTheme._();

  static ThemeData light({ColorScheme? dynamicScheme}) =>
      _build(Brightness.light, dynamicScheme);
  static ThemeData dark({ColorScheme? dynamicScheme}) =>
      _build(Brightness.dark, dynamicScheme);

  static ThemeData _build(Brightness brightness, [ColorScheme? override]) {
    // Material You: when a wallpaper-derived scheme is available
    // (Android 12+, some macOS builds) use it directly so every role in
    // the palette tracks the user's accent. Harmonizing the dynamic
    // primary against the brand seed clamps everything back to green and
    // defeats Material You, so we only fall back to a brand-seeded scheme
    // when no dynamic scheme is provided by the platform.
    final ColorScheme scheme = override ??
        ColorScheme.fromSeed(
          seedColor: kBrandSeed,
          brightness: brightness,
        );
    final bool isDark = brightness == Brightness.dark;

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      scaffoldBackgroundColor: scheme.surface,
      splashFactory: InkSparkle.splashFactory,

      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 2,
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
      // (Android 14+), iOS / macOS use Cupertino, other desktops use the
      // standard M3 zoom transition.
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: <TargetPlatform, PageTransitionsBuilder>{
          TargetPlatform.android: PredictiveBackPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.macOS: CupertinoPageTransitionsBuilder(),
          TargetPlatform.linux: ZoomPageTransitionsBuilder(),
          TargetPlatform.windows: ZoomPageTransitionsBuilder(),
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
