import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../data/selected_device_controller.dart';
import '../routes.dart';
import '../util/device_detector.dart';

/// Compact home-page link to the service details and enquiry options.
class WorkWithMonsiuCard extends StatelessWidget {
  const WorkWithMonsiuCard({super.key});

  Future<void> _openServices(BuildContext context) async {
    final DetectedDevice detected = await DeviceDetector.instance.detect();
    final SelectedDeviceController selected = SelectedDeviceController.instance;
    final Map<String, String> params = <String, String>{};
    final String manufacturer = detected.manufacturer.isNotEmpty
        ? detected.manufacturer
        : selected.brand ?? '';
    final String model = detected.model.isNotEmpty
        ? detected.model
        : selected.model ?? '';
    final String codename = detected.codename.isNotEmpty
        ? detected.codename
        : selected.codename ?? '';
    if (manufacturer.isNotEmpty) params['manufacturer'] = manufacturer;
    if (model.isNotEmpty) params['model'] = model;
    if (codename.isNotEmpty) params['codename'] = codename;
    final Uri uri = Uri(
      path: AppRoutes.services,
      queryParameters: params.isEmpty ? null : params,
    );
    if (context.mounted) context.push(uri.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.android_outlined),
        title: const Text('Custom ROM builds', maxLines: 1),
        subtitle: const Text('Check device eligibility', maxLines: 1),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () => _openServices(context),
      ),
    );
  }
}
