import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Helper for optimistic state updates with rollback on failure.
///
/// Usage in a controller:
/// ```dart
/// await performOptimistic(
///   ref: ref,
///   optimisticState: state.copyWith(liked: true),
///   action: () => repository.likeListing(id),
///   onSuccess: () => state = state.copyWith(liked: true),
///   onError: (error) => state = state.copyWith(error: error),
/// );
/// ```
class OptimisticUpdate {
  const OptimisticUpdate._();

  /// Performs an optimistic update pattern.
  ///
  /// 1. Immediately applies [optimisticState] to the provider
  /// 2. Runs [action] (the real API call)
  /// 3. On success, calls [onSuccess] (confirms the optimistic state)
  /// 4. On failure, calls [onError] (typically rolls back to previous state)
  static Future<void> perform<T>({
    required Ref ref,
    required T optimisticState,
    required T previousState,
    required void Function(T state) setState,
    required Future<void> Function() action,
    void Function()? onSuccess,
    void Function(Object error)? onError,
  }) async {
    // Apply optimistic state immediately
    setState(optimisticState);

    try {
      await action();
      onSuccess?.call();
    } catch (e) {
      // Rollback on failure
      setState(previousState);
      onError?.call(e);
    }
  }
}
