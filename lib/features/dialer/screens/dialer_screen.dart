import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:call_log/call_log.dart' as call_log_pkg;
import '../../../core/models/call_info.dart';
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
            behavior: SnackBarBehavior.floating,
          ));
        } else if (state is DialerCalling && state.number.isNotEmpty) {
          // dial() succeeded — navigate to the in-call screen.
          context.push('/in-call', extra: {
            'callInfo': CallInfo(
              callId: state.number,
              state: CallState.dialing,
              callerNumber: state.number,
            ),
          });
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<DialerBloc, DialerState>(
            builder: (context, state) {
              // Both DialerPlacingCall (waiting for OS) and DialerCalling
              // (after success, briefly before push navigation fires) show overlay.
              if (state is DialerCalling || state is DialerPlacingCall) {
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

// ─── Number Display ──────────────────────────────────────────────────────────

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
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 88,
      child: Row(
        children: [
          IconButton(
            onPressed: onPaste,
            icon: const Icon(Icons.content_paste_rounded),
            iconSize: 20,
            color: scheme.onSurfaceVariant,
            tooltip: 'Paste number',
          ),
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 120),
              transitionBuilder: (child, anim) =>
                  FadeTransition(opacity: anim, child: child),
              child: FittedBox(
                key: ValueKey(formatted),
                fit: BoxFit.scaleDown,
                alignment: Alignment.center,
                child: Text(
                  formatted,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    color: scheme.onSurface,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 4,
                  ),
                ),
              ),
            ),
          ),
          // Symmetry spacer matching the paste icon button width
          const SizedBox(width: 48),
        ],
      ),
    );
  }
}

// ─── SIM Selector ────────────────────────────────────────────────────────────

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
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: sims.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final label = (sims[i] is Map)
              ? (sims[i] as Map)['displayName']?.toString() ?? 'SIM ${i + 1}'
              : 'SIM ${i + 1}';
          return ChoiceChip(
            label: Text(label),
            selected: selected == i,
            onSelected: (v) { if (v) onSelect(i); },
          );
        },
      ),
    );
  }
}

// ─── T9 Suggestion Bar ───────────────────────────────────────────────────────

class _SuggestionBar extends StatelessWidget {
  const _SuggestionBar({required this.suggestions, required this.onTap});

  final List<dynamic> suggestions;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: suggestions.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = suggestions[i];
          final name = c.name as String? ?? '';
          final phone = c.phoneNumber as String? ?? '';
          return Card(
            clipBehavior: Clip.hardEdge,
            child: InkWell(
              onTap: () => onTap(phone),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(phone,
                        style: textTheme.bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─── Action Row ──────────────────────────────────────────────────────────────

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
          // Left — redial (when nothing typed) / empty placeholder
          SizedBox(
            width: 52,
            height: 52,
            child: hasNumber
                ? null
                : IconButton.outlined(
                    icon: const Icon(Icons.history_rounded),
                    onPressed: onRedial,
                    tooltip: 'Redial last',
                  ),
          ),

          // Center — call button
          _CallButton(enabled: hasNumber, onTap: onCall),

          // Right — backspace (when digits typed) / empty placeholder
          SizedBox(
            width: 52,
            height: 52,
            child: hasNumber
                ? GestureDetector(
                    onLongPress: onBackspaceLong,
                    child: IconButton(
                      icon: const Icon(Icons.backspace_outlined),
                      onPressed: onBackspace,
                      tooltip: 'Backspace',
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

// ─── Call Button ─────────────────────────────────────────────────────────────

class _CallButton extends StatelessWidget {
  const _CallButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  static const _green = Color(0xFF1EA74A);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: enabled ? _green : scheme.surfaceContainerHighest,
      shape: const CircleBorder(),
      elevation: enabled ? 4 : 0,
      shadowColor: _green.withValues(alpha: 0.45),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: enabled ? onTap : null,
        splashColor: Colors.white24,
        child: SizedBox(
          width: 72,
          height: 72,
          child: Icon(
            Icons.call_rounded,
            color: enabled ? Colors.white : scheme.onSurfaceVariant,
            size: 30,
          ),
        ),
      ),
    );
  }
}

// ─── Calling Overlay ─────────────────────────────────────────────────────────

class _CallingOverlay extends StatelessWidget {
  const _CallingOverlay();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: scheme.primary, strokeWidth: 3),
          const SizedBox(height: 24),
          Text(
            'Placing call…',
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
