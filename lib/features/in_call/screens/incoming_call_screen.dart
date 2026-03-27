import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dailathon_dialer/features/in_call/bloc/in_call_bloc.dart';
import 'package:dailathon_dialer/core/channels/call_method_channel.dart';
import 'package:dailathon_dialer/core/models/call_info.dart';
import 'package:dailathon_dialer/core/service_locator.dart';

/// Full-screen incoming call UI for the Flutter layer.
/// Displayed when incoming call notification is tapped or during active calls.
class IncomingCallScreen extends StatefulWidget {

  const IncomingCallScreen({
    required this.phoneNumber, Key? key,
    this.displayName,
    this.callId,
  }) : super(key: key);
  final String phoneNumber;
  final String? displayName;
  final String? callId;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  Duration _elapsedDuration = Duration.zero;
  late DateTime _callStartTime;
  double _swipeDx = 0;
  static const double _swipeThreshold = 100;

  @override
  void initState() {
    super.initState();
    _callStartTime = DateTime.now();

    // Pulse animation for ringing effect
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 0.9, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Update elapsed time
    _updateElapsedTime();
  }

  void _updateElapsedTime() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _elapsedDuration = DateTime.now().difference(_callStartTime);
        });
        _updateElapsedTime();
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top status bar with elapsed time
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text(
                    _formatDuration(_elapsedDuration),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Caller information
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Avatar pulse
                    ScaleTransition(
                      scale: _pulseAnimation,
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.blue.shade400,
                              Colors.purple.shade400,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _getInitials(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Caller name
                    Text(
                      widget.displayName ?? 'Unknown Caller',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 12),

                    // Phone number
                    Text(
                      widget.phoneNumber,
                      style: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 20,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 24),

                    // Ringing status
                    Text(
                      'Ringing...',
                      style: TextStyle(
                        color: Colors.grey.shade300,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Swipe to answer/decline area
            GestureDetector(
              onHorizontalDragUpdate: (details) {
                setState(() => _swipeDx += details.delta.dx);
              },
              onHorizontalDragEnd: (details) {
                if (_swipeDx > _swipeThreshold) {
                  // Swipe right → Answer via native
                  _answerCall();
                } else if (_swipeDx < -_swipeThreshold) {
                  // Swipe left → Decline via native
                  _declineCall();
                }
                setState(() => _swipeDx = 0);
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.grey.shade900,
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.call_end, color: Colors.red.shade300, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      '← Decline    Swipe    Answer →',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    ),
                    const SizedBox(width: 8),
                    Icon(Icons.call, color: Colors.green.shade300, size: 20),
                  ],
                ),
              ),
            ),

            // Action buttons
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Decline button
                  _buildActionButton(
                    icon: Icons.call_end,
                    label: 'Decline',
                    color: Colors.red,
                    onPressed: _declineCall,
                  ),

                  const SizedBox(width: 32),

                  // Answer button
                  _buildActionButton(
                    icon: Icons.call,
                    label: 'Answer',
                    color: Colors.green,
                    onPressed: _answerCall,
                  ),
                ],
              ),
            ),

            // Additional actions
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                'Volume Up = Answer  |  Volume Down = Decline',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) => Column(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: color,
          child: Icon(icon, color: Colors.white, size: 32),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
          ),
        ),
      ],
    );

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getInitials() {
    final name = widget.displayName ?? widget.phoneNumber;
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  void _answerCall() {
    ServiceLocator().callMethodChannel.answer();
  }

  void _declineCall() {
    ServiceLocator().callMethodChannel.rejectCall();
    if (mounted) Navigator.of(context).pop();
  }
}
