import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../chats/application/cursor_list_controller.dart';
import '../data/payments_api.dart';
import '../data/payment_method_dto.dart';
import '../domain/payment_method.dart';
import '../domain/razorpay_order.dart';

/// Controller that exposes the user's saved payment methods as a
/// cursor-paginated list, plus the write/mutation operations the UI needs.
///
/// The actual card capture is expected to happen via Razorpay.js / SDK;
/// this controller only forwards the resulting token to the backend via
/// `POST /payments/methods`.
class PaymentMethodsController
    extends CursorListController<PaymentMethod> {
  @override
  Future<
      ({
        List<PaymentMethod> items,
        String? nextCursor,
        bool hasMore,
      })> fetchPage({String? cursor}) async {
    final page = await ref.read(paymentsApiProvider).listPaymentMethods(
          cursor: cursor,
        );
    return (
      items: page.items.map(PaymentMethod.fromDto).toList(),
      nextCursor: page.nextCursor,
      hasMore: page.hasMore,
    );
  }

  /// Adds a new method via the backend. The caller is expected to have
  /// already tokenized the card with Razorpay.js/SDK and have a token
  /// ready to forward.
  Future<PaymentMethod> add(PaymentMethodCreateDto request) async {
    final dto = await ref.read(paymentsApiProvider).addPaymentMethod(request);
    final method = PaymentMethod.fromDto(dto);
    // Optimistically prepend so the user sees their new card without
    // waiting for the next page load.
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(items: [method, ...current.items]),
      );
    } else {
      // No cache yet — kick off a fresh load so the list is populated.
      unawaited(refresh());
    }
    return method;
  }

  /// Updates the mutable fields (nickname + default flag) on a saved method.
  Future<PaymentMethod> update(
    int id,
    PaymentMethodUpdateDto request,
  ) async {
    final dto =
        await ref.read(paymentsApiProvider).updatePaymentMethod(id, request);
    final method = PaymentMethod.fromDto(dto);
    final current = state.valueOrNull;
    if (current != null) {
      // The backend flips every other method's `is_default` to false when
      // setting a new default, so a full reload is safer than a local patch.
      unawaited(refresh());
    }
    return method;
  }

  Future<void> delete(int id) async {
    await ref.read(paymentsApiProvider).deletePaymentMethod(id);
    final current = state.valueOrNull;
    if (current != null) {
      state = AsyncValue.data(
        current.copyWith(
          items: current.items.where((m) => m.id != id).toList(),
        ),
      );
    }
  }
}

final paymentMethodsControllerProvider = NotifierProvider<
    PaymentMethodsController,
    AsyncValue<CursorListState<PaymentMethod>>>(
  PaymentMethodsController.new,
);

/// Wrapper controller for the Razorpay checkout flow. The actual hosted
/// checkout runs in `url_launcher` (web) or via the Razorpay SDK (mobile)
/// and emits the identifiers this controller forwards to
/// `POST /payments/razorpay/verify` for backend signature verification.
class PaymentsController extends Notifier<AsyncValue<RazorpayOrder?>> {
  @override
  AsyncValue<RazorpayOrder?> build() {
    return const AsyncValue.data(null);
  }

  /// Mints a Razorpay order for the supplied booking id. Caller is
  /// expected to hand the [RazorpayOrder] to Razorpay.js / SDK to collect
  /// the payment.
  Future<RazorpayOrder> createOrder(int bookingId) async {
    state = const AsyncValue.loading();
    try {
      final dto =
          await ref.read(paymentsApiProvider).createRazorpayOrder(bookingId);
      final order = RazorpayOrder.fromDto(dto);
      state = AsyncValue.data(order);
      return order;
    } catch (e, st) {
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  /// Forwards the Razorpay-issued identifiers to the backend so it can
  /// verify the HMAC signature and capture the payment.
  Future<void> verifyPayment({
    required int bookingId,
    required String razorpayOrderId,
    required String razorpayPaymentId,
    required String razorpaySignature,
  }) async {
    try {
      await ref.read(paymentsApiProvider).verifyRazorpayPayment(
            bookingId: bookingId,
            razorpayOrderId: razorpayOrderId,
            razorpayPaymentId: razorpayPaymentId,
            razorpaySignature: razorpaySignature,
          );
    } catch (e, st) {
      if (kDebugMode) {
        debugPrint('PaymentsController.verifyPayment failed: $e');
      }
      state = AsyncValue.error(e, st);
      rethrow;
    }
  }

  void reset() {
    state = const AsyncValue.data(null);
  }
}

final paymentsControllerProvider =
    NotifierProvider<PaymentsController, AsyncValue<RazorpayOrder?>>(
  PaymentsController.new,
);
