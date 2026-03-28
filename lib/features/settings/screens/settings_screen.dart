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

                  const SizedBox(height: 32),

                  // Call Behavior Section
                  Text(
                    'Call Behavior',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),

                  // Call Waiting Toggle
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final enabled = state is SettingsLoaded
                          ? state.callWaitingEnabled
                          : false;
                      return _buildToggleCard(
                        context,
                        title: 'Call Waiting',
                        description: 'Allow incoming calls while on a call',
                        value: enabled,
                        onChanged: (v) => context
                            .read<SettingsBloc>()
                            .add(CallWaitingToggled(enabled: v)),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Power Button Ends Call
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final enabled = state is SettingsLoaded
                          ? state.powerButtonEndCall
                          : false;
                      return _buildToggleCard(
                        context,
                        title: 'Power Button Ends Call',
                        description: 'Press power button to end active call',
                        value: enabled,
                        onChanged: (v) => context
                            .read<SettingsBloc>()
                            .add(PowerButtonEndCallToggled(enabled: v)),
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  // Volume Button Behavior
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final behavior = state is SettingsLoaded
                          ? state.volumeButtonBehavior
                          : 'mute';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                              'Action when volume button is pressed',
                              style: TextStyle(
                                  color: Colors.grey.shade600, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            DropdownButton<String>(
                              value: behavior,
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: 'mute', child: Text('Mute ringtone')),
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

                  // Appearance Section
                  Text(
                    'Appearance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final themeMode = state is SettingsLoaded
                          ? state.themeMode
                          : 'system';
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                            const SizedBox(height: 8),
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
                                    ThemeModeChanged(
                                        themeMode: selection.first));
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Blocked Numbers Section
                  Text(
                    'Blocked Numbers',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  BlocBuilder<SettingsBloc, SettingsState>(
                    builder: (context, state) {
                      final blocked = state is SettingsLoaded
                          ? state.blockedNumbers
                          : <String>[];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '${blocked.length} blocked',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                  ),
                                ),
                                TextButton.icon(
                                  onPressed: () =>
                                      _showAddBlockedNumberDialog(context),
                                  icon: const Icon(Icons.add, size: 18),
                                  label: const Text('Add'),
                                ),
                              ],
                            ),
                            if (blocked.isEmpty)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                child: Text(
                                  'No blocked numbers',
                                  style: TextStyle(
                                      color: Colors.grey.shade500),
                                ),
                              )
                            else
                              ...blocked.map((number) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    leading: const Icon(Icons.block,
                                        color: Colors.red, size: 20),
                                    title: Text(number),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.delete_outline,
                                          size: 20),
                                      onPressed: () => context
                                          .read<SettingsBloc>()
                                          .add(BlockedNumberRemoved(
                                              number: number)),
                                    ),
                                  )),
                          ],
                        ),
                      );
                    },
                  ),

                  const SizedBox(height: 32),

                  // Battery Optimization Section
                  Text(
                    'Battery & Performance',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(height: 16),
                  _buildSettingCard(
                    context,
                    title: 'Battery Optimization',
                    description:
                        'Disable battery optimization for reliable call reception',
                    onTap: () => _showBatteryOptimizationGuide(context),
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

  Widget _buildToggleCard(
    BuildContext context, {
    required String title,
    required String description,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
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
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );

  void _showAddBlockedNumberDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Block a Number'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.phone,
          decoration: const InputDecoration(
            hintText: '+1234567890',
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
                context
                    .read<SettingsBloc>()
                    .add(BlockedNumberAdded(number: number));
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('Block'),
          ),
        ],
      ),
    );
  }

  void _showBatteryOptimizationGuide(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Battery Optimization'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'To ensure reliable incoming calls, disable battery '
                'optimization for this app:',
                style: TextStyle(fontSize: 14),
              ),
              SizedBox(height: 12),
              Text('1. Go to Settings → Battery → Battery Optimization',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 4),
              Text('2. Find "Dailathon" in the list',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 4),
              Text('3. Select "Don\'t optimize"',
                  style: TextStyle(fontSize: 13)),
              SizedBox(height: 12),
              Text(
                'For Xiaomi/Redmi/POCO devices, also enable '
                '"Autostart" in Security → Manage apps.',
                style: TextStyle(
                    fontSize: 13, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

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
