import 'dart:convert';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  bool _isProcessing = false;
  final TextEditingController _passIdController = TextEditingController();
  Map<String, dynamic>? _lastResult;
  bool? _lastSuccess;
  bool _scannerReady = false;

  @override
  void initState() {
    super.initState();
    _registerQRScanner();
    _listenForScans();
  }

  void _registerQRScanner() {
    registerQRScannerView();
    setState(() => _scannerReady = true);
  }

  void _listenForScans() {
    listenForScans((String code) {
      _verifyPass(code);
    });
  }

  Future<void> _verifyPass(String passId) async {
    if (passId.trim().isEmpty || _isProcessing) return;
    setState(() {
      _isProcessing = true;
      _lastResult = null;
      _lastSuccess = null;
    });
    try {
      final response = await ApiService.get('/passes/verify/$passId/');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _lastSuccess = true;
          _lastResult = data;
        });
        _showResultDialog(
          true,
          'Pass Valid ✓',
          'ID: $passId\nUser: ${data['user_email']}\nStatus: ${data['status']}',
        );
      } else {
        setState(() => _lastSuccess = false);
        _showResultDialog(false, 'Invalid Pass', 'Pass ID "$passId" was not found or is expired.');
      }
    } catch (e) {
      setState(() => _lastSuccess = false);
      _showResultDialog(false, 'Connection Error', 'Could not verify pass. Please check connection.');
    }
    setState(() => _isProcessing = false);
  }

  void _showResultDialog(bool success, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF1E293B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(success ? Icons.check_circle : Icons.error, color: success ? Colors.greenAccent : Colors.redAccent, size: 28),
            SizedBox(width: 12),
            Expanded(child: Text(title, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
        content: Text(message, style: GoogleFonts.outfit(color: Colors.white70, height: 1.6)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Conductor Scanner Terminal', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: Color(0xFF1E293B).withOpacity(0.95),
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              Provider.of<AuthProvider>(context, listen: false).logout();
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => LoginScreen()),
                (route) => false,
              );
            },
            icon: Icon(Icons.logout, color: Colors.white70, size: 18),
            label: Text('Logout', style: TextStyle(color: Colors.white70)),
          ),
          SizedBox(width: 12),
        ],
      ),
      body: Stack(
        children: [
          // Background
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.88), BlendMode.darken),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 750;
                
                final scannerWidget = Container(
                  height: isMobile ? 280 : double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Color(0xFF6366F1).withOpacity(0.3), width: 2),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: _scannerReady
                      ? (kIsWeb 
                          ? const HtmlElementView(viewType: 'qr-scanner-view')
                          : (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)
                              ? MobileScanner(
                                  onDetect: (capture) {
                                    final List<Barcode> barcodes = capture.barcodes;
                                    for (final barcode in barcodes) {
                                      final String? code = barcode.rawValue;
                                      if (code != null && !_isProcessing) {
                                        _verifyPass(code);
                                      }
                                    }
                                  },
                                )
                              : Center(
                                  child: Text(
                                    'QR Scanner is available on Web, Android, & iOS.\nPlease use manual entry on Desktop.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.white54, fontSize: 16),
                                  ),
                                ))
                      : Center(child: CircularProgressIndicator(color: Color(0xFF6366F1))),
                );

                final manualEntryWidget = Column(
                  children: [
                    // Manual Input Card
                    Container(
                      padding: EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.keyboard, color: Color(0xFF6366F1), size: 24),
                              SizedBox(width: 12),
                              Text('Manual Entry', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                            ],
                          ),
                          SizedBox(height: 8),
                          Text('Type a Pass ID to verify manually', style: TextStyle(color: Colors.white54, fontSize: 13)),
                          SizedBox(height: 20),
                          TextField(
                            controller: _passIdController,
                            onSubmitted: (value) => _verifyPass(value.trim().toUpperCase()),
                            decoration: InputDecoration(
                              hintText: 'e.g. MTC2026-000001',
                              hintStyle: TextStyle(color: Colors.white24, fontSize: 14),
                              filled: true,
                              fillColor: Colors.white.withOpacity(0.05),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white10),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Colors.white10),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: Color(0xFF6366F1)),
                              ),
                              prefixIcon: Icon(Icons.credit_card, color: Colors.white38),
                            ),
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                          SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton.icon(
                              onPressed: _isProcessing
                                  ? null
                                  : () => _verifyPass(_passIdController.text.trim().toUpperCase()),
                              icon: _isProcessing
                                  ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                  : Icon(Icons.verified_user, color: Colors.white, size: 20),
                              label: Text(
                                _isProcessing ? 'Verifying...' : 'Verify Pass',
                                style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                elevation: 0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 24),
                    // Last Result Card
                    if (_lastSuccess != null)
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: (_lastSuccess! ? Colors.green : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: (_lastSuccess! ? Colors.green : Colors.red).withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: (_lastSuccess! ? Colors.green : Colors.red).withOpacity(0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _lastSuccess! ? Icons.check_circle : Icons.cancel,
                                color: _lastSuccess! ? Colors.greenAccent : Colors.redAccent,
                                size: 32,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _lastSuccess! ? 'PASS VALID' : 'PASS INVALID',
                                    style: GoogleFonts.outfit(
                                      color: _lastSuccess! ? Colors.greenAccent : Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                  if (_lastResult != null) ...[
                                    SizedBox(height: 4),
                                    Text(
                                      '${_lastResult!['user_email']}',
                                      style: TextStyle(color: Colors.white70, fontSize: 13),
                                    ),
                                    Text(
                                      'Status: ${_lastResult!['status']}',
                                      style: TextStyle(color: Colors.white54, fontSize: 12),
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    SizedBox(height: 24),
                    // Info Card
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.03),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white.withOpacity(0.05)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('How to Scan', style: GoogleFonts.outfit(color: Colors.white70, fontWeight: FontWeight.bold, fontSize: 14)),
                          SizedBox(height: 8),
                          _infoRow(Icons.qr_code_scanner, 'Hold the QR code in front of the camera'),
                          _infoRow(Icons.keyboard, 'Or type the Pass ID manually'),
                          _infoRow(Icons.check, 'Valid passes will show green confirmation'),
                        ],
                      ),
                    ),
                  ],
                );

                if (isMobile) {
                  return SingleChildScrollView(
                    physics: BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Column(
                        children: [
                          scannerWidget,
                          SizedBox(height: 24),
                          manualEntryWidget,
                        ],
                      ),
                    ),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(flex: 5, child: scannerWidget),
                        SizedBox(width: 32),
                        Expanded(flex: 4, child: SingleChildScrollView(child: manualEntryWidget)),
                      ],
                    ),
                  );
                }
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.white38, size: 16),
          SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: Colors.white38, fontSize: 12))),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _passIdController.dispose();
    super.dispose();
  }
}
