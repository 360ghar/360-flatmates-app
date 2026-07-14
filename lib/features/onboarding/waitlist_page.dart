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
  bool _submitting = false;

  Future<void> _notify() async {
    final locale = AppLocalizations.of(context);
    setState(() => _submitting = true);
    try {
      await ref
          .read(profileRepositoryProvider)
          .updateProfile(
            payload: {
              'preferences': {
                'waitlist_city': widget.city,
                'waitlist_at': DateTime.now().toUtc().toIso8601String(),
              },
            },
          );
      if (!mounted) return;
      setState(() => _notified = true);
      FlatmatesToast.success(context, locale.waitlistConfirmed);
    } catch (e, st) {
      debugPrint('[WaitlistPage] notify error: $e\n$st');
      if (!mounted) return;
      FlatmatesToast.error(context, locale.errorUnknown);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

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
                  onPressed: _submitting ? null : _notify,
                  icon: Icons.notifications_active_outlined,
                ),
                const SizedBox(height: AppSpacing.md),
                FlatmatesButton.secondary(
                  key: const Key('waitlist_invite_friends_button'),
                  label: locale.waitlistInviteFriends,
                  fullWidth: true,
                  onPressed: () {
                    final url = DeepLinkService.flatmatesUrl(city: widget.city);
                    Share.share(locale.waitlistShareMessage(widget.city, url));
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
