import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/providers.dart';
import '../../l10n/gen/app_localizations.dart';
import '../bootstrap/bootstrap_controller.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class ManageListingPage extends ConsumerStatefulWidget {
  const ManageListingPage({super.key});

  @override
  ConsumerState<ManageListingPage> createState() => _ManageListingPageState();
}

class _ManageListingPageState extends ConsumerState<ManageListingPage> {
  final _pausedListingIds = <int>{};

  @override
  Widget build(BuildContext context) {
    final listings = ref.watch(discoverListingsProvider);
    final bootstrap = ref.watch(bootstrapControllerProvider);
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final profile = bootstrap.valueOrNull?.profile;

    return Scaffold(
      appBar: AppBar(title: Text(locale.manageListingTitle)),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/post'),
        icon: const Icon(Icons.add_home_outlined),
        label: Text(locale.postListingTitle),
      ),
      body: SafeArea(
        child: listings.when(
          data: (items) {
            final myListings = items.where((i) => i.ownerId == profile?.id).toList();

            if (myListings.isEmpty) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.add_home_outlined, size: 64, color: theme.colorScheme.onSurfaceVariant),
                    const SizedBox(height: 16),
                    Text(locale.emptyListings, style: theme.textTheme.bodyLarge),
                    const SizedBox(height: 24),
                    GradientActionButton(
                      label: locale.postListingTitle,
                      onPressed: () => context.push('/post'),
                      icon: Icons.add_home_outlined,
                      height: 52,
                    ),
                  ],
                ),
              );
            }

            return RefreshIndicator(
              onRefresh: () async => ref.invalidate(discoverListingsProvider),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
                children: myListings.map((listing) {
                  final isPaused = _pausedListingIds.contains(listing.id);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(18),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (listing.mainImageUrl != null)
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(14),
                                    child: Image.network(
                                      listing.mainImageUrl!,
                                      width: 72,
                                      height: 72,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, _, _) => Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(14),
                                        ),
                                        child: const Icon(Icons.apartment_rounded),
                                      ),
                                    ),
                                  )
                                else
                                  Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary.withValues(alpha: 0.15),
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                    child: const Icon(Icons.apartment_rounded),
                                  ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(listing.title, style: theme.textTheme.titleLarge, maxLines: 2, overflow: TextOverflow.ellipsis),
                                      if (listing.monthlyRent != null)
                                        Text('₹${listing.monthlyRent!.toStringAsFixed(0)}/mo', style: theme.textTheme.bodyLarge?.copyWith(color: theme.colorScheme.primary, fontWeight: FontWeight.w700)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (listing.interestCount > 0)
                                  InfoPill(icon: Icons.favorite_outline, label: locale.homeInterestCount(listing.interestCount)),
                                InfoPill(
                                  icon: isPaused
                                      ? Icons.pause_circle_outline
                                      : listing.interestCount > 0
                                          ? Icons.check_circle_outline
                                          : Icons.schedule_outlined,
                                  label: isPaused
                                      ? locale.listingPaused
                                      : listing.interestCount > 0
                                          ? locale.listingLive
                                          : locale.listingUnderReview,
                                  highlighted: !isPaused && listing.interestCount > 0,
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => Share.share(
                                      'Check out this flat on 360 FlatMates: ${listing.title} at ₹${listing.monthlyRent?.toStringAsFixed(0) ?? "N/A"}/mo in ${listing.locality ?? listing.city ?? ""}',
                                    ),
                                    icon: const Icon(Icons.share_outlined, size: 16),
                                    label: Text(locale.shareCta),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: GradientActionButton(
                                    label: locale.boostListingCta,
                                    onPressed: () {},
                                    icon: Icons.rocket_launch_outlined,
                                    height: 44,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    onPressed: () => context.push('/post?listingId=${listing.id}'),
                                    icon: const Icon(Icons.edit_outlined, size: 16),
                                    label: Text(locale.editListingCta),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _PauseResumeButton(
                                    isPaused: isPaused,
                                    listingId: listing.id,
                                    onToggle: _togglePause,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text(e.toString())),
        ),
      ),
    );
  }

  Future<void> _togglePause(int listingId, bool currentlyPaused) async {
    try {
      await ref.read(apiClientProvider).put(
        '/properties/$listingId',
        data: {'status': currentlyPaused ? 'live' : 'paused'},
      );
      setState(() {
        if (currentlyPaused) {
          _pausedListingIds.remove(listingId);
        } else {
          _pausedListingIds.add(listingId);
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update listing status.')),
        );
      }
    }
  }
}

class _PauseResumeButton extends StatelessWidget {
  const _PauseResumeButton({
    required this.isPaused,
    required this.listingId,
    required this.onToggle,
  });

  final bool isPaused;
  final int listingId;
  final Future<void> Function(int listingId, bool currentlyPaused) onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale = AppLocalizations.of(context);

    return OutlinedButton.icon(
      onPressed: () => onToggle(listingId, isPaused),
      icon: Icon(
        isPaused ? Icons.play_arrow_outlined : Icons.pause_outlined,
        size: 16,
      ),
      label: Text(
        isPaused ? locale.listingLive : locale.pauseListingCta,
        style: theme.textTheme.labelLarge?.copyWith(
          color: isPaused ? theme.colorScheme.primary : theme.colorScheme.error,
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: isPaused ? theme.colorScheme.primary : theme.colorScheme.error,
        side: BorderSide(
          color: isPaused
              ? theme.colorScheme.primary.withValues(alpha: 0.5)
              : theme.colorScheme.error.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}
