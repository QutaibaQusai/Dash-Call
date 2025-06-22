// lib/screens/about_page.dart - Updated with URL Launcher

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // ADD THIS IMPORT
import '../themes/app_themes.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context),
      appBar: _buildAppBar(context),
      body: _buildBody(context),
    );
  }

  /// Build app bar
  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: AppThemes.getSettingsBackgroundColor(context),
      elevation: 0,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.primary,
          size: 20,
        ),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        'About DashCall',
        style: TextStyle(
          color: Theme.of(context).colorScheme.onBackground,
          fontSize: 17,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  /// Build main body
  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final scale = _calculateScale(constraints);
          return SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 40 * scale),
                  _buildAppInfoSection(context, scale),
                  SizedBox(height: 32 * scale),
                  _buildBasicInfoSection(context, scale),
                  SizedBox(height: 50 * scale),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  /// Calculate responsive scale
  double _calculateScale(BoxConstraints constraints) {
    const baseWidth = 375.0;
    const baseHeight = 667.0;
    final scaleWidth = constraints.maxWidth / baseWidth;
    final scaleHeight = constraints.maxHeight / baseHeight;
    return (scaleWidth + scaleHeight) / 2;
  }

  /// App Information Section
  Widget _buildAppInfoSection(BuildContext context, double scale) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.all(16 * scale),
      padding: EdgeInsets.all(32 * scale),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(20 * scale),
      ),
      child: Column(
        children: [
          // App Icon
          Container(
            width: 120 * scale,
            height: 120 * scale,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24 * scale),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24 * scale),
              child: Image.asset(
                'assets/icon/dashcall_icon.png',
                width: 120 * scale,
                height: 120 * scale,
                fit: BoxFit.cover,
              ),
            ),
          ),
          
          SizedBox(height: 24 * scale),
          
          // App Name
          Text(
            'DashCall',
            style: TextStyle(
              fontSize: 32 * scale,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          
          SizedBox(height: 8 * scale),
          
          // Version
          Text(
            'Version 1.0.0',
            style: TextStyle(
              fontSize: 16 * scale,
              color: AppThemes.getSecondaryTextColor(context),
            ),
          ),
          
          SizedBox(height: 16 * scale),
          
          // Description
          Text(
            'A modern VoIP calling application. DashCall provides high-quality voice calls with an intuitive interface.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15 * scale,
              color: AppThemes.getSecondaryTextColor(context),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  /// Basic Information Section - UPDATED: Added onTap for MUJEER
  Widget _buildBasicInfoSection(BuildContext context, double scale) {
    return _buildSection(
      context: context,
      title: 'Informations',
      scale: scale,
      children: [
        _buildInfoItem(
          context: context,
          imagePath: 'assets/images/mujeer_logo.jpg', 
          iconColor: Colors.blue, 
          title: 'Built with',
          subtitle: 'MUJEER Company',
          scale: scale,
          onTap: () => _openMujeerWebsite(), // NEW: Added onTap callback
        ),
        _buildDivider(context),
        _buildInfoItem(
          context: context,
          icon: CupertinoIcons.circle,
          iconColor: Colors.grey,
          title: 'Copyright',
          subtitle: '© 2025 DashCall. All rights reserved.',
          scale: scale,
        ),
      ],
    );
  }

  /// NEW: Method to open MUJEER website
  Future<void> _openMujeerWebsite() async {
    final Uri url = Uri.parse('https://mujeer.com/en');
    
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(
          url,
          mode: LaunchMode.externalApplication, // Opens in external browser
        );
        print('✅ [AboutPage] Successfully opened MUJEER website');
      } else {
        print('❌ [AboutPage] Could not launch URL: $url');
        // You could show a snackbar here if needed
      }
    } catch (e) {
      print('❌ [AboutPage] Error launching URL: $e');
      // You could show an error dialog here if needed
    }
  }

  /// Generic section builder
  Widget _buildSection({
    required BuildContext context,
    required String title,
    required List<Widget> children,
    required double scale,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16 * scale, vertical: 8 * scale),
          child: Text(
            title,
            style: TextStyle(
              color: AppThemes.getSecondaryTextColor(context),
              fontSize: 13 * scale,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: EdgeInsets.symmetric(horizontal: 16 * scale),
          decoration: BoxDecoration(
            color: AppThemes.getCardBackgroundColor(context),
            borderRadius: BorderRadius.circular(12 * scale),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }

  /// Info item builder - UPDATED: Added optional onTap callback
  Widget _buildInfoItem({
    required BuildContext context,
    IconData? icon,
    String? imagePath,
    required Color iconColor,
    required String title,
    required String subtitle,
    required double scale,
    VoidCallback? onTap, // NEW: Optional onTap callback
  }) {
    Widget content = Padding(
      padding: EdgeInsets.all(16 * scale),
      child: Row(
        children: [
          Container(
            width: 36 * scale,
            height: 36 * scale, 
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8 * scale),
            ),
            child: imagePath != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8 * scale), 
                    child: Image.asset(
                      imagePath,
                      width: 36 * scale, 
                      height: 36 * scale, 
                      fit: BoxFit.cover, 
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          padding: EdgeInsets.all(8 * scale), 
                          child: Icon(
                            icon ?? CupertinoIcons.photo,
                            color: iconColor,
                            size: 20 * scale,
                          ),
                        );
                      },
                    ),
                  )
                : Container(
                    padding: EdgeInsets.all(8 * scale),
                    child: Icon(
                      icon ?? CupertinoIcons.photo,
                      color: iconColor,
                      size: 20 * scale,
                    ),
                  ),
          ),
          SizedBox(width: 12 * scale),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 2 * scale),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13 * scale,
                    color: AppThemes.getSecondaryTextColor(context),
                  ),
                ),
              ],
            ),
          ),
       
        ],
      ),
    );

    // NEW: Wrap with InkWell if onTap is provided
    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12 * scale),
        child: content,
      );
    }

    return content;
  }
  
  /// Divider builder
  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 56),
      color: AppThemes.getDividerColor(context),
    );
  }
}