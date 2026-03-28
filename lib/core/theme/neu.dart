import 'package:flutter/material.dart';
import 'app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// NeuCard — raised neumorphic container, optionally tappable.
// ─────────────────────────────────────────────────────────────────────────────

class NeuCard extends StatelessWidget {
  const NeuCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.borderRadius = AppTheme.radiusMd,
    this.distance = 5,
    this.blur = 15,
    this.onTap,
    this.color,
    this.margin,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double borderRadius;
  final double distance;
  final double blur;
  final VoidCallback? onTap;
  final Color? color;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppTheme.bg;
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(borderRadius),
      boxShadow: AppTheme.raisedShadow(distance: distance, blur: blur),
    );

    Widget content = Padding(padding: padding, child: child);

    if (onTap != null) {
      content = Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          splashColor: AppTheme.primary.withOpacity(0.06),
          highlightColor: AppTheme.primary.withOpacity(0.04),
          child: content,
        ),
      );
    }

    return Container(
      margin: margin,
      decoration: decoration,
      child: content,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NeuButton — press-animated neumorphic button.
// ─────────────────────────────────────────────────────────────────────────────

class NeuButton extends StatefulWidget {
  const NeuButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.labelColor,
    this.width,
    this.height = 52,
    this.borderRadius = AppTheme.radiusFull,
    this.fontSize = 16,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final Color? labelColor;
  final double? width;
  final double height;
  final double borderRadius;
  final double fontSize;

  @override
  State<NeuButton> createState() => _NeuButtonState();
}

class _NeuButtonState extends State<NeuButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final isDisabled = widget.onPressed == null;
    final bg = isDisabled
        ? AppTheme.textHint
        : (widget.color ?? AppTheme.primary);
    final fg = widget.labelColor ?? Colors.white;

    return GestureDetector(
      onTapDown: isDisabled ? null : (_) => setState(() => _pressed = true),
      onTapUp: isDisabled
          ? null
          : (_) {
              setState(() => _pressed = false);
              widget.onPressed?.call();
            },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(widget.borderRadius),
          boxShadow: (_pressed || isDisabled)
              ? AppTheme.flatShadow()
              : AppTheme.raisedShadow(distance: 4, blur: 12),
        ),
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon, color: fg, size: widget.fontSize + 2),
                const SizedBox(width: 8),
              ],
              Text(
                widget.label,
                style: TextStyle(
                  color: fg,
                  fontSize: widget.fontSize,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NeuDialKey — circular neumorphic dial-pad key.
// ─────────────────────────────────────────────────────────────────────────────

class NeuDialKey extends StatefulWidget {
  const NeuDialKey({
    super.key,
    required this.label,
    this.sublabel,
    required this.onTap,
    this.onLongPress,
    this.size = 72,
    this.icon,
  });

  final String label;
  final String? sublabel;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final double size;
  final IconData? icon;

  @override
  State<NeuDialKey> createState() => _NeuDialKeyState();
}

class _NeuDialKeyState extends State<NeuDialKey>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: this,
      lowerBound: 0.0,
      upperBound: 1.0,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.9).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        setState(() => _pressed = true);
        _scaleController.forward();
      },
      onTapUp: (_) {
        setState(() => _pressed = false);
        _scaleController.reverse();
        widget.onTap();
      },
      onTapCancel: () {
        setState(() => _pressed = false);
        _scaleController.reverse();
      },
      onLongPress: widget.onLongPress,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: AppTheme.bg,
            shape: BoxShape.circle,
            boxShadow: _pressed
                ? AppTheme.insetShadow()
                : AppTheme.raisedShadow(distance: 4, blur: 10),
          ),
          child: Center(
            child: widget.icon != null
                ? Icon(widget.icon, color: AppTheme.textPrimary, size: 26)
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: AppTheme.textPrimary,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          height: 1.1,
                        ),
                      ),
                      if (widget.sublabel != null &&
                          widget.sublabel!.isNotEmpty)
                        Text(
                          widget.sublabel!,
                          style: const TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.4,
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

// ─────────────────────────────────────────────────────────────────────────────
// NeuStatCard — stat pill for the home dashboard.
// ─────────────────────────────────────────────────────────────────────────────

class NeuStatCard extends StatelessWidget {
  const NeuStatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.raisedShadow(distance: 4, blur: 12),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// NeuProgressBar — inset neumorphic progress bar.
// ─────────────────────────────────────────────────────────────────────────────

class NeuProgressBar extends StatelessWidget {
  const NeuProgressBar({super.key, required this.value, this.color});

  final double value; // 0.0 – 1.0
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primary;
    return Container(
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(4),
        boxShadow: AppTheme.insetShadow(),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [c.withOpacity(0.7), c],
              ),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NeuBadge — pill-shaped label.
// ─────────────────────────────────────────────────────────────────────────────

class NeuBadge extends StatelessWidget {
  const NeuBadge({
    super.key,
    required this.label,
    this.color,
    this.textColor,
  });

  final String label;
  final Color? color;
  final Color? textColor;

  @override
  Widget build(BuildContext context) {
    final badgeColor = color ?? AppTheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(AppTheme.radiusFull),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: textColor ?? badgeColor,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// NeuTextField — inset neumorphic text field wrapper.
// ─────────────────────────────────────────────────────────────────────────────

class NeuTextField extends StatelessWidget {
  const NeuTextField({
    super.key,
    this.controller,
    this.hintText,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.onChanged,
    this.keyboardType,
    this.textInputAction,
    this.focusNode,
    this.onFieldSubmitted,
    this.readOnly = false,
  });

  final TextEditingController? controller;
  final String? hintText;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final ValueChanged<String>? onFieldSubmitted;
  final bool readOnly;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.bg,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        boxShadow: AppTheme.insetShadow(),
      ),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        onChanged: onChanged,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        focusNode: focusNode,
        readOnly: readOnly,
        style: const TextStyle(
          color: AppTheme.textPrimary,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: const TextStyle(color: AppTheme.textHint),
          prefixIcon: prefixIcon,
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: OutlineInputBorder(
            borderRadius:
                BorderRadius.circular(AppTheme.radiusMd),
            borderSide:
                const BorderSide(color: AppTheme.primary, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 14),
        ),
        onSubmitted: onFieldSubmitted,
      ),
    );
  }
}
