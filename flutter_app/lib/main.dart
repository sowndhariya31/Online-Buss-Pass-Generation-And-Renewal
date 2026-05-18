import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/pass_provider.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'web_utils_stub.dart' if (dart.library.html) 'web_utils_web.dart';

void main() {
  if (kIsWeb) {
    registerWebMapView();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..checkAuth()),
        ChangeNotifierProvider(create: (_) => PassProvider()),
      ],
      child: CityPassApp(),
    ),
  );
}

class CityPassApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'City Pass',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: Color(0xFF6366F1),
        scaffoldBackgroundColor: Color(0xFF0F172A),
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.dark().textTheme),
      ),
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          return auth.isAuthenticated ? DashboardScreen() : LoginScreen();
        },
      ),
    );
  }
}

