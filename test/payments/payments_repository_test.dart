import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flatmates_app/core/config/endpoints.dart';
import 'package:flatmates_app/core/network/api_client.dart';
import 'package:flatmates_app/core/providers.dart';
import 'package:flatmates_app/features/payments/application/payments_controller.dart';
import 'package:flatmates_app/features/payments/data/payment_method_dto.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/test_helpers.dart';

void main() {
  group('PaymentsApi', () {
    test(
      'createRazorpayOrder POSTs booking_id and parses response',
      () async {
        final adapter = _CapturingAdapter(
          responseBody: jsonEncode({
            'order_id': 'order_123',
            'amount': 25000,
            'currency': 'INR',
            'receipt': 'rcpt_42',
            'status': 'created',
            'checkout_url': 'https://rzp.io/i/abc',
          }),
        );
        final container = _containerWith(adapter);
        addTearDown(container.dispose);

        final order = await container
            .read(paymentsApiProvider)
            .createRazorpayOrder(42);

        expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentRazorpayOrder);
        expect(adapter.lastRequest?.method, 'POST');
        expect(adapter.lastRequest?.data, {'booking_id': 42});
        expect(order.orderId, 'order_123');
        expect(order.amount, 25000);
        expect(order.currency, 'INR');
        expect(order.checkoutUrl, 'https://rzp.io/i/abc');
      },
    );

    test('verifyRazorpayPayment POSTs razorpay identifiers', () async {
      final adapter = _CapturingAdapter();
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      await container.read(paymentsApiProvider).verifyRazorpayPayment(
            bookingId: 7,
            razorpayOrderId: 'order_1',
            razorpayPaymentId: 'pay_1',
            razorpaySignature: 'sig',
          );

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentRazorpayVerify);
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'booking_id': 7,
        'razorpay_order_id': 'order_1',
        'razorpay_payment_id': 'pay_1',
        'razorpay_signature': 'sig',
      });
    });

    test('listPaymentMethods returns paged payment methods', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'items': [
            {
              'id': 1,
              'method_type': 'card',
              'brand': 'visa',
              'last4': '4242',
              'is_default': true,
            },
            {
              'id': 2,
              'method_type': 'upi',
              'is_default': false,
            },
          ],
          'next_cursor': 'cursor-token',
          'has_more': true,
          'limit': 20,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final page =
          await container.read(paymentsApiProvider).listPaymentMethods();
      expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentMethods);
      expect(page.items, hasLength(2));
      expect(page.items[0].last4, '4242');
      expect(page.items[0].isDefault, isTrue);
      expect(page.nextCursor, 'cursor-token');
      expect(page.hasMore, isTrue);
    });

    test('addPaymentMethod forwards token + brand + last4', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'id': 9,
          'method_type': 'card',
          'brand': 'mastercard',
          'last4': '1111',
          'is_default': false,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      final method = await container.read(paymentsApiProvider).addPaymentMethod(
            const PaymentMethodCreateDto(
              methodType: 'card',
              brand: 'mastercard',
              last4: '1111',
              razorpayToken: 'tok_xyz',
              isDefault: false,
            ),
          );

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentMethods);
      expect(adapter.lastRequest?.method, 'POST');
      expect(adapter.lastRequest?.data, {
        'method_type': 'card',
        'brand': 'mastercard',
        'last4': '1111',
        'razorpay_token': 'tok_xyz',
        'is_default': false,
      });
      expect(method.id, 9);
    });

    test('updatePaymentMethod PUTs nickname + is_default', () async {
      final adapter = _CapturingAdapter(
        responseBody: jsonEncode({
          'id': 9,
          'method_type': 'card',
          'brand': 'visa',
          'last4': '4242',
          'nickname': 'Personal',
          'is_default': true,
        }),
      );
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      await container.read(paymentsApiProvider).updatePaymentMethod(
            9,
            const PaymentMethodUpdateDto(
              nickname: 'Personal',
              isDefault: true,
            ),
          );

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentMethod(9));
      expect(adapter.lastRequest?.method, 'PUT');
      expect(adapter.lastRequest?.data, {
        'nickname': 'Personal',
        'is_default': true,
      });
    });

    test('deletePaymentMethod DELETEs the method by id', () async {
      final adapter = _CapturingAdapter();
      final container = _containerWith(adapter);
      addTearDown(container.dispose);

      await container.read(paymentsApiProvider).deletePaymentMethod(9);

      expect(adapter.lastRequest?.path, FlatmatesEndpoints.paymentMethod(9));
      expect(adapter.lastRequest?.method, 'DELETE');
    });
  });
}

ProviderContainer _containerWith(HttpClientAdapter adapter) {
  final apiClient = ApiClient(
    baseUrl: 'https://api.test.example.com',
    tokenProvider: FakeAuthTokenProvider(),
  );
  apiClient.dio.httpClientAdapter = adapter;
  return ProviderContainer(
    overrides: [apiClientProvider.overrideWithValue(apiClient)],
  );
}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter({this.responseBody = '{}'});

  final String responseBody;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<List<int>>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return ResponseBody.fromString(
      responseBody,
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}
