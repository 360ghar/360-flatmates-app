import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Simple mutable value holder replacing [StateProvider] for shared state.
///
/// Prefer this for **shared / product** mutable state (filters, routing
/// signals, cross-widget UI flags). Prefer widget-local `setState` for true
/// ephemeral UI (password visibility, carousel index, one-shot spinners).
///
/// ```dart
/// final flagProvider =
///     NotifierProvider<MutableNotifier<bool>, bool>(() => MutableNotifier(false));
///
/// ref.watch(flagProvider);
/// ref.read(flagProvider.notifier).set(true);
/// ref.read(flagProvider.notifier).update((v) => !v);
/// ```
class MutableNotifier<T> extends Notifier<T> {
  MutableNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;

  void update(T Function(T current) fn) => state = fn(state);
}

/// Auto-dispose variant for route-scoped shared state.
class AutoDisposeMutableNotifier<T> extends AutoDisposeNotifier<T> {
  AutoDisposeMutableNotifier(this._initial);

  final T _initial;

  @override
  T build() => _initial;

  void set(T value) => state = value;

  void update(T Function(T current) fn) => state = fn(state);
}
