import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/errors/app_failure.dart';
import '../../core/notifications/notification_service.dart';
import '../../core/providers.dart';
import 'data/auth_repository.dart';
import 'domain/auth_state.dart';

export 'domain/auth_state.dart';

final pendingPhoneProvider = StateProvider<String?>((ref) => null);

class AuthController extends Notifier<AuthState> {
  StreamSubscription<String?>? _tokenSubscription;

  @override
  AuthState build() {
    _watchTokenClears();
    Future<void>.microtask(checkSession);
    return const AuthState(status: AuthStatus.checking);
  }

  AuthRepository get _repository => ref.read(authRepositoryProvider);

  void _watchTokenClears() {
    _tokenSubscription = ref
        .read(authTokenStorageProvider)
        .changes
        .listen(
          (token) {
            if (token == null &&
                state.isLoggedIn &&
                state.status != AuthStatus.submitting) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
          onError: (error) {
            if (state.status != AuthStatus.submitting) {
              state = const AuthState(status: AuthStatus.unauthenticated);
            }
          },
        );

    ref.onDispose(() {
      _tokenSubscription?.cancel();
    });
  }

  Future<void> checkSession() async {
    try {
      final session = _repository.currentSession;
      if (session == null) {
        state = const AuthState(status: AuthStatus.unauthenticated);
        return;
      }
      state = AuthState(
        status: AuthStatus.authenticated,
        phone: _repository.currentPhone,
      );
    } catch (_) {
      state = const AuthState(status: AuthStatus.unauthenticated);
    }
  }

  void clearError() {
    if (state.status == AuthStatus.error) {
      state = AuthState(status: AuthStatus.unauthenticated, phone: state.phone);
    }
  }

  String _userSafeMessage(Object error) {
    if (error is AppFailure) return error.label;
    return 'Something went wrong';
  }

  Future<void> requestOtp(String phone) async {
    clearError();
    state = AuthState(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.requestOtp(phone);
      state = AuthState(status: AuthStatus.unauthenticated, phone: phone);
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
    }
  }

  Future<bool> signInWithPassword({
    required String phone,
    required String password,
  }) async {
    clearError();
    state = AuthState(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.signInWithPassword(phone: phone, password: password);
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  Future<bool> signUpWithPassword({
    required String fullName,
    required String phone,
    required String password,
    String? email,
  }) async {
    clearError();
    state = AuthState(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.signUpWithPassword(
        fullName: fullName,
        phone: phone,
        password: password,
        email: email,
      );
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  Future<bool> verifyOtp({required String phone, required String otp}) async {
    clearError();
    state = AuthState(status: AuthStatus.submitting, phone: phone);
    try {
      await _repository.verifyOtp(phone: phone, otp: otp);
      state = AuthState(status: AuthStatus.authenticated, phone: phone);
      return true;
    } catch (error) {
      state = AuthState(
        status: AuthStatus.error,
        errorMessage: _userSafeMessage(error),
        phone: phone,
      );
      return false;
    }
  }

  Future<void> signOut() async {
    try {
      await ref.read(notificationServiceProvider).clearToken();
    } catch (_) {}
    try {
      await _repository.signOut();
    } catch (_) {}
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    apiClient: ref.watch(apiClientProvider),
    tokenStorage: ref.watch(authTokenStorageProvider),
  ),
);

final authControllerProvider = NotifierProvider<AuthController, AuthState>(
  AuthController.new,
);
