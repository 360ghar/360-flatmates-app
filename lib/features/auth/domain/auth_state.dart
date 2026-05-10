import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_state.freezed.dart';

enum AuthStatus { checking, unauthenticated, authenticated, submitting, error }

@Freezed()
class AuthState with _$AuthState {
  const AuthState._();

  const factory AuthState({
    required AuthStatus status,
    String? phone,
    String? errorMessage,
  }) = _AuthState;

  bool get isLoggedIn => status == AuthStatus.authenticated;
}
