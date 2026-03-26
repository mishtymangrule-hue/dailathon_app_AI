import 'package:flutter/material.dart';
import 'package:dailathon_dialer/core/models/call_info.dart';

/// Call waiting banner UI shown when a second call arrives during an active call.
/// Provides options to answer + hold, answer + end, or decline the incoming call.
class CallWaitingBanner extends StatelessWidget {

  const CallWaitingBanner({
    Key? key,
    required this.waitingCall,
    required this.onAnswerAndHold,
    required this.onAnswerAndEnd,
    required this.onDecline,
  }) : super(key: key);
  final CallInfo waitingCall;
  final VoidCallback onAnswerAndHold;
  final VoidCallback onAnswerAndEnd;
  final VoidCallback onDecline;

  @override
  Widget build(BuildContext context) => Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.call,
                  color: Colors.orange, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Incoming call",
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    Text(
                      waitingCall.callerName ?? waitingCall.callerNumber,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ActionButton(
                icon: Icons.pause,
                label: "Hold",
                color: Colors.blue,
                onTap: onAnswerAndHold,
              ),
              _ActionButton(
                icon: Icons.call_end,
                label: "End",
                color: Colors.orange,
                onTap: onAnswerAndEnd,
              ),
              _ActionButton(
                icon: Icons.close,
                label: "Decline",
                color: Colors.red,
                onTap: onDecline,
              ),
            ],
          ),
        ],
      ),
    );
}

class _ActionButton extends StatelessWidget {

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.2),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: color, fontSize: 12),
            ),
          ],
        ),
      ),
    );
}
