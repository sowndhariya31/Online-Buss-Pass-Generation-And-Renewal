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
            child: LayoutBuilder(
              builder: (context, constraints) {
                final bool isMobile = constraints.maxWidth < 800;
                final double paddingValue = isMobile ? 16.0 : 32.0;

                Widget leftPanel = Container(
                  width: isMobile ? double.infinity : 400,
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
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
                );

                Widget rightPanel = Container(
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: Colors.black,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white10),
                  ),
                  child: kIsWeb 
                      ? HtmlElementView(viewType: 'leaflet-map')
                      : InteractiveRouteMap(selectedBus: _selectedBus),
                );

                return Padding(
                  padding: EdgeInsets.all(paddingValue),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '🚌 Smart Transport Finder', 
                              style: GoogleFonts.outfit(color: Colors.white, fontSize: isMobile ? 20 : 28, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6366F1), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                            child: Text('Back'),
                          ),
                        ],
                      ),
                      SizedBox(height: isMobile ? 16 : 32),
                      Expanded(
                        child: isMobile
                            ? SingleChildScrollView(
                                physics: BouncingScrollPhysics(),
                                child: Column(
                                  children: [
                                    leftPanel,
                                    SizedBox(height: 20),
                                    SizedBox(
                                      height: 380,
                                      width: double.infinity,
                                      child: rightPanel,
                                    ),
                                    SizedBox(height: 20),
                                  ],
                                ),
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  leftPanel,
                                  SizedBox(width: 32),
                                  Expanded(child: rightPanel),
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

class InteractiveRouteMap extends StatefulWidget {
  final Map<String, dynamic>? selectedBus;

  const InteractiveRouteMap({Key? key, this.selectedBus}) : super(key: key);

  @override
  _InteractiveRouteMapState createState() => _InteractiveRouteMapState();
}

class _InteractiveRouteMapState extends State<InteractiveRouteMap> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  String? _selectedStop;

  static const Map<String, Offset> stopCoordinates = {
    "KOYAMBEDU": Offset(13.0727, 80.2015),
    "THIRUVANMIYUR": Offset(12.9830, 80.2439),
    "TAMBARAM": Offset(12.9229, 80.1274),
    "ADYAR": Offset(13.0012, 80.2565),
    "GUINDY": Offset(13.0067, 80.2206),
    "ISLAND GROUND": Offset(13.0727, 80.2837),
    "PERAMBUR": Offset(13.1090, 80.2444),
    "VILLIVAKKAM": Offset(13.1065, 80.2037),
    "KILAMBAKKAM": Offset(12.8362, 80.0768),
    "BESANT NAGAR": Offset(13.0003, 80.2667),
    "MAMALLAPURAM": Offset(12.6269, 80.1927),
    "TOLLGATE": Offset(13.1256, 80.2982),
    "THIRU.VI.KA.NAGAR": Offset(13.1147, 80.2312),
    "M.G.R.CENTRAL": Offset(13.0827, 80.2707),
    "GUDUVANCHERY": Offset(12.8427, 80.0632),
    "KOVALAM": Offset(12.7916, 80.2492),
    "THIRUPORUR": Offset(12.7244, 80.1931),
    "KANNAGI NAGAR": Offset(12.9212, 80.2392),
    "PERUMBAKKAM": Offset(12.9022, 80.1983),
    "ADYAR B.S.": Offset(13.0012, 80.2565),
    "ADYAR DEPOT": Offset(12.9894, 80.2514),
    "TAMBARAM WEST": Offset(12.9229, 80.1174),
    "VANDALUR ZOO": Offset(12.8804, 80.0812),
    "SHOLINGANALLUR": Offset(12.9010, 80.2279),
    "M.M.D.A.COLONY": Offset(13.0612, 80.2104),
    "JAFFARKHAN PET": Offset(13.0234, 80.2098),
    "CIPET": Offset(13.0123, 80.2188),
    "ENG.COLLEGE": Offset(13.0112, 80.2367),
    "SECRETARIAT": Offset(13.0789, 80.2812),
    "CHEPAUK": Offset(13.0645, 80.2789),
    "Q.M.C": Offset(13.0456, 80.2778),
    "MANDAVELI": Offset(13.0234, 80.2612),
    "ADYAR GATE": Offset(13.0189, 80.2512),
    "KOTTURPURAM": Offset(13.0145, 80.2423),
    "PALLAVARAM": Offset(12.9678, 80.1489),
    "VANDALUR": Offset(12.8912, 80.0823),
    "SHIVASHANMUGAPURAM": Offset(13.1112, 80.2523),
    "K.M.C": Offset(13.0789, 80.2423),
    "STERLING RD": Offset(13.0612, 80.2412),
    "PONDY BAZAAR": Offset(13.0412, 80.2312),
    "SAIDAPET": Offset(13.0212, 80.2289),
    "KILPAUK GARDEN": Offset(13.0812, 80.2289),
    "TAYLORS ROAD": Offset(13.0712, 80.2367),
    "KOTTIVAKKAM": Offset(12.9689, 80.2545),
    "PALAVAKKAM": Offset(12.9567, 80.2523),
    "NEELANKARAI": Offset(12.9478, 80.2512),
    "VETTUVANKENI": Offset(12.9367, 80.2489),
    "V.G.P": Offset(12.9234, 80.2467),
    "PANAIYUR": Offset(12.9012, 80.2445),
    "MUTTUKKADU": Offset(12.8123, 80.2412),
    "EGMORE": Offset(13.0789, 80.2589),
    "ANNA ROAD": Offset(13.0612, 80.2689),
    "WESLEY H.S": Offset(13.0512, 80.2645),
    "Y.M.I.A": Offset(13.0312, 80.2612),
    "CHROMEPET": Offset(12.9512, 80.1412),
    "KANDANCHAVADI": Offset(12.9645, 80.2489),
    "FORESHORE ESTATE": Offset(13.0312, 80.2745),
    "THIRUVOTRIYUR": Offset(13.1612, 80.3012),
    "SRP TOOLS": Offset(12.9812, 80.2467),
    "THORAPAKKAM": Offset(12.9612, 80.2412),
    "KARAPAKKAM": Offset(12.9289, 80.2312)
  };

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.selectedBus == null) {
      return AnimatedBuilder(
        animation: _animController,
        builder: (context, child) {
          return CustomPaint(
            painter: NetworkConstellationPainter(
              stopCoordinates: stopCoordinates,
              animationValue: _animController.value,
            ),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(24),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white10),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.radar, color: Color(0xFF818CF8), size: 40),
                    const SizedBox(height: 12),
                    Text(
                      'Live Bus Network Tracking',
                      style: GoogleFonts.outfit(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Select a bus route from the left panel to track live vehicle movement on the map.',
                      style: TextStyle(color: Colors.white54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    }

    final bus = widget.selectedBus!;
    final List<String> stops = [
      bus['start'] as String,
      ...List<String>.from(bus['stops']),
      bus['end'] as String,
    ];

    // Find bounding box for projection
    double minLat = 999;
    double maxLat = -999;
    double minLng = 999;
    double maxLng = -999;

    for (var stop in stops) {
      final pos = stopCoordinates[stop.toUpperCase()] ?? const Offset(13.0827, 80.2707);
      if (pos.dx < minLat) minLat = pos.dx;
      if (pos.dx > maxLat) maxLat = pos.dx;
      if (pos.dy < minLng) minLng = pos.dy;
      if (pos.dy > maxLng) maxLng = pos.dy;
    }

    final double latSpan = (maxLat - minLat).abs() < 0.001 ? 0.01 : (maxLat - minLat);
    final double lngSpan = (maxLng - minLng).abs() < 0.001 ? 0.01 : (maxLng - minLng);

    return LayoutBuilder(
      builder: (context, constraints) {
        final double width = constraints.maxWidth;
        final double height = constraints.maxHeight;

        Offset project(Offset pos) {
          double y = height * 0.85 - ((pos.dx - minLat) / latSpan) * (height * 0.7);
          double x = width * 0.15 + ((pos.dy - minLng) / lngSpan) * (width * 0.7);
          return Offset(x, y);
        }

        final List<Offset> projectedPoints = stops.map((s) {
          final pos = stopCoordinates[s.toUpperCase()] ?? const Offset(13.0827, 80.2707);
          return project(pos);
        }).toList();

        return Stack(
          children: [
            GestureDetector(
              onTapDown: (details) {
                final tapPos = details.localPosition;
                int? closestIndex;
                double minDist = 30.0;

                for (int i = 0; i < projectedPoints.length; i++) {
                  final dist = (tapPos - projectedPoints[i]).distance;
                  if (dist < minDist) {
                    minDist = dist;
                    closestIndex = i;
                  }
                }

                setState(() {
                  if (closestIndex != null) {
                    _selectedStop = stops[closestIndex];
                  } else {
                    _selectedStop = null;
                  }
                });
              },
              child: AnimatedBuilder(
                animation: _animController,
                builder: (context, child) {
                  return CustomPaint(
                    size: Size(width, height),
                    painter: RouteVectorPainter(
                      stops: stops,
                      points: projectedPoints,
                      animationValue: _animController.value,
                    ),
                  );
                },
              ),
            ),
            // floating tooltip for tapped stops
            if (_selectedStop != null)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1B4B).withOpacity(0.9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF818CF8).withOpacity(0.5)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.location_on, color: Colors.greenAccent, size: 18),
                      const SizedBox(width: 8),
                      Text(
                        _selectedStop!,
                        style: GoogleFonts.outfit(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => setState(() => _selectedStop = null),
                        child: const Icon(Icons.close, color: Colors.white38, size: 16),
                      ),
                    ],
                  ),
                ),
              ),
            // Floating instructions banner
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  '💡 Tap stop nodes to view names',
                  style: TextStyle(color: Colors.white54, fontSize: 10),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class NetworkConstellationPainter extends CustomPainter {
  final Map<String, Offset> stopCoordinates;
  final double animationValue;

  NetworkConstellationPainter({required this.stopCoordinates, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    // 1. Grid backdrop
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    // 2. Radar sweep effect
    final double radarRadius = size.shortestSide * 0.8 * animationValue;
    final center = Offset(size.width / 2, size.height / 2);
    final paintRadar = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.08 * (1.0 - animationValue))
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radarRadius, paintRadar);

    final paintRadarRing = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.2 * (1.0 - animationValue))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radarRadius, paintRadarRing);

    // 3. Draw constellation stops
    final paintStop = Paint()..color = Colors.white24;
    final paintConn = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.04)
      ..strokeWidth = 1;

    // We can list stops and project them to bounds
    double minLat = 12.6;
    double maxLat = 13.2;
    final double latSpan = maxLat - minLat;
    double minLng = 80.05;
    double maxLng = 80.35;
    final double lngSpan = maxLng - minLng;

    Offset project(Offset pos) {
      double y = size.height * 0.85 - ((pos.dx - minLat) / latSpan) * (size.height * 0.7);
      double x = size.width * 0.15 + ((pos.dy - minLng) / lngSpan) * (size.width * 0.7);
      return Offset(x, y);
    }

    final Map<String, Offset> projected = {};
    stopCoordinates.forEach((key, val) {
      projected[key] = project(val);
    });

    // Draw connection lines between nearby stops to look like a transit grid
    final keys = projected.keys.toList();
    for (int i = 0; i < keys.length; i++) {
      final p1 = projected[keys[i]]!;
      for (int j = i + 1; j < keys.length; j++) {
        final p2 = projected[keys[j]]!;
        final dist = (p1 - p2).distance;
        if (dist < 80) {
          canvas.drawLine(p1, p2, paintConn);
        }
      }
    }

    // Draw dots
    for (var p in projected.values) {
      canvas.drawCircle(p, 3, paintStop);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

class RouteVectorPainter extends CustomPainter {
  final List<String> stops;
  final List<Offset> points;
  final double animationValue;

  RouteVectorPainter({required this.stops, required this.points, required this.animationValue});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    // 1. Grid backdrop
    final paintGrid = Paint()
      ..color = Colors.white.withOpacity(0.02)
      ..strokeWidth = 1;

    for (double i = 0; i < size.width; i += 40) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paintGrid);
    }
    for (double j = 0; j < size.height; j += 40) {
      canvas.drawLine(Offset(0, j), Offset(size.width, j), paintGrid);
    }

    // 2. Route Path
    final paintPath = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.3)
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final paintGlow = Paint()
      ..color = const Color(0xFF6366F1).withOpacity(0.15)
      ..strokeWidth = 18
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(points[0].dx, points[0].dy);
    for (int i = 1; i < points.length; i++) {
      path.lineTo(points[i].dx, points[i].dy);
    }

    canvas.drawPath(path, paintGlow);
    canvas.drawPath(path, paintPath);

    // Active path overlay (animated)
    final paintActivePath = Paint()
      ..color = const Color(0xFF818CF8)
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;
    canvas.drawPath(path, paintActivePath);

    // 3. Draw Station nodes
    for (int i = 0; i < points.length; i++) {
      final p = points[i];
      final isStart = i == 0;
      final isEnd = i == points.length - 1;

      // Pulse ring for terminal stops
      if (isStart || isEnd) {
        final double pulseRadius = 10 + 8 * (1.0 - animationValue);
        final paintPulse = Paint()
          ..color = (isStart ? Colors.greenAccent : Colors.redAccent).withOpacity(0.4 * animationValue)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;
        canvas.drawCircle(p, pulseRadius, paintPulse);
      }

      // Station outer dot
      final paintOuter = Paint()
        ..color = isStart 
            ? Colors.greenAccent 
            : isEnd 
                ? Colors.redAccent 
                : const Color(0xFF6366F1)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 6, paintOuter);

      // Station inner dot
      final paintInner = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill;
      canvas.drawCircle(p, 3.5, paintInner);

      // Draw start / end tooltips directly on canvas
      if (isStart || isEnd) {
        final textSpan = TextSpan(
          text: isStart ? "START" : "END",
          style: GoogleFonts.outfit(
            color: isStart ? Colors.greenAccent : Colors.redAccent,
            fontSize: 9,
            fontWeight: FontWeight.w900,
            letterSpacing: 0.5,
          ),
        );
        final textPainter = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        textPainter.layout();
        textPainter.paint(canvas, Offset(p.dx - textPainter.width / 2, p.dy - 22));
      }
    }

    // 4. Moving Active Bus
    if (points.length >= 2) {
      // Find position of the bus along the polyline segments
      final double totalSegments = (points.length - 1).toDouble();
      final double progress = animationValue * totalSegments;
      final int currentSeg = progress.floor().clamp(0, points.length - 2);
      final double segProgress = progress - currentSeg;

      final pStart = points[currentSeg];
      final pEnd = points[currentSeg + 1];

      final double busX = pStart.dx + (pEnd.dx - pStart.dx) * segProgress;
      final double busY = pStart.dy + (pEnd.dy - pStart.dy) * segProgress;
      final busOffset = Offset(busX, busY);

      // Bus Outer Glow
      final paintBusGlow = Paint()
        ..color = Colors.amberAccent.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
      canvas.drawCircle(busOffset, 16, paintBusGlow);

      // Bus Ring
      final paintBusRing = Paint()
        ..color = Colors.amberAccent
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;
      canvas.drawCircle(busOffset, 10, paintBusRing);

      // Bus fill
      final paintBus = Paint()
        ..color = const Color(0xFF0F172A)
        ..style = PaintingStyle.fill;
      canvas.drawCircle(busOffset, 9, paintBus);

      final paintBusDot = Paint()
        ..color = Colors.amberAccent
        ..style = PaintingStyle.fill;
      canvas.drawCircle(busOffset, 4, paintBusDot);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
