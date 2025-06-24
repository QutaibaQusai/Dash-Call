// lib/screens/qr_scanner_screen.dart - NEW: Scanner-only screen for adding accounts

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:adaptive_dialog/adaptive_dialog.dart';
import '../services/multi_account_manager.dart';
import '../themes/app_themes.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen>
    with TickerProviderStateMixin {
  MobileScannerController? controller;
  bool isProcessing = false;
  String? errorMessage;

  // Loading states
  bool isLoading = false;
  String loadingMessage = '';

  late AnimationController _slideController;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();

    _slideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );

    // Start scanner immediately
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startScanning();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          // Main scanner content
          _buildScannerScreen(context),

          // Full-screen loading overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: _buildLoadingWidget(),
              ),
            ),
        ],
      ),
    );
  }

  // Loading widget
  Widget _buildLoadingWidget() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Animated loading indicator
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).colorScheme.primary,
              ),
              strokeWidth: 4,
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Loading message
          Text(
            loadingMessage,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
          ),
          
          const SizedBox(height: 8),
          
          Text(
            'Please wait...',
            style: TextStyle(
              fontSize: 14,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // Show loading with message
  void _showLoading(String message) {
    setState(() {
      isLoading = true;
      loadingMessage = message;
    });
  }

  // Hide loading
  void _hideLoading() {
    setState(() {
      isLoading = false;
      loadingMessage = '';
    });
  }

  Widget _buildScannerScreen(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: Container(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Column(
          children: [
            // Header with back button and title
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: AppThemes.getCardBackgroundColor(context),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        ),
                      ),
                      child: IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: Icon(
                          Icons.arrow_back_rounded,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Add Account',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Text(
                            'Scan QR code to add new account',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppThemes.getSecondaryTextColor(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Scanner area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(30),
                  child: Stack(
                    children: [
                      // Mobile Scanner
                      if (controller != null)
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

                      // Scanner overlay
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
                                    color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
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

            // Bottom section - error or instructions
            SafeArea(
              child: Container(
                padding: const EdgeInsets.all(24),
                child: errorMessage != null
                    ? _buildErrorSection()
                    : _buildInstructionsSection(),
              ),
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
              'Position the QR code within the frame to add your new account',
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
      controller = MobileScannerController();
    });
    _slideController.forward();
  }

  // QR processing with loading states
  Future<void> _processQRCode(String qrCode) async {
    if (isProcessing) return;

    setState(() {
      isProcessing = true;
      errorMessage = null;
    });

    print('🔍 [QRScanner] Processing QR code: $qrCode');

    try {
      await controller?.stop();

      // Show validation loading
      _showLoading('Validating QR Code...');
      await Future.delayed(const Duration(milliseconds: 500));

      final parts = qrCode.split(';');

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

      print('✅ [QRScanner] QR code validation successful');

      // Update loading message
      _showLoading('Setting up account...');
      await Future.delayed(const Duration(milliseconds: 300));

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

      // Update loading message
      _showLoading('Connecting to server...');
      await Future.delayed(const Duration(milliseconds: 300));

      await accountManager.connectAllAccounts();

      // Success message
      _showLoading('Account added successfully!');
      await Future.delayed(const Duration(milliseconds: 800));

      _hideLoading();

      // Show success dialog and go back
      if (mounted) {
        await showOkAlertDialog(
          context: context,
          title: 'Success',
          message: 'Account "$fullName" has been added successfully!',
        );
        
        Navigator.of(context).pop(); // Go back to settings
      }
    } catch (e) {
      print('❌ [QRScanner] QR code processing failed: $e');
      _hideLoading();
      
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
    final paint = Paint()
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