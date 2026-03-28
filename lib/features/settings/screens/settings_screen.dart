import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/theme/app_theme.dart';
import '../bloc/settings_bloc.dart';

/// Settings screen — strictly scoped to:
///   1. Call Forwarding
///   2. Volume Button Action
///   3. Theme Mode (Dark / Light / System Default)
///
/// Permissions, battery optimization, default dialer, blocked numbers,
/// call waiting and power-button settings are intentionally excluded.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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

                //  Call Forwarding 
                _sectionHeader(context, 'Call Forwarding'),
                const SizedBox(height: 16),
                _buildForwardingCard(context,
                    title: 'Unconditional Forwarding',
                    description: 'Forward all incoming calls',
                    forwardingType: 'unconditional'),
                const SizedBox(height: 12),
                _buildForwardingCard(context,
                    title: 'Busy Forwarding',
                    description: 'Forward calls when busy',
                    forwardingType: 'busy'),
                const SizedBox(height: 12),
                _buildForwardingCard(context,
                    title: 'No Answer Forwarding',
                    description: 'Forward calls when not answered',
                    forwardingType: 'noAnswer'),
                const SizedBox(height: 12),
                _buildForwardingCard(context,
                    title: 'Unreachable Forwarding',
                    description: 'Forward calls when unreachable',
                    forwardingType: 'unreachable'),
                const SizedBox(height: 32),

                //  Volume Button Action 
                _sectionHeader(context, 'Volume Button Action'),
                const SizedBox(height: 16),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final behavior = state is SettingsLoaded
                        ? state.volumeButtonBehavior
                        : 'mute';
                    return _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Volume Button During Ringing',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Action when volume button is pressed while phone rings',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(height: 12),
                          DropdownButton<String>(
                            value: behavior,
                            isExpanded: true,
                            underline: const Divider(height: 1),
                            items: const [
                              DropdownMenuItem(
                                  value: 'mute',
                                  child: Text('Mute ringtone')),
                              DropdownMenuItem(
                                  value: 'decline',
                                  child: Text('Decline call')),
                              DropdownMenuItem(
                                  value: 'nothing',
                                  child: Text('Do nothing')),
                            ],
                            onChanged: (v) {
                              if (v != null) {
                                context.read<SettingsBloc>().add(
                                    VolumeButtonBehaviorChanged(behavior: v));
                              }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

                //  Theme Mode 
                _sectionHeader(context, 'Appearance'),
                const SizedBox(height: 16),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final themeMode = state is SettingsLoaded
                        ? state.themeMode
                        : 'system';
                    return _buildCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Theme',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 12),
                          SegmentedButton<String>(
                            segments: const [
                              ButtonSegment(
                                value: 'light',
                                icon: Icon(Icons.light_mode),
                                label: Text('Light'),
                              ),
                              ButtonSegment(
                                value: 'dark',
                                icon: Icon(Icons.dark_mode),
                                label: Text('Dark'),
                              ),
                              ButtonSegment(
                                value: 'system',
                                icon: Icon(Icons.settings_brightness),
                                label: Text('System'),
                              ),
                            ],
                            selected: {themeMode},
                            onSelectionChanged: (selection) {
                              context.read<SettingsBloc>().add(
                                  ThemeModeChanged(themeMode: selection.first));
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),

              ],
            ),
          ),
        ),
      ),
    );

  Widget _sectionHeader(BuildContext context, String title) => Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      );

  Widget _buildCard({required Widget child}) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        child: child,
      );

  Widget _buildForwardingCard(
    BuildContext context, {
    required String title,
    required String description,
    required String forwardingType,
  }) =>
      _buildCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text(description,
                          style: TextStyle(
                              color: Colors.grey.shade600, fontSize: 12)),
                    ],
                  ),
                ),
                BlocBuilder<SettingsBloc, SettingsState>(
                  builder: (context, state) {
                    final isEnabled = state is SettingsLoaded
                        ? state.getForwardingEnabled(forwardingType)
                        : false;
                    return Switch(
                      value: isEnabled,
                      onChanged: (value) {
                        if (value) {
                          _showForwardingNumberDialog(context, forwardingType);
                        } else {
                          context.read<SettingsBloc>().add(
                              DisableForwardingRequested(
                                  forwardingType: forwardingType));
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
                final number = state is SettingsLoaded
                    ? (state.getForwardingNumber(forwardingType) ?? '')
                    : '';
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
      );

  void _showForwardingNumberDialog(
      BuildContext context, String forwardingType) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Enter Forwarding Number'),
        content: TextField(
          controller: controller,
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
              final number = controller.text.trim();
              if (number.isNotEmpty) {
                context.read<SettingsBloc>().add(EnableForwardingRequested(
                    forwardingType: forwardingType,
                    forwardingNumber: number));
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