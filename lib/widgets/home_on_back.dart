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
/// - On the Home page itself ([isHome] = true) this widget adds nothing: it
///   returns [child] untouched so the system owns the back gesture and can
///   play the Android predictive back-to-home animation (the launcher
///   sliding into view) when the app exits.
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

  /// When true the back gesture is left entirely to the system on the Home
  /// page, so it exits the app with the predictive back-to-home animation.
  final bool isHome;

  @override
  Widget build(BuildContext context) {
    // On Home, do not wrap in a PopScope at all. The root route already
    // reports that it can pop (bubble), so the system shows the predictive
    // back-to-home animation; a no-op PopScope here would only risk
    // suppressing it.
    if (isHome) {
      return child;
    }
    final GoRouter? router = GoRouter.maybeOf(context);
    // Outside a GoRouter (for example in widget tests that pump a page on its
    // own) there is nothing to intercept, so behave as a plain passthrough.
    if (router == null) {
      return child;
    }
    // Let the framework pop natively when there is a previous page to return
    // to (so detail pages keep their normal back animation). Only when there
    // is nothing to pop (a top-level destination reached directly) do we
    // intercept and send the user to the app's Home page rather than out of
    // the app.
    return PopScope<Object?>(
      canPop: router.canPop(),
      onPopInvokedWithResult: (bool didPop, Object? result) {
        if (didPop) {
          return;
        }
        context.go(AppRoutes.home);
      },
      child: child,
    );
  }
}
