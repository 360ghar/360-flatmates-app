import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../profile/profile_repository.dart';
import '../shared/presentation/components.dart';

class WaitlistPage extends ConsumerStatefulWidget {
  const WaitlistPage({required this.city, super.key});

  final String city;

  @override
  ConsumerState<WaitlistPage> createState() => _WaitlistPageState();
}

class _WaitlistPageState extends ConsumerState<WaitlistPage> {
  bool _notified = false;

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.horizontalScreen,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              FlatmatesEmptyState(
                icon: Icons.group_add_rounded,
                title: locale.waitlistTitle,
                subtitle: locale.waitlistSubtitle(widget.city),
              ),
              const SizedBox(height: AppSpacing.screen),
              if (_notified) ...[
                InfoPill(
                  icon: Icons.check_circle_rounded,
                  label: locale.waitlistConfirmed,
                  highlighted: true,
                ),
              ] else ...[
                FlatmatesButton(
                  label: locale.waitlistNotifyCta,
                  fullWidth: true,
                  onPressed: () async {
                    try {
                      await ref
                          .read(profileRepositoryProvider)
                          .updateProfile(
                            payload: {'waitlist_city': widget.city},
                          );
                      if (mounted) setState(() => _notified = true);
                    } catch (e, st) {
                      debugPrint('[WaitlistPage] notify error: $e\n$st');
                    }
                  },
                  icon: Icons.notifications_active_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                FlatmatesButton.secondary(
                  key: const Key('waitlist_invite_friends_button'),
                  label: locale.waitlistInviteFriends,
                  fullWidth: true,
                  onPressed: () {
                    final url = DeepLinkService.flatmatesUrl(city: widget.city);
                    SharePlus.instance.share(
                      ShareParams(text: locale.waitlistShareMessage(widget.city, url)),
                    );
                  },
                  icon: Icons.share_outlined,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
