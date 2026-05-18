import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'scanner_screen.dart';
import 'profile_screen.dart';

class ConductorDashboardScreen extends StatefulWidget {
  @override
  _ConductorDashboardScreenState createState() => _ConductorDashboardScreenState();
}

class _ConductorDashboardScreenState extends State<ConductorDashboardScreen> {
  @override
  void initState() {
    super.initState();
    // Auto-open scanner after a short delay to allow UI to settle
    Future.delayed(Duration(milliseconds: 500), () {
      if (mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (context) => ScannerScreen()));
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(100),
        child: AppBar(
          backgroundColor: Color(0xFF1E293B).withOpacity(0.9),
          elevation: 0,
          leadingWidth: 120,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset('assets/b_logo.png', height: 80, fit: BoxFit.contain),
          ),
          title: Text('Conductor Panel', style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 26)),
          centerTitle: true,
          actions: [
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () {
                Provider.of<AuthProvider>(context, listen: false).logout();
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => LoginScreen()),
                  (route) => false,
                );
              },
            ),
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
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.directions_bus, color: Color(0xFF6366F1), size: 80),
                  SizedBox(height: 24),
                  Text(
                    'Ready to Verify Passes?',
                    style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Use the scanner to validate student and public bus passes in real-time.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16),
                  ),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 100,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ScannerScreen())),
                      icon: Icon(Icons.qr_code_scanner, size: 32),
                      label: Text('Open QR Scanner', style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6366F1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
