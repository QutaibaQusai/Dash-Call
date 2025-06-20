import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import '../services/sip_service.dart';

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
            final name =
                contact.displayName.isNotEmpty
                    ? _cleanString(contact.displayName)
                    : _cleanString(
                      '${contact.name.first} ${contact.name.last}'.trim(),
                    );

            if (name.isNotEmpty) {
              contactList.add(
                Contact(
                  name: name,
                  number: _cleanString(contact.phones.first.number),
                ),
              );
            }
          }
        }

        contactList.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
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

  List<Contact> get _filteredContacts {
    if (_searchQuery.isEmpty) {
      return _contacts;
    }
    return _contacts.where((contact) {
      return contact.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          contact.number.contains(_searchQuery);
    }).toList();
  }

  // Clean string to remove invalid UTF-16 characters
  String _cleanString(String input) {
    if (input.isEmpty) return input;

    // Remove invalid UTF-16 characters and control characters
    return input.runes
        .where((rune) => rune >= 32 && rune <= 126 || rune >= 160)
        .map((rune) => String.fromCharCode(rune))
        .join();
  }

  // Generate first letter from first name and last name
  String _getInitials(String name) {
    if (name.isEmpty) return '';

    final cleanName = _cleanString(name);
    if (cleanName.isEmpty) return '';

    final parts =
        cleanName.trim().split(' ').where((part) => part.isNotEmpty).toList();

    if (parts.isEmpty) return '';

    if (parts.length >= 2) {
      // First letter of first name + first letter of last name
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else {
      // Just first letter if only one name
      return parts[0][0].toUpperCase();
    }
  }

  // Check if contact has a proper name or just a number
  bool _hasProperName(String name) {
    if (name.isEmpty) return false;

    final cleanName = _cleanString(name);
    if (cleanName.isEmpty) return false;

    // Check if name contains only digits, spaces, +, -, (, )
    final numberPattern = RegExp(r'^[\d\s\+\-\(\)]+$');
    return !numberPattern.hasMatch(cleanName);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFE5E5EA),
              borderRadius: BorderRadius.circular(10),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
              style: const TextStyle(fontSize: 17, fontFamily: '.SF UI Text'),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: TextStyle(
                  color: const Color(0xFF8E8E93),
                  fontSize: 17,
                  fontFamily: '.SF UI Text',
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  color: Color(0xFF8E8E93),
                  size: 20,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
              ),
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? Container(
                      color: Colors.white,
                      child: const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFF0077F9),
                        ),
                      ),
                    )
                    : _filteredContacts.isEmpty
                    ? _buildEmptyState()
                    : Container(
                      color: Colors.white,
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
                    ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_outline, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              _searchQuery.isEmpty
                  ? 'No contacts found'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF UI Text',
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isEmpty
                  ? 'Add some contacts to get started'
                  : 'Try searching for something else',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade500,
                fontFamily: '.SF UI Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(Contact contact, bool isLast) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFF8E8E93),
                shape: BoxShape.circle,
              ),
              child: Center(
                child:
                    _hasProperName(contact.name)
                        ? Text(
                          _getInitials(contact.name),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            fontFamily: '.SF UI Text',
                          ),
                        )
                        : const Icon(
                          Icons.person,
                          color: Colors.white,
                          size: 20,
                        ),
              ),
            ),
            title: Text(
              _cleanString(contact.name),
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontFamily: '.SF UI Text',
              ),
            ),
            onTap: () => _showContactDetails(contact),
          ),

          // iOS-style separator line
          if (!isLast)
            Container(
              height: 0.5,
              margin: const EdgeInsets.only(left: 72),
              color: const Color(0xFFC6C6C8),
            ),
        ],
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder:
          (context) => Container(
            height: MediaQuery.of(context).size.height * 0.9,
            decoration: const BoxDecoration(
              color: Color(0xFFF2F2F7),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                // Handle bar
                Container(
                  width: 36,
                  height: 5,
                  margin: const EdgeInsets.only(top: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C6C8),
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
                      const Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: '.SF UI Text',
                        ),
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text(
                            'Cancel',
                            style: TextStyle(
                              fontSize: 17,
                              color: Color(0xFF007AFF),
                              fontFamily: '.SF UI Text',
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact info section
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
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
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E8E93),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child:
                                    _hasProperName(contact.name)
                                        ? Text(
                                          _getInitials(contact.name),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 54,
                                            fontWeight: FontWeight.w300,
                                            fontFamily: '.SF UI Text',
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
                              _cleanString(contact.name),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w600,
                                color: Colors.black,
                                fontFamily: '.SF UI Text',
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
                        decoration: const BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: Color(0xFFC6C6C8),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Text(
                              'mobile',
                              style: TextStyle(
                                fontSize: 17,
                                color: Color(0xFF007AFF),
                                fontFamily: '.SF UI Text',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                _cleanString(contact.number),
                                style: const TextStyle(
                                  fontSize: 17,
                                  color: Colors.black,
                                  fontFamily: '.SF UI Text',
                                ),
                              ),
                            ),
                            Consumer<SipService>(
                              builder: (context, sipService, child) {
                                return IconButton(
                                  onPressed:
                                      sipService.status ==
                                              SipConnectionStatus.connected
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
                                          sipService.status ==
                                                  SipConnectionStatus.connected
                                              ? const Color(0xFF34C759)
                                              : const Color(0xFFE5E5EA),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.phone,
                                      color:
                                          sipService.status ==
                                                  SipConnectionStatus.connected
                                              ? Colors.white
                                              : const Color(0xFF8E8E93),
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
          ),
    );
  }
}

class Contact {
  final String name;
  final String number;

  Contact({required this.name, required this.number});
}
