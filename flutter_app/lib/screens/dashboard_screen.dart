import 'dart:convert';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils_web.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/bus_pass.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'id_card_screen.dart';
import 'route_finder_screen.dart';
import 'apply_pass_screen.dart';
import 'profile_screen.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'package:gal/gal.dart';

import 'admin_dashboard_screen.dart';
import 'conductor_dashboard_screen.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _currentIndex = 0;
  
  List<Widget> _getScreens(User? user) {
    if (user?.role == 'ADMIN') {
      return [AdminDashboardScreen()];
    } else if (user?.role == 'CONDUCTOR') {
      return [ScannerScreen()];
    }
    return [_HomeContent()];
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final screens = _getScreens(user);

    return Scaffold(
      body: screens[_currentIndex],
    );
  }
}

class _HomeContent extends StatefulWidget {
  @override
  __HomeContentState createState() => __HomeContentState();
}

class __HomeContentState extends State<_HomeContent> {
  List<BusPass> _passes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchPasses();
  }

  Future<void> _fetchPasses() async {
    try {
      final response = await ApiService.get('/passes/list/');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _passes = data.map((json) => BusPass.fromJson(json)).toList();
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      print('Fetch passes error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF1E293B).withOpacity(0.95),
          elevation: 0,
          leadingWidth: 70,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/b_logo.png', height: 40),
          ),
          title: Text(
            'CITY PASS',
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(Icons.home, color: Colors.white, size: 24),
              tooltip: 'Home',
              onPressed: () {
                _fetchPasses();
              },
            ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.redAccent, size: 24),
              tooltip: 'Logout',
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
            SizedBox(width: 8),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.8), BlendMode.darken),
              ),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: Color(0xFF6366F1),
              onRefresh: _fetchPasses,
              child: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 100),
                      Container(height: 1, color: Colors.white10),
                      SizedBox(height: 24),
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        alignment: WrapAlignment.start,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          Text(
                            'My Bus Passes',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              _buildHeaderButton(
                                'Route Finder',
                                () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RouteFinderScreen()),
                                ),
                              ),
                              _buildHeaderButton(
                                'Renewal',
                                () {
                                  try {
                                    final activePass = _passes.firstWhere(
                                      (p) => p.status == 'ACTIVE',
                                    );
                                    _showRenewalMonthSelector(context, activePass);
                                  } catch (_) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('No active bus pass found to renew!')),
                                    );
                                  }
                                },
                              ),
                              ElevatedButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => ApplyPassScreen()),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF6366F1),
                                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: Text('+ Apply Fresh Pass', style: TextStyle(fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: 32),
                      Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          physics: BouncingScrollPhysics(),
                          child: SizedBox(
                            width: 950,
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    _headerCell('PASS ID', 1),
                                    _headerCell('TYPE', 1),
                                    _headerCell('ISSUE DATE', 1.5),
                                    _headerCell('EXPIRY DATE', 1.5),
                                    _headerCell('STATUS', 1),
                                    _headerCell('VALID UNTIL', 1.5),
                                    _headerCell('DAILY USAGE', 1),
                                    _headerCell('ACTION', 2),
                                  ],
                                ),
                                Divider(color: Colors.white10, height: 40),
                                if (_passes.isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40.0),
                                    child: Text('No active passes found', style: TextStyle(color: Colors.white38)),
                                  )
                                else
                                  ..._passes.map((p) => _buildPassRow(p, user)).toList(),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      _buildRecentRenewalsSection(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderButton(String label, VoidCallback onTap) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: Colors.white24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _headerCell(String label, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5)),
    );
  }

  Widget _buildPassRow(BusPass p, User? user) {
    final statusColor = p.status == 'ACTIVE' 
        ? (p.isCurrentlyValid ? Color(0xFF10B981) : Color(0xFFF59E0B))
        : (p.status == 'PENDING' ? Color(0xFF3B82F6) : Color(0xFFEF4444));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          _dataCell(p.passId.isEmpty ? '(Pending)' : p.passId, 1),
          _dataCell(p.passType, 1),
          _dataCell(p.issueDate.toString().substring(0, 10), 1.5),
          _dataCell(p.expiryDate.toString().substring(0, 10), 1.5),
          Expanded(
            flex: 10,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                p.status == 'ACTIVE' 
                    ? (p.isCurrentlyValid ? 'ACTIVE' : 'RENEWAL REQ') 
                    : p.status,
                style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          _dataCell(
            p.currentValidTo != null 
                ? p.currentValidTo.toString().substring(0, 10) 
                : 'No Renewal', 
            1.5,
            textColor: p.currentValidTo != null 
                ? (p.isCurrentlyValid ? Color(0xFF10B981) : Color(0xFFEF4444)) 
                : Colors.white70,
            fontWeight: p.currentValidTo != null ? FontWeight.bold : FontWeight.normal,
          ),
          _dataCell(p.status == 'ACTIVE' ? '${p.dailyTripCount} / 2' : '-', 1),
          Expanded(
            flex: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (p.status == 'ACTIVE') ...[
                  if (p.paymentStatus != 'PAID') ...[
                    ElevatedButton(
                      onPressed: () => _showPaymentDialog(context, p),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      child: Text('Pay Initial Fee', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ] else ...[
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        OutlinedButton(
                          onPressed: () => _showQRCodeDialog(context, p),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Color(0xFF10B981), width: 1.5),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Scan QR / Download',
                            style: GoogleFonts.outfit(
                              color: Color(0xFF10B981),
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => _showRenewalMonthSelector(context, p),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6366F1),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'Renew / Extend',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => IDCardScreen(pass: p, user: user)),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF0EA5E9),
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                          child: Text(
                            'ID Card',
                            style: GoogleFonts.outfit(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ] else if (p.status == 'PENDING') ...[
                  Text(
                    'Awaiting Admin Approval',
                    style: TextStyle(
                      color: Color(0xFF818CF8),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ] else if (p.status == 'BLOCKED') ...[
                  Text(
                    'Application Rejected',
                    style: TextStyle(
                      color: Color(0xFFEF4444),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _dataCell(String value, double flex, {Color textColor = Colors.white70, FontWeight fontWeight = FontWeight.normal}) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(value, style: TextStyle(color: textColor, fontSize: 14, fontWeight: fontWeight)),
    );
  }

  Widget _buildRecentRenewalsSection() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent Renewals & Usage', style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('View your monthly renewals and usage history here.', style: TextStyle(color: Colors.white54)),
        ],
      ),
    );
  }

  Widget _buildDataColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.outfit(color: Colors.white38, fontSize: 10, fontWeight: FontWeight.bold)),
        SizedBox(height: 4),
        Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
      ],
    );
  }

  void _showRenewalMonthSelector(BuildContext context, BusPass p) {
    final months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    final currentMonthIdx = DateTime.now().month - 1;
    final availableMonths = List.generate(3, (i) => months[(currentMonthIdx + i) % 12]);
    String selectedMonth = availableMonths[0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          backgroundColor: Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text(
            'Renew Bus Pass',
            style: GoogleFonts.outfit(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Permanent Pass ID:', style: TextStyle(color: Colors.white38, fontSize: 11)),
              Text(p.passId.isEmpty ? '(Pending)' : p.passId, style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
              SizedBox(height: 16),
              Text('Select Renewal Month:', style: TextStyle(color: Colors.white54, fontSize: 13, fontWeight: FontWeight.w600)),
              SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: availableMonths.map((m) {
                  final isSelected = selectedMonth == m;
                  return Expanded(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          selectedMonth = m;
                        });
                      },
                      child: Container(
                        margin: EdgeInsets.symmetric(horizontal: 4),
                        padding: EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? Color(0xFF818CF8) : Colors.white10,
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            m,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.white70,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _showPaymentDialog(context, p, isMonthly: true, renewalMonth: selectedMonth);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6366F1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text('Proceed to Payment', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blueAccent.withOpacity(0.08) : Colors.white.withOpacity(0.02),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? Colors.blueAccent.withOpacity(0.3) : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? Colors.blueAccent : Colors.white60, size: 24),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                  SizedBox(height: 2),
                  Text(subtitle, style: TextStyle(color: Colors.white54, fontSize: 11)),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.radio_button_checked, color: Colors.blueAccent, size: 20)
            else
              Icon(Icons.radio_button_off, color: Colors.white24, size: 20),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(BuildContext context, BusPass p, {bool isMonthly = false, String? renewalMonth}) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool processing = false;
        String selectedMethod = 'upi';
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: Color(0xFF0F172A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
              contentPadding: EdgeInsets.zero,
              content: ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: Container(
                  width: 380,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                        color: Color(0xFF0B2545),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.security, color: Colors.blueAccent, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  'Razorpay Secure Checkout',
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'razorpay',
                              style: GoogleFonts.outfit(
                                color: Colors.blueAccent,
                                fontWeight: FontWeight.w900,
                                fontStyle: FontStyle.italic,
                                fontSize: 18,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (processing) ...[
                        Container(
                          padding: EdgeInsets.all(40),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              CircularProgressIndicator(color: Colors.blueAccent),
                              SizedBox(height: 24),
                              Text(
                                'Processing payment securely...',
                                style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Please do not close this window.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Padding(
                          padding: EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('MERCHANT', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                                      Text('CITY PASS TRANSIT', style: GoogleFonts.outfit(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                                    ],
                                  ),
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text('AMOUNT DUE', style: TextStyle(color: Colors.white38, fontSize: 10, letterSpacing: 1.2)),
                                          Text(p.passType == 'PUBLIC' ? '₹10000.00' : '₹280.00', style: GoogleFonts.outfit(color: Colors.greenAccent, fontSize: 22, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                ],
                              ),
                              Divider(color: Colors.white12, height: 32),
                              Text('SELECT PAYMENT METHOD', style: TextStyle(color: Colors.blueAccent, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 1)),
                              SizedBox(height: 16),
                              _buildPaymentMethodTile(
                                icon: Icons.qr_code,
                                title: 'Google Pay / PhonePe / UPI',
                                subtitle: 'Instant Transfer via secure UPI address',
                                isSelected: selectedMethod == 'upi',
                                onTap: () => setState(() => selectedMethod = 'upi'),
                              ),
                              SizedBox(height: 12),
                              _buildPaymentMethodTile(
                                icon: Icons.credit_card,
                                title: 'Card (Visa, MasterCard, RuPay)',
                                subtitle: 'Debit or Credit card transactions',
                                isSelected: selectedMethod == 'card',
                                onTap: () => setState(() => selectedMethod = 'card'),
                              ),
                              SizedBox(height: 12),
                              _buildPaymentMethodTile(
                                icon: Icons.account_balance,
                                title: 'Netbanking',
                                subtitle: 'All major Indian banks available',
                                isSelected: selectedMethod == 'netbanking',
                                onTap: () => setState(() => selectedMethod = 'netbanking'),
                              ),
                              SizedBox(height: 24),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    isMonthly ? 'Monthly Renewal ($renewalMonth)' : 'Initial Pass Issuance',
                                    style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    p.passId.isEmpty ? 'TEMP-ID' : p.passId,
                                    style: TextStyle(color: Colors.white54, fontSize: 12, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: () async {
                                    setState(() => processing = true);
                                    
                                    try {
                                      // 1. Hit the Django API to initiate the Razorpay order
                                      final response = await ApiService.post(
                                        '/passes/${p.id}/initiate_razorpay/',
                                        {
                                          'is_monthly': isMonthly,
                                          'month': renewalMonth,
                                        },
                                      );
                                      
                                      if (response.statusCode == 200) {
                                        final Map<String, dynamic> data = json.decode(response.body);
                                        
                                        // 2. Open the official Razorpay payment modal directly on Flutter
                                        final isPopup = startRazorpayPayment(
                                           key: data['key'],
                                           amount: data['amount'],
                                           orderId: data['order_id'],
                                           name: data['name'],
                                           email: data['email'],
                                           contact: data['contact'],
                                           fallbackUrl: data['payment_url'],
                                           onSuccess: (paymentId, signature) async {
                                             // Close the overlay dialog first
                                             Navigator.pop(context);
                                             
                                             // Show payment verified/confirming loading state
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(content: Text('Verifying payment details... Please wait.')),
                                             );
                                             
                                             try {
                                               // 3. Confirm/Verify signature on Django backend!
                                               final verifyRes = await ApiService.post('/passes/confirm_razorpay/', {
                                                 'razorpay_payment_id': paymentId,
                                                 'razorpay_order_id': data['order_id'],
                                                 'razorpay_signature': signature,
                                               });
                                               
                                               if (verifyRes.statusCode == 200) {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(
                                                     content: Text('🎉 Payment Successful and Verified! Your pass is active!'),
                                                     backgroundColor: Colors.green,
                                                   ),
                                                 );
                                                 _fetchPasses();
                                               } else {
                                                 ScaffoldMessenger.of(context).showSnackBar(
                                                   SnackBar(
                                                     content: Text('❌ Verification failed on the server. Contact Support.'),
                                                     backgroundColor: Colors.redAccent,
                                                   ),
                                                 );
                                               }
                                             } catch (e) {
                                               ScaffoldMessenger.of(context).showSnackBar(
                                                 SnackBar(content: Text('Error verifying payment: $e')),
                                               );
                                             }
                                           },
                                           onFailure: (error) {
                                             setState(() => processing = false);
                                             ScaffoldMessenger.of(context).showSnackBar(
                                               SnackBar(
                                                 content: Text('❌ $error'),
                                                 backgroundColor: Colors.redAccent,
                                               ),
                                             );
                                           },
                                         );

                                         if (!isPopup) {
                                           // We are on Desktop! The browser has been launched!
                                           // Immediately close the "Processing payment securely..." modal on Flutter app
                                           Navigator.pop(context);
                                           // Show a friendly popup instruction card instead!
                                           _showDesktopPaymentInstruction(context);
                                         }
                                      } else {
                                        setState(() => processing = false);
                                        String errMsg = 'Failed to initialize transaction.';
                                        try {
                                          final errData = json.decode(response.body);
                                          if (errData['error'] != null) {
                                            errMsg = errData['error'];
                                          }
                                        } catch (_) {}
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text('❌ $errMsg'),
                                            backgroundColor: Colors.redAccent,
                                            duration: Duration(seconds: 6),
                                          ),
                                        );
                                      }
                                    } catch (e) {
                                      setState(() => processing = false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Connection Error: $e')),
                                      );
                                    }
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0xFF3399FF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                    elevation: 6,
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.lock, size: 16),
                                      SizedBox(width: 8),
                                      Text(
                                        'PAY ₹280 VIA RAZORPAY',
                                        style: GoogleFonts.outfit(fontSize: 15, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: Text('Cancel Payment', style: TextStyle(color: Colors.white54, fontSize: 13)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showDesktopPaymentInstruction(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0F172A),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: BorderSide(color: Colors.white10)),
          content: Container(
            width: 360,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 12),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: Colors.blueAccent.withOpacity(0.08),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.blueAccent.withOpacity(0.3), width: 2),
                  ),
                  child: Icon(Icons.open_in_new, color: Colors.blueAccent, size: 36),
                ),
                SizedBox(height: 24),
                Text(
                  'Browser Payment Launched',
                  style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 12),
                Text(
                  'We have opened a secure Razorpay checkout page in your default web browser.\n\n1. Complete the payment in the browser tab.\n2. Once done, return here and tap the Home icon at the top (or pull down the screen to refresh) to view your active pass!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      _fetchPasses();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueAccent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Done & Refresh', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                ),
                SizedBox(height: 8),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showQRCodeDialog(BuildContext context, BusPass p) {
    final screenshotController = ScreenshotController();
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
          contentPadding: EdgeInsets.all(28),
          content: Screenshot(
            controller: screenshotController,
            child: Container(
              width: 320,
              color: Color(0xFF0F172A), // Background color for the screenshot
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Digital QR Pass',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.close, color: Colors.white54),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.3),
                        blurRadius: 20,
                        offset: Offset(0, 8),
                      ),
                    ],
                  ),
                  child: QrImageView(
                    data: p.passId.isEmpty ? 'TEMP-${p.id}' : p.passId,
                    version: QrVersions.auto,
                    size: 200.0,
                    gapless: false,
                  ),
                ),
                SizedBox(height: 24),
                Text(
                  p.passId.isEmpty ? 'TEMPORARY PASS ID' : p.passId,
                  style: GoogleFonts.outfit(
                    color: Color(0xFF10B981),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Valid Until: ${p.currentValidTo != null ? p.currentValidTo.toString().substring(0, 10) : 'Not Active'}',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      try {
                        final image = await screenshotController.capture();
                        if (image != null) {
                          await Gal.putImageBytes(image);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('🎉 Digital pass saved to local gallery successfully!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                            Navigator.pop(context);
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Failed to save image: $e'), backgroundColor: Colors.red),
                          );
                        }
                      }
                    },
                    icon: Icon(Icons.download, color: Colors.white),
                    label: Text(
                      'Download Pass',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }
}
