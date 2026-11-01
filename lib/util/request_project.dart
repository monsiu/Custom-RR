import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens GitHub's issue form so users can ask for a new catalog entry.
///
/// [kind] is a short human label such as `'ROM'`, `'recovery'`, or
/// `'ROM or recovery'`. It sets the issue title prefix and, when it maps to a
/// concrete catalog type, preselects the form's type dropdown. The request
/// opens the `rom_request.yml` issue form, which applies the `request` label
/// server-side so it sticks even for first-time reporters.
Future<void> openProjectRequest({required String kind}) async {
  final String titleKind = kind.isEmpty
      ? kind
      : '${kind[0].toUpperCase()}${kind.substring(1)}';
  final Map<String, String> params = <String, String>{
    'template': 'rom_request.yml',
    'title': '$titleKind request: ',
    'labels': 'request',
  };
  // Preselect the form's type dropdown when the entry point is specific.
  // Unrecognised values (e.g. the generic menu entry) are left for the user
  // to pick; GitHub ignores dropdown prefills that do not match an option.
  switch (kind.toLowerCase()) {
    case 'rom':
      params['kind'] = 'Custom ROM';
      break;
    case 'recovery':
      params['kind'] = 'Recovery';
      break;
    case 'gsi':
      params['kind'] = 'GSI (Treble generic system image)';
      break;
    case 'root':
    case 'root solution':
      params['kind'] = 'Root solution';
      break;
  }
  final Uri uri = Uri.https(
    'github.com',
    '/monsiu/Custom-RR/issues/new',
    params,
  );
  await _openIssueForm(uri);
}

/// Opens GitHub's issue form so users can ask for a missing device to be added.
/// Opens the `device_request.yml` form (label `device`).
///
/// [query] is the text the user was searching for (brand, model, or codename)
/// when they hit no results; when present it seeds the issue title so the
/// reporter does not have to retype it.
Future<void> openDeviceRequest({
  String? query,
  String? brand,
  String? model,
  String? codename,
}) async {
  final String trimmed = (query ?? '').trim();
  final Map<String, String> params = <String, String>{
    'template': 'device_request.yml',
    'title': trimmed.isEmpty ? 'Device request: ' : 'Device request: $trimmed',
    'labels': 'device',
  };
  // The device issue form uses these IDs, so device cards can fill the exact
  // fields when detection already knows more than the search query.
  if ((brand ?? '').trim().isNotEmpty) params['brand'] = brand!.trim();
  if ((model ?? '').trim().isNotEmpty) {
    params['model'] = model!.trim();
  } else if (trimmed.isNotEmpty) {
    params['model'] = trimmed;
  }
  if ((codename ?? '').trim().isNotEmpty) {
    params['codename'] = codename!.trim();
  }
  final Uri uri = Uri.https(
    'github.com',
    '/monsiu/Custom-RR/issues/new',
    params,
  );
  await _openIssueForm(uri);
}

/// Opens the structured form for reporting a broken link or incorrect catalog
/// details. This gives maintainers enough context to verify and fix a listing.
Future<void> openCatalogReport({
  required String projectName,
  required String projectId,
  required String currentUrl,
}) async {
  final Uri uri =
      Uri.https('github.com', '/monsiu/Custom-RR/issues/new', <String, String>{
        'template': 'catalog_correction.yml',
        'title': 'Catalog report: $projectName',
        'labels': 'data',
        'entry': '$projectName (catalog ID: $projectId)',
        'source': currentUrl,
      });
  await _openIssueForm(uri);
}

/// Open GitHub's web issue form on phones and tablets. Some native GitHub
/// clients ignore YAML issue-form templates and can submit an empty issue.
/// Desktop builds continue to use the system browser.
Future<void> _openIssueForm(Uri uri) async {
  final bool isMobile =
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);
  final LaunchMode mode = isMobile
      ? LaunchMode.inAppBrowserView
      : LaunchMode.externalApplication;
  final bool launched = await launchUrl(uri, mode: mode);
  if (!launched && isMobile) {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
