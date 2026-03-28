import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:call_log/call_log.dart' as call_log_pkg;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../dialer/bloc/dialer_bloc.dart';
import '../widgets/dialpad.dart';

/// Neumorphic Dialer Screen — number display, SIM selector, T9 suggestions,
/// dialpad grid and call button.
class DialerScreen extends StatefulWidget {
  const DialerScreen({super.key});

  @override
  State<DialerScreen> createState() => _DialerScreenState();
}

class _DialerScreenState extends State<DialerScreen> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      _initialized = true;
      context.read<DialerBloc>().add(const DialerStarted());
    }
  }

  Future<void> _haptic() async {
    try {
      await HapticFeedback.selectionClick();
    } catch (_) {}
  }

  String _formatNumber(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^\d+*#]'), '');
    if (digits.length <= 4) return digits;
    if (digits.startsWith('+')) {
      // +91 85528 86242 style
      if (digits.length > 3 && digits.length <= 8) {
        return '${digits.substring(0, 3)} ${digits.substring(3)}';
      } else if (digits.length > 8) {
        return '${digits.substring(0, 3)} ${digits.substring(3, 8)} ${digits.substring(8)}';
      }
    } else if (digits.length > 5) {
      // 85528 86242 style
      return '${digits.substring(0, 5)} ${digits.substring(5)}';
    }
    return digits;
  }

  Future<void> _pasteNumber() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      final cleaned = data.text!.replaceAll(RegExp(r'[^\d+*#]'), '');
      if (cleaned.isNotEmpty && mounted) {
        context.read<DialerBloc>().add(NumberChanged(number: cleaned));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.bg,
      appBar: AppBar(
        backgroundColor: AppTheme.bg,
        title: const Text('Dialer'),
        elevation: 0,
      ),
      body: BlocBuilder<DialerBloc, DialerState>(
        builder: (context, state) {
          if (state is DialerCalling) {
            return const Center(child: CircularProgressIndicator());
          }
          final s = state is DialerActive ? state : const DialerActive();

          return Column(
            children: [
              // ── Number display ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppTheme.bg,
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusMd),
                    boxShadow: AppTheme.insetShadow(),
                  ),
                  child: Row(
                    children: [
                      // Paste button
                      GestureDetector(
                        onTap: _pasteNumber,
                        child: const Icon(Icons.content_paste_rounded,
                            color: AppTheme.textHint, size: 20),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          s.currentNumber.isEmpty ? '  ' : _formatNumber(s.currentNumber),
                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.w300,
                            color: AppTheme.textPrimary,
                            letterSpacing: 3,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 28),
                    ],
                  ),
                ),
              ),

              // ── SIM selector ───────────────────────────────────────────
              if (s.availableSims.length > 1)
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      s.availableSims.length,
                      (i) => Padding(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6),
                        child: _SimChip(
                          label: 'SIM ${i + 1}',
                          selected: s.selectedSimSlot == i,
                          onTap: () => context
                              .read<DialerBloc>()
                              .add(SimSlotSelected(i)),
                        ),
                      ),
                    ),
                  ),
                ),

              // ── T9 suggestions ─────────────────────────────────────────
              if (s.contactSuggestions.isNotEmpty)
                Container(
                  height: 80,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: s.contactSuggestions.length,
                    itemBuilder: (_, i) {
                      final c = s.contactSuggestions[i];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: NeuCard(
                          onTap: () => context.read<DialerBloc>().add(
                              NumberChanged(number: c.phoneNumber)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                c.name,
                                style: const TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                c.phoneNumber,
                                style: const TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

              // ── Dialpad ────────────────────────────────────────────────
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Dialpad(
                    onDigitPressed: (digit) async {
                      await _haptic();
                      context.read<DialerBloc>().add(NumberChanged(
                          number: s.currentNumber + digit));
                    },
                    onLongPressDigit: (digit) {
                      context.read<DialerBloc>().add(
                          SpeedDialLongPress(position: int.parse(digit)));
                    },
                  ),
                ),
              ),

              // ── Call + Backspace row ───────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 8, 32, 28),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left: Redial last number (only when dialer is empty)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: s.currentNumber.isEmpty
                          ? GestureDetector(
                              onTap: () async {
                                try {
                                  final entries = await call_log_pkg.CallLog.get();
                                  final last = entries.firstWhere(
                                    (e) => e.callType == call_log_pkg.CallType.outgoing && e.number != null,
                                  );
                                  if (mounted && last.number != null) {
                                    context.read<DialerBloc>().add(NumberChanged(number: last.number!));
                                  }
                                } catch (_) {}
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.bg,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.raisedShadow(distance: 3, blur: 8),
                                ),
                                child: const Icon(Icons.restart_alt_rounded,
                                    color: AppTheme.textSecondary, size: 22),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),

                    // Center: Call button
                    _CallButton(
                      enabled: s.currentNumber.isNotEmpty,
                      onTap: s.currentNumber.isEmpty
                          ? null
                          : () => context.read<DialerBloc>().add(
                              CallInitiated(
                                number: s.currentNumber,
                                simSlot: s.selectedSimSlot,
                              ),
                            ),
                    ),

                    // Right: Backspace (visible when number entered)
                    SizedBox(
                      width: 48,
                      height: 48,
                      child: s.currentNumber.isNotEmpty
                          ? GestureDetector(
                              onTap: () async {
                                await _haptic();
                                context.read<DialerBloc>().add(NumberChanged(
                                    number: s.currentNumber.substring(
                                        0, s.currentNumber.length - 1)));
                              },
                              onLongPress: () async {
                                await _haptic();
                                context.read<DialerBloc>()
                                    .add(const NumberChanged(number: ''));
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: AppTheme.bg,
                                  shape: BoxShape.circle,
                                  boxShadow: AppTheme.raisedShadow(distance: 3, blur: 8),
                                ),
                                child: const Icon(Icons.backspace_outlined,
                                    color: AppTheme.textSecondary, size: 22),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _SimChip extends StatelessWidget {
  const _SimChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : AppTheme.bg,
          borderRadius:
              BorderRadius.circular(AppTheme.radiusFull),
          boxShadow: selected
              ? AppTheme.flatShadow()
              : AppTheme.raisedShadow(distance: 3, blur: 8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppTheme.textSecondary,
            fontSize: 13,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _CallButton extends StatefulWidget {
  const _CallButton({this.onTap, required this.enabled});
  final VoidCallback? onTap;
  final bool enabled;

  @override
  State<_CallButton> createState() => _CallButtonState();
}

class _CallButtonState extends State<_CallButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final color =
        widget.enabled ? AppTheme.success : AppTheme.textHint;
    return GestureDetector(
      onTapDown: widget.enabled
          ? (_) => setState(() => _pressed = true)
          : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: _pressed || !widget.enabled
              ? AppTheme.flatShadow()
              : [
                  BoxShadow(
                    color: AppTheme.success.withOpacity(0.4),
                    offset: const Offset(0, 6),
                    blurRadius: 18,
                  ),
                  ...AppTheme.raisedShadow(distance: 4, blur: 12),
                ],
        ),
        child: const Icon(Icons.call_rounded,
            color: Colors.white, size: 30),
      ),
    );
  }
}
