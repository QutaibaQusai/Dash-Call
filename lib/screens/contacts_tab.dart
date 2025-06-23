// lib/screens/contacts_tab.dart - Updated with Shared Action Sheet

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';
import '../widgets/search_bar_widget.dart';
import '../widgets/shared_contact_action_sheet.dart'; // NEW: Import shared component

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
          const SizedBox(height: 16),
          SearchBarWidget(
            controller: _searchController,
            onChanged: _onSearchChanged,
            hintText: 'Search',
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildContactsList()),
        ],
      ),
    );
  }

  Widget _buildContactsList() {
    if (_isLoading) {
      return _buildLoadingState();
    }

    if (_filteredContacts.isEmpty) {
      return _buildEmptyState();
    }

    return _buildContactsListView();
  }

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

  Widget _buildContactsListView() {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
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
    );
  }

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
            onTap: () => _showContactDetails(contact), // UPDATED: Use shared sheet
          ),
          if (!isLast) _buildDivider(),
        ],
      ),
    );
  }

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

  Widget _buildDivider() {
    return Container(
      height: 0.5,
      margin: const EdgeInsets.only(left: 72),
      color: AppThemes.getDividerColor(context),
    );
  }

  // UPDATED: Use shared action sheet helper
  void _showContactDetails(Contact contact) {
    ContactActionSheetHelper.show(
      context: context,
      displayName: contact.displayName,
      phoneNumber: contact.number,
      showDeleteAction: false, // Contacts don't have delete action
    );
  }

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

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
  }

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.displayName.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.number.contains(_searchQuery);
    }).toList();
  }
}

class Contact {
  final String displayName;
  final String number;

  const Contact({
    required this.displayName,
    required this.number,
  });

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
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return parts[0][0].toUpperCase();
    }
  }

  bool get hasProperName {
    if (displayName.isEmpty) return false;

    final cleanName = _cleanString(displayName);
    if (cleanName.isEmpty) return false;

    final numberPattern = RegExp(r'^[\d\s\+\-\(\)]+$');
    return !numberPattern.hasMatch(cleanName);
  }

  static String _cleanString(String input) {
    if (input.isEmpty) return input;

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