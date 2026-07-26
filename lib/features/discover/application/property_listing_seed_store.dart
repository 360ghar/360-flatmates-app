import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/property_listing.dart';

/// Survives [GoRouter] rebuilds that drop `state.extra`.
///
/// After create/update the router often refreshes (bootstrap invalidation),
/// which re-instantiates route builders without the original `extra` seed.
/// Pages that need a pending listing (under-review / flat-details) should
/// prefer this store over relying solely on navigation `extra`.
class PropertyListingSeedStore extends Notifier<Map<int, PropertyListing>> {
  @override
  Map<int, PropertyListing> build() => const {};

  void put(PropertyListing listing) {
    if (listing.id <= 0) return;
    state = {...state, listing.id: listing};
  }

  PropertyListing? get(int id) => state[id];

  void remove(int id) {
    if (!state.containsKey(id)) return;
    final next = Map<int, PropertyListing>.from(state)..remove(id);
    state = next;
  }

  void clear() => state = const {};
}

final propertyListingSeedStoreProvider =
    NotifierProvider<PropertyListingSeedStore, Map<int, PropertyListing>>(
      PropertyListingSeedStore.new,
    );
