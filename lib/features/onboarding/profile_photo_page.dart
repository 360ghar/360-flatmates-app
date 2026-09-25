import 'package:flutter/material.dart';
import 'package:flatmates_app/core/theme/app_semantic_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage/image_upload_service.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';
import '../../l10n/gen/app_localizations.dart';
import '../shared/presentation/components.dart';
import 'onboarding_controller.dart';

class ProfilePhotoPage extends ConsumerStatefulWidget {
  const ProfilePhotoPage({required this.onComplete, super.key});

  final void Function(List<String> urls) onComplete;

  @override
  ConsumerState<ProfilePhotoPage> createState() => _ProfilePhotoPageState();
}

class _ProfilePhotoPageState extends ConsumerState<ProfilePhotoPage> {
  final _photoUrls = <String>[];
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    final controllerState = ref.read(onboardingControllerProvider);
    _photoUrls.addAll(controllerState.photoUrls);
  }

  Future<void> _pickFromGallery() async {
    final service = ref.read(imageUploadServiceProvider);
    final files = await service.pickImages(limit: 5 - _photoUrls.length);
    if (files.isEmpty || !mounted) return;
    setState(() => _uploading = true);
    try {
      for (final file in files) {
        final result = await service.uploadProfilePhoto(file);
        if (result is UploadSuccess) {
          _photoUrls.add(result.url);
          if (mounted) setState(() {});
        } else if (result is UploadFailure) {
          debugPrint(
            '[ProfilePhotoPage] _pickFromGallery upload failed: ${result.reason}',
          );
          if (mounted) {
            FlatmatesToast.error(
              context,
              AppLocalizations.of(context).errorUpload,
            );
          }
        }
      }
    } catch (e, st) {
      debugPrint('[ProfilePhotoPage] _pickFromGallery error: $e\n$st');
      if (mounted) {
        FlatmatesToast.error(context, AppLocalizations.of(context).errorUpload);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickFromCamera() async {
    final service = ref.read(imageUploadServiceProvider);
    final file = await service.pickFromCamera();
    if (file == null) return;
    setState(() => _uploading = true);
    try {
      final result = await service.uploadProfilePhoto(file);
      if (result is UploadSuccess) {
        _photoUrls.add(result.url);
        if (mounted) setState(() {});
      } else if (result is UploadFailure) {
        debugPrint(
          '[ProfilePhotoPage] _pickFromCamera upload failed: ${result.reason}',
        );
        if (mounted) {
          FlatmatesToast.error(
            context,
            AppLocalizations.of(context).errorUpload,
          );
        }
      }
    } catch (e, st) {
      debugPrint('[ProfilePhotoPage] _pickFromCamera error: $e\n$st');
      if (mounted) {
        FlatmatesToast.error(context, AppLocalizations.of(context).errorUpload);
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _removePhoto(int index) {
    setState(() => _photoUrls.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final locale = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final state = ref.watch(onboardingControllerProvider);
    final uploading = _uploading;
    final fullName = state.fullName;
    final displayUrl = _photoUrls.isEmpty ? null : _photoUrls.first;

    return Material(
      // Steps sit inside the onboarding FlatmatesScreen, which owns the
      // scaffold and safe area; this only gives fields a Material ancestor.
      type: MaterialType.transparency,
      child: Padding(
        padding: AppSpacing.horizontalScreen,
        child: ListView(
          children: [
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.profilePhotoTitle,
              style: theme.textTheme.headlineLarge,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              locale.profilePhotoSubtitle,
              style: theme.textTheme.bodyLarge?.copyWith(
                color: AppSemanticColors.textSecondaryFor(theme.brightness),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            InfoPill(
              icon: Icons.lightbulb_outline,
              label: locale.profilePhotoNudge,
              highlighted: true,
            ),
            const SizedBox(height: AppSpacing.screen),
            Center(
              child: FlatmatesAvatar(
                name: fullName,
                imageUrl: displayUrl,
                size: 140,
                onTap: _uploading || _photoUrls.length >= 5
                    ? null
                    : _pickFromGallery,
              ),
            ),
            // Always shown, so a new user can add the first photo.
            const SizedBox(height: AppSpacing.screen),
            FlatmatesCard(
              child: Wrap(
                spacing: AppSpacing.base,
                runSpacing: AppSpacing.base,
                children: [
                  ..._photoUrls.asMap().entries.map((entry) {
                    return _PhotoTile(
                      imageUrl: entry.value,
                      onRemove: () => _removePhoto(entry.key),
                    );
                  }),
                  if (_photoUrls.length < 5)
                    _AddPhotoTile(
                      onGallery: _pickFromGallery,
                      onCamera: _pickFromCamera,
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.screen + AppSpacing.lg),
            if (uploading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.lg),
                child: Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              )
            else ...[
              FlatmatesButton(
                key: const Key('onboarding_photo_next'),
                label: locale.onboardingNext,
                fullWidth: true,
                onPressed: () => widget.onComplete(List.of(_photoUrls)),
                icon: Icons.arrow_forward_rounded,
              ),
              const SizedBox(height: AppSpacing.sm),
              Center(
                child: FlatmatesButton.tertiary(
                  key: const Key('onboarding_photo_skip'),
                  label: locale.skipCta,
                  onPressed: () => widget.onComplete(const <String>[]),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.imageUrl, required this.onRemove});

  final String imageUrl;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final brightness = Theme.of(context).brightness;
    return Stack(
      children: [
        FlatmatesNetworkImage(
          imageUrl: imageUrl,
          width: 130,
          height: 160,
          borderRadius: AppRadius.cardBorder,
        ),
        // 48 dp tap target inside the tile; the visible disc is 32 dp.
        Positioned(
          right: 0,
          top: 0,
          child: Semantics(
            button: true,
            label: AppLocalizations.of(context).removePhotoTooltip,
            child: Tooltip(
              message: AppLocalizations.of(context).removePhotoTooltip,
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: SizedBox.square(
                  dimension: kMinInteractiveDimension,
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: AppSemanticColors.dangerFor(brightness),
                        shape: BoxShape.circle,
                      ),
                      child: Padding(
                        padding: AppSpacing.edgeSm,
                        child: Icon(
                          Icons.close,
                          color: AppSemanticColors.onClayFor(brightness),
                          size: 16,
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
    );
  }
}

class _AddPhotoTile extends StatelessWidget {
  const _AddPhotoTile({required this.onGallery, required this.onCamera});

  final VoidCallback onGallery;
  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color: AppSemanticColors.disabledSurfaceFor(
        theme.brightness,
      ).withValues(alpha: 0.5),
      borderRadius: AppRadius.cardBorder,
      child: InkWell(
        borderRadius: AppRadius.cardBorder,
        onTap: onGallery,
        onLongPress: onCamera,
        child: SizedBox(
          width: 130,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.camera_alt_outlined,
                size: 28,
                color: AppSemanticColors.clayFor(theme.brightness),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppLocalizations.of(context).addPhotoCta,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppSemanticColors.textSecondaryFor(theme.brightness),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
