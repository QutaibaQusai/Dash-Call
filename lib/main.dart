import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'services/sip_service.dart';
import 'screens/main_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Request essential permissions
  await _requestPermissions();
  
  runApp(const DashCallApp());
}

Future<void> _requestPermissions() async {
  // Request microphone permission for voice calls
  await Permission.microphone.request();
  
  // Request phone permission (optional but recommended)
  await Permission.phone.request();
  
  // For Android, also request audio settings
  if (await Permission.microphone.isDenied) {
    await Permission.microphone.request();
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
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 2,
          ),
        ),
        home: const MainScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}