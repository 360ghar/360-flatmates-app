import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../chats/application/cursor_list_controller.dart';
import '../discover/domain/property_listing.dart';
import 'listings_repository.dart';

/// Cursor-paginated controller for the user's listings.
class MyListingsController extends CursorListController<PropertyListing> {
  @override
  Future<
      ({
        List<PropertyListing> items,
        String? nextCursor,
        bool hasMore,
      })> fetchPage({String? cursor}) async {
    return ref
        .read(listingsRepositoryProvider)
        .fetchMyListingsPage(cursor: cursor);
  }
}

final myListingsListControllerProvider = NotifierProvider<
    MyListingsController, AsyncValue<CursorListState<PropertyListing>>>(
  MyListingsController.new,
);
