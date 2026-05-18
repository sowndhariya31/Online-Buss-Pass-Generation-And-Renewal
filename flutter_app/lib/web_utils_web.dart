import 'dart:html' as html;
import 'dart:ui_web' as ui;
import 'dart:js' as js;

void registerWebMapView() {
  ui.platformViewRegistry.registerViewFactory(
    'leaflet-map',
    (int viewId) => html.IFrameElement()
      ..id = 'map-iframe'
      ..srcdoc = """
        <!DOCTYPE html>
        <html>
        <head>
          <link rel="stylesheet" href="https://unpkg.com/leaflet@1.9.4/dist/leaflet.css"/>
          <script src="https://unpkg.com/leaflet@1.9.4/dist/leaflet.js"></script>
          <style>
            body { margin: 0; padding: 0; background: #0F172A; }
            #map { width: 100vw; height: 100vh; }
            .map-tiles { filter: invert(100%) hue-rotate(180deg) brightness(95%) contrast(90%); }
          </style>
        </head>
        <body>
          <div id="map"></div>
          <script>
            var map = L.map('map').setView([13.0827, 80.2707], 12);
            L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
              className: 'map-tiles'
            }).addTo(map);
            
            var coords = {
              "KOYAMBEDU": [13.07, 80.20], "THIRUVANMIYUR": [12.98, 80.24], "TAMBARAM": [12.92, 80.12],
              "ADYAR": [13.00, 80.25], "GUINDY": [13.00, 80.22], "ISLAND GROUND": [13.07, 80.28],
              "PERAMBUR": [13.10, 80.24], "VILLIVAKKAM": [13.11, 80.20], "KILAMBAKKAM": [12.83, 80.07],
              "BESANT NAGAR": [13.00, 80.26], "MAMALLAPURAM": [12.62, 80.19], "TOLLGATE": [13.12, 80.29],
              "THIRU.VI.KA.NAGAR": [13.11, 80.23], "M.G.R.CENTRAL": [13.08, 80.27], "GUDUVANCHERY": [12.84, 80.06],
              "KOVALAM": [12.79, 80.24], "THIRUPORUR": [12.72, 80.19], "KANNAGI NAGAR": [12.92, 80.23],
              "PERUMBAKKAM": [12.90, 80.19], "ADYAR B.S.": [13.00, 80.25], "ADYAR DEPOT": [12.99, 80.25],
              "TAMBARAM WEST": [12.92, 80.11], "VANDALUR ZOO": [12.88, 80.08], "SHOLINGANALLUR": [12.90, 80.22]
            };

            window.addEventListener('message', function(e) {
              if (e.data.type === 'UPDATE_ROUTE') {
                map.eachLayer(function(layer) {
                  if (layer instanceof L.Marker || layer instanceof L.Polyline) {
                    map.removeLayer(layer);
                  }
                });

                var points = [];
                var busNo = e.data.busNo;
                var stops = e.data.stops;

                for(var i=0; i<stops.length; i++) {
                  var name = stops[i].toUpperCase();
                  var pos = coords[name];
                  
                  // Fallback if stop not in list
                  if (!pos) {
                    var startPos = coords[stops[0]] || [13.08, 80.27];
                    var endPos = coords[stops[stops.length-1]] || [13.04, 80.24];
                    var ratio = i / (stops.length - 1);
                    pos = [
                      startPos[0] + (endPos[0] - startPos[0]) * ratio + (Math.random() * 0.01),
                      startPos[1] + (endPos[1] - startPos[1]) * ratio + (Math.random() * 0.01)
                    ];
                  }
                  
                  points.push(pos);
                  var marker = L.marker(pos).addTo(map);
                  marker.bindPopup("<b>" + stops[i] + "</b><br>Bus " + busNo);
                  if (i === 0) marker.bindTooltip("START", {permanent: true, direction: 'top'});
                  if (i === stops.length - 1) marker.bindTooltip("END", {permanent: true, direction: 'top'});
                }

                var polyline = L.polyline(points, {color: '#6366F1', weight: 4, opacity: 0.8}).addTo(map);
                map.fitBounds(polyline.getBounds(), {padding: [50, 50]});
              }
            });
          </script>
        </body>
        </html>
      """
      ..style.border = 'none',
  );
}

