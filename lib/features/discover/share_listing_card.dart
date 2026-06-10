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
  final _whatsappKey = GlobalKey();
  final _instagramKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = widget.listing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Original share card (kept intact)
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            width: 360,
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
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Center(
                  child: Text(
                    locale.downloadToConnect,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── WhatsApp square share template (1080x1080) ──
        RepaintBoundary(
          key: _whatsappKey,
          child: _buildWhatsAppSquareTemplate(context, l, locale, theme),
        ),
        const SizedBox(height: AppSpacing.md),

        // ── Instagram story template (1080x1920) ──
        RepaintBoundary(
          key: _instagramKey,
          child: _buildInstagramStoryTemplate(context, l, locale, theme),
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
        const SizedBox(height: AppSpacing.md),

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
      ],
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

  // ── WhatsApp square share template (1080×1080 logical px) ──

  Widget _buildWhatsAppSquareTemplate(
    BuildContext context,
    PropertyListing l,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    // Use a fixed 360×360 widget that renders at 3x = 1080×1080
    return SizedBox(
      width: 360,
      height: 360,
      child: Container(
        decoration: BoxDecoration(
          color: AppSemanticColors.surfaceFor(theme.brightness),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            // Large listing image at top (60% height = 216)
            Expanded(
              flex: 6,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (l.effectiveMainImageUrl != null &&
                      l.effectiveMainImageUrl!.isNotEmpty)
                    FlatmatesNetworkImage(
                      imageUrl: l.effectiveMainImageUrl!,
                      fit: BoxFit.cover,
                    )
                  else
                    _imagePlaceholder(theme),
                  // Gradient overlay at bottom of image
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content below image (40% height = 144)
            Expanded(
              flex: 4,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Rent price
                    FlatmatesPriceText.hero(
                      amount: l.monthlyRent.toInt(),
                      period: 'mo',
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // Locality
                    if (l.locality != null)
                      Row(
                        children: [
                          Icon(
                            Icons.location_on_outlined,
                            size: 16,
                            color: AppSemanticColors.textSecondaryFor(
                              theme.brightness,
                            ),
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Flexible(
                            child: Text(
                              l.locality!,
                              style: theme.textTheme.bodyMedium?.copyWith(
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
                    const SizedBox(height: AppSpacing.sm),
                    // 3 amenity pills
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: l.features.take(3).map((f) {
                        return FlatmatesChip(
                          label: localizedFlatmatesFeatureLabel(locale, f),
                          variant: FlatmatesChipVariant.info,
                        );
                      }).toList(),
                    ),
                    const Spacer(),
                    // Branding footer
                    const Center(
                      child: Text(
                        '360 FLATMATES',
                        style: TextStyle(
                          color: AppSemanticColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.6,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Instagram story template (1080×1920 logical px) ──

  Widget _buildInstagramStoryTemplate(
    BuildContext context,
    PropertyListing l,
    AppLocalizations locale,
    ThemeData theme,
  ) {
    // Use a fixed 360×640 widget that renders at 3x = 1080×1920
    return SizedBox(
      width: 360,
      height: 640,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-bleed image
            if (l.effectiveMainImageUrl != null &&
                l.effectiveMainImageUrl!.isNotEmpty)
              FlatmatesNetworkImage(
                imageUrl: l.effectiveMainImageUrl!,
                fit: BoxFit.cover,
              )
            else
              _imagePlaceholder(theme),
            // Gradient overlay for text readability
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  stops: [0.0, 0.35, 0.7, 1.0],
                  colors: [
                    Colors.black45,
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black87,
                  ],
                ),
              ),
            ),
            // Content overlay
            Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top: brand
                  const Text(
                    '360 FLATMATES',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.6,
                    ),
                  ),
                  const Spacer(),
                  // Bottom section: listing info
                  FlatmatesPriceText.hero(
                    amount: l.monthlyRent.toInt(),
                    period: 'month',
                    color: Colors.white,
                  ),
                  if (l.locality != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: Colors.white70,
                          size: 18,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            l.locality!,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (l.availableFrom != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_today_outlined,
                          color: Colors.white70,
                          size: 16,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'Move-in: ${l.availableFrom!.toLocal().day}/${l.availableFrom!.toLocal().month}/${l.availableFrom!.toLocal().year}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: AppSpacing.xl),
                  // "Scan to connect" CTA
                  Center(
                    child: Text(
                      locale.scanToConnect,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  // QR code area
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppSemanticColors.surfaceFor(theme.brightness),
                        borderRadius: BorderRadius.circular(12),
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
                  const SizedBox(height: AppSpacing.md),
                  // Branding footer
                  const Center(
                    child: Text(
                      '360 FLATMATES',
                      style: TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder(ThemeData theme) {
    return Container(
      color: AppSemanticColors.accent.withValues(alpha: 0.15),
      child: Center(
        child: Icon(
          Icons.apartment_rounded,
          size: 48,
          color: AppSemanticColors.accent.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Future<void> _share() async {
    final deepLink = DeepLinkService.listingUrl(widget.listing.id);
    final locale = AppLocalizations.of(context);
    try {
      final boundary =
          _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flatmates_share_card.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles([
        XFile(file.path),
      ], text: '${locale.checkOutListingShare} $deepLink');
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
      await Share.share(text.toString());
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
