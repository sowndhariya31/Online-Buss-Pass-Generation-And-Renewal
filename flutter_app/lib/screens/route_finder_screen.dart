import 'dart:convert';
import '../web_utils_stub.dart' if (dart.library.html) '../web_utils_web.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';

class RouteFinderScreen extends StatefulWidget {
  @override
  _RouteFinderScreenState createState() => _RouteFinderScreenState();
}

class _RouteFinderScreenState extends State<RouteFinderScreen> {
  List<dynamic> _routes = [];
  List<dynamic> _filteredRoutes = [];
  Map<String, dynamic>? _selectedBus;
  bool _isLoading = true;
  final TextEditingController _originController = TextEditingController();
  final TextEditingController _destController = TextEditingController();

  final List<Map<String, dynamic>> _hardcodedRoutes = [
    { "no": "78", "start": "KOYAMBEDU", "end": "THIRUVANMIYUR", "stops": ["M.M.D.A.COLONY", "JAFFARKHAN PET", "CIPET", "GUINDY", "ENG.COLLEGE", "ADYAR B.S.", "ADYAR DEPOT"] },
    { "no": "21G", "start": "ISLAND GROUND", "end": "KILAMBAKKAM", "stops": ["SECRETARIAT", "CHEPAUK", "Q.M.C", "MANDAVELI", "ADYAR GATE", "KOTTURPURAM", "GUINDY", "PALLAVARAM", "TAMBARAM", "VANDALUR ZOO"] },
    { "no": "29C", "start": "PERAMBUR", "end": "BESANT NAGAR", "stops": ["SHIVASHANMUGAPURAM", "K.M.C", "STERLING RD", "PONDY BAZAAR", "SAIDAPET", "ENG.COLLEGE", "ADYAR B.S."] },
    { "no": "47A", "start": "VILLIVAKKAM", "end": "THIRUVANMIYUR", "stops": ["KILPAUK GARDEN", "TAYLORS ROAD", "PONDY BAZAAR", "SAIDAPET", "ENG.COLLEGE", "ADYAR B.S."] },
    { "no": "588", "start": "THIRUVANMIYUR", "end": "MAMALLAPURAM", "stops": ["KOTTIVAKKAM", "PALAVAKKAM", "NEELANKARAI", "VETTUVANKENI", "V.G.P", "PANAIYUR", "MUTTUKKADU", "KOVALAM"] },
    { "no": "6D", "start": "TOLLGATE", "end": "THIRUVANMIYUR", "stops": ["PERAMBUR", "EGMORE", "ANNA ROAD", "MANDAVELI", "ADYAR DEPOT"] },
    { "no": "T29", "start": "THIRU.VI.KA.NAGAR", "end": "THIRUVANMIYUR", "stops": ["M.G.R.CENTRAL", "WESLEY H.S", "Y.M.I.A", "MANDAVELI", "ADYAR DEPOT"] },
    { "no": "A1", "start": "M.G.R.CENTRAL", "end": "THIRUVANMIYUR", "stops": ["TAMBARAM WEST", "CHROMEPET", "PALLAVARAM", "V.G.P", "NEELANKARAI", "KOTTIVAKKAM"] },
    { "no": "99", "start": "TAMBARAM WEST", "end": "ADYAR B.S.", "stops": ["GUDUVANCHERY", "VANDALUR ZOO", "TAMBARAM", "CHROMEPET", "KANDANCHAVADI", "THIRUVANMIYUR"] },
    { "no": "91V", "start": "GUDUVANCHERY", "end": "THIRUVANMIYUR", "stops": ["ISLAND GROUND", "CHEPAUK", "Q.M.C", "FORESHORE ESTATE", "ADYAR DEPOT", "KOVALAM"] },
    { "no": "109", "start": "ISLAND GROUND", "end": "KOVALAM", "stops": ["ADYAR B.S.", "THIRUVANMIYUR", "PALAVAKKAM", "NEELANKARAI", "V.G.P", "PANAIYUR", "MUTTUKKADU"] },
    { "no": "109CT", "start": "ADYAR B.S.", "end": "KOVALAM", "stops": ["THIRUVOTRIYUR", "EGMORE", "SECRETARIAT", "CHEPAUK", "FORESHORE ESTATE", "ADYAR DEPOT", "THIRUVANMIYUR"] },
    { "no": "109T", "start": "THIRUVOTRIYUR", "end": "KOVALAM", "stops": ["ISLAND GROUND", "CHEPAUK", "Q.M.C", "FORESHORE ESTATE", "THIRUVANMIYUR", "THIRUPORUR"] },
    { "no": "109X", "start": "ISLAND GROUND", "end": "THIRUPORUR", "stops": ["ADYAR DEPOT", "SRP TOOLS", "THORAPAKKAM", "SHOLINGANALLUR", "PERUMBAKKAM", "KANNAGI NAGAR"] },
    { "no": "102K", "start": "ISLAND GROUND", "end": "KANNAGI NAGAR", "stops": ["CHEPAUK", "Q.M.C", "ADYAR DEPOT", "THORAPAKKAM", "KARAPAKKAM", "SHOLINGANALLUR"] },
    { "no": "102P", "start": "ISLAND GROUND", "end": "PERUMPAKKAM", "stops": ["CHEPAUK", "Q.M.C", "ADYAR DEPOT", "THORAPAKKAM", "KARAPAKKAM", "SHOLINGANALLUR"] }
  ];

  @override
  void initState() {
    super.initState();
    _routes = _hardcodedRoutes;
    _filteredRoutes = [];
    _isLoading = false;
  }

