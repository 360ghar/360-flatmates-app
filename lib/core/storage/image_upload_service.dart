import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:video_player/video_player.dart';

/// Callback for tracking upload progress (0.0 – 1.0).
/// Note: Supabase storage upload does not expose progress events yet,
/// so this callback is accepted but currently unused.
typedef UploadProgressCallback = void Function(double progress);

/// Sealed result type for upload operations.
sealed class UploadResult {
  const UploadResult();
}

/// Upload succeeded — [url] is the public URL of the stored object.
final class UploadSuccess extends UploadResult {
  const UploadSuccess(this.url);
  final String url;
}

/// Upload failed — [reason] is a human-readable description.
/// [underlyingError] may hold the original exception for logging.
final class UploadFailure extends UploadResult {
  const UploadFailure({required this.reason, this.underlyingError});
  final String reason;
  final Object? underlyingError;
}

class ImageUploadService {
  const ImageUploadService();

  static final _random = Random.secure();

  Future<List<File>> pickImages({int limit = 10}) async {
    final picker = ImagePicker();
    final images = await picker.pickMultiImage(imageQuality: 80, limit: limit);
    if (images.isEmpty) return [];
    return images.map((x) => File(x.path)).toList();
  }

  Future<File?> pickFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickVideo({
    Duration maxDuration = const Duration(seconds: 30),
  }) async {
    final picker = ImagePicker();
    final video = await picker.pickVideo(
      source: ImageSource.gallery,
      maxDuration: maxDuration,
    );
    if (video == null) return null;
    return File(video.path);
  }

  Future<VideoValidationResult> validateVideo(File file) async {
    final size = await file.length();
    if (size > 50 * 1024 * 1024) {
      return const VideoValidationResult(
        tooLarge: true,
        tooLong: false,
        tooShort: false,
      );
    }
    final duration = await _getVideoDuration(file);
    final hasDuration = duration > Duration.zero;
    return VideoValidationResult(
      tooLarge: false,
      tooLong: hasDuration && duration > const Duration(seconds: 30),
      tooShort: hasDuration && duration < const Duration(seconds: 15),
    );
  }

  Future<Duration> _getVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (_) {
      return Duration.zero;
    } finally {
      await controller.dispose();
    }
  }

  Future<UploadResult> uploadProfilePhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(file, 'profile-photos', onProgress: onProgress);
  }

  Future<UploadResult> uploadListingPhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(file, 'listing-photos', onProgress: onProgress);
  }

  Future<UploadResult> uploadChatPhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(file, 'chat-photos', onProgress: onProgress);
  }

  Future<UploadResult> uploadVideoTour(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(file, 'listing-videos', onProgress: onProgress);
  }

  Future<UploadResult> _upload(
    File file,
    String bucket, {
    UploadProgressCallback? onProgress,
  }) async {
    final supabase = Supabase.instance.client;

    // Generate a unique, collision-resistant filename.
    final ext = file.path.split('.').last;
    final safeExt = ext.isEmpty ? 'jpg' : ext;
    final name =
        '${DateTime.now().microsecondsSinceEpoch}_${_random.nextInt(999999)}.$safeExt';

    try {
      await supabase.storage.from(bucket).upload(name, file);
      final url = supabase.storage.from(bucket).getPublicUrl(name);
      return UploadSuccess(url);
    } on StorageException catch (e) {
      return UploadFailure(
        reason: 'Storage upload failed: ${e.message}',
        underlyingError: e,
      );
    } on SocketException catch (e) {
      return UploadFailure(
        reason: 'Network error during upload — please check your connection.',
        underlyingError: e,
      );
    } catch (e) {
      return UploadFailure(reason: 'Upload failed: $e', underlyingError: e);
    }
  }
}

class VideoValidationResult {
  const VideoValidationResult({
    required this.tooLarge,
    required this.tooLong,
    required this.tooShort,
  });

  final bool tooLarge;
  final bool tooLong;
  final bool tooShort;

  bool get isValid => !tooLarge && !tooLong && !tooShort;
}

final imageUploadServiceProvider = Provider<ImageUploadService>(
  (ref) => const ImageUploadService(),
);
