import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:google_fonts/google_fonts.dart';
import 'services/sip_service.dart';
import 'screens/main_screen.dart';
import 'screens/qr_login_screen.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _requestPermissions();

  runApp(const DashCallApp());
}

Future<void> _requestPermissions() async {
  print('🔐 [Permissions] Requesting permissions...');

  // Essential permissions for VoIP calling
  List<Permission> permissions = [Permission.microphone, Permission.camera];

  // Android-specific permissions
  if (Platform.isAndroid) {
    permissions.addAll([
      Permission.phone,
      Permission.contacts,
      Permission.bluetooth,
      Permission.bluetoothConnect,
      Permission.systemAlertWindow,
      Permission.notification,
      Permission.scheduleExactAlarm,
      Permission.ignoreBatteryOptimizations,
    ]);
  }

  // iOS-specific permissions
  if (Platform.isIOS) {
    permissions.addAll([Permission.contacts]);
  }

  // Request all permissions
  Map<Permission, PermissionStatus> statuses = await permissions.request();

  // Log permission results
  statuses.forEach((permission, status) {
    String permissionName = permission.toString().split('.').last;
    String statusName = status.toString().split('.').last;

    if (status.isGranted) {
      print('✅ [Permissions] $permissionName: $statusName');
    } else if (status.isDenied) {
      print('❌ [Permissions] $permissionName: $statusName');
    } else if (status.isPermanentlyDenied) {
      print(
        '🚫 [Permissions] $permissionName: $statusName (permanently denied)',
      );
    } else {
      print('⚠️ [Permissions] $permissionName: $statusName');
    }
  });

  // Handle critical permissions
  await _handleCriticalPermissions(statuses);

  // Android-specific optimizations
  if (Platform.isAndroid) {
    await _requestAndroidOptimizations();
  }
}

Future<void> _handleCriticalPermissions(
  Map<Permission, PermissionStatus> statuses,
) async {
  // Check microphone permission (critical for VoIP)
  if (statuses[Permission.microphone]?.isDenied == true) {
    print('⚠️ [Permissions] Microphone permission is required for calling');
    // You might want to show a dialog here explaining why the permission is needed
  }

  // Check camera permission (for QR scanning)
  if (statuses[Permission.camera]?.isDenied == true) {
    print(
      '⚠️ [Permissions] Camera permission is required for QR code scanning',
    );
  }

  // Handle permanently denied permissions
  List<Permission> permanentlyDenied =
      statuses.entries
          .where((entry) => entry.value.isPermanentlyDenied)
          .map((entry) => entry.key)
          .toList();

  if (permanentlyDenied.isNotEmpty) {
    print(
      '🚫 [Permissions] Some permissions are permanently denied. User needs to enable them in settings.',
    );
    // You could show a dialog directing users to app settings
  }
}

Future<void> _requestAndroidOptimizations() async {
  try {
    // Request to ignore battery optimizations for VoIP apps
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      print('🔋 [Android] Requesting battery optimization exemption...');
      await Permission.ignoreBatteryOptimizations.request();
    }

    // Request system alert window permission for call overlay
    if (await Permission.systemAlertWindow.isDenied) {
      print('📱 [Android] Requesting system alert window permission...');
      await Permission.systemAlertWindow.request();
    }

    // Request notification permission for Android 13+
    if (await Permission.notification.isDenied) {
      print('🔔 [Android] Requesting notification permission...');
      await Permission.notification.request();
    }
  } catch (e) {
    print('❌ [Android] Error requesting Android optimizations: $e');
  }
}

class DashCallApp extends StatelessWidget {
  const DashCallApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SipService()..initialize(),
      child: MaterialApp(
        title: 'DashCall',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          textTheme: GoogleFonts.tajawalTextTheme(Theme.of(context).textTheme),
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
              textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ),
          textButtonTheme: TextButtonThemeData(
            style: TextButton.styleFrom(
              textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              textStyle: GoogleFonts.tajawal(fontWeight: FontWeight.w600),
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
    return const Scaffold(body: SizedBox.shrink());
  }
}
