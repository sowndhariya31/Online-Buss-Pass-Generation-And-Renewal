import 'package:flutter/services.dart';

void registerWebMapView() {}
void registerQRScannerView() {}
void updateMapRoute(Map<String, dynamic> bus, List<dynamic> allStops) {}
void listenForScans(Function(String) onScan) {}

void openUrlInNewTab(String url) async {
  const platform = MethodChannel('com.example.app/browser');
  try {
    await platform.invokeMethod('openUrl', {'url': url});
  } catch (e) {
    print('MethodChannel launch error: $e');
  }
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
    // Automatically launch browser to handle Razorpay checkout flow
    openUrlInNewTab(fallbackUrl);
    return false;
  }
  return false;
}
