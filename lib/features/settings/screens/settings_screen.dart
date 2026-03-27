import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/settings_bloc.dart';

/// Settings screen for managing call forwarding and other app settings.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _forwardingNumberController;

  @override
  void initState() {
    super.initState();
    _forwardingNumberController = TextEditingController();
  }

  @override
  void dispose() {
    _forwardingNumberController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) {
        if (state is SettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
        if (state is SettingsSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Settings updated successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Settings'),
          centerTitle: true,
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) => SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Call Forwarding Section
                  Text(
                    'Call Forwarding',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildForwardingCard(
                    context,
                    title: 'Unconditional Forwarding',
                    description: 'Forward all incoming calls',
                    forwardingType: 'unconditional',
                  ),
                  const SizedBox(height: 12),
                  _buildForwardingCard(
                    context,
                    title: 'Busy Forwarding',
                    description: 'Forward calls when busy',
                    forwardingType: 'busy',
                  ),
                  const SizedBox(height: 12),
                  _buildForwardingCard(
                    context,
                    title: 'No Answer Forwarding',
                    description: 'Forward calls when not answered',
                    forwardingType: 'noAnswer',
                  ),
                  const SizedBox(height: 12),
                  _buildForwardingCard(
                    context,
                    title: 'Unreachable Forwarding',
                    description: 'Forward calls when unreachable',
                    forwardingType: 'unreachable',
                  ),
                  const SizedBox(height: 32),

                  // General Settings Section
                  Text(
                    'General',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final isDefaultDialer = state is SettingsLoaded 
                          ? state.isDefaultDialer 
                          : false;
                      
                      return _buildSettingCard(
                        context,
                        title: isDefaultDialer 
                            ? 'Default Dialer (Active)' 
                            : 'Set as Default Dialer',
                        description: isDefaultDialer
                            ? 'This app is currently your default dialer'
                            : 'Make this app your default phone dialer',
                        onTap: isDefaultDialer
                            ? null
                            : () {
                          context.read<SettingsBloc>().add(
                                SetDefaultDialerRequested(),
                              );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _buildSettingCard(
                    context,
                    title: 'App Version',
                    description: 'Version 1.0.0 (Build 1)',
                    onTap: null,
                  ),
                ],
              ),
            ),
        ),
      ),
    );

  Widget _buildForwardingCard(
    BuildContext context, {
    required String title,
    required String description,
    required String forwardingType,
  }) => Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    var isEnabled = false;
                    if (state is SettingsLoaded) {
                      isEnabled = state.getForwardingEnabled(forwardingType);
                    }
                    return Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showForwardingNumberDialog(
                            context,
                            forwardingType,
                          );
                        } else {
                          context.read<SettingsBloc>().add(
                                DisableForwardingRequested(
                                  forwardingType: forwardingType,
                                ),
                              );
                        }
                      },
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            BlocBuilder<SettingsBloc, SettingsState>(
              builder: (context, state) {
                var number = '';
                if (state is SettingsLoaded) {
                  number = state.getForwardingNumber(forwardingType) ?? '';
                }
                return Text(
                  number.isNotEmpty ? 'Forward to: $number' : 'Not configured',
                  style: TextStyle(
                    fontSize: 12,
                    color: number.isNotEmpty
                        ? Colors.green.shade700
                        : Colors.grey.shade600,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );

  Widget _buildSettingCard(
    BuildContext context, {
    required String title,
    required String description,
    required VoidCallback? onTap,
  }) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              if (onTap != null)
                Icon(Icons.chevron_right, color: Colors.grey.shade600),
            ],
          ),
        ),
      ),
    );

  void _showForwardingNumberDialog(
    BuildContext context,
    String forwardingType,
  ) {
    _forwardingNumberController.clear();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Forwarding Number'),
        content: TextField(
          controller: _forwardingNumberController,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+1234567890 or USSD code',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final number = _forwardingNumberController.text.trim();
              if (number.isNotEmpty) {
                context.read<SettingsBloc>().add(
                      EnableForwardingRequested(
                        forwardingType: forwardingType,
                        forwardingNumber: number,
                      ),
                    );
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Enable'),
          ),
        ],
      ),
    );
  }
}
