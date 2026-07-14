import 'dart:developer';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/errors/app_failure.dart';
import '../../core/providers.dart';
import '../../core/utils/paged_envelope.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/application/move_in_filter.dart';
import '../discover/discover_repository.dart';

class SwipeProfile {
  const SwipeProfile({
    required this.id,
    required this.fullName,
    required this.profileImageUrl,
    required this.imageUrls,
    required this.mode,
    required this.city,
    required this.locality,
    required this.bio,
    required this.budgetMin,
    required this.budgetMax,
    required this.moveInTimeline,
    required this.sleepSchedule,
    required this.cleanliness,
    required this.foodHabits,
    required this.smokingDrinking,
    required this.guestsPolicy,
    required this.workStyle,
    required this.gender,
    required this.genderPreference,
    required this.nonNegotiables,
    required this.hasPets,
    required this.partyHabit,
    required this.listingDetails,
    this.age,
    this.profession,
  });

  final int id;
  final String? fullName;
  final String? profileImageUrl;
  final List<String> imageUrls;
  final String? mode;
  final String? city;
  final String? locality;
  final String? bio;
  final double? budgetMin;
  final double? budgetMax;
  final String? moveInTimeline;
  final String? sleepSchedule;
  final String? cleanliness;
  final String? foodHabits;
  final String? smokingDrinking;
  final String? guestsPolicy;
  final String? workStyle;
  final String? gender;
  final String? genderPreference;
  final List<String> nonNegotiables;
  final bool hasPets;
  final String? partyHabit;
  final int? age;
  final String? profession;

  /// Extra listing detail fields from the API response.
  /// Expected keys:
  ///   - 'society_name' (`String`)
  ///   - 'society_type' (`String`)
  ///   - 'society_amenities' (`List<String>`)
  ///   - 'society_vibes' (`List<String>`)
  ///   - 'room_type' (`String`)
  ///   - 'furnishing' (`List<String>`)
  ///   - 'room_features' (`List<String>`)
  ///   - 'flat_config' (`String`, e.g. "2 BHK")
  ///   - 'floor' (`String`)
  ///   - 'total_floors' (`String`)
  ///   - 'flat_amenities' (`List<String>`)
  ///   - 'monthly_rent' (`double`)
  ///   - 'security_deposit' (`double`)
  ///   - 'maintenance' (`double`)
  ///   - 'existing_flatmates' (`List<Map<String, String>>`)
  ///     each with keys: 'name', 'profession', 'lifestyle_chips'
  final Map<String, dynamic> listingDetails;

  factory SwipeProfile.fromJson(Map<String, dynamic> json) {
    // Extract known listing detail keys from the JSON response, if present.
    final listingKeys = <String>[
      'society_name',
      'society_type',
      'society_amenities',
      'society_vibes',
      'room_type',
      'furnishing',
      'room_features',
      'flat_config',
      'floor',
      'total_floors',
      'flat_amenities',
      'monthly_rent',
      'security_deposit',
      'maintenance',
      'existing_flatmates',
      'available_from',
      'video_tour_url',
      'latitude',
      'longitude',
    ];
    final details = <String, dynamic>{};
    for (final key in listingKeys) {
      if (json.containsKey(key)) {
        details[key] = json[key];
      }
    }

    return SwipeProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      imageUrls: _parseImageUrls(json['image_urls']),
      mode: json['mode'] as String?,
      city: json['city'] as String?,
      locality: json['locality'] as String?,
      bio: json['bio'] as String?,
      budgetMin: (json['budget_min'] as num?)?.toDouble(),
      budgetMax: (json['budget_max'] as num?)?.toDouble(),
      moveInTimeline: json['move_in_timeline'] as String?,
      sleepSchedule: json['sleep_schedule'] as String?,
      cleanliness: json['cleanliness'] as String?,
      foodHabits: json['food_habits'] as String?,
      smokingDrinking: json['smoking_drinking'] as String?,
      guestsPolicy: json['guests_policy'] as String?,
      workStyle: json['work_style'] as String?,
      gender: json['gender'] as String?,
      genderPreference: json['gender_preference'] as String?,
      nonNegotiables:
          (json['non_negotiables'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
      hasPets: json['has_pets'] as bool? ?? false,
      partyHabit: json['party_habit'] as String?,
      listingDetails: details,
      age: (json['age'] as num?)?.toInt(),
      profession: json['profession'] as String?,
    );
  }

  static List<String> _parseImageUrls(dynamic raw) {
    if (raw is List && raw.isNotEmpty) {
      return raw
          .whereType<String>()
          .where(
            (url) => url.startsWith('http://') || url.startsWith('https://'),
          )
          .toList(growable: false);
    }
    return const [];
  }
}

class SwipeResult {
  const SwipeResult({required this.didMatch, this.conversationId});

