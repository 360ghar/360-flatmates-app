import 'package:flatmates_app/core/network/flatmates_realtime_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isFlatmatesRealtimeNetworkError', () {
    test('detects failed host lookup / SocketException', () {
      expect(
        isFlatmatesRealtimeNetworkError(
          'WebSocketChannelException: SocketException: Failed host lookup: '
          "'zthcndwkvhstjgusovqw.supabase.co' "
          '(OS Error: nodename nor servname provided, or not known, errno = 8)',
        ),
        isTrue,
      );
    });

    test('returns false for null and non-network messages', () {
      expect(isFlatmatesRealtimeNetworkError(null), isFalse);
      expect(isFlatmatesRealtimeNetworkError('JWT expired'), isFalse);
      expect(isFlatmatesRealtimeNetworkError('Unauthorized'), isFalse);
    });
  });

  group('realtime reconnect delay helpers', () {
    test('network errors floor wait at min delay', () {
      expect(
        realtimeReconnectWaitSeconds(
          currentDelaySeconds: 1,
          isNetworkError: true,
        ),
        kRealtimeNetworkErrorMinDelaySeconds,
      );
      expect(
        realtimeReconnectWaitSeconds(
          currentDelaySeconds: 10,
          isNetworkError: true,
        ),
        10,
      );
    });

    test('doubles delay and caps at max', () {
      expect(
        nextRealtimeReconnectDelaySeconds(
          currentDelaySeconds: 5,
          isNetworkError: true,
        ),
        10,
      );
      expect(
        nextRealtimeReconnectDelaySeconds(
          currentDelaySeconds: 40,
          isNetworkError: true,
        ),
        kRealtimeMaxReconnectDelaySeconds,
      );
      expect(
        nextRealtimeReconnectDelaySeconds(
          currentDelaySeconds: 1,
          isNetworkError: false,
        ),
        2,
      );
    });
  });

  group('FlatmatesRealtimeService network pause', () {
    test('setNetworkAvailable(false) keeps channel config without opening', () {
      final service = FlatmatesRealtimeService();
      addTearDown(service.dispose);

      service.setNetworkAvailable(false);
      service.connect(
        channelName: 'flatmates:user:1',
        tokenRefresher: () async => 'token',
      );

      expect(service.channelName, 'flatmates:user:1');
      expect(service.isNetworkAvailable, isFalse);
      expect(service.isConnecting, isFalse);
      expect(service.hasPendingReconnect, isFalse);
    });

    test('offline cancels pending reconnect timer state', () {
      final service = FlatmatesRealtimeService();
      addTearDown(service.dispose);

      // Offline before connect — no timer should be armed.
      service.setNetworkAvailable(false);
      service.connect(
        channelName: 'flatmates:user:99',
        tokenRefresher: () async => null,
      );
      expect(service.hasPendingReconnect, isFalse);

      service.setNetworkAvailable(true);
      // Still offline path already false; going online with null token would
      // schedule reconnect if Supabase were not required — without Supabase
      // init, open path may throw. Pause again to ensure no crash.
      service.setNetworkAvailable(false);
      expect(service.isNetworkAvailable, isFalse);
      expect(service.hasPendingReconnect, isFalse);
    });

    test('connect is idempotent for same channel while offline', () {
      final service = FlatmatesRealtimeService();
      addTearDown(service.dispose);

      service.setNetworkAvailable(false);
      service.connect(
        channelName: 'flatmates:user:1',
        tokenRefresher: () async => 'a',
      );
      service.connect(
        channelName: 'flatmates:user:1',
        tokenRefresher: () async => 'b',
      );

      expect(service.channelName, 'flatmates:user:1');
      expect(service.isConnecting, isFalse);
    });
  });
}
