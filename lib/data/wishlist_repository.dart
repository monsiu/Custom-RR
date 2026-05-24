import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Stores the set of devices the user has starred ("My phones").
///
/// Devices are keyed as `"<brand>|<codename>"` so that two phones with the
/// same marketing name but different codenames (Pixel 6 vs Pixel 6 Pro for
/// example) are stored separately.
///
/// Persisted locally via [SharedPreferences]; no account, no cloud sync.
class WishlistRepository extends ChangeNotifier {
  WishlistRepository._();
  static final WishlistRepository instance = WishlistRepository._();

  static const String _prefsKey = 'wishlist_keys_v1';

  final Set<String> _keys = <String>{};
  bool _loaded = false;
  SharedPreferences? _prefs;

  bool get isLoaded => _loaded;
  Set<String> get keys => Set<String>.unmodifiable(_keys);
  int get count => _keys.length;

  Future<void> load() async {
    if (_loaded) return;
    _prefs = await SharedPreferences.getInstance();
    final List<String>? saved = _prefs!.getStringList(_prefsKey);
    if (saved != null) {
      _keys
        ..clear()
        ..addAll(saved);
    }
    _loaded = true;
    // Notify in case load runs after the first frame (lazy startup path)
    // so any AnimatedBuilder listeners pick up the persisted set.
    notifyListeners();
  }

  static String keyFor(String brand, String codename) => '$brand|$codename';

  ({String brand, String codename})? splitKey(String key) {
    final int i = key.indexOf('|');
    if (i < 0) return null;
    return (brand: key.substring(0, i), codename: key.substring(i + 1));
  }

  bool contains(String brand, String codename) =>
      _keys.contains(keyFor(brand, codename));

  Future<void> toggle(String brand, String codename) async {
    final String k = keyFor(brand, codename);
    if (_keys.contains(k)) {
      _keys.remove(k);
    } else {
      _keys.add(k);
    }
    await _persist();
    notifyListeners();
  }

  Future<void> clear() async {
    if (_keys.isEmpty) return;
    _keys.clear();
    await _persist();
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_prefs == null) return;
    await _prefs!.setStringList(_prefsKey, _keys.toList());
  }
}