  final bool didMatch;
  final int? conversationId;
}

class SwipeRepository {
  const SwipeRepository(this._ref);

  final Ref _ref;

  /// Fetches a single page of swipe profiles using cursor pagination.
  ///
  /// The backend wraps all list endpoints in
  /// `{ items, next_cursor, has_more, limit }`.
  Future<({List<SwipeProfile> items, String? nextCursor, bool hasMore})>
  fetchSwipeProfilesPage({
    DiscoverFilters? filters,
    String? cursor,
    int limit = 20,
  }) async {
    try {
      final bootstrap = _ref.read(bootstrapControllerProvider).valueOrNull;
      final userProfile = bootstrap?.profile;
      final userNonNegotiables = _extractUserNonNegotiables(
        userProfile?.preferences,
      );

      final queryParams = <String, dynamic>{'limit': limit};
      if (cursor != null && cursor.isNotEmpty) {
        queryParams['cursor'] = cursor;
      }
      if (userNonNegotiables.isNotEmpty) {
        queryParams['non_negotiables'] = userNonNegotiables.join(',');
      }
      if (userProfile?.genderPreference != null &&
          userProfile!.genderPreference != 'any') {
        queryParams['gender_preference'] = userProfile.genderPreference;
      }
      final moveIn = moveInFilterQueryValue(filters?.moveInTimeline);
      if (moveIn != null) {
        queryParams['move_in'] = moveIn;
      }
      if (filters?.hasGeoLocation ?? false) {
        final f = filters!;
        queryParams['lat'] = f.latitude!.toStringAsFixed(6);
        queryParams['lng'] = f.longitude!.toStringAsFixed(6);
        if (f.radiusKm != null) {
          queryParams['radius'] = f.radiusKm!.round();
        }
      }

      final response = await _ref
          .read(apiClientProvider)
          .get(
            FlatmatesEndpoints.flatmatesProfiles,
            queryParameters: queryParams,
          );
      final responseData = response.data;
      // Backend now wraps every list endpoint in
      // `{ items, next_cursor, has_more, limit }`. Older fallback keys
      // (`profiles`, `data`, `results`) are intentionally no longer supported
      // because the migration to cursor envelopes is final.
      final Map<String, dynamic> data;
      if (responseData is Map) {
        data = responseData.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      } else {
        data = const <String, dynamic>{};
      }
      final page = parsePagedEnvelope(
        data,
        SwipeProfile.fromJson,
        label: 'swipeProfiles',
      );
      final moveInFiltered = _dedupeValidProfiles(
        page.items
            .where(
              (profile) =>
                  _profileMatchesMoveIn(profile, filters?.moveInTimeline),
            )
            .toList(),
      );
      log(
        '[SwipeRepo] Response status: ${response.statusCode}, '
        'rows: ${moveInFiltered.length}, hasMore: ${page.hasMore}',
      );
      final filtered = _applyDealBreakerFilter(
        moveInFiltered,
        userNonNegotiables,
        userProfile,
      );
      return (
        items: filtered,
        nextCursor: page.nextCursor,
        hasMore: page.hasMore,
      );
    } on AppFailure {
      // Already typed — let the controller map it to AsyncError.
      rethrow;
    } catch (e, st) {
      // Non-Dio errors (TypeError from parsing, FormatException, etc.) need
      // to be wrapped so the controller's AsyncError carries an AppFailure
      // and the error UI can render a typed, localized message.
      throw UnknownFailure(underlyingError: e, stackTrace: st);
    }
  }

  /// Backwards-compatible helper returning the first page as a list.
  Future<List<SwipeProfile>> fetchSwipeProfiles({
    DiscoverFilters? filters,
  }) async {
    final page = await fetchSwipeProfilesPage(filters: filters);
    return page.items;
  }

  bool _profileMatchesMoveIn(SwipeProfile profile, String? moveInTimeline) {
    final normalized = normalizeMoveInFilter(moveInTimeline);
    if (normalized == null) return true;

    final rawAvailableFrom = profile.listingDetails['available_from'];
    if (rawAvailableFrom != null) {
      final availableFrom = DateTime.tryParse(rawAvailableFrom.toString());
      if (availableFrom != null) {
        return listingMatchesMoveInFilter(availableFrom, normalized);
      }
    }

    return normalizeMoveInFilter(profile.moveInTimeline) == normalized;
  }

