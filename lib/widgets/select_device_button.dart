import 'package:flutter/material.dart';

import '../data/selected_device_controller.dart';

/// Sets (or clears) the app-wide active device used to filter the ROMs and
/// Recoveries lists. Rebuilds via [AnimatedBuilder] on the controller so the
/// label flips between "Use this device" and "Selected device" live.
///
/// Render this wherever a concrete (brand, codename) is in context: the
/// per-model device page, find-my-phone matches, the auto-detect card.
class SelectDeviceButton extends StatelessWidget {
  const SelectDeviceButton({
    super.key,
    required this.brand,
    required this.codename,
    this.model,
  });

  final String brand;
  final String codename;

  /// Marketing name for display and the saved label; falls back to codename.
  final String? model;

  @override
  Widget build(BuildContext context) {
    final SelectedDeviceController controller =
        SelectedDeviceController.instance;
    return AnimatedBuilder(
      animation: controller,
      builder: (BuildContext context, _) {
        final bool selected = controller.isSelected(brand, codename);
        final String name = (model == null || model!.isEmpty) ? codename : model!;
        if (selected) {
          return OutlinedButton.icon(
            icon: const Icon(Icons.check_circle, size: 18),
            label: const Text('Selected device'),
            onPressed: () async {
              await controller.clear();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: Text('Cleared $name as your device'),
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
            },
          );
        }
        return FilledButton.tonalIcon(
          icon: const Icon(Icons.smartphone, size: 18),
          label: const Text('Use this device'),
          onPressed: () async {
            await controller.select(
              brand: brand,
              codename: codename,
              model: model,
            );
            if (!context.mounted) return;
            ScaffoldMessenger.of(context)
              ..hideCurrentSnackBar()
              ..showSnackBar(
                SnackBar(
                  content: Text(
                    'ROMs and recoveries now filtered to $name',
                  ),
                  behavior: SnackBarBehavior.floating,
                  duration: const Duration(seconds: 2),
                ),
              );
          },
        );
      },
    );
  }
}
