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
          if (state is DialerCalling) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is DialerError) {
            return Center(child: Text('Error: ${state.error}'));
          }
          final activeState = state is DialerActive ? state : const DialerActive();
          return Column(
            children: [
              // Number Display Box
              Container(
                color: Colors.grey.shade100,
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Column(
                  children: [
                    // Current Number
                    SelectableText(
                      activeState.currentNumber.isEmpty ? '0' : activeState.currentNumber,
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                          ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    // SIM Selector (multi-SIM only)
                    if (activeState.availableSims.length > 1)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            activeState.availableSims.length,
                            (index) => Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 4),
                              child: FilterChip(
                                label: Text('SIM ${index + 1}'),
                                selected:
                                    activeState.selectedSimSlot == index,
                                onSelected: (selected) {
                                  context.read<DialerBloc>().add(
                                        SimSlotSelected(index),
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
              if (activeState.contactSuggestions.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
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
                          itemCount: activeState.contactSuggestions.length,
                          itemBuilder: (context, index) {
                            final contact = activeState.contactSuggestions[index];
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
                  padding: const EdgeInsets.all(16),
                  child: Dialpad(
                    onDigitPressed: (digit) async {
                      // Haptic feedback on key press (fast)
                      await _triggerHaptic();
                      
                      context.read<DialerBloc>().add(
                            NumberChanged(
                              number: activeState.currentNumber + digit,
                            ),
                          );
                    },
                    onBackspacePressed: () async {
                      // Haptic feedback on backspace
                      await _triggerHaptic();
                      
                      context.read<DialerBloc>().add(
                            NumberChanged(
                              number: activeState.currentNumber.isNotEmpty
                                  ? activeState.currentNumber
                                      .substring(0, activeState.currentNumber.length - 1)
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
                padding: const EdgeInsets.all(16),
                child: FloatingActionButton.extended(
                  onPressed: activeState.currentNumber.isEmpty
                      ? null
                      : () {
                          context.read<DialerBloc>().add(
                                CallInitiated(
                                  number: activeState.currentNumber,
                                  simSlot: activeState.selectedSimSlot,
                                ),
                              );
                        },
                  icon: const Icon(Icons.call),
                  label: const Text('Call'),
                  backgroundColor: activeState.currentNumber.isEmpty
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
