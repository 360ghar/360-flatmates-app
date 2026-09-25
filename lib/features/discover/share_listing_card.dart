import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/deep_links/deep_link_service.dart';
import '../../core/theme/app_radius.dart';
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

/// Secondary text on the exported clay card (on-clay at 90 %).
final _onCard = AppSemanticColors.onClay.withValues(alpha: 0.9);

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
            // Exported as an image, so it uses the fixed light brand colours
            // in both themes, on an opaque fill (no transparent PNG edges).
            child: Container(
              width: MediaQuery.sizeOf(context).width.clamp(0.0, 480.0),
              padding: AppSpacing.edgeXl,
              decoration: const BoxDecoration(
                color: AppSemanticColors.clay,
                borderRadius: AppRadius.xlBorder,
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
                          borderRadius: AppRadius.smBorder,
                        )
                      else
                        const Icon(
                          Icons.apartment_rounded,
                          color: AppSemanticColors.onClay,
                          size: 28,
                        ),
                      const SizedBox(width: AppSpacing.sm),
                      Text(
                        '360 Flatmates',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          color: AppSemanticColors.onClay,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    l.title,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      color: AppSemanticColors.onClay,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  FlatmatesPriceText.hero(
                    amount: l.monthlyRent.toInt(),
                    period: locale.perMonthSuffix,
                    color: _onCard,
                  ),
                  if (l.locality != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: _onCard,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l.locality!,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: _onCard,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s20),
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.sm,
                    children: l.features.take(3).map((f) {
                      return FlatmatesChip(
                        label: localizedFlatmatesFeatureLabel(locale, f),
                        variant: FlatmatesChipVariant.info,
                      );
                    }).toList(),
                  ),
                  if (l.availableFrom != null) ...[
                    const SizedBox(height: AppSpacing.md),
                    Text(
                      locale.homeMoveInValue(
                        DateFormat.MMMd(
                          locale.localeName,
                        ).format(l.availableFrom!.toLocal()),
                      ),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: AppSemanticColors.onClay,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // QR code of the listing deep link, on white for scanning.
                  Center(
                    child: Container(
                      padding: AppSpacing.edgeMd,
                      decoration: const BoxDecoration(
                        color: AppSemanticColors.paper3,
                        borderRadius: AppRadius.mdBorder,
                      ),
                      child: QrImageView(
                        data: DeepLinkService.listingUrl(l.id),
                        size: 120,
                        backgroundColor: AppSemanticColors.paper3,
                        eyeStyle: const QrEyeStyle(
                          eyeShape: QrEyeShape.square,
                          color: AppSemanticColors.clay,
                        ),
                        dataModuleStyle: const QrDataModuleStyle(
                          dataModuleShape: QrDataModuleShape.square,
                          color: AppSemanticColors.clay,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Center(
                    child: Text(
                      locale.scanToOpen,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _onCard,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Center(
                    child: Text(
                      locale.downloadToConnect,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: _onCard,
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
                child: FlatmatesButton.secondary(
                  label: locale.shareToWhatsapp,
                  onPressed: _shareToWhatsApp,
                  icon: Icons.chat_rounded,
                  fullWidth: true,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: FlatmatesButton(
                  label: locale.shareListingCta,
                  onPressed: _share,
                  icon: Icons.share_rounded,
                  fullWidth: true,
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
      text.writeln(
        '${FlatmatesPriceText.formatRupee(l.monthlyRent.round())}${locale.perMonthSuffix}',
      );
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
    text.writeln(
      '${FlatmatesPriceText.formatRupee(l.monthlyRent.round())}${locale.perMonthSuffix}',
    );
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
