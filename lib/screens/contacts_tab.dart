// lib/screens/contacts_tab.dart - Updated with Multi-Account Support

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../services/multi_account_manager.dart';
import '../services/sip_service.dart';
import '../themes/app_themes.dart';
import '../widgets/search_bar_widget.dart';

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
            onTap: () => _showContactDetails(contact),
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

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildContactDetailsModal(contact),
    );
  }

  Widget _buildContactDetailsModal(Contact contact) {
    return Consumer<MultiAccountManager>(
      builder: (context, accountManager, child) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: BoxDecoration(
            color: AppThemes.getSettingsBackgroundColor(context),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                width: 36,
                height: 5,
                margin: const EdgeInsets.only(top: 5),
                decoration: BoxDecoration(
                  color: AppThemes.getDividerColor(context),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
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
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: AppThemes.getCardBackgroundColor(context),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(
                  children: [
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
                          _buildCallButton(accountManager, contact.number),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // NEW: Show active account info if available
              if (accountManager.hasAccounts) ...[
                const SizedBox(height: 20),
                _buildActiveAccountInfo(accountManager),
              ],
            ],
          ),
        );
      },
    );
  }

  /// NEW: Build call button with multi-account support
  Widget _buildCallButton(MultiAccountManager accountManager, String number) {
    final activeSipService = accountManager.activeSipService;
    final canCall = activeSipService?.status == SipConnectionStatus.connected;
    
    return IconButton(
      onPressed: canCall
          ? () {
              Navigator.pop(context);
              activeSipService!.makeCall(number);
            }
          : null,
      icon: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: canCall
              ? const Color(0xFF34C759)
              : _getDisabledButtonColor(),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.phone,
          color: canCall
              ? Colors.white
              : AppThemes.getSecondaryTextColor(context),
          size: 18,
        ),
      ),
    );
  }

  /// NEW: Build active account info section
  Widget _buildActiveAccountInfo(MultiAccountManager accountManager) {
    final activeAccount = accountManager.activeAccount;
    final activeSipService = accountManager.activeSipService;
    
    if (activeAccount == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.orange.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning, color: Colors.orange, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'No active account selected',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      );
    }

    final connectionStatus = activeSipService?.status ?? SipConnectionStatus.disconnected;
    final statusColor = _getConnectionStatusColor(connectionStatus);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemes.getCardBackgroundColor(context),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          // Account avatar
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: _getAvatarColor(activeAccount.id),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                _getInitials(activeAccount.displayName),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 12),
          
          // Account info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Calling from: ${activeAccount.displayName}',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getConnectionStatusText(connectionStatus),
                      style: TextStyle(
                        fontSize: 12,
                        color: AppThemes.getSecondaryTextColor(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
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

  Color _getDisabledButtonColor() {
    return Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2C2C2E)
        : const Color(0xFFE5E5EA);
  }

  /// Get avatar color for account
  Color _getAvatarColor(String accountId) {
    final colors = [
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.red,
      Colors.teal,
      Colors.indigo,
      Colors.pink,
    ];
    
    final index = accountId.hashCode % colors.length;
    return colors[index.abs()];
  }

  /// Get initials from name
  String _getInitials(String name) {
    if (name.isEmpty) return '?';
    
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      return name[0].toUpperCase();
    }
  }

  /// Get connection status color
  Color _getConnectionStatusColor(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return Colors.green;
      case SipConnectionStatus.connecting:
        return Colors.orange;
      case SipConnectionStatus.error:
        return Colors.red;
      case SipConnectionStatus.disconnected:
        return Colors.grey;
    }
  }

  /// Get connection status text
  String _getConnectionStatusText(SipConnectionStatus status) {
    switch (status) {
      case SipConnectionStatus.connected:
        return 'Connected';
      case SipConnectionStatus.connecting:
        return 'Connecting';
      case SipConnectionStatus.error:
        return 'Error';
      case SipConnectionStatus.disconnected:
        return 'Offline';
    }
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