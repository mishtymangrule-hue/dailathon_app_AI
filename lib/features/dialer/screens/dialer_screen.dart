import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:call_log/call_log.dart' as call_log_pkg;
import '../../../core/theme/app_theme.dart';
import '../../../core/theme/neu.dart';
import '../../dialer/bloc/dialer_bloc.dart';
import '../widgets/dialpad.dart';

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
    final d = raw.replaceAll(RegExp(r'[^\d+*#]'), '');
    if (d.length <= 4) return d;
    if (d.startsWith('+')) {
      if (d.length <= 8) return '${d.substring(0, 3)} ${d.substring(3)}';
      return '${d.substring(0, 3)} ${d.substring(3, 8)} ${d.substring(8)}';
    }
    if (d.length > 5) return '${d.substring(0, 5)} ${d.substring(5)}';
    return d;
  }

  Future<void> _pasteNumber() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text == null || data!.text!.isEmpty) return;
    final cleaned = data.text!.replaceAll(RegExp(r'[^\d+*#]'), '');
    if (cleaned.isNotEmpty && mounted) {
      context.read<DialerBloc>().add(NumberChanged(number: cleaned));
    }
  }

  Future<void> _redialLast() async {
    try {
      final entries = await call_log_pkg.CallLog.get();
      final last = entries.firstWhere(
        (e) => e.callType == call_log_pkg.CallType.outgoing && e.number != null,
      );
      if (mounted && last.number != null) {
        context.read<DialerBloc>().add(NumberChanged(number: last.number!));
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<DialerBloc, DialerState>(
      listener: (context, state) {
        if (state is DialerError) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(state.error),
            backgroundColor: AppTheme.errorColor,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppTheme.radiusSm),
            ),
          ));
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bg,
        body: SafeArea(
          child: BlocBuilder<DialerBloc, DialerState>(
            builder: (context, state) {
              if (state is DialerCalling) {
                return const _CallingOverlay();
              }
              final s = state is DialerActive ? state : const DialerActive();
              return Column(
                children: [
                  _NumberDisplay(
                    number: s.currentNumber,
                    formatted: s.currentNumber.isEmpty
                        ? ''
                        : _formatNumber(s.currentNumber),
                    onPaste: _pasteNumber,
                  ),
                  if (s.availableSims.length > 1) ...[
                    const SizedBox(height: 6),
                    _SimSelector(
                      sims: s.availableSims,
                      selected: s.selectedSimSlot,
                      onSelect: (i) =>
                          context.read<DialerBloc>().add(SimSlotSelected(i)),
                    ),
                  ],
                  if (s.contactSuggestions.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _SuggestionBar(
                      suggestions: s.contactSuggestions,
                      onTap: (number) => context
                          .read<DialerBloc>()
                          .add(NumberChanged(number: number)),
                    ),
                  ],
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Dialpad(
                        onDigitPressed: (digit) async {
                          await _haptic();
                          context.read<DialerBloc>().add(
                              NumberChanged(number: s.currentNumber + digit));
                        },
                        onLongPressDigit: (digit) {
                          context.read<DialerBloc>().add(SpeedDialLongPress(
                              position: int.parse(digit)));
                        },
                      ),
                    ),
                  ),
                  _ActionRow(
                    hasNumber: s.currentNumber.isNotEmpty,
                    onCall: () => context.read<DialerBloc>().add(
                          CallInitiated(
                            number: s.currentNumber,
                            simSlot: s.selectedSimSlot,
                          ),
                        ),
                    onBackspace: () {
                      _haptic();
                      final n = s.currentNumber;
                      context.read<DialerBloc>().add(NumberChanged(
                          number: n.isEmpty ? n : n.substring(0, n.length - 1)));
                    },
                    onBackspaceLong: () {
                      _haptic();
                      context
                          .read<DialerBloc>()
                          .add(const NumberChanged(number: ''));
                    },
                    onRedial: _redialLast,
                  ),
                  const SizedBox(height: 16),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

//  Number display 

class _NumberDisplay extends StatelessWidget {
  const _NumberDisplay({
    required this.number,
    required this.formatted,
    required this.onPaste,
  });

  final String number;
  final String formatted;
  final VoidCallback onPaste;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Container(
        height: 80,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: AppTheme.bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusMd),
          boxShadow: AppTheme.insetShadow(),
        ),
        child: Row(
          children: [
            // Paste icon — always visible but only active
            GestureDetector(
              onTap: onPaste,
              behavior: HitTestBehavior.opaque,
              child: const Padding(
                padding: EdgeInsets.all(8),
                child: Icon(Icons.content_paste_rounded,
                    size: 19, color: AppTheme.textHint),
              ),
            ),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 150),
                transitionBuilder: (child, anim) =>
                    FadeTransition(opacity: anim, child: child),
                child: Text(
                  formatted.isEmpty ? '' : formatted,
                  key: ValueKey(formatted),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: number.length > 10 ? 26 : 34,
                    fontWeight: FontWeight.w300,
                    color: AppTheme.textPrimary,
                    letterSpacing: 2.5,
                  ),
                ),
              ),
            ),
            // Spacer to balance the paste icon
            const SizedBox(width: 35),
          ],
        ),
      ),
    );
  }
}

