import 'bootstrap_controller.dart';

class CatalogOption {
  const CatalogOption({
    required this.id,
    required this.label,
    this.meta = const {},
  });

  final String id;
  final String label;
  final Map<String, dynamic> meta;
}

extension FlatmatesCatalogs on BootstrapData {
  CatalogEntryModel? catalog(String key) {
    for (final entry in catalogs) {
      if (entry.key == key) return entry;
    }
    return null;
  }

  List<CatalogOption> catalogOptions(String key) {
    final payload = catalog(key)?.payload;
    final rawItems = payload?['items'];
    if (rawItems is! List) return const [];

    return rawItems
        .map((item) {
          if (item is Map) {
            final map = Map<String, dynamic>.from(item);
            final id = (map['id'] ?? map['value'] ?? map['key'] ?? map['label'])
                ?.toString()
                .trim();
            final label = (map['label'] ?? map['name'] ?? id)
                ?.toString()
                .trim();
            if (id == null || id.isEmpty || label == null || label.isEmpty) {
              return null;
            }
            return CatalogOption(id: id, label: label, meta: map);
          }
          final label = item.toString().trim();
          return label.isEmpty ? null : CatalogOption(id: label, label: label);
        })
        .whereType<CatalogOption>()
        .toList(growable: false);
  }
}
