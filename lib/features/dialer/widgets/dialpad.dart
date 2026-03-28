import 'package:flutter/material.dart';
import '../../../core/theme/neu.dart';

/// Neumorphic dialpad — 3×4 circular keys.
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
        _buildRow(0),
        _buildRow(1),
        _buildRow(2),
        _buildRow(3),
      ],
    );
  }

  Widget _buildRow(int row) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (int col = 0; col < 3; col++)
          NeuDialKey(
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
