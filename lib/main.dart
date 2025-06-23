// lib/main.dart - FIXED: Better initialization sequence

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'services/multi_account_manager.dart';
import 'services/theme_service.dart' as services;
import 'services/call_history_manager.dart';
import 'themes/app_themes.dart';
import 'screens/main_screen.dart';
import 'screens/qr_login_screen.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize database first
  await CallHistoryManager.initialize();

  await _requestPermissions();

  runApp(const DashCallApp());
}

// Rest of your existing permission code remains the same...
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
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => MultiAccountManager(),
        ),
        ChangeNotifierProvider(
          create: (_) => services.ThemeService()..initialize(),
        ),
      ],
      child: Consumer<services.ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'DashCall',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: _convertThemeMode(themeService.themeMode),
            home: const LoginCheckScreen(),
            routes: {
              '/main': (context) => const MainScreen(),
              '/qr-login': (context) => const QRLoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeService.handleSystemBrightnessChange();
              });
              return child!;
            },
          );
        },
      ),
    );
  }

  ThemeMode _convertThemeMode(services.ThemeMode themeMode) {
    switch (themeMode) {
      case services.ThemeMode.light:
        return ThemeMode.light;
      case services.ThemeMode.dark:
        return ThemeMode.dark;
      case services.ThemeMode.system:
        return ThemeMode.system;
    }
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
      // FIXED: Get MultiAccountManager from context and initialize
      final multiAccountManager = Provider.of<MultiAccountManager>(context, listen: false);
      
      print('🔄 [LoginCheck] Initializing MultiAccountManager...');
      await multiAccountManager.initialize();
      
      print('✅ [LoginCheck] MultiAccountManager initialized');
      print('📊 [LoginCheck] Has accounts: ${multiAccountManager.hasAccounts}');

      if (mounted) {
        if (multiAccountManager.hasAccounts) {
          print('🔌 [LoginCheck] Connecting all accounts...');
          // Connect all accounts on app start with a small delay
          await Future.delayed(const Duration(milliseconds: 500));
          await multiAccountManager.connectAllAccounts();
          
          print('📱 [LoginCheck] Navigating to main screen...');
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          print('🔑 [LoginCheck] No accounts found, navigating to login...');
          Navigator.of(context).pushReplacementNamed('/qr-login');
        }
      }
    } catch (e) {
      print('❌ [LoginCheck] Error checking login status: $e');
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/qr-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App logo or icon
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                Icons.phone,
                color: Colors.white,
                size: 40,
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Loading indicator
            CircularProgressIndicator(
              color: Theme.of(context).colorScheme.primary,
            ),
            
            const SizedBox(height: 16),
            
            // Status text
            Text(
              'Initializing DashCall...',
              style: TextStyle(
                fontSize: 16,
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}