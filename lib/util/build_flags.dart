/// Compile-time build flags.
///
/// [kFdroidBuild] is set by the F-Droid build recipe via
/// `--dart-define=FDROID_BUILD=true`. When true, the app's self-update
/// machinery is compiled out: the background GitHub release poll, the
/// in-app APK download/install path, and the "Check for updates"
/// affordances. F-Droid distributes and updates the app itself, and its
/// inclusion policy discourages apps from side-loading executable
/// binaries, so the F-Droid variant ships without any of it.
///
/// Defaults to `false`, so the regular GitHub-release builds keep their
/// bundled updater unchanged.
const bool kFdroidBuild = bool.fromEnvironment('FDROID_BUILD');
