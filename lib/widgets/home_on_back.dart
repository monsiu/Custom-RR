import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../routes.dart';

/// Makes the system back button and swipe-back gesture context aware.
///
/// - If the current page has somewhere to go back to (a pushed detail page,
///   such as a single ROM, recovery, or device), back returns to that
///   previous page with its normal animation.
/// - If the current page is a top-level destination with no back history
///   (the Custom ROMs, Recoveries, Root, Treble & GSI, devices lists, etc.),
///   back goes to the app's Home page instead of leaving the app.
/// - On the Home page itself ([isHome] = true) back keeps its normal
///   behaviour and exits the app.
///
/// Modal routes pushed above the current page (dialogs, bottom sheets, the
/// navigation drawer) still close first via their own handlers, since they
/// sit nearer the back event than this wrapper.
class HomeOnBack extends StatelessWidget {
  const HomeOnBack({
    super.key,
    required this.child,
    this.isHome = false,
  });

  final Widget child;

  /// When true the back gesture is left alone on the Home page so it exits
  /// the app as usual.
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    final GoRouter? router = GoRouter.maybeOf(context);
    // Outside a GoRouter (for example in widget tests that pump a page on its
    // own) there is nothing to intercept, so behave as a plain passthrough.
    if (router == null) {
      return child;
    }
    // Let the framework pop natively when there is a previous page to return
    // to (so detail pages keep their normal back animation) and on Home (so
    // back exits the app). Everywhere else, intercept and send the user to
    // the app's Home page rather than out of the app.
    final bool allowNativePop = isHome || router.canPop();
    return PopScope<Object?>(
      canPop: allowNativePop,
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        if (router.canPop()) {
          router.pop();
        } else {
          context.go(AppRoutes.home);
        }
      },
      child: child,
    );
  }
}
