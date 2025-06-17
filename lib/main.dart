import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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
        // Start with QR login screen
        home: const QRLoginScreen(),
        routes: {
          '/main': (context) => const MainScreen(),
          '/qr-login': (context) => const QRLoginScreen(),
        },
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}