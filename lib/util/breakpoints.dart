import 'package:flutter/widgets.dart';

/// Material 3 window size class breakpoints.
///
/// See https://m3.material.io/foundations/layout/applying-layout/window-size-classes
class Breakpoints {
  const Breakpoints._();

  /// Compact / phone (< 600 dp).
  static const double compact = 600;

  /// Medium / small tablet (>= 600 dp, < 840 dp).
  static const double medium = 840;

  static double widthOf(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isCompact(BuildContext context) => widthOf(context) < compact;

  static bool isMedium(BuildContext context) {
    final double w = widthOf(context);
    return w >= compact && w < medium;
  }

  static bool isExpanded(BuildContext context) => widthOf(context) >= medium;

  /// "Page content" max width: wide screens get a centered column rather than
  /// stretched-edge-to-edge text.
  static const double readingMaxWidth = 720;
}
