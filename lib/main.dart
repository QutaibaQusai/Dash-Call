// lib/main.dart - FIXED: Status Bar Configuration

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
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

  // FIXED: Configure system UI overlay BEFORE orientation lock
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent, // Keep transparent but ensure visibility
      statusBarIconBrightness: Brightness.dark, // Default to dark icons
      statusBarBrightness: Brightness.light, // Default to light status bar
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  // ADDED: Enable edge-to-edge display but keep status bar visible
  SystemChrome.setEnabledSystemUIMode(
    SystemUiMode.edgeToEdge,
    overlays: [SystemUiOverlay.top, SystemUiOverlay.bottom], // Keep both overlays
  );

  // ⛔ Lock orientation to portrait only
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize database
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
            home: const LoginCheckScreen(),
            routes: {
              '/main': (context) => const MainScreen(),
              '/qr-login': (context) => const QRLoginScreen(),
            },
            debugShowCheckedModeBanner: false,
            builder: (context, child) {
              // ADDED: Update status bar based on current theme
              WidgetsBinding.instance.addPostFrameCallback((_) {
                themeService.handleSystemBrightnessChange();
                _updateStatusBarForTheme(themeService.isDarkMode);
              });
              
              // Handle CallScreen navigation globally
              if (callManager.shouldShowCallScreen) {
                return WillPopScope(
                  onWillPop: () async {
                    // Prevent back navigation during active calls
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

  // ADDED: Helper method to update status bar for current theme
  void _updateStatusBarForTheme(bool isDarkMode) {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent, // Keep transparent
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

// KEEP ALL YOUR EXISTING LoginCheckScreen CODE - Just ensure it uses SafeArea properly
class LoginCheckScreen extends StatefulWidget {
  const LoginCheckScreen({super.key});

  @override
  State<LoginCheckScreen> createState() => _LoginCheckScreenState();
}

class _LoginCheckScreenState extends State<LoginCheckScreen>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  
  String _loadingMessage = 'Starting DashCall...';
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    
    // Setup animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );
    
    _animationController.forward();
    _checkLoginStatus();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _checkLoginStatus() async {
    try {
      // Step 1: Initialize services
      _updateProgress(0.2, 'Initializing services...');
      await Future.delayed(const Duration(milliseconds: 500));

      final multiAccountManager = Provider.of<MultiAccountManager>(context, listen: false);
      
      // Step 2: Initialize MultiAccountManager
      _updateProgress(0.4, 'Loading account data...');
      await Future.delayed(const Duration(milliseconds: 300));
      
      print('🔄 [LoginCheck] Initializing MultiAccountManager...');
      await multiAccountManager.initialize();
      
      print('✅ [LoginCheck] MultiAccountManager initialized');
      print('📊 [LoginCheck] Has accounts: ${multiAccountManager.hasAccounts}');

      if (mounted) {
        if (multiAccountManager.hasAccounts) {
          // Step 3: Connect accounts
          _updateProgress(0.7, 'Connecting to servers...');
          await Future.delayed(const Duration(milliseconds: 300));
          
          print('🔌 [LoginCheck] Connecting all accounts...');
          await multiAccountManager.connectAllAccounts();
          
          // Step 4: Complete
          _updateProgress(1.0, 'Ready!');
          await Future.delayed(const Duration(milliseconds: 500));
          
          print('📱 [LoginCheck] Navigating to main screen...');
          Navigator.of(context).pushReplacementNamed('/main');
        } else {
          // Step 3: No accounts found
          _updateProgress(1.0, 'No accounts found');
          await Future.delayed(const Duration(milliseconds: 300));
          
          print('🔑 [LoginCheck] No accounts found, navigating to login...');
          Navigator.of(context).pushReplacementNamed('/qr-login');
        }
      }
    } catch (e) {
      print('❌ [LoginCheck] Error checking login status: $e');
      _updateProgress(1.0, 'Error occurred');
      await Future.delayed(const Duration(milliseconds: 500));
      
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/qr-login');
      }
    }
  }

  void _updateProgress(double progress, String message) {
    if (mounted) {
      setState(() {
        _progress = progress;
        _loadingMessage = message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: _buildGradientBackground(context),
        child: SafeArea( // IMPORTANT: Always use SafeArea
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 2),
                  
                  // App logo with animation
                  _buildAppLogo(context),
                  
                  const SizedBox(height: 60),
                  
                  // Loading content
                  _buildLoadingContent(context),
                  
                  const Spacer(flex: 3),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAppLogo(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: Image.asset(
              'assets/images/dashcall_icon.png',
              width: 120,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: const Icon(
                    Icons.phone_android_rounded,
                    size: 60,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // App name
        Text(
          'DashCall',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onBackground,
            letterSpacing: 1.5,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Tagline
        Text(
          'Work Remotely, Anywhere',
          style: TextStyle(
            fontSize: 16,
            color: Theme.of(context).colorScheme.onBackground.withOpacity(0.7),
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Container(
          width: 200,
          height: 4,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
            borderRadius: BorderRadius.circular(2),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: _progress,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 24),
        
        // Loading message
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _loadingMessage,
            key: ValueKey(_loadingMessage),
            style: TextStyle(
              fontSize: 16,
              color: Theme.of(context).colorScheme.onBackground.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Percentage indicator
        Text(
          '${(_progress * 100).toInt()}%',
          style: TextStyle(
            fontSize: 14,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  BoxDecoration _buildGradientBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (isDark) {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1C1C1E),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      );
    } else {
      return BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).scaffoldBackgroundColor,
          ],
        ),
      );
    }
  }
}