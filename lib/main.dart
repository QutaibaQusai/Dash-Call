
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; 
import 'services/multi_account_manager.dart';
import 'services/theme_service.dart' as services;
import 'services/call_history_manager.dart';
import 'services/call_manager.dart';
import 'themes/app_themes.dart';
import 'screens/main_screen.dart';
import 'screens/qr_login_screen.dart';
import 'dart:io';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom],
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database
  await CallHistoryManager.initialize();

  await _requestPermissions();

  runApp(const DashCallApp());
}

Future<void> _requestPermissions() async {
  List<Permission> permissions = [Permission.microphone, Permission.camera];

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

  if (Platform.isIOS) {
    permissions.addAll([Permission.contacts]);
  }

  Map<Permission, PermissionStatus> statuses = await permissions.request();

  await _handleCriticalPermissions(statuses);

  if (Platform.isAndroid) {
    await _requestAndroidOptimizations();
  }
}

Future<void> _handleCriticalPermissions(
  Map<Permission, PermissionStatus> statuses,
) async {
  if (statuses[Permission.microphone]?.isDenied == true) {
  }

  if (statuses[Permission.camera]?.isDenied == true) {
  }

  List<Permission> permanentlyDenied =
      statuses.entries
          .where((entry) => entry.value.isPermanentlyDenied)
          .map((entry) => entry.key)
          .toList();

  if (permanentlyDenied.isNotEmpty) {
  }
}

Future<void> _requestAndroidOptimizations() async {
  try {
    if (await Permission.ignoreBatteryOptimizations.isDenied) {
      await Permission.ignoreBatteryOptimizations.request();
    }

    if (await Permission.systemAlertWindow.isDenied) {
      await Permission.systemAlertWindow.request();
    }

    if (await Permission.notification.isDenied) {
      await Permission.notification.request();
    }
  } catch (e) {
    // Handle Android optimization request errors
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
        ChangeNotifierProvider(
          create: (_) => CallManager(),
        ),
      ],
      child: Consumer2<services.ThemeService, CallManager>(
        builder: (context, themeService, callManager, child) {
          return MaterialApp(
            title: 'DashCall',
            theme: AppThemes.lightTheme,
            darkTheme: AppThemes.darkTheme,
            themeMode: _convertThemeMode(themeService.themeMode),
            home: const AppInitializer(),
            routes: {
              '/main': (context) => const MainScreen(),
              '/qr-login': (context) => const QRLoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeService.handleSystemBrightnessChange();
                _updateStatusBarForTheme(themeService.isDarkMode);
              });
              
              if (callManager.shouldShowCallScreen) {
                return WillPopScope(
                  onWillPop: () async {
                    return false;
                  },
                  child: child!,
                );
              }
              
              return child!;
            },
          );
        },
      ),
    );
  }

  void _updateStatusBarForTheme(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkMode ? Brightness.dark : Brightness.light,
        systemNavigationBarColor: isDarkMode ? const Color(0xFF000000) : const Color(0xFFFFFFFF),
        systemNavigationBarIconBrightness: isDarkMode ? Brightness.light : Brightness.dark,
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

class AppInitializer extends StatefulWidget {
  const AppInitializer({super.key});

  @override
  State<AppInitializer> createState() => _AppInitializerState();
}

class _AppInitializerState extends State<AppInitializer> {
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    try {
      final multiAccountManager = Provider.of<MultiAccountManager>(context, listen: false);
      
      await multiAccountManager.initialize();

      if (mounted) {
        if (multiAccountManager.hasAccounts) {
          await multiAccountManager.connectAllAccounts();
          
          FlutterNativeSplash.remove();
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          FlutterNativeSplash.remove();
          Navigator.of(context).pushReplacementNamed('/qr-login');
        }
      }
    } catch (e) {
      if (mounted) {
        FlutterNativeSplash.remove();
        Navigator.of(context).pushReplacementNamed('/qr-login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: const Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}