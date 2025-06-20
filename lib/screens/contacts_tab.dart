import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/sip_service.dart';

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  // Sample contacts data - in a real app, this would come from a database or API
  final List<Contact> _contacts = [
    Contact(name: 'John Doe', number: '101'),
    Contact(name: 'Jane Smith', number: '102'),
    Contact(name: 'Mike Johnson', number: '103'),
    Contact(name: 'Sarah Wilson', number: '104'),
    Contact(name: 'David Brown', number: '105'),
    Contact(name: 'Emma Davis', number: '106'),
    Contact(name: 'Alex Miller', number: '107'),
    Contact(name: 'Lisa Garcia', number: '108'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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

  // Generate first letter from name
  String _getInitials(String name) {
    if (name.isEmpty) return '';
    return name[0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Proportional scaling system
            final baseWidth = 375.0; // iPhone SE reference
            final scaleWidth = constraints.maxWidth / baseWidth;
            final scaleHeight = constraints.maxHeight / 667.0;
            final scale = (scaleWidth + scaleHeight) / 2;

            return Column(
              children: [
                Container(
                  margin: EdgeInsets.fromLTRB(
                    16 * scale,
                    8 * scale,
                    16 * scale,
                    0,
                  ),
                  height: 36 * scale,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E5EA),
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    style: TextStyle(
                      fontSize: 17 * scale,
                      fontFamily: '.SF UI Text',
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search',
                      hintStyle: TextStyle(
                        color: const Color(0xFF8E8E93),
                        fontSize: 17 * scale,
                        fontFamily: '.SF UI Text',
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        color: const Color(0xFF8E8E93),
                        size: 20 * scale,
                      ),
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 8 * scale,
                        vertical: 8 * scale,
                      ),
                    ),
                  ),
                ),

                Expanded(
                  child:
                      _filteredContacts.isEmpty
                          ? _buildEmptyState(scale)
                          : Container(
                            color: Colors.white,
                            child: ListView.builder(
                              itemCount: _filteredContacts.length,
                              itemBuilder: (context, index) {
                                final contact = _filteredContacts[index];
                                return _buildContactTile(
                                  contact,
                                  index == _filteredContacts.length - 1,
                                  scale,
                                );
                              },
                            ),
                          ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(double scale) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline,
              size: 64 * scale,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 16 * scale),
            Text(
              _searchQuery.isEmpty
                  ? 'No contacts found'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(
                fontSize: 18 * scale,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w500,
                fontFamily: '.SF UI Text',
              ),
            ),
            SizedBox(height: 8 * scale),
            Text(
              _searchQuery.isEmpty
                  ? 'Add some contacts to get started'
                  : 'Try searching for something else',
              style: TextStyle(
                fontSize: 14 * scale,
                color: Colors.grey.shade500,
                fontFamily: '.SF UI Text',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactTile(Contact contact, bool isLast, double scale) {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.symmetric(
              horizontal: 16 * scale,
              vertical: 8 * scale,
            ),
            leading: Container(
              width: 40 * scale,
              height: 40 * scale,
              decoration: const BoxDecoration(
                color: Color(0xFF8E8E93),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  _getInitials(contact.name),
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16 * scale,
                    fontWeight: FontWeight.w500,
                    fontFamily: '.SF UI Text',
                  ),
                ),
              ),
            ),
            title: Text(
              contact.name,
              style: TextStyle(
                fontSize: 17 * scale,
                fontWeight: FontWeight.w400,
                color: Colors.black,
                fontFamily: '.SF UI Text',
              ),
            ),
            onTap: () => _showContactDetails(contact, scale),
          ),

          // iOS-style separator line
          if (!isLast)
            Container(
              height: 0.5,
              margin: EdgeInsets.only(left: 72 * scale),
              color: const Color(0xFFC6C6C8),
            ),
        ],
      ),
    );
  }

  void _showContactDetails(Contact contact, double scale) {
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
                  width: 36 * scale,
                  height: 5 * scale,
                  margin: EdgeInsets.only(top: 5 * scale),
                  decoration: BoxDecoration(
                    color: const Color(0xFFC6C6C8),
                    borderRadius: BorderRadius.circular(3 * scale),
                  ),
                ),

                // Header
                Container(
                  height: 44 * scale,
                  padding: EdgeInsets.symmetric(horizontal: 16 * scale),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 17 * scale,
                            color: const Color(0xFF007AFF),
                            fontFamily: '.SF UI Text',
                          ),
                        ),
                      ),
                      Text(
                        'Contact',
                        style: TextStyle(
                          fontSize: 17 * scale,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                          fontFamily: '.SF UI Text',
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Edit contact
                        },
                        child: Text(
                          'Edit',
                          style: TextStyle(
                            fontSize: 17 * scale,
                            color: const Color(0xFF007AFF),
                            fontFamily: '.SF UI Text',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 20 * scale),

                // Contact info section
                Container(
                  margin: EdgeInsets.symmetric(horizontal: 16 * scale),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10 * scale),
                  ),
                  child: Column(
                    children: [
                      // Contact avatar and name
                      Container(
                        padding: EdgeInsets.all(20 * scale),
                        child: Column(
                          children: [
                            Container(
                              width: 120 * scale,
                              height: 120 * scale,
                              decoration: const BoxDecoration(
                                color: Color(0xFF8E8E93),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  _getInitials(contact.name),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 54 * scale,
                                    fontWeight: FontWeight.w300,
                                    fontFamily: '.SF UI Text',
                                  ),
                                ),
                              ),
                            ),
                            SizedBox(height: 16 * scale),
                            Text(
                              contact.name,
                              style: TextStyle(
                                fontSize: 24 * scale,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: 16 * scale,
                          vertical: 12 * scale,
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
                            Text(
                              'mobile',
                              style: TextStyle(
                                fontSize: 17 * scale,
                                color: const Color(0xFF007AFF),
                                fontFamily: '.SF UI Text',
                              ),
                            ),
                            SizedBox(width: 16 * scale),
                            Expanded(
                              child: Text(
                                contact.number,
                                style: TextStyle(
                                  fontSize: 17 * scale,
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
                                    width: 32 * scale,
                                    height: 32 * scale,
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
                                      size: 18 * scale,
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
