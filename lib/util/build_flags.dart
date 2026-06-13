/// Compile-time build flags.
///
/// [kGithubReleaseBuild] is set only by the GitHub release workflow via
/// `--dart-define=GITHUB_RELEASE_BUILD=true`. It marks artifacts that are
/// distributed from GitHub Releases and are therefore allowed to use the
/// app's bundled GitHub-release update checker and APK installer.
///
/// Defaults to `false`, so updater code is disabled in normal source builds
/// unless a distribution workflow opts in explicitly.
const bool kGithubReleaseBuild = bool.fromEnvironment('GITHUB_RELEASE_BUILD');

/// [kFdroidBuild] is set by the F-Droid build recipe via
/// `--dart-define=FDROID_BUILD=true`. When true, the app's self-update
/// machinery is compiled out: the background GitHub release poll, the
/// in-app APK download/install path, and the "Check for updates"
/// affordances. F-Droid distributes and updates the app itself, and its
/// inclusion policy discourages apps from side-loading executable
/// binaries, so the F-Droid variant ships without any of it.
///
/// Defaults to `false`, so normal source builds do not include the updater.
const bool kFdroidBuild = bool.fromEnvironment('FDROID_BUILD');

/// [kPlayBuild] is set for the Google Play variant via
/// `--dart-define=PLAY_BUILD=true`. Google Play distributes and updates the
/// app itself and its policies disallow self-updating / APK side-loading, so
/// the Play build (like the F-Droid one) ships without the in-app updater.
/// Play's payment and financial-services policies also make in-app crypto
/// solicitation risky, so the Play build hides the crypto donation UI and
/// keeps only the external "Buy Me a Coffee" link.
///
/// Defaults to `false`.
const bool kPlayBuild = bool.fromEnvironment('PLAY_BUILD');

/// True only for the GitHub-release channel, the one variant that bundles the
/// self-update machinery (background release poll, "Check for updates" UI, and
/// the APK download/install path). Both the F-Droid and Play variants leave
/// updates to the store, and normal source builds keep updater code disabled
/// by default for store-policy compliance.
const bool kSelfUpdateEnabled =
    kGithubReleaseBuild && !kFdroidBuild && !kPlayBuild;

/// Whether to surface the in-app crypto donation UI (wallet addresses, QR
/// codes, wallet deep-links). Hidden on the Play build to stay clear of
/// Google Play's financial-services policy; the external Buy Me a Coffee link
/// remains available on every variant.
const bool kShowCryptoDonate = !kPlayBuild;
