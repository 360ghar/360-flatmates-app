import 'dart:developer';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/endpoints.dart';
import '../../core/domain/wire_enums.dart';
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
    required this.guestsPolicy,
    required this.workStyle,
    required this.gender,
    required this.genderPreference,
    required this.nonNegotiables,
    required this.hasPets,
    required this.partyHabit,
    required this.listingDetails,
    this.ageBucket,
    this.profession,
    this.smoking,
    this.drinking,
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
  final String? guestsPolicy;
  final String? workStyle;
  final String? gender;
  final String? genderPreference;
  final List<String> nonNegotiables;
  final bool hasPets;
  final String? partyHabit;
  final String? profession;

  /// Privacy-bucketed age range of the peer (`age_bucket`, e.g. "18-24"). A
  /// peer payload never carries an exact age.
  final String? ageBucket;

  /// Lifestyle values of the peer: `never`, `occasionally` or `regularly`.
  final String? smoking;
  final String? drinking;

  /// Listing detail of the peer, read from the `listing` object of the peer
  /// payload (`PeerListingSummary`; null when the peer has no live listing).
  /// Keys:
  ///   - 'society_name' (`String`, the listing `sub_locality`)
  ///   - 'room_type' (`String`)
  ///   - 'furnishing' (`List<String>`, the furnishing ids among `features`)
  ///   - 'room_features' (`List<String>`, the listing `features`)
  ///   - 'flat_config' (`String`, e.g. "2 BHK")
  ///   - 'floor' / 'total_floors' (`int`)
  ///   - 'flat_amenities' (`List<String>`, the listing `amenities`)
  ///   - 'monthly_rent' / 'security_deposit' / 'maintenance' (`double`)
  ///   - 'available_from' (`String`, YYYY-MM-DD)
  ///   - 'video_tour_url' (`String`)
  ///   - 'latitude' / 'longitude' (`double`)
  final Map<String, dynamic> listingDetails;

  factory SwipeProfile.fromJson(Map<String, dynamic> json) {
    final listing = json['listing'];
    final details = listing is Map
        ? listingDetailsFromListing(Map<String, dynamic>.from(listing))
        : const <String, dynamic>{};

    return SwipeProfile(
      id: (json['id'] as num?)?.toInt() ?? 0,
      fullName: json['full_name'] as String?,
      profileImageUrl: json['profile_image_url'] as String?,
      imageUrls: _parseImageUrls(listing is Map ? listing['image_urls'] : null),
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
      ageBucket: json['age_bucket'] as String?,
      profession: json['profession'] as String?,
      smoking: json['smoking'] as String?,
      drinking: json['drinking'] as String?,
    );
  }

  /// Maps a `PeerListingSummary` to the keys [listingDetails] documents.
  /// Keys with no value are left out.
  @visibleForTesting
  static Map<String, dynamic> listingDetailsFromListing(
    Map<String, dynamic> listing,
  ) {
    List<String> strings(Object? raw) => raw is List
        ? raw.map((e) => e.toString()).where((e) => e.isNotEmpty).toList()
        : const <String>[];
    final features = strings(listing['features']);
    final furnishing = [
      for (final f in features)
        if (FurnishingLevel.values.any((level) => level.wire == f)) f,
    ];
    final bedrooms = (listing['bedrooms'] as num?)?.toInt();
    final entries = <String, Object?>{
      'society_name': listing['sub_locality'],
      'room_type': listing['room_type'],
      'furnishing': furnishing.isEmpty ? null : furnishing,
      'room_features': features.isEmpty ? null : features,
      'flat_config': bedrooms == null ? null : '$bedrooms BHK',
      'floor': listing['floor_number'],
      'total_floors': listing['total_floors'],
      'flat_amenities': strings(listing['amenities']).isEmpty
          ? null
          : strings(listing['amenities']),
      'monthly_rent': listing['monthly_rent'],
      'security_deposit': listing['security_deposit'],
      'maintenance': listing['maintenance_charges'],
      'available_from': listing['available_from'],
      'video_tour_url': listing['video_tour_url'],
      'latitude': listing['latitude'],
      'longitude': listing['longitude'],
    };
    return {
      for (final entry in entries.entries)
        if (entry.value != null) entry.key: entry.value,
    };
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

/// The body of `POST /flatmates/swipes` (201).
class SwipeResult {
  const SwipeResult({
    required this.didMatch,
    this.conversationId,
    this.matchId,
  });

  final bool didMatch;
  final int? conversationId;
  final int? matchId;
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
      // `gender_preference` is declared on the route (any, male, female) and
      // the server filters peers by it. `any` means no filter; a value this
      // build does not know is not sent.
      final genderPreference = ListingGenderPreference.fromJson(
        userProfile?.genderPreference,
      );
      if (genderPreference != null &&
          genderPreference != ListingGenderPreference.any) {
        queryParams['gender_preference'] = genderPreference.wire;
      }
      final moveIn = moveInFilterQueryValue(filters?.moveInTimeline);
      if (moveIn != null) {
        queryParams['move_in'] = moveIn;
      }
      // `age_min` and `age_max` are integers from 18 to 100.
      if (filters?.ageMin != null) {
        queryParams['age_min'] = filters!.ageMin!.clamp(18, 100);
      }
      if (filters?.ageMax != null) {
        queryParams['age_max'] = filters!.ageMax!.clamp(18, 100);
      }
      if (filters?.hasGeoLocation ?? false) {
        final f = filters!;
        queryParams['lat'] = f.latitude!.toStringAsFixed(6);
        queryParams['lng'] = f.longitude!.toStringAsFixed(6);
        if (f.radiusKm != null) {
          queryParams['radius'] = f.radiusKm!.round().clamp(1, 100);
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
      final lifestyleFiltered = _applyLifestyleFilters(moveInFiltered, filters);
      final filtered = _applyDealBreakerFilter(
        lifestyleFiltered,
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

  /// Applies the explicit smoking / drinking lifestyle filters to peer
  /// profiles (client-side, defensive against the F1 profile split: values
  /// never / occasionally / regularly).
  List<SwipeProfile> _applyLifestyleFilters(
    List<SwipeProfile> profiles,
    DiscoverFilters? filters,
  ) {
    if (filters == null) return profiles;
    final smoking = filters.smoking;
    final drinking = filters.drinking;
    if ((smoking == null || smoking == 'no_preference') &&
        (drinking == null || drinking == 'no_preference')) {
      return profiles;
    }
    return profiles
        .where((peer) {
          final matchesSmoking = switch (smoking) {
            null || 'no_preference' => true,
            'never' =>
              peer.smoking != 'occasionally' && peer.smoking != 'regularly',
            'occasionally' => peer.smoking != 'regularly',
            'regularly' => true,
            _ => true,
          };
          final matchesDrinking = switch (drinking) {
            null || 'no_preference' => true,
            'never' =>
              peer.drinking != 'occasionally' && peer.drinking != 'regularly',
            'occasionally' => peer.drinking != 'regularly',
            'regularly' => true,
            _ => true,
          };
          return matchesSmoking && matchesDrinking;
        })
        .toList(growable: false);
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
            final peerSmoking = peer.smoking;
            if (peerSmoking == 'occasionally' || peerSmoking == 'regularly') {
              return false;
            }
            break;
          // Drinking: user requires no alcohol, peer drinks
          case 'no_drinking':
            final peerDrinking = peer.drinking;
            if (peerDrinking == 'occasionally' || peerDrinking == 'regularly') {
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
    required SwipeAction action,
  }) async {
    final response = await _ref
        .read(apiClientProvider)
        .post(
          FlatmatesEndpoints.swipes,
          data: {
            'target_type': SwipeTargetType.user.wire,
            'action': action.wire,
            'target_user_id': targetUserId,
          },
        );
    final data = response.data is Map
        ? Map<String, dynamic>.from(response.data as Map)
        : <String, dynamic>{};
    return SwipeResult(
      didMatch: data['did_match'] as bool? ?? false,
      conversationId: (data['conversation_id'] as num?)?.toInt(),
      matchId: (data['match_id'] as num?)?.toInt(),
    );
  }

  /// `POST /flatmates/profile-views`. The API accepts 0 to 3600 seconds, so a
  /// longer view is sent as 3600 instead of being dropped with a 422.
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
            'duration_seconds': clampProfileViewSeconds(durationSeconds),
            'source': source,
            if (scrollDepthPercent != null)
              'scroll_depth_percent': scrollDepthPercent.clamp(0, 100),
          },
        );
  }
}

/// Longest view the API accepts (`ProfileViewEventCreate.duration_seconds`).
const int kMaxProfileViewSeconds = 3600;

/// [seconds] limited to the 0 to 3600 the API accepts.
int clampProfileViewSeconds(int seconds) =>
    seconds.clamp(0, kMaxProfileViewSeconds);

final swipeRepositoryProvider = Provider<SwipeRepository>(
  (ref) => SwipeRepository(ref),
);
