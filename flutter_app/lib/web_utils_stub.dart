import 'dart:io';

void registerWebMapView() {}
void registerQRScannerView() {}
void updateMapRoute(Map<String, dynamic> bus, List<dynamic> allStops) {}
void listenForScans(Function(String) onScan) {}

void openUrlInNewTab(String url) {
  Process.run('start', [url], runInShell: true);
}

bool startRazorpayPayment({
  required String key,
  required String amount,
  required String orderId,
  required String name,
  required String email,
  required String contact,
  String? fallbackUrl,
  required Function(String paymentId, String signature) onSuccess,
  required Function(String error) onFailure,
}) {
  if (fallbackUrl != null) {
    // Launch in the browser specifically for native desktop
    openUrlInNewTab(fallbackUrl);
    return false;
  }
  return false;
}
