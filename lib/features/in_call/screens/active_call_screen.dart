import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dailathon_dialer/features/in_call/bloc/in_call_bloc.dart';
import 'package:dailathon_dialer/features/in_call/widgets/call_waiting_banner.dart';
import 'package:dailathon_dialer/core/models/call_info.dart';

/// Active call screen displayed during ongoing calls.
class ActiveCallScreen extends StatefulWidget {

  const ActiveCallScreen({
    Key? key,
    required this.callInfo,
  }) : super(key: key);
  final CallInfo callInfo;

  @override
  State<ActiveCallScreen> createState() => _ActiveCallScreenState();
}

class _ActiveCallScreenState extends State<ActiveCallScreen>
    with SingleTickerProviderStateMixin {
  late DateTime _callStartTime;
  Duration _elapsedDuration = Duration.zero;
  bool _showKeypad = false;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();
    _updateCallDuration();
  }

  void _updateCallDuration() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _elapsedDuration = DateTime.now().difference(_callStartTime);
        });
        _updateCallDuration();
      }
    });
  }

  @override
  Widget build(BuildContext context) => BlocBuilder<InCallBloc, InCallState>(
      builder: (context, state) {
        final hasWaitingCall = state is InCallActive && state.hasCallWaiting;
        
        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Column(
              children: [
                // Call waiting banner at the top
                if (hasWaitingCall && state is InCallActive)
                  CallWaitingBanner(
                    waitingCall: state.waitingCall!,
                    onAnswerAndHold: () {
                      context.read<InCallBloc>().add(
                            const AnswerWaitingCallAndHold(),
                          );
                    },
                    onAnswerAndEnd: () {
                      context.read<InCallBloc>().add(
                            const AnswerWaitingCallAndEnd(),
                          );
                    },
                    onDecline: () {
                      context.read<InCallBloc>().add(
                            const DeclineWaitingCall(),
                          );
                    },
                  ),

                // Header with elapsed time and close
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const SizedBox(width: 48),
                      Text(
                        _formatDuration(_elapsedDuration),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.expand_less, color: Colors.white),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ),

                // Caller info
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.green.shade400,
                                Colors.teal.shade400,
                              ],
                            ),
                          ),
                          child: Center(
                            child: Text(
                              _getInitials(),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 36,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          widget.callInfo.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Connected',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // Call controls
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24.0),
                  child: Column(
                    children: [
                      // Row 1: Mute, Speaker, Bluetooth
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.mic_off,
                            label: 'Mute',
                            isActive: widget.callInfo.isMuted,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    MuteToggled(widget.callInfo.isMuted),
                                  );
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.volume_up,
                            label: 'Speaker',
                            isActive: widget.callInfo.isSpeakerEnabled,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    SpeakerToggled(widget.callInfo.isSpeakerEnabled),
                                  );
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.bluetooth_audio,
                            label: 'BT',
                            isActive: widget.callInfo.isBluetoothAudio,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    BluetoothToggled(widget.callInfo.isBluetoothAudio),
                                  );
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Row 2: Hold, Keypad, Add Call
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.pause_circle,
                            label: widget.callInfo.isHeld ? 'Resume' : 'Hold',
                            isActive: widget.callInfo.isHeld,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    HoldToggled(widget.callInfo.isHeld),
                                  );
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.dialpad,
                            label: 'Keypad',
                            isActive: _showKeypad,
                            onPressed: () {
                              setState(() => _showKeypad = !_showKeypad);
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.add_call,
                            label: 'Add Call',
                            isActive: false,
                            onPressed: () {
                              // TODO: Add call functionality
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Row 3: Merge, Swap, End
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildControlButton(
                            icon: Icons.call_merge,
                            label: 'Merge',
                            isActive: false,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    const MergeCallsRequested(),
                                  );
                            },
                          ),
                          _buildControlButton(
                            icon: Icons.import_export,
                            label: 'Swap',
                            isActive: false,
                            onPressed: () {
                              context.read<InCallBloc>().add(
                                    const SwapCallsRequested(),
                                  );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // DTMF Keypad (if visible)
                if (_showKeypad)
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: _buildDtmfKeypad(),
                  ),

                // End call button
                Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: FloatingActionButton.extended(
                    onPressed: () {
                      context.read<InCallBloc>().add(const CallEnded());
                      Navigator.of(context).pop();
                    },
                    backgroundColor: Colors.red,
                    icon: const Icon(Icons.call_end),
                    label: const Text('End Call'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onPressed,
  }) => Column(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue.shade600 : Colors.grey.shade700,
          ),
          child: IconButton(
            icon: Icon(icon, color: Colors.white, size: 24),
            onPressed: onPressed,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );

  Widget _buildDtmfKeypad() {
    const dtmfButtons = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['*', '0', '#'],
    ];

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey.shade900,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: dtmfButtons
                .map(
                  (row) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: row
                          .map(
                            (digit) => GestureDetector(
                              onTap: () {
                                context.read<InCallBloc>().add(
                                      DtmfSent(digit),
                                    );
                              },
                              child: Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.grey.shade800,
                                  border: Border.all(
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    digit,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ],
    );
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getInitials() {
    final number = widget.callInfo.number;
    return number.isNotEmpty ? number[0].toUpperCase() : '?';
  }
}
