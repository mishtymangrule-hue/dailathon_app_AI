import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/utils/call_utils.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() { _isLoading = true; });

    // Fetch contacts with phone numbers only
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,  // includes phone numbers
      withPhoto: false,       // skip photos for performance
    );

    // Sort alphabetically
    contacts.sort((a, b) =>
        a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase()));

    if (!mounted) return;
    setState(() {
      _allContacts = contacts;
      _filteredContacts = contacts;
      _isLoading = false;
    });
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredContacts = _allContacts.where((c) {
        final nameMatch = c.displayName.toLowerCase().contains(query);
        final numberMatch = c.phones.any(
          (p) => p.number.contains(query),
        );
        return nameMatch || numberMatch;
      }).toList();
    });
  }

  // Group contacts by first letter
  Map<String, List<Contact>> _groupContacts(List<Contact> contacts) {
    final Map<String, List<Contact>> grouped = {};
    for (final contact in contacts) {
      final letter = contact.displayName.isNotEmpty
          ? contact.displayName[0].toUpperCase()
          : '#';
      grouped.putIfAbsent(letter, () => []).add(contact);
    }
    return Map.fromEntries(
      grouped.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
              ),
            ),
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await FlutterContacts.openExternalInsert();
        },
        backgroundColor: Colors.blue,
        child: const Icon(Icons.person_add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    // No contacts found
    if (_filteredContacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No contacts found on device'
                  : 'No results for "${_searchController.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Grouped contact list
    final grouped = _groupContacts(_filteredContacts);

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final letter = grouped.keys.elementAt(index);
          final contacts = grouped[letter]!;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section header
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 6),
                color: Colors.grey.shade100,
                width: double.infinity,
                child: Text(
                  letter,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ),
              // Contacts in this section
              ...contacts.map((contact) => _ContactTile(contact: contact)),
            ],
          );
        },
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  const _ContactTile({required this.contact});

  @override
  Widget build(BuildContext context) {
    final number = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : null;
    final initial = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '?';

    return ListTile(
      onTap: () => _showContactDetail(context),
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(initial,
            style: const TextStyle(color: Colors.white,
                fontWeight: FontWeight.bold)),
      ),
      title: Text(contact.displayName,
          style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: number != null
          ? Text(number, style: const TextStyle(color: Colors.grey))
          : const Text('No number', style: TextStyle(color: Colors.grey)),
      trailing: number != null
          ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.message, color: Colors.blue),
                  onPressed: () => CallUtils.openSms(context, number),
                ),
                IconButton(
                  icon: const Icon(Icons.call, color: Colors.green),
                  onPressed: () => CallUtils.makeCall(context, number),
                ),
              ],
            )
          : null,
    );
  }

  void _showContactDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        final initial = contact.displayName.isNotEmpty
            ? contact.displayName[0].toUpperCase()
            : '?';
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                child: Text(initial,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              Text(contact.displayName,
                  style: const TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              // List all phone numbers
              ...contact.phones.map((phone) => ListTile(
                    leading: const Icon(Icons.phone),
                    title: Text(phone.number),
                    subtitle: Text(phone.label.name),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.message, color: Colors.blue),
                          onPressed: () {
                            Navigator.pop(ctx);
                            CallUtils.openSms(context, phone.number);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.chat, color: Colors.green),
                          onPressed: () {
                            Navigator.pop(ctx);
                            CallUtils.openWhatsApp(context, phone.number);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.call, color: Colors.green),
                          onPressed: () {
                            Navigator.pop(ctx);
                            CallUtils.makeCall(context, phone.number);
                          },
                        ),
                      ],
                    ),
                  )),
              if (contact.phones.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No phone numbers',
                      style: TextStyle(color: Colors.grey)),
                ),
            ],
          ),
        );
      },
    );
  }
}

