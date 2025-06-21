// lib/widgets/theme_selector.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_service.dart' as services;
import '../themes/app_themes.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<services.ThemeService>(
      builder: (context, themeService, child) {
        return Scaffold(
          backgroundColor: AppThemes.getSettingsBackgroundColor(context),
          appBar: AppBar(
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
              'Appearance',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onBackground,
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
            ),
            centerTitle: true,
          ),
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                
                // Theme Options Section
                _buildThemeSection(context, themeService),
                
              
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildThemeSection(BuildContext context, services.ThemeService themeService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Theme',
            style: TextStyle(
              color: AppThemes.getSecondaryTextColor(context),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: AppThemes.getCardBackgroundColor(context),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _buildThemeOption(
                context,
                themeService,
                services.ThemeMode.system,
                'System',
                'Match device appearance',
                Icons.brightness_auto,
              ),
              _buildDivider(context),
              _buildThemeOption(
                context,
                themeService,
                services.ThemeMode.light,
                'Light',
                'Use light appearance',
                Icons.light_mode,
              ),
              _buildDivider(context),
              _buildThemeOption(
                context,
                themeService,
                services.ThemeMode.dark,
                'Dark',
                'Use dark appearance',
                Icons.dark_mode,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption(
    BuildContext context,
    services.ThemeService themeService,
    services.ThemeMode mode,
    String title,
    String subtitle,
    IconData icon,
  ) {
    final isSelected = themeService.themeMode == mode;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(10),
        onTap: () => themeService.setThemeMode(mode),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Theme Icon
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Title and Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    if (subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppThemes.getSecondaryTextColor(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Selection Indicator
              if (isSelected)
                Icon(
                  Icons.check,
                  color: Theme.of(context).colorScheme.primary,
                  size: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider(BuildContext context) {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 56),
      color: AppThemes.getDividerColor(context),
    );
  }


}