import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/pass_provider.dart';
import '../models/bus_pass.dart';
import '../models/user.dart';
import 'scanner_screen.dart';
import 'login_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  @override
  _AdminDashboardScreenState createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Set<int> _viewedPasses = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    Future.microtask(() {
      final passProv = Provider.of<PassProvider>(context, listen: false);
      passProv.fetchAllPasses();
      passProv.fetchUsers();
      passProv.fetchAuditLogs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final passProvider = Provider.of<PassProvider>(context);
    final allPasses = passProvider.allPasses;
    
    final pendingStudents = allPasses.where((p) => p.status == 'PENDING' && p.passType == 'STUDENT').toList();
    final pendingPublic = allPasses.where((p) => p.status == 'PENDING' && p.passType == 'PUBLIC').toList();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(80),
        child: AppBar(
          backgroundColor: Color(0xFF1E293B).withOpacity(0.95),
          elevation: 0,
          leadingWidth: 120,
          leading: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Image.asset('assets/b_logo.png', height: 40),
          ),
          title: Text(
            'CITY PASS',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFFA78BFA),
            ),
          ),
          actions: [
            TextButton(onPressed: () {}, child: Text('Home', style: TextStyle(color: Colors.white))),
            SizedBox(width: 8),
            TextButton.icon(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ScannerScreen())),
              icon: Icon(Icons.qr_code_scanner, color: Colors.white, size: 20),
              label: Text('Scanner', style: TextStyle(color: Colors.white)),
            ),
            SizedBox(width: 16),
            Container(
              margin: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              child: ElevatedButton(
                onPressed: () {
                  Provider.of<AuthProvider>(context, listen: false).logout();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => LoginScreen()),
                    (route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  side: BorderSide(color: Colors.white24),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text('Logout', style: TextStyle(color: Colors.white)),
              ),
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
                colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.85), BlendMode.darken),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 800;
                final double contentPadding = isMobile ? 16.0 : 40.0;
                return Padding(
                  padding: EdgeInsets.all(contentPadding),
                  child: Column(
                    children: [
                      // Stats Cards
                      if (isMobile) ...[
                        _buildStatCard(
                          count: pendingStudents.length.toString(),
                          label: 'Pending Student',
                          subText: 'Active: ${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'STUDENT').length} | Revenue: ₹${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'STUDENT').length * 280}',
                          color: Color(0xFF6366F1),
                        ),
                        SizedBox(height: 16),
                        _buildStatCard(
                          count: pendingPublic.length.toString(),
                          label: 'Pending Public',
                          subText: 'Active: ${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'PUBLIC').length} | Revenue: ₹${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'PUBLIC').length * 1000}',
                          color: Color(0xFF10B981),
                        ),
                      ] else ...[
                        Row(
                          children: [
                            _buildStatCard(
                              count: pendingStudents.length.toString(),
                              label: 'Pending Student',
                              subText: 'Active: ${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'STUDENT').length} | Revenue: ₹${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'STUDENT').length * 280}',
                              color: Color(0xFF6366F1),
                            ),
                            SizedBox(width: 24),
                            _buildStatCard(
                              count: pendingPublic.length.toString(),
                              label: 'Pending Public',
                              subText: 'Active: ${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'PUBLIC').length} | Revenue: ₹${allPasses.where((p) => p.status == 'ACTIVE' && p.passType == 'PUBLIC').length * 1000}',
                              color: Color(0xFF10B981),
                            ),
                          ],
                        ),
                      ],
                      SizedBox(height: isMobile ? 24 : 40),
                      // Tab Bar
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          isScrollable: true,
                          indicator: BoxDecoration(
                            color: Color(0xFF6366F1).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Color(0xFF6366F1).withOpacity(0.5)),
                          ),
                          labelColor: Colors.white,
                          unselectedLabelColor: Colors.white54,
                          tabs: [
                            _buildTab('🎓 Pending Student', pendingStudents.length),
                            _buildTab('👤 Pending Public', pendingPublic.length),
                            _buildTab('🎓 Student Users', passProvider.studentUsers.length),
                            _buildTab('👤 Public Users', passProvider.publicUsers.length),
                            _buildTab('🎫 All Passes', allPasses.length),
                            _buildTab('📝 Audit Logs', passProvider.auditLogs.length),
                          ],
                        ),
                      ),
                      SizedBox(height: 32),
                      // Tab Content
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            _buildApplicationsTable(pendingStudents, passProvider),
                            _buildApplicationsTable(pendingPublic, passProvider),
                            _buildUsersTable(passProvider.studentUsers, isStudent: true),
                            _buildUsersTable(passProvider.publicUsers, isStudent: false),
                            _buildAllPassesTable(allPasses),
                            _buildAuditLogsTable(passProvider.auditLogs),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({required String count, required String label, required String subText, required Color color}) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    final cardContent = Container(
      padding: EdgeInsets.all(isMobile ? 20 : 32),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withOpacity(0.3)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withOpacity(0.1), Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          Text(count, style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 36 : 48, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 15 : 18, fontWeight: FontWeight.w600)),
          SizedBox(height: 8),
          Text(subText, style: TextStyle(color: Colors.white54, fontSize: isMobile ? 12 : 14), textAlign: TextAlign.center),
        ],
      ),
    );

    if (isMobile) {
      return SizedBox(width: double.infinity, child: cardContent);
    } else {
      return Expanded(child: cardContent);
    }
  }

  Tab _buildTab(String label, int count) {
    return Tab(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Row(
          children: [
            Text(label),
            if (count > 0) ...[
              SizedBox(width: 8),
              Container(
                padding: EdgeInsets.all(6),
                decoration: BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                child: Text(count.toString(), style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildApplicationsTable(List<BusPass> apps, PassProvider provider) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
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
                  _headerCell('USER', 2.0),
                  _headerCell('COLLEGE / ADDRESS', 2.0),
                  _headerCell('ROUTE (FROM → TO)', 2.5),
                  _headerCell('DOCUMENTS', 1.5),
                  _headerCell('ACTIONS', 2.0),
                ],
              ),
              Divider(color: Colors.white10, height: isMobile ? 20 : 40),
              Expanded(
                child: apps.isEmpty
                    ? Center(child: Text('No pending applications', style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: apps.length,
                        itemBuilder: (context, index) => _buildAppRow(apps[index], provider),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAllPassesTable(List<BusPass> passes) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: SizedBox(
          width: 850,
          child: Column(
            children: [
              Row(
                children: [
                  _headerCell('PASS ID', 1.5),
                  _headerCell('USER', 2.0),
                  _headerCell('TYPE', 1.0),
                  _headerCell('STATUS', 1.0),
                  _headerCell('ISSUED ON', 1.5),
                  _headerCell('EXPIRY', 1.5),
                ],
              ),
              Divider(color: Colors.white10, height: isMobile ? 20 : 40),
              Expanded(
                child: ListView.builder(
                  physics: BouncingScrollPhysics(),
                  itemCount: passes.length,
                  itemBuilder: (context, index) {
                    final p = passes[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Row(
                        children: [
                          _dataCell(p.passId.isEmpty ? '(Pending)' : p.passId, 1.5),
                          _dataCell(p.username ?? 'No Name', 2.0),
                          _dataCell(p.passType, 1.0),
                          _dataCell(p.status, 1.0, color: p.status == 'ACTIVE' ? Colors.greenAccent : Colors.orangeAccent),
                          _dataCell(p.issueDate.toString().substring(0, 10), 1.5),
                          _dataCell(p.expiryDate.toString().substring(0, 10), 1.5),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String label, double flex) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _dataCell(String value, double flex, {Color color = Colors.white70}) {
    return Expanded(
      flex: (flex * 10).toInt(),
      child: Text(value, style: TextStyle(color: color, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
    );
  }

  Widget _buildAppRow(BusPass p, PassProvider provider) {
    return Container(
      margin: EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.white.withOpacity(0.05))),
      ),
      child: Row(
        children: [
          // USER
          Expanded(
            flex: 20,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundImage: (p.userPhoto != null && p.userPhoto!.isNotEmpty) ? NetworkImage(p.userPhoto!) : null,
                  child: (p.userPhoto == null || p.userPhoto!.isEmpty) ? Icon(Icons.person, size: 20) : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.username ?? 'No Name', style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                      Text(p.userEmail ?? '', style: TextStyle(color: Colors.white54, fontSize: 11)),
                      Text(p.userPhone ?? '', style: TextStyle(color: Colors.white38, fontSize: 10)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // COLLEGE / ADDRESS
          Expanded(
            flex: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.collegeName ?? 'N/A', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                SizedBox(height: 4),
                Text(p.userAddress ?? 'No Address', style: TextStyle(color: Colors.white54, fontSize: 11), maxLines: 2, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          // ROUTE
          Expanded(
            flex: 25,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.location_on, color: Colors.greenAccent, size: 12),
                    SizedBox(width: 4),
                    Expanded(child: Text(p.routeFrom ?? '-', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
                SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.flag, color: Colors.redAccent, size: 12),
                    SizedBox(width: 4),
                    Expanded(child: Text(p.routeTo ?? '-', style: TextStyle(color: Colors.white70, fontSize: 12))),
                  ],
                ),
              ],
            ),
          ),
          // DOCUMENTS
          Expanded(
            flex: 15,
            child: Row(
              children: [
                IconButton(
                  icon: Icon(Icons.image, color: Color(0xFF6366F1), size: 20),
                  onPressed: () => _showIDProof(p.userPhoto, p.id),
                  tooltip: 'View Photo',
                ),
                IconButton(
                  icon: Icon(Icons.badge, color: Color(0xFFEAB308), size: 20),
                  onPressed: () => _showIDProof(p.userIdProof, p.id),
                  tooltip: 'View ID Proof',
                ),
              ],
            ),
          ),
          // ACTIONS
          Expanded(
            flex: 20,
            child: Row(
              children: [
                _buildSolidButton(
                  'Approve', 
                  _viewedPasses.contains(p.id) ? Color(0xFF10B981) : Colors.white24, 
                  _viewedPasses.contains(p.id) 
                      ? () => provider.updatePassStatus(p.id, 'ACTIVE') 
                      : () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please view the documents first before approving.')))
                ),
                SizedBox(width: 8),
                _buildSolidButton('Reject', Color(0xFFEF4444), () => provider.updatePassStatus(p.id, 'REJECTED')),
                SizedBox(width: 8),
                _buildSolidButton('Drop', Colors.white12, () => provider.deletePass(p.id)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSolidButton(String label, Color color, VoidCallback onTap) {
    return Expanded(
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          elevation: 0,
        ),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildUsersTable(List<User> users, {bool isStudent = true}) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
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
                  _headerCell('USERNAME', 2.0),
                  _headerCell('EMAIL', 2.5),
                  _headerCell('PHONE NUMBER', 2.0),
                  _headerCell('ROUTE (FROM ⇌ TO)', 3.0),
                  if (isStudent) _headerCell('COLLEGE', 2.5),
                ],
              ),
              Divider(color: Colors.white10, height: isMobile ? 20 : 40),
              Expanded(
                child: users.isEmpty
                    ? Center(child: Text('No users registered', style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: users.length,
                        itemBuilder: (context, index) {
                          final u = users[index];
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                _dataCell(u.username, 2.0, color: Colors.white),
                                _dataCell(u.email, 2.5),
                                _dataCell(u.phoneNumber, 2.0),
                                _dataCell('${u.routeFrom ?? '-'} ⇌ ${u.routeTo ?? '-'}', 3.0, color: Colors.greenAccent),
                                if (isStudent) _dataCell(u.college ?? 'N/A', 2.5),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAuditLogsTable(List<Map<String, dynamic>> logs) {
    final bool isMobile = MediaQuery.of(context).size.width < 800;
    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 32),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.4),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: BouncingScrollPhysics(),
        child: SizedBox(
          width: 850,
          child: Column(
            children: [
              Row(
                children: [
                  _headerCell('LOG ID', 1.0),
                  _headerCell('PASS ID', 2.0),
                  _headerCell('USER (EMAIL)', 3.0),
                  _headerCell('SCAN TIME', 2.5),
                  _headerCell('TRIP NO.', 1.5),
                ],
              ),
              Divider(color: Colors.white10, height: isMobile ? 20 : 40),
              Expanded(
                child: logs.isEmpty
                    ? Center(child: Text('No audit logs registered yet', style: TextStyle(color: Colors.white24)))
                    : ListView.builder(
                        physics: BouncingScrollPhysics(),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          String formattedTime = log['time'] ?? '-';
                          if (formattedTime.length >= 19) {
                            formattedTime = formattedTime.substring(0, 19).replaceAll('T', ' ');
                          }
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12.0),
                            child: Row(
                              children: [
                                _dataCell(log['id'].toString(), 1.0),
                                _dataCell(log['pass_id'] ?? '-', 2.0, color: Colors.blueAccent),
                                _dataCell(log['user'] ?? '-', 3.0, color: Colors.white),
                                _dataCell(formattedTime, 2.5),
                                _dataCell('Trip ${log['trip']}', 1.5, color: Colors.orangeAccent),
                              ],
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderTab(String title) {
    return Center(child: Text('$title content coming soon', style: TextStyle(color: Colors.white24)));
  }

  void _showIDProof(String? url, [int? passId]) {
    if (url == null || url.isEmpty) return;

    if (passId != null) {
      setState(() {
        _viewedPasses.add(passId);
      });
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              decoration: BoxDecoration(color: Color(0xFF1E293B), borderRadius: BorderRadius.circular(16)),
              padding: EdgeInsets.all(8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(url, fit: BoxFit.contain),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Close')),
          ],
        ),
      ),
    );
  }
}
