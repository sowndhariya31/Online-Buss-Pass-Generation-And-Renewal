import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF1E293B).withOpacity(0.9),
          elevation: 0,
          title: Text('My Profile', style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
          centerTitle: true,
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
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Color(0xFF6366F1),
                    child: Text(user?.username?[0].toUpperCase() ?? 'U', style: TextStyle(fontSize: 40, color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  SizedBox(height: 16),
                  Text(user?.username ?? 'User Name', style: GoogleFonts.outfit(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(user?.role ?? 'Role', style: GoogleFonts.outfit(color: Colors.white70, fontSize: 16)),
                  SizedBox(height: 40),
                  _buildProfileItem(Icons.email, 'Email', user?.email ?? 'N/A'),
                  _buildProfileItem(Icons.phone, 'Phone', user?.phoneNumber ?? 'N/A'),
                  _buildProfileItem(Icons.school, 'College', user?.college ?? 'Not specified'),
                  _buildProfileItem(Icons.route, 'Main Route', '${user?.routeFrom ?? "N/A"} to ${user?.routeTo ?? "N/A"}'),
                  SizedBox(height: 40),
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: OutlinedButton.icon(
                      onPressed: () => Provider.of<AuthProvider>(context, listen: false).logout(),
                      icon: Icon(Icons.logout, color: Colors.redAccent),
                      label: Text('Logout from Account', style: GoogleFonts.outfit(color: Colors.redAccent, fontWeight: FontWeight.bold)),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.redAccent.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

  Widget _buildProfileItem(IconData icon, String label, String value) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFF6366F1), size: 24),
          SizedBox(width: 20),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.outfit(color: Colors.white54, fontSize: 13)),
              Text(value, style: GoogleFonts.outfit(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ],
      ),
    );
  }
}
