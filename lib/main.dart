import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/sip_service.dart';
import 'screens/main_screen.dart';
import 'screens/qr_login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request essential permissions
  await _requestPermissions();
  
  runApp(const DashCallApp());
}

Future<void> _requestPermissions() async {
  print('🔐 [Main] Requesting permissions...');
  
  // Request microphone permission for voice calls
  final micStatus = await Permission.microphone.request();
  print('🎤 [Main] Microphone permission: $micStatus');
  
  // Request camera permission (required by WebRTC and QR scanner)
  final cameraStatus = await Permission.camera.request();
  print('📷 [Main] Camera permission: $cameraStatus');
  
  // Request phone permission (optional but recommended)
  final phoneStatus = await Permission.phone.request();
  print('📞 [Main] Phone permission: $phoneStatus');
  
  // For Android, also request audio settings
  if (await Permission.microphone.isDenied) {
    print('🎤 [Main] Microphone denied, requesting again...');
    await Permission.microphone.request();
  }
  
  if (await Permission.camera.isDenied) {
    print('📷 [Main] Camera denied, requesting again...');
    await Permission.camera.request();
  }
  
  print('✅ [Main] Permission requests completed');
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
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
        ),
        // Use LoginCheckScreen to determine initial route
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

// NEW: Screen to check login status and navigate accordingly
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
    print('🔍 [LoginCheck] Checking login status...');
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
      
      print('📱 [LoginCheck] Login status: $isLoggedIn');
      
      if (mounted) {
        if (isLoggedIn) {
          print('✅ [LoginCheck] User is logged in, navigating to MainScreen');
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          print('🔐 [LoginCheck] User not logged in, navigating to QR Login');
          Navigator.of(context).pushReplacementNamed('/qr-login');
        }
      }
    } catch (e) {
      print('❌ [LoginCheck] Error checking login status: $e');
      // On error, default to login screen
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/qr-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Return empty container while checking, navigation will happen immediately
    return const Scaffold(
      body: SizedBox.shrink(),
    );
  }
}