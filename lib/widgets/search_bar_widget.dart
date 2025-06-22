// lib/widgets/search_bar_widget.dart

import 'package:flutter/material.dart';
import '../themes/app_themes.dart';

class SearchBarWidget extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final String hintText;
  final EdgeInsets? margin;
  final double? height;

  const SearchBarWidget({
    super.key,
    required this.controller,
    required this.onChanged,
    this.hintText = 'Search',
    this.margin,
    this.height = 36,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.fromLTRB(16, 8, 16, 0),
      height: height,
      decoration: BoxDecoration(
        color: _getSearchBarColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        style: TextStyle(
          fontSize: 17,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppThemes.getSecondaryTextColor(context),
            fontSize: 17,
            fontWeight: FontWeight.normal,
          ),
          prefixIcon: Icon(
            Icons.search,
            color: AppThemes.getSecondaryTextColor(context),
            size: 20,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 30,
            maxWidth: 30,
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 0,
            vertical: 8,
          ),
        ),
      ),
    );
  }

  /// Get search bar color based on theme
  Color _getSearchBarColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }
}