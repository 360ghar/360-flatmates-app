import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/flatmates_toast.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_chip.dart';
import '../shared/presentation/flatmates_price_text.dart';
import '../shared/presentation/flatmates_ui.dart';
import '../shared/presentation/flatmates_network_image.dart';

class ShareListingCard extends ConsumerStatefulWidget {
  const ShareListingCard({required this.listing, super.key});

  final PropertyListing listing;

  @override
  ConsumerState<ShareListingCard> createState() => _ShareListingCardState();
}

class _ShareListingCardState extends ConsumerState<ShareListingCard> {
  final _cardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    // Copy the deep link to clipboard on open and notify the user.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _copyLink();
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = widget.listing;

    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Shareable link with copy action
          Container(
            key: const Key('share_link_row'),
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.5,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.link, size: 18),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    DeepLinkService.listingUrl(l.id),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  key: const Key('copy_link_button'),
                  tooltip: locale.copyLinkAction,
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: _copyLink,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Original share card (kept intact).
          // Clamped to 480 so the captured image isn't excessively wide on tablets.
          RepaintBoundary(
            key: _cardKey,
            child: Container(
              width: MediaQuery.sizeOf(context).width.clamp(0.0, 480.0),
              padding: const EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppSemanticColors.accent.withValues(alpha: 0.95),
                    AppSemanticColors.accent.withValues(alpha: 0.7),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      if (l.effectiveMainImageUrl != null &&
                          l.effectiveMainImageUrl!.isNotEmpty)
                        FlatmatesNetworkImage(
                          imageUrl: l.effectiveMainImageUrl!,
                          width: 28,
                          height: 28,
                          borderRadius: BorderRadius.circular(8),
                        )
                      else
                        const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      const SizedBox(width: 10),
                      const Text(
                        '360 FLATMATES',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FlatmatesPriceText.hero(
                    amount: l.monthlyRent.toInt(),
                    period: 'month',
                    color: Colors.white70,
                  ),
                  if (l.locality != null) ...[
                    const SizedBox(height: AppSpacing.sm - AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          l.locality!,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.md + AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.xs + AppSpacing.xs,
                    runSpacing: AppSpacing.xs + AppSpacing.xs,
                    children: l.features.take(3).map((f) {
                      return FlatmatesChip(
                        label: localizedFlatmatesFeatureLabel(locale, f),
                        variant: FlatmatesChipVariant.info,
                      );
                    }).toList(),
                  ),
                  if (l.availableFrom != null) ...[
                    const SizedBox(height: AppSpacing.sm + AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Move-in: ${l.availableFrom!.toLocal().day}/${l.availableFrom!.toLocal().month}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // QR code of the listing deep link
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.surfaceFor(theme.brightness),
                        borderRadius: BorderRadius.circular(AppSpacing.md),
                      ),
                      child: QrImageView(
                        data: DeepLinkService.listingUrl(l.id),
                        size: 120,
                        backgroundColor: Colors.white,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppSemanticColors.accent,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppSemanticColors.accent,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md + AppSpacing.sm),
                  Center(
                    child: Text(
                      locale.scanToOpen,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Center(
                    child: Text(
                      locale.downloadToConnect,
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Share buttons row (existing behavior preserved)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _shareToWhatsApp,
                  icon: const Icon(Icons.chat_rounded),
                  label: Text(locale.shareToWhatsapp),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FlatmatesButton(
                  label: locale.shareListingCta,
                  onPressed: _share,
                  icon: Icons.share_rounded,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _copyLink() async {
    final locale = AppLocalizations.of(context);
    await Clipboard.setData(
      ClipboardData(text: DeepLinkService.listingUrl(widget.listing.id)),
    );
    if (!mounted) return;
    FlatmatesToast.success(context, locale.linkCopiedToast);
  }

  Future<void> _share() async {
    final deepLink = DeepLinkService.listingUrl(widget.listing.id);
    final locale = AppLocalizations.of(context);

    // Compute a share-position origin rect from the captured card so iPadOS
    // and iOS 26+ anchor the share popover correctly (required there,
    // harmless elsewhere). Computed before any await so it is not subject to
    // build-context-after-await checks.
    final renderObj = _cardKey.currentContext?.findRenderObject();
    Rect? shareOrigin;
    if (renderObj is RenderBox && renderObj.hasSize) {
      shareOrigin = renderObj.localToGlobal(Offset.zero) & renderObj.size;
    }

    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flatmates_share_card.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: '${locale.checkOutListingShare} $deepLink',
        sharePositionOrigin: shareOrigin,
      );
    } catch (e) {
      debugPrint(
        'ShareListingCard._share: image capture failed, falling back to text: $e',
      );
      // Fallback to text-only share if image capture fails
      final l = widget.listing;
      final text = StringBuffer();
      text.writeln(l.title);
      text.writeln('Rs ${l.monthlyRent.toStringAsFixed(0)}/month');
      if (l.locality != null) {
        text.writeln(l.locality);
      }
      text.writeln();
      text.writeln(locale.findYourFlatmateShare);
      text.writeln(deepLink);
      await Share.share(text.toString(), sharePositionOrigin: shareOrigin);
    }
  }

  Future<void> _shareToWhatsApp() async {
    final deepLink = DeepLinkService.listingUrl(widget.listing.id);
    final l = widget.listing;
    final locale = AppLocalizations.of(context);
    final text = StringBuffer();
    text.writeln(l.title);
    text.writeln('Rs ${l.monthlyRent.toStringAsFixed(0)}/month');
    if (l.locality != null) text.writeln(l.locality);
    text.writeln();
    text.writeln(locale.findYourFlatmateShare);
    text.writeln(deepLink);

    final whatsappUrl = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(text.toString())}',
    );
    final canLaunch = await canLaunchUrl(whatsappUrl);
    if (canLaunch) {
      await launchUrl(whatsappUrl);
    } else {
      if (!mounted) return;
      final locale = AppLocalizations.of(context);
      FlatmatesToast.info(context, locale.whatsappNotInstalled);
    }
  }
}
