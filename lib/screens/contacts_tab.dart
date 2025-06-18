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
    Contact(name: 'John Doe', number: '101', avatar: '👤'),
    Contact(name: 'Jane Smith', number: '102', avatar: '👩'),
    Contact(name: 'Mike Johnson', number: '103', avatar: '👨'),
    Contact(name: 'Sarah Wilson', number: '104', avatar: '👩‍💼'),
    Contact(name: 'David Brown', number: '105', avatar: '👨‍💻'),
    Contact(name: 'Emma Davis', number: '106', avatar: '👩‍🎨'),
    Contact(name: 'Alex Miller', number: '107', avatar: '👨‍🎤'),
    Contact(name: 'Lisa Garcia', number: '108', avatar: '👩‍🔬'),
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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Search bar
        Container(
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _searchQuery = value;
              });
            },
            decoration: InputDecoration(
              hintText: 'Search ',
              hintStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, color: Colors.grey.shade500),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
        
        // Contacts list
        Expanded(
          child: _filteredContacts.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  itemCount: _filteredContacts.length,
                  itemBuilder: (context, index) {
                    final contact = _filteredContacts[index];
                    return _buildContactTile(contact);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return Center(
     
     
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off_outlined,
            size: 64,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            _searchQuery.isEmpty ? 'No contacts found' : 'No results for "$_searchQuery"',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
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
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    
    );
  }

  Widget _buildContactTile(Contact contact) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: CircleAvatar(
          backgroundColor: const Color(0xFF1501FF).withOpacity(0.1),
          radius: 24,
          child: Text(
            contact.avatar,
            style: const TextStyle(fontSize: 20),
          ),
        ),
        title: Text(
          contact.name,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Text(
          contact.number,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 14,
          ),
        ),
        trailing: Consumer<SipService>(
          builder: (context, sipService, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Call button
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment(-0.05, -1.0),
                      end: Alignment(0.05, 1.0),
                      colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: sipService.status == SipConnectionStatus.connected
                          ? () => sipService.makeCall(contact.number)
                          : null,
                      child: const Icon(
                        Icons.call,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // More options
                IconButton(
                  icon: Icon(
                    Icons.more_vert,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () => _showContactOptions(contact),
                ),
              ],
            );
          },
        ),
        onTap: () => _showContactDetails(contact),
      ),
    );
  }

  void _showContactDetails(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            
            // Contact avatar and name
            CircleAvatar(
              backgroundColor: const Color(0xFF1501FF).withOpacity(0.1),
              radius: 40,
              child: Text(
                contact.avatar,
                style: const TextStyle(fontSize: 32),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              contact.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              contact.number,
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 32),
            
            // Action buttons
            Consumer<SipService>(
              builder: (context, sipService, child) {
                return Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 56,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment(-0.05, -1.0),
                            end: Alignment(0.05, 1.0),
                            colors: [Color(0xFF1501FF), Color(0xFF00A3FF)],
                          ),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: sipService.status == SipConnectionStatus.connected
                                ? () {
                                    Navigator.pop(context);
                                    sipService.makeCall(contact.number);
                                  }
                                : null,
                            child: const Center(
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.call, color: Colors.white),
                                  SizedBox(width: 8),
                                  Text(
                                    'Call',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }

  void _showContactOptions(Contact contact) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle bar
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            
            ListTile(
              leading: const Icon(Icons.edit, color: Color(0xFF1501FF)),
              title: const Text('Edit Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement edit contact
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Contact'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement delete contact
              },
            ),
            
            SizedBox(height: MediaQuery.of(context).padding.bottom),
          ],
        ),
      ),
    );
  }
}

class Contact {
  final String name;
  final String number;
  final String avatar;

  Contact({
    required this.name,
    required this.number,
    required this.avatar,
  });
}