//  SIM selector 

class _SimSelector extends StatelessWidget {
  const _SimSelector({
    required this.sims,
    required this.selected,
    required this.onSelect,
  });

  final List<dynamic> sims;
  final int selected;
  final void Function(int) onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 32,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: sims.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final isSelected = selected == i;
          final label = (sims[i] is Map)
              ? (sims[i] as Map)['displayName']?.toString() ?? 'SIM ${i + 1}'
              : 'SIM ${i + 1}';
          return GestureDetector(
            onTap: () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.primary : AppTheme.bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusFull),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: AppTheme.primary.withValues(alpha: 0.35),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ]
                    : AppTheme.raisedShadow(distance: 3, blur: 7),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : AppTheme.textSecondary,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

//  T9 suggestions 

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.suggestions, required this.onTap});

  final List<dynamic> suggestions;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 66,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = suggestions[i];
          final name = c.name as String? ?? '';
          final phone = c.phoneNumber as String? ?? '';
          return GestureDetector(
            onTap: () => onTap(phone),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.bg,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
                boxShadow: AppTheme.raisedShadow(distance: 3, blur: 9),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

//  Action row 

class _ActionRow extends StatelessWidget {
  const _ActionRow({
    required this.hasNumber,
    required this.onCall,
    required this.onBackspace,
    required this.onBackspaceLong,
    required this.onRedial,
  });

  final bool hasNumber;
  final VoidCallback onCall;
  final VoidCallback onBackspace;
  final VoidCallback onBackspaceLong;
  final VoidCallback onRedial;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(28, 4, 28, 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left — redial / empty placeholder
          SizedBox(
            width: 52,
            height: 52,
            child: hasNumber
                ? const SizedBox.shrink()
                : _IconAction(
                    icon: Icons.history_rounded,
                    onTap: onRedial,
                  ),
          ),

          // Center — call button
          _CallFab(enabled: hasNumber, onTap: hasNumber ? onCall : null),

          // Right — backspace / empty placeholder
          SizedBox(
            width: 52,
            height: 52,
            child: hasNumber
                ? _IconAction(
                    icon: Icons.backspace_outlined,
                    onTap: onBackspace,
                    onLongPress: onBackspaceLong,
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

//  Auxiliary widgets 

class _IconAction extends StatefulWidget {
  const _IconAction({
    required this.icon,
    required this.onTap,
    this.onLongPress,
  });

  final IconData icon;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  @override
  State<_IconAction> createState() => _IconActionState();
}

class _IconActionState extends State<_IconAction> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      onLongPress: widget.onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 80),
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: AppTheme.bg,
          shape: BoxShape.circle,
          boxShadow: _pressed
              ? AppTheme.insetShadow()
              : AppTheme.raisedShadow(distance: 3, blur: 9),
        ),
        child: Icon(widget.icon, size: 22, color: AppTheme.textSecondary),
      ),
    );
  }
}

class _CallFab extends StatefulWidget {
  const _CallFab({required this.enabled, this.onTap});

  final bool enabled;
  final VoidCallback? onTap;

  @override
  State<_CallFab> createState() => _CallFabState();
}

class _CallFabState extends State<_CallFab>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
    if (widget.enabled) _pulse.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(_CallFab old) {
    super.didUpdateWidget(old);
    if (widget.enabled && !old.enabled) {
      _pulse.repeat(reverse: true);
    } else if (!widget.enabled && old.enabled) {
      _pulse.stop();
      _pulse.reset();
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.enabled ? AppTheme.success : AppTheme.textHint;
    return GestureDetector(
      onTapDown: widget.enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap?.call();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedBuilder(
        animation: _pulseAnim,
        builder: (_, child) => Transform.scale(
          scale: (widget.enabled && !_pressed) ? _pulseAnim.value : 1.0,
          child: child,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 80),
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: _pressed || !widget.enabled
                ? AppTheme.insetShadow()
                : [
                    BoxShadow(
                      color: AppTheme.success.withValues(alpha: 0.45),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    ...AppTheme.raisedShadow(distance: 4, blur: 12),
                  ],
          ),
          child: const Icon(Icons.call_rounded, color: Colors.white, size: 30),
        ),
      ),
    );
  }
}

class _CallingOverlay extends StatelessWidget {
  const _CallingOverlay();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: AppTheme.success,
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Placing call',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
