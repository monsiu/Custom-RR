import 'package:custom_rr/data/selected_device_controller.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests for [SelectedDeviceController], the persisted single active
/// device that drives the ROMs/Recoveries device filter.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final SelectedDeviceController controller = SelectedDeviceController.instance;

  setUp(() async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    await controller.clear();
  });

  test('starts with no selection', () {
    expect(controller.hasSelection, isFalse);
    expect(controller.label, isEmpty);
  });

  test('select stores brand, codename, and model', () async {
    await controller.select(
      brand: 'Xiaomi',
      codename: 'vayu',
      model: 'Poco X3 Pro',
    );
    expect(controller.hasSelection, isTrue);
    expect(controller.brand, 'Xiaomi');
    expect(controller.codename, 'vayu');
    expect(controller.model, 'Poco X3 Pro');
    expect(controller.isSelected('Xiaomi', 'vayu'), isTrue);
    expect(controller.isSelected('Xiaomi', 'alioth'), isFalse);
  });

  test('label uses the model name with codename', () async {
    await controller.select(
      brand: 'Xiaomi',
      codename: 'vayu',
      model: 'Poco X3 Pro',
    );
    expect(controller.label, 'Poco X3 Pro (vayu)');
  });

  test('label falls back to codename when model is missing', () async {
    await controller.select(brand: 'Google', codename: 'oriole');
    expect(controller.label, 'oriole (oriole)');
  });

  test('clear removes the selection', () async {
    await controller.select(
      brand: 'Xiaomi',
      codename: 'vayu',
      model: 'Poco X3 Pro',
    );
    await controller.clear();
    expect(controller.hasSelection, isFalse);
    expect(controller.brand, isNull);
    expect(controller.codename, isNull);
  });

  test('notifies listeners on select and clear', () async {
    int notifications = 0;
    void listener() => notifications++;
    controller.addListener(listener);
    await controller.select(brand: 'Xiaomi', codename: 'vayu');
    await controller.clear();
    controller.removeListener(listener);
    expect(notifications, greaterThanOrEqualTo(2));
  });

  test('select is a no-op when nothing changes', () async {
    await controller.select(brand: 'Xiaomi', codename: 'vayu');
    int notifications = 0;
    void listener() => notifications++;
    controller.addListener(listener);
    await controller.select(brand: 'Xiaomi', codename: 'vayu');
    controller.removeListener(listener);
    expect(notifications, 0);
  });

  test('load restores a persisted selection', () async {
    SharedPreferences.setMockInitialValues(<String, Object>{
      'selectedDevice.brand': 'OnePlus',
      'selectedDevice.codename': 'instantnoodle',
      'selectedDevice.model': 'OnePlus 8',
    });
    await controller.load();
    expect(controller.hasSelection, isTrue);
    expect(controller.brand, 'OnePlus');
    expect(controller.codename, 'instantnoodle');
    expect(controller.model, 'OnePlus 8');
  });
}
