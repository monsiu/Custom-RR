import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// The user's single active device, remembered across the app.
///
/// Distinct from [WishlistRepository] (which stars MANY devices): this holds
/// the ONE device the user is currently browsing for, so the ROMs and
/// Recoveries lists can filter down to builds that support it.
///
/// Keyed by `(brand, codename)`; [model] is a display label only. Persisted
/// locally via [SharedPreferences]; no account, no cloud sync.
class SelectedDeviceController extends ChangeNotifier {
  SelectedDeviceController._();
  static final SelectedDeviceController instance =
      SelectedDeviceController._();

  static const String _brandKey = 'selectedDevice.brand';
  static const String _codenameKey = 'selectedDevice.codename';
  static const String _modelKey = 'selectedDevice.model';

  String? _brand;
  String? _codename;
  String? _model;

  String? get brand => _brand;
  String? get codename => _codename;

  /// Marketing name for display; falls back to the codename when unknown.
  String? get model => _model;

  /// True when a device is currently selected.
  bool get hasSelection => _brand != null && _codename != null;

  /// Human label for banners, e.g. "Poco X3 Pro (vayu)".
  String get label {
    if (!hasSelection) return '';
    final String name = (_model == null || _model!.isEmpty) ? _codename! : _model!;
    return '$name ($_codename)';
  }

  /// Loads the saved device from disk. Call once during app startup.
  Future<void> load() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    _brand = prefs.getString(_brandKey);
    _codename = prefs.getString(_codenameKey);
    _model = prefs.getString(_modelKey);
    notifyListeners();
  }

  /// Sets the active device and persists it.
  Future<void> select({
    required String brand,
    required String codename,
    String? model,
  }) async {
    if (_brand == brand && _codename == codename && _model == model) return;
    _brand = brand;
    _codename = codename;
    _model = model;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_brandKey, brand);
    await prefs.setString(_codenameKey, codename);
    if (model == null || model.isEmpty) {
      await prefs.remove(_modelKey);
    } else {
      await prefs.setString(_modelKey, model);
    }
  }

  /// True when [brand]/[codename] match the current selection.
  bool isSelected(String brand, String codename) =>
      _brand == brand && _codename == codename;

  /// Clears the active device and persists the cleared state.
  Future<void> clear() async {
    if (!hasSelection) return;
    _brand = null;
    _codename = null;
    _model = null;
    notifyListeners();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove(_brandKey);
    await prefs.remove(_codenameKey);
    await prefs.remove(_modelKey);
  }
}
