import 'package:flutter/material.dart';

import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/flatmates_card.dart';
import '../../../shared/presentation/flatmates_network_image.dart';
import '../../../shared/presentation/flatmates_price_text.dart';
import '../../discover_repository.dart';

class DiscoverListingCard extends StatelessWidget {
  const DiscoverListingCard({
    required this.item,
    required this.onLike,
    super.key,
    this.badgeLabel,
  });

  final PropertyListing item;
  final VoidCallback onLike;
  final String? badgeLabel;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final titleLocation = [
      if (item.locality != null && item.locality!.trim().isNotEmpty)
        item.locality!.trim(),
      if (item.subLocality != null && item.subLocality!.trim().isNotEmpty)
        item.subLocality!.trim(),
    ].join(', ');

    final metaParts = <String>[
      if (item.bedrooms != null) locale.homeBedsValue(item.bedrooms!),
      if (item.bathrooms != null) locale.homeBathsValue(item.bathrooms!),
      if (item.areaSqft != null)
        locale.homeAreaValue(item.areaSqft!.toStringAsFixed(0)),
    ];

    final genderSuffix = switch (item.genderPreference) {
      'male' => locale.genderSuffixMaleOnly,
      'female' => locale.genderSuffixFemaleOnly,
      _ => locale.genderSuffixAny,
    };
    metaParts.add(genderSuffix);

    Widget? availabilityWidget;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (item.availableFrom != null) {
      final availableDate = DateTime(
        item.availableFrom!.year,
        item.availableFrom!.month,
        item.availableFrom!.day,
      );
      if (!availableDate.isAfter(today)) {
        availabilityWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.green.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              locale.availableNowLabel,
              style: TextStyle(
                fontSize: 10,
                color: Colors.green.shade700,
              ),
            ),
          ],
        );
      } else {
        final monthStr = _shortMonth(item.availableFrom!);
        availabilityWidget = Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: Colors.orange.shade600,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 4),
            Text(
              locale.availableFromShort(
                '${item.availableFrom!.day} $monthStr',
              ),
              style: TextStyle(
                fontSize: 10,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        );
      }
    } else if (item.isAvailable) {
      availabilityWidget = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.green.shade600,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            locale.availableLabel,
            style: TextStyle(
              fontSize: 10,
              color: Colors.green.shade700,
            ),
          ),
        ],
      );
    }

    return FlatmatesCard(
      key: Key('discover_listing_card_${item.id}'),
      padding: const EdgeInsets.all(10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                  Text(
                    _formatRent(item.monthlyRent.round()),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppSemanticColors.textPrimaryFor(theme.brightness),
                      fontWeight: FontWeight.w700,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.owner?.fullName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      locale.byOwnerLabel(item.owner!.fullName),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 11,
                        color: AppSemanticColors.textSecondaryFor(theme.brightness),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  if (titleLocation.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          size: 12,
                          color: AppSemanticColors.textSecondaryFor(
                            theme.brightness,
                          ),
                        ),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            titleLocation,
                            style: theme.textTheme.bodySmall?.copyWith(
                              fontSize: 11,
                              color: AppSemanticColors.textSecondaryFor(
                                theme.brightness,
                              ),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (availabilityWidget != null) ...[
                    const SizedBox(height: 3),
                    availabilityWidget,
                  ],
                  if (metaParts.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      metaParts.join(' · '),
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        color: AppSemanticColors.textSecondaryFor(
                          theme.brightness,
                        ),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
          _ListingImage(
            imageUrl: item.mainImageUrl,
            title: item.title,
            sharingType: item.sharingType,
            onLike: onLike,
            itemId: item.id,
          ),
        ],
      ),
    );
  }

  static String _formatRent(int amount) {
    if (amount >= 100000) {
      final lakhs = amount / 100000;
      final value = lakhs.toStringAsFixed(lakhs >= 10 ? 1 : 2);
      final compact = value.replaceAll(RegExp(r'\.?0+$'), '');
      return '₹${compact}L';
    }
    return FlatmatesPriceText.formatRupee(amount);
  }

  static String _shortMonth(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return months[date.month - 1];
  }
}

class _ListingImage extends StatelessWidget {
  const _ListingImage({
    required this.imageUrl,
    required this.title,
    this.sharingType,
    this.onLike,
    this.itemId,
  });

  final String? imageUrl;
  final String title;
  final String? sharingType;
  final VoidCallback? onLike;
  final int? itemId;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.trim().isNotEmpty;

    return SizedBox(
      width: 90,
      child: AspectRatio(
        aspectRatio: 0.82,
        child: ClipRRect(
          borderRadius: AppRadius.cardBorder,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (hasImage)
                FlatmatesNetworkImage(imageUrl: imageUrl!, fit: BoxFit.cover)
              else
                _ListingImageFallback(title: title),
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                      ],
                      stops: const [0.5, 1.0],
                    ),
                  ),
                ),
              ),
              if (sharingType != null &&
                  (sharingType == 'private_room' ||
                      sharingType == 'shared_room'))
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      sharingType == 'private_room' ? 'Private' : 'Shared',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              if (onLike != null)
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: SizedBox(
                    width: 30,
                    height: 30,
                    child: IconButton(
                      key: Key('discover_like_$itemId'),
                      onPressed: onLike,
                      icon: const Icon(
                        Icons.favorite_border_rounded,
                        size: 15,
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.zero,
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.black38,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ListingImageFallback extends StatelessWidget {
  const _ListingImageFallback({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppSemanticColors.accent.withValues(alpha: 0.9),
            AppSemanticColors.accent.withValues(alpha: 0.35),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Spacer(),
          const Icon(Icons.apartment_rounded, color: Colors.white, size: 24),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
