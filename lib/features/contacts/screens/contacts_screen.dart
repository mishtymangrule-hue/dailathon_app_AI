import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import '../../../core/utils/call_utils.dart';

class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Contact> _allContacts = [];
  List<Contact> _filteredContacts = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadContacts();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadContacts() async {
    setState(() { _isLoading = true; });

    // Fetch contacts with phone numbers and photos
    final contacts = await FlutterContacts.getContacts(
      withProperties: true,  // includes phone numbers
      withPhoto: true,        // include thumbnails
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
          preferredSize: const Size.fromHeight(100),
          child: Column(
            children: [
              Padding(
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
              TabBar(
                controller: _tabController,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white60,
                indicatorColor: Colors.white,
                tabs: const [
                  Tab(text: 'All'),
                  Tab(icon: Icon(Icons.star), text: 'Favorites'),
                ],
              ),
            ],
          ),
        ),
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddContactForm(context),
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

    return TabBarView(
      controller: _tabController,
      children: [
        _buildContactList(_filteredContacts),
        _buildContactList(
            _filteredContacts.where((c) => c.isStarred).toList()),
      ],
    );
  }

  Widget _buildContactList(List<Contact> contacts) {
    // No contacts found
    if (contacts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _searchController.text.isEmpty
                  ? 'No contacts found'
                  : 'No results for "${_searchController.text}"',
              style: const TextStyle(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    // Grouped contact list
    final grouped = _groupContacts(contacts);

    return RefreshIndicator(
      onRefresh: _loadContacts,
      child: ListView.builder(
        itemCount: grouped.length,
        itemBuilder: (context, index) {
          final letter = grouped.keys.elementAt(index);
          final groupContacts = grouped[letter]!;
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
              ...groupContacts.map((contact) => _ContactTile(
                    contact: contact,
                    onEdit: () => _showEditContactForm(context, contact),
                  )),
            ],
          );
        },
      ),
    );
  }

  void _showAddContactForm(BuildContext context) {
    _showContactForm(context, null);
  }

  void _showEditContactForm(BuildContext context, Contact contact) {
    _showContactForm(context, contact);
  }

  void _showContactForm(BuildContext context, Contact? existing) {
    final nameController =
        TextEditingController(text: existing?.displayName ?? '');
    final phoneController = TextEditingController(
        text: existing?.phones.isNotEmpty == true
            ? existing!.phones.first.number
            : '');
    final isEdit = existing != null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isEdit ? 'Edit Contact' : 'Add Contact',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: phoneController,
              decoration: const InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final phone = phoneController.text.trim();
                if (name.isEmpty || phone.isEmpty) return;

                final contact = existing ?? Contact();
                contact.name = Name(first: name);
                contact.phones = [Phone(phone)];

                if (isEdit) {
                  await FlutterContacts.updateContact(contact);
                } else {
                  await FlutterContacts.insertContact(contact);
                }

                if (ctx.mounted) Navigator.pop(ctx);
                _loadContacts();
              },
              child: Text(isEdit ? 'Save' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final Contact contact;
  final VoidCallback? onEdit;
  const _ContactTile({required this.contact, this.onEdit});

  @override
  Widget build(BuildContext context) {
    final number = contact.phones.isNotEmpty
        ? contact.phones.first.number
        : null;
    final initial = contact.displayName.isNotEmpty
        ? contact.displayName[0].toUpperCase()
        : '?';
    final Uint8List? photo = contact.photo;

    return ListTile(
      onTap: () => _showContactDetail(context),
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        backgroundImage: photo != null ? MemoryImage(photo) : null,
        child: photo == null
            ? Text(initial,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold))
            : null,
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
        final Uint8List? photo = contact.photo;
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue,
                backgroundImage: photo != null ? MemoryImage(photo) : null,
                child: photo == null
                    ? Text(initial,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 32,
                            fontWeight: FontWeight.bold))
                    : null,
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
              const SizedBox(height: 12),
              if (onEdit != null)
                OutlinedButton.icon(
                  onPressed: () {
                    Navigator.pop(ctx);
                    onEdit!();
                  },
                  icon: const Icon(Icons.edit),
                  label: const Text('Edit Contact'),
                ),
            ],
          ),
        );
      },
    );
  }
}