  void _doSearch() {
    final q1 = _originController.text.trim().toUpperCase();
    final q2 = _destController.text.trim().toUpperCase();
    if (q1.isEmpty) return;

    setState(() {
      _filteredRoutes = _routes.where((r) {
        final hasQ1 = r['no'] == q1 || r['start'].contains(q1) || r['end'].contains(q1) || (r['stops'] as List).any((s) => s.contains(q1));
        if (q2.isEmpty) return hasQ1;
        final hasQ2 = r['start'].contains(q2) || r['end'].contains(q2) || (r['stops'] as List).any((s) => s.contains(q2));
        return hasQ1 && hasQ2;
      }).toList();
      _selectedBus = null;
    });
  }

  void _selectBus(Map<String, dynamic> bus) {
    setState(() => _selectedBus = bus);
    final allStops = [bus['start'], ...bus['stops'], bus['end']];
    
    // Send message to IFrame (web only)
    updateMapRoute(bus, allStops);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
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
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('🚌 Smart Public Transport Finder', style: GoogleFonts.outfit(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                      ElevatedButton(
                        onPressed: () => Navigator.pop(context),
                        style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                        child: Text('Back'),
                      ),
                    ],
                  ),
                  SizedBox(height: 32),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left Panel: Search & Results
                        Container(
                          width: 400,
                          padding: EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.5),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: Colors.white10),
                          ),
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildInputLabel('From Point / Bus No.'),
                                TextField(
                                  controller: _originController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: _inputDecoration('E.g. 78 or KOYAMBEDU'),
                                ),
                                SizedBox(height: 20),
                                _buildInputLabel('To Point (Optional)'),
                                TextField(
                                  controller: _destController,
                                  style: TextStyle(color: Colors.white),
                                  decoration: _inputDecoration('E.g. THIRUVANMIYUR'),
                                ),
                                SizedBox(height: 24),
                                SizedBox(
                                  width: double.infinity,
                                  height: 50,
                                  child: ElevatedButton.icon(
                                    onPressed: _doSearch,
                                    icon: Icon(Icons.search, size: 20),
                                    label: Text('Search Buses', style: TextStyle(fontWeight: FontWeight.bold)),
                                    style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                                  ),
                                ),
                                if (_selectedBus != null) ...[
                                  SizedBox(height: 24),
                                  _buildRouteDetails(_selectedBus!),
                                ] else if (_filteredRoutes.isNotEmpty) ...[
                                  SizedBox(height: 24),
                                  Text('Matching Buses', style: TextStyle(color: Colors.white54, fontSize: 12)),
                                  SizedBox(height: 12),
                                  ..._filteredRoutes.map((r) => _buildBusCard(r)).toList(),
                                ]
                              ],
                            ),
                          ),
                        ),
                        SizedBox(width: 32),
                        // Right Panel: Map View
                        Expanded(
                          child: Container(
                            clipBehavior: Clip.antiAlias,
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(color: Colors.white10),
                            ),
                            child: kIsWeb 
                                ? HtmlElementView(viewType: 'leaflet-map')
                                : Center(
                                    child: Text(
                                      'Map View is only available on Web.\nPlease use the web version to view the map.',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(color: Colors.white54, fontSize: 16),
                                    ),
                                  ),
                          ),
                        ),
                      ],
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

  void _showInitialMap() {
    // Optional: send initial center to map
  }

  Widget _buildInputLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(label, style: GoogleFonts.outfit(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white24),
      filled: true,
      fillColor: Colors.white.withOpacity(0.05),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    );
  }

  Widget _buildBusCard(Map<String, dynamic> r) {
    return InkWell(
      onTap: () => _selectBus(r),
      child: Container(
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Bus ${r['no']}', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.bold)),
                Text('${r['start']} ⇌ ${r['end']}', style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
            Icon(Icons.chevron_right, color: Colors.white24),
          ],
        ),
      ),
    );
  }

  Widget _buildRouteDetails(Map<String, dynamic> bus) {
    final allStops = [bus['start'], ...bus['stops'], bus['end']];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OutlinedButton(
          onPressed: () => setState(() => _selectedBus = null),
          child: Text('← Back to Results', style: TextStyle(color: Colors.white54, fontSize: 12)),
          style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white10)),
        ),
        SizedBox(height: 16),
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(color: Color(0xFF6366F1), borderRadius: BorderRadius.circular(16)),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bus Number', style: TextStyle(color: Colors.white70, fontSize: 10)),
                  Text(bus['no'], style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                ],
              ),
              Icon(Icons.directions_bus, color: Colors.white54, size: 32),
            ],
          ),
        ),
        SizedBox(height: 24),
        ...allStops.map((s) => _buildStopItem(s)).toList(),
      ],
    );
  }

  Widget _buildStopItem(String stop) {
    return Container(
      margin: EdgeInsets.only(left: 10),
      padding: EdgeInsets.only(left: 20, bottom: 20),
      decoration: BoxDecoration(border: Border(left: BorderSide(color: Colors.white10, width: 2))),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            left: -26,
            top: 2,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: Color(0xFF6366F1),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Color(0xFF6366F1), blurRadius: 8)],
              ),
            ),
          ),
          Text(stop, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class RoutePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(0xFF6366F1).withOpacity(0.5)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(size.width * 0.2, size.height * 0.2);
    path.quadraticBezierTo(size.width * 0.4, size.height * 0.8, size.width * 0.8, size.height * 0.5);
    
    canvas.drawPath(path, paint);

    // Draw markers
    final dotPaint = Paint()..color = Color(0xFF6366F1);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 6, dotPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 6, dotPaint);
    
    // Draw glow
    final glowPaint = Paint()..color = Color(0xFF6366F1).withOpacity(0.2)..maskFilter = MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawCircle(Offset(size.width * 0.2, size.height * 0.2), 15, glowPaint);
    canvas.drawCircle(Offset(size.width * 0.8, size.height * 0.5), 15, glowPaint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
