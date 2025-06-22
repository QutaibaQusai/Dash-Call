// lib/screens/contacts_tab.dart - Rewritten with Clean Architecture (Same UI)

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../services/sip_service.dart';
import '../themes/app_themes.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Contact> _contacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          const SizedBox(height: 16), // Added top margin
          _buildSearchBar(),
          const SizedBox(height: 12), // Added spacing between search and list
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  /// Build search bar - keeping exact same UI
 Widget _buildSearchBar() {
  return Container(
    margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
    height: 36,
    decoration: BoxDecoration(
      color: _getSearchBarColor(),
      borderRadius: BorderRadius.circular(10),
    ),
    child: TextField(
      controller: _searchController,
      onChanged: _onSearchChanged,
      style: TextStyle(
        fontSize: 17,
        color: Theme.of(context).colorScheme.onSurface,
      ),
      decoration: InputDecoration(
        hintText: 'Search',
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
        prefixIconConstraints: BoxConstraints(
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

  /// Build contacts list
  Widget _buildContactsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredContacts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContactsListView();
  }

  /// Build loading state - keeping exact same UI
  Widget _buildLoadingState() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Build empty state - keeping exact same UI
  Widget _buildEmptyState() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64,
              color: AppThemes.getSecondaryTextColor(context),
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No contacts found'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 18,
                color: AppThemes.getSecondaryTextColor(context),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add some contacts to get started'
                  : 'Try searching for something else',
              style: TextStyle(
                fontSize: 14,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build contacts list view - keeping exact same UI
  Widget _buildContactsListView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _filteredContacts.length,
              itemBuilder: (context, index) {
                final contact = _filteredContacts[index];
                return _buildContactTile(
                  contact,
                  index == _filteredContacts.length - 1,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  /// Build contact tile - keeping exact same UI
  Widget _buildContactTile(Contact contact, bool isLast) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: _buildContactAvatar(contact),
            title: Text(
              contact.displayName,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Theme.of(context).colorScheme.onBackground,
              ),
            ),
            subtitle: Text(
              contact.number,
              style: TextStyle(
                fontSize: 15,
                color: AppThemes.getSecondaryTextColor(context),
              ),
            ),
            onTap: () => _showContactDetails(contact),
          ),
          // iOS-style separator line
          if (!isLast) _buildDivider(),
        ],
      ),
    );
  }

  /// Build contact avatar - keeping exact same UI
  Widget _buildContactAvatar(Contact contact) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppThemes.getSecondaryTextColor(context),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: contact.hasProperName
            ? Text(
                contact.initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              )
            : const Icon(
                Icons.person,
                color: Colors.white,
                size: 20,
              ),
      ),
    );
  }

  /// Build divider - keeping exact same UI
  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 72),
      color: AppThemes.getDividerColor(context),
    );
  }

  /// Show contact details - keeping exact same UI
  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildContactDetailsModal(contact),
    );
  }

  /// Build contact details modal - keeping exact same UI
  Widget _buildContactDetailsModal(Contact contact) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: AppThemes.getSettingsBackgroundColor(context),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle bar
          Container(
            width: 36,
            height: 5,
            margin: const EdgeInsets.only(top: 5),
            decoration: BoxDecoration(
              color: AppThemes.getDividerColor(context),
              borderRadius: BorderRadius.circular(3),
            ),
          ),

          // Header
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Text(
                  'Contact',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onBackground,
                  ),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 17,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Contact info section - keeping exact same UI
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: AppThemes.getCardBackgroundColor(context),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                // Contact avatar and name
                Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppThemes.getSecondaryTextColor(context),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: contact.hasProperName
                              ? Text(
                                  contact.initials,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 54,
                                    fontWeight: FontWeight.w300,
                                  ),
                                )
                              : const Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 60,
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        contact.displayName,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),

                // Phone section
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: AppThemes.getDividerColor(context),
                        width: 0.5,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        'mobile',
                        style: TextStyle(
                          fontSize: 17,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          contact.number,
                          style: TextStyle(
                            fontSize: 17,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      Consumer<SipService>(
                        builder: (context, sipService, child) {
                          return IconButton(
                            onPressed:
                                sipService.status == SipConnectionStatus.connected
                                    ? () {
                                        Navigator.pop(context);
                                        sipService.makeCall(contact.number);
                                      }
                                    : null,
                            icon: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color:
                                    sipService.status == SipConnectionStatus.connected
                                        ? const Color(0xFF34C759)
                                        : _getDisabledButtonColor(),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.phone,
                                color:
                                    sipService.status == SipConnectionStatus.connected
                                        ? Colors.white
                                        : AppThemes.getSecondaryTextColor(context),
                                size: 18,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Load contacts from device
  Future<void> _loadContacts() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (await fc.FlutterContacts.requestPermission()) {
        final contacts = await fc.FlutterContacts.getContacts(
          withProperties: true,
        );

        final contactList = <Contact>[];
        for (final contact in contacts) {
          if (contact.phones.isNotEmpty) {
            final processedContact = Contact.fromFlutterContact(contact);
            if (processedContact != null) {
              contactList.add(processedContact);
            }
          }
        }

        contactList.sort(
          (a, b) => a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()),
        );

        setState(() {
          _contacts = contactList;
          _isLoading = false;
        });
      } else {
        setState(() {
          _contacts = [];
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _contacts = [];
        _isLoading = false;
      });
    }
  }

  /// Handle search query change
  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  /// Get filtered contacts based on search query
  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.number.contains(_searchQuery);
    }).toList();
  }

  /// Get search bar color based on theme
  Color _getSearchBarColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }

  /// Get disabled button color based on theme
  Color _getDisabledButtonColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }
}

