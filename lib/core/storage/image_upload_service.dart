import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';

import '../config/endpoints.dart';
import '../domain/wire_enums.dart';
import '../errors/api_error_envelope.dart';
import '../network/api_client.dart';
import '../providers.dart';

/// Callback for tracking upload progress (0.0 – 1.0).
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
  ImageUploadService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Picks up to [limit] gallery images. image_picker's multi-picker throws
  /// for a limit below 2, so a limit of 1 uses the single-image picker and a
  /// limit below 1 picks nothing.
  Future<List<File>> pickImages({int limit = 10}) async {
    if (limit < 1) return [];
    final picker = ImagePicker();
    if (limit == 1) {
      final image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1920,
        maxHeight: 1920,
      );
      return image == null ? [] : [File(image.path)];
    }
    final images = await picker.pickMultiImage(
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
      limit: limit,
    );
    if (images.isEmpty) return [];
    return images.map((x) => File(x.path)).toList();
  }

  Future<File?> pickFromCamera() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (photo == null) return null;
    return File(photo.path);
  }

  Future<File?> pickVideo({
    Duration maxDuration = const Duration(seconds: 60),
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
      tooLong: hasDuration && duration > const Duration(seconds: 60),
      tooShort: hasDuration && duration < const Duration(seconds: 15),
    );
  }

  Future<Duration> _getVideoDuration(File file) async {
    final controller = VideoPlayerController.file(file);
    try {
      await controller.initialize();
      return controller.value.duration;
    } catch (e) {
      debugPrint('ImageUploadService._getVideoDuration failed: $e');
      return Duration.zero;
    } finally {
      await controller.dispose();
    }
  }

  Future<UploadResult> uploadProfilePhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(
      file,
      folderType: StorageFolderType.avatar,
      visibility: TourVisibility.public,
      onProgress: onProgress,
    );
  }

  Future<UploadResult> uploadListingPhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(
      file,
      // `property_image` needs a property id, which a draft listing has not
      // got yet, so POST /upload refuses it. Listing photos go to `generic`.
      folderType: StorageFolderType.generic,
      visibility: TourVisibility.public,
      onProgress: onProgress,
    );
  }

  Future<UploadResult> uploadChatPhoto(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(
      file,
      folderType: StorageFolderType.generic,
      visibility: TourVisibility.private,
      onProgress: onProgress,
    );
  }

  Future<UploadResult> uploadVideoTour(
    File file, {
    UploadProgressCallback? onProgress,
  }) async {
    return _upload(
      file,
      folderType: StorageFolderType.generic,
      visibility: TourVisibility.public,
      onProgress: onProgress,
    );
  }

  /// Upload a file through the backend API which routes to Cloudinary.
  Future<UploadResult> _upload(
    File file, {
    required StorageFolderType folderType,
    required TourVisibility visibility,
    UploadProgressCallback? onProgress,
  }) async {
    try {
      final fileName = file.path.split('/').last;
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(file.path, filename: fileName),
        'folder_type': folderType.wire,
        'visibility': visibility.wire,
      });

      final response = await _apiClient.dio.post(
        FlatmatesEndpoints.upload,
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
          sendTimeout: const Duration(seconds: 120),
          receiveTimeout: const Duration(seconds: 120),
        ),
        onSendProgress: (sent, total) {
          if (onProgress != null && total > 0) {
            onProgress(sent / total);
          }
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final url = data?['public_url'] as String? ?? '';
      if (url.isEmpty) {
        return const UploadFailure(
          reason: 'Upload succeeded but no URL returned.',
        );
      }
      return UploadSuccess(url);
    } on DioException catch (e) {
      final detail = ApiErrorEnvelope.tryParse(e.response?.data)?.message;
      debugPrint('ImageUploadService._upload failed: ${detail ?? e.message}');
      return UploadFailure(
        reason: detail ?? e.message ?? e.type.name,
        underlyingError: e,
      );
    } on SocketException catch (e) {
      return UploadFailure(
        reason: 'Network error during upload — please check your connection.',
        underlyingError: e,
      );
    } catch (e) {
      return UploadFailure(reason: '$e', underlyingError: e);
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
  (ref) => ImageUploadService(apiClient: ref.watch(apiClientProvider)),
);
