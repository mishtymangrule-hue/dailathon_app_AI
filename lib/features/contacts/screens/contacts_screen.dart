import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../contacts/bloc/contacts_bloc.dart';

/// Neumorphic Contacts screen with search + alphabetical tiles.
class ContactsScreen extends StatefulWidget {
  const ContactsScreen({super.key});

  @override
  State<ContactsScreen> createState() => _ContactsScreenState();
}

class _ContactsScreenState extends State<ContactsScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ContactsBloc>().add(const ContactsRequested());
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    context.read<ContactsBloc>().add(ContactSearched(_searchCtrl.text));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Contacts'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: NeuTextField(
              controller: _searchCtrl,
              hintText: 'Search contacts ...',
              prefixIcon: const Icon(Icons.search_rounded,
                  color: AppTheme.textHint, size: 20),
              suffixIcon: _searchCtrl.text.isNotEmpty
                  ? GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        context
                            .read<ContactsBloc>()
                            .add(const ContactSearched(''));
                      },
                      child: const Icon(Icons.close_rounded,
                          color: AppTheme.textHint, size: 18),
                    )
                  : null,
            ),
          ),
          Expanded(
            child: BlocBuilder<ContactsBloc, ContactsState>(
              builder: (_, state) {
                if (state is ContactsLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (state is ContactsLoaded) {
                  final contacts = state.contacts;
                  if (contacts.isEmpty) {
                    return const Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.people_outline_rounded,
                              size: 64, color: AppTheme.textHint),
                          SizedBox(height: 12),
                          Text(
                            'No contacts found',
                            style:
                                TextStyle(color: AppTheme.textSecondary),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding:
                        const EdgeInsets.fromLTRB(16, 0, 16, 28),
                    itemCount: contacts.length,
                    itemBuilder: (ctx, i) {
                      final c = contacts[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: NeuCard(
                          onTap: () =>
                              _showDetail(context, c),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppTheme.primary
                                      .withOpacity(0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: Center(
                                  child: Text(
                                    c.name[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: AppTheme.primary,
                                      fontWeight: FontWeight.w700,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      c.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      c.phoneNumber,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _call(c),
                                child: Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppTheme.catInterested
                                        .withOpacity(0.12),
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: const Icon(
                                    Icons.call_rounded,
                                    color: AppTheme.catInterested,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                }
                return const Center(
                    child: Text('Error loading contacts',
                        style:
                            TextStyle(color: AppTheme.textSecondary)));
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _call(dynamic c) async {
    final uri = Uri(
        scheme: 'tel',
        path: (c.phoneNumber as String).replaceAll(' ', ''));
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  void _showDetail(BuildContext context, dynamic c) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.bg,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLg)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  (c.name as String)[0].toUpperCase(),
                  style: const TextStyle(
                    color: AppTheme.primary,
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              c.name as String,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              c.phoneNumber as String,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: NeuButton(
                    label: 'Call',
                    icon: Icons.call_rounded,
                    color: AppTheme.catInterested,
                    onPressed: () {
                      Navigator.pop(ctx);
                      _call(c);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: NeuButton(
                    label: 'SMS',
                    icon: Icons.sms_rounded,
                    color: AppTheme.info,
                    onPressed: () async {
                      Navigator.pop(ctx);
                      final uri = Uri(
                          scheme: 'sms',
                          path: (c.phoneNumber as String)
                              .replaceAll(' ', ''));
                      if (await canLaunchUrl(uri)) await launchUrl(uri);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

