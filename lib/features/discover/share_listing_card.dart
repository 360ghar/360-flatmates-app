import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../l10n/gen/app_localizations.dart';
import '../discover/discover_repository.dart';
import '../shared/presentation/flatmates_ui.dart';

class ShareListingCard extends ConsumerStatefulWidget {
  const ShareListingCard({required this.listing, super.key});

  final PropertyListing listing;

  @override
  ConsumerState<ShareListingCard> createState() => _ShareListingCardState();
}

class _ShareListingCardState extends ConsumerState<ShareListingCard> {
  final _cardKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final l = widget.listing;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        RepaintBoundary(
          key: _cardKey,
          child: Container(
            width: 360,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary.withValues(alpha: 0.95),
                  theme.colorScheme.primary.withValues(alpha: 0.7),
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
                    if (l.mainImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          l.mainImageUrl!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (_, _, _) =>
                              const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
                        ),
                      )
                    else
                      const Icon(Icons.apartment_rounded, color: Colors.white, size: 28),
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
                const SizedBox(height: 20),
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
                const SizedBox(height: 8),
                if (l.monthlyRent != null)
                  Text(
                    '₹${l.monthlyRent!.toStringAsFixed(0)}/month',
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (l.locality != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        l.locality!,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: l.features.take(3).map((f) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        localizedFlatmatesFeatureLabel(locale, f),
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    );
                  }).toList(),
                ),
                if (l.availableFrom != null) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Move-in: ${l.availableFrom!.toLocal().day}/${l.availableFrom!.toLocal().month}',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                const Center(
                  child: Text(
                    'Download 360 FlatMates to connect',
                    style: TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            GradientActionButton(
              label: locale.shareListingCta,
              onPressed: _share,
              icon: Icons.share_rounded,
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _share() async {
    try {
      final boundary = _cardKey.currentContext!.findRenderObject()! as RenderRepaintBoundary;
      final image = await boundary.toImage(pixelRatio: 3.0);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/flatmates_share_card.png');
      await file.writeAsBytes(byteData!.buffer.asUint8List());
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Check out this listing on 360 FlatMates!',
      );
    } catch (_) {
      // Fallback to text-only share if image capture fails
      final l = widget.listing;
      final text = StringBuffer();
      text.writeln(l.title);
      if (l.monthlyRent != null) text.writeln('Rs ${l.monthlyRent!.toStringAsFixed(0)}/month');
      if (l.locality != null) text.writeln(l.locality);
      text.writeln();
      text.writeln('Find your flatmate on 360 FlatMates!');
      text.writeln('Android: https://play.google.com/store/apps/details?id=com.the360ghar.flatmates');
      text.writeln('iOS: https://apps.apple.com/app/idXXXXXXX');
      await Share.share(text.toString());
    }
  }
}
