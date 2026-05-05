enum MapProviderKind {
  google('google'),
  goong('goong'),
  osm('osm');

  /// Giá trị dùng cho `--dart-define=MAP_PROVIDER=...`.
  final String configValue;
  const MapProviderKind(this.configValue);

  static MapProviderKind? fromConfigValue(String? raw) {
    if (raw == null) return null;
    final normalized = raw.trim().toLowerCase();
    if (normalized.isEmpty) return null;
    for (final kind in values) {
      if (kind.configValue == normalized) return kind;
    }
    return null;
  }
}
