import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../dialer/bloc/dialer_bloc.dart';
import '../widgets/dialpad.dart';

/// DialerScreen displays the main dialing interface.
/// Includes dialpad, number display, SIM selector, and contact suggestions.
class DialerScreen extends StatefulWidget {
  const DialerScreen({Key? key}) : super(key: key);

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  static const _platform = MethodChannel('com.mangrule.dailathon/call_commands');

  // Trigger haptic feedback on dialpad key press
  Future<void> _triggerHaptic() async {
    try {
      // First try Flutter built-in haptic (fastest)
      await HapticFeedback.selectionClick();
    } catch (e) {
      debugPrint('Haptic feedback error: $e');
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      appBar: AppBar(
        title: const Text('Dialer'),
        centerTitle: true,
        elevation: 0,
      ),
      body: BlocBuilder<DialerBloc, DialerState>(
        builder: (context, state) {
          return Column(
            children: [
              // Number Display Box
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 24.0),
                child: Column(
                  children: [
                    // Current Number
                    SelectableText(
                      state.currentNumber.isEmpty ? '0' : state.currentNumber,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // SIM Selector (multi-SIM only)
                    if (state.availableSims.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            state.availableSims.length,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4.0),
                              child: FilterChip(
                                label: Text('SIM ${index + 1}'),
                                selected:
                                    state.selectedSimSlot == index,
                                onSelected: (selected) {
                                  context.read<DialerBloc>().add(
                                        SimSelected(slot: index),
                                      );
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // T9 Search Suggestions
              if (state.contactSuggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contacts',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 100,
                        child: ListView.builder(
                          itemCount: state.contactSuggestions.length,
                          itemBuilder: (context, index) {
                            final contact = state.contactSuggestions[index];
                            return ListTile(
                              dense: true,
                              leading: CircleAvatar(
                                child: Text(contact.name[0].toUpperCase()),
                              ),
                              title: Text(contact.name),
                              subtitle: Text(contact.phoneNumber),
                              onTap: () {
                                context.read<DialerBloc>().add(
                                      NumberChanged(
                                        number: contact.phoneNumber,
                                      ),
                                    );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              // Dialpad
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Dialpad(
                    onDigitPressed: (digit) async {
                      // Haptic feedback on key press (fast)
                      await _triggerHaptic();
                      
                      context.read<DialerBloc>().add(
                            NumberChanged(
                              number: state.currentNumber + digit,
                            ),
                          );
                    },
                    onBackspacePressed: () async {
                      // Haptic feedback on backspace
                      await _triggerHaptic();
                      
                      context.read<DialerBloc>().add(
                            NumberChanged(
                              number: state.currentNumber.isNotEmpty
                                  ? state.currentNumber
                                      .substring(0, state.currentNumber.length - 1)
                                  : '',
                            ),
                          );
                    },
                    onClearPressed: () async {
                      // Haptic feedback on clear
                      await _triggerHaptic();
                      
                      context.read<DialerBloc>().add(
                            const NumberChanged(number: ''),
                          );
                    },
                  ),
                ),
              ),
              // Call Button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: FloatingActionButton.extended(
                  onPressed: state.currentNumber.isEmpty
                      ? null
                      : () {
                          context.read<DialerBloc>().add(
                                CallInitiated(
                                  number: state.currentNumber,
                                  simSlot: state.selectedSimSlot,
                                ),
                              );
                        },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  backgroundColor: state.currentNumber.isEmpty
                      ? Colors.grey
                      : Colors.green,
                ),
              ),
            ],
          );
        },
      ),
    );
}