  List<SwipeProfile> _dedupeValidProfiles(List<SwipeProfile> profiles) {
    final seenIds = <int>{};
    return profiles
        .where((profile) {
          if (profile.id <= 0) return false;
          return seenIds.add(profile.id);
        })
        .toList(growable: false);
  }

  /// Extract non-negotiables from user preferences map stored in bootstrap.
  List<String> _extractUserNonNegotiables(Map<String, dynamic>? preferences) {
    if (preferences == null) return const [];
    final raw = preferences['non_negotiables'];
    if (raw is List) {
      return raw.map((e) => e.toString()).toList();
    }
    return const [];
  }

  /// Filter out profiles that conflict with the current user's non-negotiables.
  List<SwipeProfile> _applyDealBreakerFilter(
    List<SwipeProfile> profiles,
    List<String> userNonNegotiables,
    FlatmatesProfileModel? user,
  ) {
    if (userNonNegotiables.isEmpty) return profiles;

    return profiles.where((peer) {
      for (final neg in userNonNegotiables) {
        switch (neg) {
          // Food: vegetarian/vegan user cannot match with non-vegetarian peer
          case 'food_veg_only':
          case 'food_vegan_only':
            final peerFood = peer.foodHabits ?? 'no_preference';
            if (peerFood == 'non_vegetarian' || peerFood == 'non_veg') {
              return false;
            }
            break;
          // Smoking: user requires non-smoker, peer smokes
          case 'no_smoking':
            final peerSD = peer.smokingDrinking ?? 'neither';
            if (peerSD == 'smoke_outside' || peerSD == 'both_fine') {
              return false;
            }
            break;
          // Drinking: user requires no alcohol, peer drinks
          case 'no_drinking':
            final peerSD = peer.smokingDrinking ?? 'neither';
            if (peerSD == 'drink_occasionally' || peerSD == 'both_fine') {
              return false;
            }
            break;
          // Guests: user requires no overnight guests, peer has open house
          case 'no_overnight_guests':
            if (peer.guestsPolicy == 'open_house' ||
                peer.guestsPolicy == 'comfortable') {
              return false;
            }
            break;
          // Pets: user requires no pets, peer has pets
          case 'no_pets':
            if (peer.hasPets) return false;
            break;
          // Gender: user requires specific gender
          case 'gender_female_only':
            if (peer.gender != null && peer.gender != 'female') return false;
            break;
          case 'gender_male_only':
            if (peer.gender != null && peer.gender != 'male') return false;
            break;
          // Partying: user requires no parties, peer is party-friendly
          case 'no_parties':
            if (peer.partyHabit == 'party_friendly') return false;
            break;
          // Hygiene: user requires minimum tidy, peer is minimal
          case 'min_tidy':
            if (peer.cleanliness == 'minimal') return false;
            break;
        }
      }
      return true;
    }).toList();
  }

  Future<SwipeResult> swipeProfile({
    required int targetUserId,
    required String action,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': 'user',
            'action': action,
            'target_user_id': targetUserId,
          },
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return SwipeResult(
      didMatch: data['did_match'] as bool? ?? false,
      conversationId: (data['conversation_id'] as num?)?.toInt(),
    );
  }

  Future<void> recordProfileView({
    required int targetUserId,
    required int durationSeconds,
    int? scrollDepthPercent,
    String source = 'swipe_deck',
  }) async {
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.profileViews,
          data: {
            'target_user_id': targetUserId,
            'duration_seconds': durationSeconds,
            'source': source,
            'scroll_depth_percent': scrollDepthPercent,
          },
        );
  }

  /// `POST /swipes/batch-remove` — undoes multiple likes/swipes in one
  /// request. The backend expects a list of property ids and returns a
  /// confirmation envelope (`{ message }`). Errors propagate via the
  /// shared [ApiClient] -> [ErrorPresenter] pipeline.
  Future<void> batchRemoveSwipes(List<int> propertyIds) async {
    if (propertyIds.isEmpty) return;
    await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipesBatchRemove,
          data: {'property_ids': propertyIds},
        );
  }
}

final swipeRepositoryProvider = Provider<SwipeRepository>(
  (ref) => SwipeRepository(ref),
);
