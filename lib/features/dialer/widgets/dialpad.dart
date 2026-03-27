import 'package:flutter/material.dart';
import '../../../core/theme/neu.dart';

/// Neumorphic dialpad — 3×4 circular keys + backspace.
class Dialpad extends StatelessWidget {
  const Dialpad({
    required this.onDigitPressed,
    required this.onBackspacePressed,
    required this.onClearPressed,
    super.key,
  });

  final void Function(String) onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;

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
      mainAxisSize: MainAxisSize.min,
      children: [
        // 4 rows of 3 keys each
        _buildRow(0),
        const SizedBox(height: 16),
        _buildRow(1),
        const SizedBox(height: 16),
        _buildRow(2),
        const SizedBox(height: 16),
        _buildRow(3),
        const SizedBox(height: 16),
        // Backspace
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            NeuDialKey(
              label: '',
              icon: Icons.backspace_outlined,
              onTap: onBackspacePressed,
              onLongPress: onClearPressed,
            ),
          ],
        ),
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
                : null,
          ),
      ],
    );
  }
}
