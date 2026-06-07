import 'package:url_launcher/url_launcher.dart';

/// Opens the native GitHub issue form so users can ask for a new ROM or
/// recovery to be added to the catalog.
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
  }
  final Uri uri = Uri.https(
    'github.com',
    '/monsiu/Custom-RR/issues/new',
    params,
  );
  await launchUrl(uri, mode: LaunchMode.externalApplication);
}
