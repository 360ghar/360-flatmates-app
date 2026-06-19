import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens a hosted URL (e.g. Razorpay's hosted checkout) in the platform
/// default browser. Returns `true` when the launch succeeded.
///
/// Real Razorpay integration on mobile would use the official `razorpay_flutter`
/// plugin (or the web SDK via `flutter_inappwebview`). For this initial
/// cut we only need to satisfy the API surface; the actual checkout will be
/// wired through the platform-specific channel by a follow-up PR.
class PaymentWebviewLauncher {
  const PaymentWebviewLauncher();

  Future<bool> openCheckout(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const FormatException('Invalid checkout URL');
    }
    if (!await canLaunchUrl(uri)) {
      throw StateError('No handler available for $uri');
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}

final paymentWebviewLauncherProvider = Provider<PaymentWebviewLauncher>(
  (ref) => const PaymentWebviewLauncher(),
);
