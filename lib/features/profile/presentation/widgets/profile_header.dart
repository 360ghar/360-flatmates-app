import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_semantic_colors.dart';
import '../../../../core/theme/app_shadows.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../l10n/gen/app_localizations.dart';
import '../../../shared/presentation/components.dart';

/// Me-tab header: the avatar with an edit badge, then the name, one contact
/// line and the location.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    required this.displayName,
    super.key,
    this.imageUrl,
    this.contact,
    this.location,
  });

  final String displayName;
  final String? imageUrl;

  /// Email, or the phone number when there is no email.
  final String? contact;
  final String? location;

  static const double _avatarSize = 80;
  static const double _badgeSize = 32;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = theme.brightness;
    final locale = AppLocalizations.of(context);
    final secondary = theme.textTheme.bodyMedium?.copyWith(
      color: AppSemanticColors.textSecondaryFor(b),
    );
    const target = kMinInteractiveDimension;
    // The badge's 48 dp target sits inside the box, so all of it is
    // hit-testable (a Stack does not hit-test children outside its bounds).
    const boxSize = _avatarSize + (target - _badgeSize) / 2;

    final avatar = SizedBox.square(
      dimension: boxSize,
      child: Stack(
        children: [
          Semantics(
            image: true,
            label: locale.profilePhotoSemantic(displayName),
            child: FlatmatesAvatar(
              name: displayName,
              imageUrl: imageUrl,
              size: _avatarSize,
              showRing: true,
            ),
          ),
          Positioned(
            right: 0,
            bottom: 0,
            child: Tooltip(
              message: locale.editProfileCta,
              child: Semantics(
                // Maestro id (keys never reach the accessibility layer).
                identifier: 'profile_edit_button',
                button: true,
                label: locale.editProfileCta,
                excludeSemantics: true,
                child: InkResponse(
                  key: const Key('profile_edit_button'),
                  onTap: () => context.push('/profile/edit'),
                  radius: target / 2,
                  child: SizedBox.square(
                    dimension: target,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: AppSemanticColors.clayFor(b),
                          shape: BoxShape.circle,
                          boxShadow: AppShadows.e2(b),
                        ),
                        child: SizedBox.square(
                          dimension: _badgeSize,
                          child: Icon(
                            Icons.edit_rounded,
                            size: 16,
                            color: AppSemanticColors.onClayFor(b),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
    final details = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        withTestId(
          const Key('profile_name_text'),
          Text(
            displayName,
            key: const Key('profile_name_text'),
            style: theme.textTheme.headlineMedium,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
        if (contact != null) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            contact!,
            style: secondary,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ],
        if (location != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 16,
                color: AppSemanticColors.textSecondaryFor(b),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  location!,
                  style: secondary,
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ],
          ),
        ],
      ],
    );

    // At large text sizes the name needs the full width.
    if (MediaQuery.textScalerOf(context).scale(1) >= 1.5) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          avatar,
          const SizedBox(height: AppSpacing.md),
          details,
        ],
      );
    }
    return Row(
      children: [
        avatar,
        const SizedBox(width: AppSpacing.lg),
        Expanded(child: details),
      ],
    );
  }
}