/// Contact model class - keeping same logic but cleaner structure
class Contact {
  final String displayName;
  final String number;

  const Contact({
    required this.displayName,
    required this.number,
  });

  /// Create Contact from FlutterContact
  static Contact? fromFlutterContact(fc.Contact flutterContact) {
    if (flutterContact.phones.isEmpty) return null;

    final displayName = flutterContact.displayName.isNotEmpty
        ? _cleanString(flutterContact.displayName)
        : _cleanString(
            '${flutterContact.name.first} ${flutterContact.name.last}'.trim(),
          );

    if (displayName.isEmpty) return null;

    final number = _cleanString(flutterContact.phones.first.number);
    if (number.isEmpty) return null;

    return Contact(
      displayName: displayName,
      number: number,
    );
  }

  /// Get initials from name
  String get initials {
    if (displayName.isEmpty) return '';

    final cleanName = _cleanString(displayName);
    if (cleanName.isEmpty) return '';

    final parts = cleanName
        .trim()
        .split(' ')
        .where((part) => part.isNotEmpty)
        .toList();

    if (parts.isEmpty) return '';

    if (parts.length >= 2) {
      // First letter of first name + first letter of last name
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      // Just first letter if only one name
      return parts[0][0].toUpperCase();
    }
  }

  /// Check if contact has a proper name (not just a number)
  bool get hasProperName {
    if (displayName.isEmpty) return false;

    final cleanName = _cleanString(displayName);
    if (cleanName.isEmpty) return false;

    // Check if name contains only digits, spaces, +, -, (, )
    final numberPattern = RegExp(r'^[\d\s\+\-\(\)]+$');
    return !numberPattern.hasMatch(cleanName);
  }

  /// Clean string to remove invalid UTF-16 characters
  static String _cleanString(String input) {
    if (input.isEmpty) return input;

    // Remove invalid UTF-16 characters and control characters
    return input.runes
        .where((rune) => rune >= 32 && rune <= 126 || rune >= 160)
        .map((rune) => String.fromCharCode(rune))
        .join();
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Contact &&
          runtimeType == other.runtimeType &&
          displayName == other.displayName &&
          number == other.number;

  @override
  int get hashCode => displayName.hashCode ^ number.hashCode;

  @override
  String toString() => 'Contact(name: $displayName, number: $number)';
}