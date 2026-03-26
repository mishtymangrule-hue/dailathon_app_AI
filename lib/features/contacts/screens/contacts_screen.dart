import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../contacts/bloc/contacts_bloc.dart';

/// ContactsScreen displays alphabetically indexed contacts.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({Key? key}) : super(key: key);

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    context.read<ContactsBloc>().add(
          ContactSearched(_searchController.text),
        );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Contacts'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search contacts...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                        },
                      )
                    : null,
              ),
            ),
          ),
          // Contacts List
          Expanded(
            child: BlocBuilder<ContactsBloc, ContactsState>(
              builder: (context, state) {
                if (state is ContactsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is ContactsLoaded) {
                  final contacts = state.contacts;

                  if (contacts.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.people,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No contacts found',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  color: Colors.grey,
                                ),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: contacts.length,
                    itemBuilder: (context, index) {
                      final contact = contacts[index];
                      return _ContactTile(
                        contact: contact,
                        onTap: () {
                          _showContactDetail(context, contact);
                        },
                      );
                    },
                  );
                }

                return const Center(child: Text('Error loading contacts'));
              },
            ),
          ),
        ],
      ),
    );

  void _showContactDetail(BuildContext context, dynamic contact) {
    showModalBottomSheet(
      context: context,
      builder: (ctx) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 40,
                  child: Text(
                    contact.name[0].toUpperCase(),
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  contact.name,
                  style: Theme.of(ctx).textTheme.titleLarge,
                ),
                Text(
                  contact.phoneNumber,
                  style: Theme.of(ctx).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.call),
            title: const Text('Call'),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: Trigger call via MethodChannel
            },
          ),
          ListTile(
            leading: const Icon(Icons.message),
            title: const Text('Send SMS'),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: Open SMS app
            },
          ),
          ListTile(
            leading: const Icon(Icons.block),
            title: const Text('Block Number'),
            onTap: () {
              Navigator.pop(ctx);
              // TODO: Block number
            },
          ),
        ],
      ),
    );
  }
}

/// Contact list tile.
class _ContactTile extends StatelessWidget {

  const _ContactTile({
    required this.contact,
    required this.onTap,
  });
  final dynamic contact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
      child: InkWell(
        onTap: onTap,
        child: ListTile(
          leading: CircleAvatar(
            child: Text(contact.name[0].toUpperCase()),
          ),
          title: Text(contact.name),
          subtitle: Text(contact.phoneNumber),
          trailing: IconButton(
            icon: const Icon(Icons.call),
            onPressed: () {
              // TODO: Quick call
            },
          ),
        ),
      ),
    );
}
