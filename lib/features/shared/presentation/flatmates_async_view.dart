import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/errors/app_failure.dart';
import '../../../core/errors/l10n_bridge.dart';
import '../../../l10n/gen/app_localizations.dart';
import 'flatmates_error_state.dart';
import 'flatmates_skeleton.dart';

/// A reusable async-state handler for screens backed by [AsyncValue].
///
/// Renders one of four states: loading, data, empty, error.
/// Eliminates per-screen ad hoc CircularProgressIndicator / error.toString()
/// / empty Center(Text(...)) patterns.
///
/// Usage:
/// ```dart
/// FlatmatesAsyncView<List<PropertyListing>>(
///   value: ref.watch(listingsProvider),
///   data: (listings) => ListingListView(listings: listings),
///   empty: FlatmatesEmptyState(title: 'No listings'),
///   onRetry: () => ref.invalidate(listingsProvider),
/// )
/// ```
class FlatmatesAsyncView<T> extends StatelessWidget {
  const FlatmatesAsyncView({
    required this.value,
    required this.data,
    super.key,
    this.loading,
    this.error,
    this.empty,
    this.onRetry,
    this.isEmpty,
  });

  /// The async value to render.
  final AsyncValue<T> value;

  /// Builder for the data state.
  final Widget Function(T data) data;

  /// Optional custom loading widget. Defaults to [FlatmatesSkeleton.list].
  final Widget? loading;

  /// Optional custom error widget.
  final Widget Function(Object error, StackTrace stack)? error;

  /// Optional empty-state widget shown when [isEmpty] returns true.
  final Widget? empty;

  /// Optional retry callback shown on error state.
  final VoidCallback? onRetry;

  /// Predicate to determine if data is "empty". Defaults to checking
  /// if the value is an empty `Iterable`.
  final bool Function(T data)? isEmpty;

  bool _checkEmpty(T d) {
    if (isEmpty != null) return isEmpty!(d);
    if (d is Iterable) return d.isEmpty;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: (d) {
        if (_checkEmpty(d) && empty != null) {
          return empty!;
        }
        return data(d);
      },
      loading: () => loading ?? const FlatmatesSkeleton.list(),
      error: (e, st) {
        if (error != null) {
          return error!(e, st);
        }
        final locale = AppLocalizations.of(context);
        final message = e is AppFailure
            ? e.userMessage(locale.toUserMessageL10n())
            : locale.errorUnknown;
        return FlatmatesErrorState(message: message, onRetry: onRetry);
      },
    );
  }
}