void registerQRScannerView() {
  ui.platformViewRegistry.registerViewFactory(
    'qr-scanner-view',
    (int viewId) => html.IFrameElement()
      ..id = 'qr-scanner-iframe'
      ..srcdoc = '''
<!DOCTYPE html>
<html>
<head>
  <script src="https://unpkg.com/html5-qrcode@2.3.8/html5-qrcode.min.js"></script>
  <style>
    body { margin: 0; padding: 0; background: #0F172A; overflow: hidden; display: flex; align-items: center; justify-content: center; height: 100vh; }
    #reader { width: 100%; height: 100%; }
    #reader video { border-radius: 16px; object-fit: cover; }
    /* hide the built-in UI */
    #reader__dashboard { display: none !important; }
    #reader__scan_region { border-radius: 16px; overflow: hidden; }
    .scanning-overlay {
      position: absolute; top: 50%; left: 50%; transform: translate(-50%, -50%);
      width: 220px; height: 220px;
      border: 3px solid rgba(99, 102, 241, 0.6);
      border-radius: 20px;
      box-shadow: 0 0 0 9999px rgba(0,0,0,0.4);
      z-index: 10;
    }
    .scan-line {
      position: absolute; top: 0; left: 5%; width: 90%; height: 3px;
      background: linear-gradient(90deg, transparent, #6366F1, transparent);
      animation: scanMove 2s ease-in-out infinite;
      border-radius: 2px;
    }
    @keyframes scanMove { 0%,100% { top: 10%; } 50% { top: 90%; } }
    .status-text {
      position: absolute; bottom: 30px; left: 50%; transform: translateX(-50%);
      color: #A78BFA; font-family: sans-serif; font-size: 14px; z-index: 20;
    }
    .no-camera {
      color: #fff; font-family: sans-serif; text-align: center; padding: 40px;
    }
    .no-camera h3 { color: #A78BFA; }
  </style>
</head>
<body>
  <div id="reader"></div>
  <div class="scanning-overlay"><div class="scan-line"></div></div>
  <div class="status-text">Scanning for QR Code...</div>

  <script>
    var scanner = new Html5Qrcode("reader");
    scanner.start(
      { facingMode: "environment" },
      { fps: 10, qrbox: { width: 250, height: 250 }, aspectRatio: 1.0 },
      function(decodedText) {
        window.parent.postMessage({ type: 'QR_SCAN_RESULT', code: decodedText }, '*');
        // Pause briefly to avoid duplicate scans
        scanner.pause(true);
        setTimeout(function() {
          try { scanner.resume(); } catch(e) {}
        }, 3000);
      },
      function(errorMessage) { /* ignore scan errors */ }
    ).catch(function(err) {
      document.body.innerHTML = '<div class="no-camera"><h3>📷 Camera Not Available</h3><p>Use the manual input field below to enter Pass ID</p></div>';
      window.parent.postMessage({ type: 'QR_SCANNER_NO_CAMERA' }, '*');
    });
  </script>
</body>
</html>
'''
      ..style.border = 'none'
      ..style.width = '100%'
      ..style.height = '100%'
      ..allow = 'camera',
  );
}

void updateMapRoute(Map<String, dynamic> bus, List<dynamic> allStops) {
  final iframe = html.document.getElementById('map-iframe') as html.IFrameElement?;
  iframe?.contentWindow?.postMessage({
    'type': 'UPDATE_ROUTE',
    'busNo': bus['no'],
    'stops': allStops,
  }, '*');
}

void listenForScans(Function(String) onScan) {
  html.window.addEventListener('message', (event) {
    final e = event as html.MessageEvent;
    if (e.data is Map) {
      final data = Map<String, dynamic>.from(e.data);
      if (data['type'] == 'QR_SCAN_RESULT') {
        final code = data['code'] as String;
        onScan(code);
      }
    }
  });
}

void openUrlInNewTab(String url) {
  html.window.open(url, '_blank');
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
  // 1. Check if checkout.js is already loaded
  if (html.document.getElementById('razorpay-sdk') == null) {
    final script = html.ScriptElement()
      ..id = 'razorpay-sdk'
      ..src = 'https://checkout.razorpay.com/v1/checkout.js'
      ..async = true;
    
    script.onLoad.listen((event) {
      _openRazorpay(key, amount, orderId, name, email, contact, onSuccess, onFailure);
    });
    
    html.document.head?.append(script);
  } else {
    _openRazorpay(key, amount, orderId, name, email, contact, onSuccess, onFailure);
  }
  return true;
}

void _openRazorpay(
  String key,
  String amount,
  String orderId,
  String name,
  String email,
  String contact,
  Function(String paymentId, String signature) onSuccess,
  Function(String error) onFailure,
) {
  final options = js.JsObject.jsify({
    'key': key,
    'amount': amount,
    'currency': 'INR',
    'name': 'CITY PASS',
    'description': 'Bus Pass Transaction',
    'order_id': orderId,
    'prefill': {
      'name': name,
      'email': email,
      'contact': contact,
    },
    'theme': {
      'color': '#6366f1',
    },
    'handler': js.allowInterop((response) {
      final paymentId = response['razorpay_payment_id'] ?? '';
      final signature = response['razorpay_signature'] ?? '';
      onSuccess(paymentId, signature);
    }),
    'modal': {
      'ondismiss': js.allowInterop(() {
        onFailure('Payment cancelled by user');
      }),
    },
  });

  final rzp = js.JsObject(js.context['Razorpay'], [options]);
  rzp.callMethod('open');
}
