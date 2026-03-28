import 'package:flutter/material.dart';

/// Material 3 dialpad — 3×4 circular keys.
/// Backspace is handled externally (in the call-button row).
class Dialpad extends StatelessWidget {
  const Dialpad({
    required this.onDigitPressed,
    this.onLongPressDigit,
    super.key,
  });

  final void Function(String) onDigitPressed;
  /// Called on long-press of digits 2-9 for speed dial.
  final void Function(String)? onLongPressDigit;

  static const List<String> _digits = [
    '1', '2', '3',
    '4', '5', '6',
    '7', '8', '9',
    '*', '0', '#',
  ];

  static const List<String> _sublabels = [
    '', 'ABC', 'DEF',
    'GHI', 'JKL', 'MNO',
    'PQRS', 'TUV', 'WXYZ',
    '', '+', '',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildRow(context, 0),
        _buildRow(context, 1),
        _buildRow(context, 2),
        _buildRow(context, 3),
      ],
    );
  }

  Widget _buildRow(BuildContext context, int row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int col = 0; col < 3; col++)
          _DialKey(
            label: _digits[row * 3 + col],
            sublabel: _sublabels[row * 3 + col],
            onTap: () => onDigitPressed(_digits[row * 3 + col]),
            onLongPress: _digits[row * 3 + col] == '0'
                ? () => onDigitPressed('+')
                : (onLongPressDigit != null &&
                        int.tryParse(_digits[row * 3 + col]) != null &&
                        int.parse(_digits[row * 3 + col]) >= 2)
                    ? () => onLongPressDigit!(_digits[row * 3 + col])
                    : null,
          ),
      ],
    );
  }
}

// ─── Dial Key ────────────────────────────────────────────────────────────────

class _DialKey extends StatelessWidget {
  const _DialKey({
    required this.label,
    this.sublabel,
    required this.onTap,
    this.onLongPress,
  });

  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: scheme.surfaceContainerHighest,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          onLongPress: onLongPress,
          splashColor: scheme.primary.withValues(alpha: 0.12),
          highlightColor: scheme.primary.withValues(alpha: 0.08),
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: textTheme.headlineSmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w400,
                    height: 1.1,
                  ),
                ),
                if (sublabel != null && sublabel!.isNotEmpty)
                  Text(
                    sublabel!,
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 9,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
