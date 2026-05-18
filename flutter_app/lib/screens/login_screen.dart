import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _isConductor = false;

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter all fields')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = await Provider.of<AuthProvider>(context, listen: false)
        .login(_emailController.text, _passwordController.text, isConductor: _isConductor);
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => DashboardScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login Failed. Please check your credentials.')),
      );
    }
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
          titleSpacing: 0,
          centerTitle: false,
          leadingWidth: 120,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset('assets/b_logo.png', height: 90, fit: BoxFit.contain),
          ),
          title: Text(
            'CITY PASS',
            style: GoogleFonts.pacifico(
              fontSize: 36,
              color: Colors.white,
            ),
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Center(
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _showLoginForm = false;
                      _emailController.clear();
                      _passwordController.clear();
                    });
                  },
                  child: Text(
                    'Home',
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          // Background Image
          Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/background.jpg'),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.black.withOpacity(0.6),
                  BlendMode.darken,
                ),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                children: [
                  SizedBox(height: 100),
                  // Travel Smarter Title
                  Text(
                    'Travel Smarter.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.pacifico(
                      fontSize: 48,
                      color: Colors.white,
                      shadows: [
                        Shadow(color: Colors.black45, offset: Offset(2, 2), blurRadius: 4),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Description text
                  Text(
                    'The complete digital bus pass solution for Students and Public commuters. Apply, renew, and travel with just a QR code.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 60),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => RegisterScreen()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6366F1),
                            padding: EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                            elevation: 8,
                          ),
                          child: Text('Get Started Now', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _isConductor = false;
                              _showLoginForm = !_showLoginForm;
                            });
                          },
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
                            padding: EdgeInsets.symmetric(vertical: 20),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text('Login to Account', style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                  
                  // Login Form (Hidden by default)
                  if (_showLoginForm) ...[
                    SizedBox(height: 40),
                    Container(
                      padding: EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.7),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(color: Colors.black45, blurRadius: 20, spreadRadius: 5),
                        ],
                      ),
                      child: Column(
                        children: [
                          SizedBox(height: 12),
                           Text(
                            _isConductor ? 'Conductor Terminal Login' : 'Login to Your Account',
                            style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          SizedBox(height: 20),
                          // Custom Segmented Toggle Control
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isConductor = false;
                                      _emailController.clear();
                                      _passwordController.clear();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: !_isConductor ? Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: !_isConductor ? Color(0xFF818CF8) : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'User / Admin',
                                        style: GoogleFonts.outfit(
                                          color: !_isConductor ? Colors.white : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isConductor = true;
                                      _emailController.clear();
                                      _passwordController.clear();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: Duration(milliseconds: 250),
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    decoration: BoxDecoration(
                                      color: _isConductor ? Color(0xFF6366F1) : Colors.white.withOpacity(0.05),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(
                                        color: _isConductor ? Color(0xFF818CF8) : Colors.transparent,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Conductor',
                                        style: GoogleFonts.outfit(
                                          color: _isConductor ? Colors.white : Colors.white60,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 24),
                          TextField(
                            controller: _emailController,
                            decoration: InputDecoration(
                              hintText: _isConductor ? 'Bus Number (e.g. 78)' : 'Email or Username',
                              hintStyle: TextStyle(color: Colors.white54),
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
                              prefixIcon: Icon(
                                _isConductor ? Icons.directions_bus : Icons.email,
                                color: Colors.white70,
                              ),
                            ),
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 16),
                          TextField(
                            controller: _passwordController,
                            decoration: InputDecoration(
                              hintText: 'Password',
                              hintStyle: TextStyle(color: Colors.white54),
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
                              prefixIcon: Icon(Icons.lock, color: Colors.white70),
                            ),
                            obscureText: true,
                            style: TextStyle(color: Colors.white),
                          ),
                          SizedBox(height: 32),
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _handleLogin,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Color(0xFF6366F1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              ),
                              child: _isLoading 
                                  ? CircularProgressIndicator(color: Colors.white) 
                                  : Text('Login Now', style: GoogleFonts.outfit(fontSize: 18, fontWeight: FontWeight.bold)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  SizedBox(height: 60),

                  // Feature Cards
                  _buildFeatureCard(
                    icon: '🎓',
                    title: 'Student Pass',
                    description: 'Yearly validity for only ₹280. Perfect for daily college travels.',
                  ),
                  SizedBox(height: 20),
                  _buildFeatureCard(
                    icon: '👱',
                    title: 'Public Pass',
                    description: 'Unlimited monthly travel for ₹1000. No daily limits, just pure freedom.',
                  ),
                  SizedBox(height: 20),
                  _buildFeatureCard(
                    icon: '📱',
                    title: 'QR Scan',
                    description: 'No more paper cards. Show your QR code to the conductor and you\'re good to go.',
                  ),
                  SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard({required String icon, required String title, required String description}) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Color(0xFF1E293B).withOpacity(0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(color: Colors.black38, blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Text(icon, style: TextStyle(fontSize: 40)),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Text(
            description,
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 16,
              color: Colors.white70,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
  
  bool _showLoginForm = false;
}
