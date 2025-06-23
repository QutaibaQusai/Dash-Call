// lib/screens/qr_login_screen.dart - Updated with Custom Design

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/multi_account_manager.dart';
import '../themes/app_themes.dart';
import 'dart:math' as math;

class QRLoginScreen extends StatefulWidget {
  final bool autoStartScanning; // NEW: Option to start scanning immediately

  const QRLoginScreen({super.key, this.autoStartScanning = false});

  @override
  State<QRLoginScreen> createState() => _QRLoginScreenState();
}

class _QRLoginScreenState extends State<QRLoginScreen>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isProcessing = false;
  bool showScanner = false;
  String? errorMessage;

  late AnimationController _floatingController;
  late AnimationController _slideController;
  late Animation<double> _floatingAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _floatingController = AnimationController(
      duration: const Duration(seconds: 5),
      vsync: this,
    )..repeat(reverse: true);

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _floatingAnimation = Tween<double>(begin: 6, end: 8).animate(
      CurvedAnimation(parent: _floatingController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // NEW: Auto-start scanning if requested
    if (widget.autoStartScanning) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _startScanning();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Use app theme colors instead of custom gradient
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Container(
        decoration: _buildThemedBackground(context),
        child: Stack(
          children: [
            // FIXED: Reduced floating particles for cleaner look
            ...List.generate(
              8, // Reduced from 20 to 8
              (index) =>
                  _buildFloatingParticle(index, MediaQuery.of(context).size),
            ),

            SafeArea(
              child:
                  !showScanner
                      ? _buildWelcomeScreen(context)
                      : _buildScannerScreen(context),
            ),
          ],
        ),
      ),
    );
  }

  // FIXED: Use app theme for background
  BoxDecoration _buildThemedBackground(BuildContext context) {
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

  Widget _buildFloatingParticle(int index, Size size) {
    final random = math.Random(index);
    final startX = random.nextDouble() * size.width;
    final startY = random.nextDouble() * size.height;
    final scale = 0.3 + random.nextDouble() * 0.7;

    return AnimatedBuilder(
      animation: _floatingController,
      builder: (context, child) {
        return Positioned(
          left:
              startX +
              math.sin(_floatingController.value * 2 * math.pi + index) * 15,
          top:
              startY +
              math.cos(_floatingController.value * 2 * math.pi + index) * 10,
          child: Opacity(
            opacity: 0.05 + (scale * 0.1),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Theme.of(context).colorScheme.primary,
           
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWelcomeScreen(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        children: [
          const Spacer(),

          Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/icon/dashcall_icon.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(40),
                      ),
                      child: Icon(
                        Icons.phone_android_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // FIXED: Removed "Hello! 👋" and simplified
              Text(
                'Welcome to',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurface.withOpacity(0.8),
                ),
              ),

              const SizedBox(height: 8),

              // App name with themed styling
              Text(
                'DashCall',
                style: TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 16),

              // Subtitle
              Text(
                'Work Remotely, Anywhere',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: AppThemes.getSecondaryTextColor(context),
                ),
              ),

              const SizedBox(height: 24),
            ],
          ),

          const Spacer(),

          // FIXED: Themed feature section
          Container(
            padding: const EdgeInsets.all(24),
            margin: const EdgeInsets.only(bottom: 40),
            decoration: BoxDecoration(
              color: AppThemes.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
              ),
            
            ),
            child: Column(
              children: [
                _buildFeatureItem(
                  Icons.security_rounded,
                  'Secure Login',
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.qr_code_scanner_rounded,
                  'QR Code Scanner',
                  Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 16),
                _buildFeatureItem(
                  Icons.speed_rounded,
                  'Quick Setup',
                  Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),

          // FIXED: Themed scan button
          AnimatedBuilder(
            animation: _floatingAnimation,
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, -_floatingAnimation.value),
                child: Container(
                  width: double.infinity,
                  height: 60,
                  margin: const EdgeInsets.only(bottom: 40),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.primary.withOpacity(0.8),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(30),
               
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(30),
                      onTap: _startScanning,
                      child: const Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner_rounded,
                              color: Colors.white,
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Text(
                              'Start Scanning',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String text, Color color) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Text(
          text,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildScannerScreen(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).scaffoldBackgroundColor,
              child: Row(
                children: [
                  // Back button
                  Container(
                    decoration: BoxDecoration(
                      color: AppThemes.getCardBackgroundColor(context),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Theme.of(
                          context,
                        ).colorScheme.primary.withOpacity(0.2),
                      ),
                    ),
                    child: IconButton(
                      onPressed: _goBack,
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Left-aligned text
                  Expanded(
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align text to left
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Scan QR Code',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        Text(
                          'Position the QR code in the frame',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppThemes.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
           
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null && !isProcessing) {
                              _processQRCode(barcode.rawValue!);
                              break;
                            }
                          }
                        },
                      ),

                      // Scanning overlay
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: CustomPaint(
                          painter: ScannerOverlayPainter(
                            Theme.of(context).colorScheme.primary,
                          ),
                          size: Size.infinite,
                        ),
                      ),

                      // Processing overlay
                      if (isProcessing)
                        Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(30),
                            color: Colors.black.withOpacity(0.8),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: SizedBox(
                                    width: 50,
                                    height: 50,
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                      strokeWidth: 3,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Processing QR Code...',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Please wait a moment',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.all(24),
              color: Theme.of(context).scaffoldBackgroundColor,
              child:
                  errorMessage != null
                      ? _buildErrorSection()
                      : _buildInstructionsSection(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.error_rounded,
                  color: Colors.red,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Scan Failed',
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      errorMessage!,
                      style: TextStyle(
                        color: AppThemes.getSecondaryTextColor(context),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _retryScanning,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              elevation: 0,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstructionsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.info_outline_rounded,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Hold your device steady and ensure the QR code is clearly visible within the frame',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _startScanning() {
    setState(() {
      showScanner = true;
      controller = MobileScannerController();
    });
    _slideController.forward();
  }

  void _goBack() {
    _slideController.reverse().then((_) {
      controller?.dispose();
      controller = null;
      setState(() {
        showScanner = false;
        errorMessage = null;
      });
    });
  }

  Future<void> _processQRCode(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    print('🔍 [QRLogin] Processing QR code: $qrCode');

    try {
      await controller?.stop();

      final parts = qrCode.split(';');

      // Validate QR code format: username;password;domain;port;protocol;firstname lastname;company
      if (parts.length != 7) {
        throw Exception(
          'Invalid QR code format. Expected 7 values separated by semicolons.',
        );
      }

      final username = parts[0].trim();
      final password = parts[1].trim();
      final domain = parts[2].trim();
      final portString = parts[3].trim();
      final protocol = parts[4].trim();
      final fullName = parts[5].trim();
      final company = parts[6].trim();

      // Validate required fields
      if (username.isEmpty) throw Exception('Username cannot be empty');
      if (password.isEmpty) throw Exception('Password cannot be empty');
      if (domain.isEmpty) throw Exception('Domain cannot be empty');
      if (portString.isEmpty) throw Exception('Port cannot be empty');
      if (fullName.isEmpty) throw Exception('Account name cannot be empty');
      if (company.isEmpty) throw Exception('Organization name cannot be empty');

      final port = int.tryParse(portString);
      if (port == null || port < 1 || port > 65535) {
        throw Exception('Invalid port number: $portString');
      }

      if (protocol.toLowerCase() != 'wss') {
        throw Exception('Invalid protocol. Expected "wss", got "$protocol"');
      }

      print('✅ [QRLogin] QR code validation successful');

      // Use MultiAccountManager to add the account
      final accountManager = Provider.of<MultiAccountManager>(
        context,
        listen: false,
      );

      final success = await accountManager.addAccount(
        sipServer: domain,
        username: username,
        password: password,
        domain: domain,
        port: port,
        accountName: fullName,
        organization: company,
      );

      if (!success) {
        throw Exception('This account is already active.');
      }

      // Connect the newly added account
      await accountManager.connectAllAccounts();

      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    } catch (e) {
      print('❌ [QRLogin] QR code processing failed: $e');
      setState(() {
        errorMessage = e.toString().replaceFirst('Exception: ', '');
      });

      await Future.delayed(const Duration(seconds: 1));
      await controller?.start();
    } finally {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
      }
    }
  }

  void _retryScanning() {
    setState(() {
      errorMessage = null;
      isProcessing = false;
    });
    controller?.start();
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _slideController.dispose();
    controller?.dispose();
    super.dispose();
  }
}

// Custom painter for scanner overlay
class ScannerOverlayPainter extends CustomPainter {
  final Color cornerColor;

  ScannerOverlayPainter(this.cornerColor);

  @override
  void paint(Canvas canvas, Size size) {
    final paint =
        Paint()
          ..color = cornerColor
          ..strokeWidth = 4
          ..style = PaintingStyle.stroke;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2),
      width: size.width * 0.65,
      height: size.width * 0.65,
    );

    const cornerLength = 50.0;

    // Top-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top + cornerLength),
      Offset(scanArea.left, scanArea.top),
      paint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.top),
      Offset(scanArea.left + cornerLength, scanArea.top),
      paint,
    );

    // Top-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.top),
      Offset(scanArea.right, scanArea.top),
      paint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.top),
      Offset(scanArea.right, scanArea.top + cornerLength),
      paint,
    );

    // Bottom-left corner
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom - cornerLength),
      Offset(scanArea.left, scanArea.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(scanArea.left, scanArea.bottom),
      Offset(scanArea.left + cornerLength, scanArea.bottom),
      paint,
    );

    // Bottom-right corner
    canvas.drawLine(
      Offset(scanArea.right - cornerLength, scanArea.bottom),
      Offset(scanArea.right, scanArea.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(scanArea.right, scanArea.bottom - cornerLength),
      Offset(scanArea.right, scanArea.bottom),
      paint,
    );
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
