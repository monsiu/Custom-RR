import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// True when the app should render its dedicated desktop UI shell
/// (pinned rail, native menu bar, denser chrome) instead of the
/// adaptive Material 3 layout used on phones / tablets / web.
///
/// Set once at startup by [initPlatformShell]; left as `false` in unit
/// tests so the existing breakpoint-based [AppShell] tests stay valid.
bool useDesktopShell = false;

/// Initialises [useDesktopShell] based on the host OS. Call from `main()`
/// before `runApp`.
///
/// Currently only Linux opts in. Windows will follow once it has been
/// tested.
void initPlatformShell() {
  if (kIsWeb) return;
  if (Platform.isLinux) {
    useDesktopShell = true;
  }
}
