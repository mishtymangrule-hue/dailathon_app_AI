import 'package:flutter/material.dart';

/// Dialpad widget displaying 0-9, *, #, and action buttons.
class Dialpad extends StatelessWidget {

  const Dialpad({
    required this.onDigitPressed, required this.onBackspacePressed, required this.onClearPressed, Key? key,
  }) : super(key: key);
  final Function(String) onDigitPressed;
  final VoidCallback onBackspacePressed;
  final VoidCallback onClearPressed;

  @override
  Widget build(BuildContext context) {
    const digits = <String>[
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '*', '0', '#',
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 1,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
      ),
      itemCount: 13, // 12 digits + 1 backspace
      itemBuilder: (context, index) {
        if (index < 12) {
          return _DialpadButton(
            label: digits[index],
            onPressed: () => onDigitPressed(digits[index]),
          );
        } else {
          // Backspace button
          return _DialpadButton(
            icon: Icons.backspace_outlined,
            onPressed: onBackspacePressed,
            color: Colors.red.shade500,
          );
        }
      },
    );
  }
}

/// Individual dialpad button.
class _DialpadButton extends StatelessWidget {

  const _DialpadButton({
    required this.onPressed, this.label,
    this.icon,
    this.color,
  });
  final String? label;
  final IconData? icon;
  final VoidCallback onPressed;
  final Color? color;

  @override
  Widget build(BuildContext context) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(12),
            color: Colors.grey.shade50,
          ),
          child: Center(
            child: label != null
                ? Text(
                    label!,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  )
                : Icon(
                    icon,
                    size: 28,
                    color: color,
                  ),
          ),
        ),
      ),
    );
}
