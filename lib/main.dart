import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sip_service.dart';
import 'screens/main_screen.dart';
import 'screens/qr_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await _requestPermissions();
  
  runApp(const DashCallApp());
}

Future<void> _requestPermissions() async {
  
  final micStatus = await Permission.microphone.request();
  
  final cameraStatus = await Permission.camera.request();
  
  final phoneStatus = await Permission.phone.request();
  
  if (await Permission.microphone.isDenied) {
    await Permission.microphone.request();
  }
  
  if (await Permission.camera.isDenied) {
    await Permission.camera.request();
  }
  
}

class DashCallApp extends StatelessWidget {
  const DashCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SipService()..initialize(),
      child: MaterialApp(
        title: 'DashCall - SIP Tester',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          textTheme: GoogleFonts.tajawalTextTheme(
            Theme.of(context).textTheme,
          ),
          primaryTextTheme: GoogleFonts.tajawalTextTheme(
            Theme.of(context).primaryTextTheme,
          ),
          appBarTheme: AppBarTheme(
            centerTitle: true,
            elevation: 2,
            titleTextStyle: GoogleFonts.tajawal(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              textStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              textStyle: GoogleFonts.tajawal(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            labelStyle: GoogleFonts.tajawal(),
            hintStyle: GoogleFonts.tajawal(),
            helperStyle: GoogleFonts.tajawal(),
            errorStyle: GoogleFonts.tajawal(),
          ),
          bottomNavigationBarTheme: BottomNavigationBarThemeData(
            selectedLabelStyle: GoogleFonts.tajawal(
              fontWeight: FontWeight.w600,
            ),
            unselectedLabelStyle: GoogleFonts.tajawal(
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        home: const LoginCheckScreen(),
        routes: {
          '/main': (context) => const MainScreen(),
          '/qr-login': (context) => const QRLoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}

class LoginCheckScreen extends StatefulWidget {
  const LoginCheckScreen({super.key});

  @override
  State<LoginCheckScreen> createState() => _LoginCheckScreenState();
}

class _LoginCheckScreenState extends State<LoginCheckScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _checkLoginStatus() async {
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      
      if (mounted) {
        if (isLoggedIn) {
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          Navigator.of(context).pushReplacementNamed('/qr-login');
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/qr-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}