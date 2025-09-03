import 'package:reentry/data/shared/keys.dart';
import 'package:reentry/data/shared/share_preference.dart';

/// Simple feature flag storage backed by [PersistentStorage].
///
/// Flags are stored under the [Keys.features] key so that
/// experimental functionality can be toggled for phased rollouts.
class FeatureFlags {
  final PersistentStorage _storage;

  FeatureFlags(this._storage);

  Map<String, dynamic> _flags() =>
      _storage.getDataFromCache(Keys.features) ?? <String, dynamic>{};

  bool isEnabled(String name) => _flags()[name] == true;

  Future<void> setFlag(String name, bool enabled) async {
    final flags = _flags();
    flags[name] = enabled;
    await _storage.cacheData(data: flags, key: Keys.features);
  }
}
